/*
===============================================================================
  WEEKLY PHARMACY SALES DATA WAREHOUSE
  Script : 06_load_fact_weekly_sales.sql
  Goal   : Aggregate and synchronize one row per pharmacy and week.
  Model  : Kimball dimensional warehouse + dedicated staging area
  Grain  : One pharmacy per Monday-starting calendar week 
  Rules  : Currently Delivered orders; week derived from Orders.CreatedOn
===============================================================================
*/

USE WeeklySalesPharmacyDWH;
GO
CREATE OR ALTER PROCEDURE dbo.usp_Load_FactWeeklyPharmacySales
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    -- Guard 1: do not silently exclude an order because a Monday date
    -- is missing from DimDate (for example outside 2020-2030).
    IF EXISTS (
        SELECT 1
        FROM stg.Orders AS o
        JOIN stg.OrderItems AS i ON i.OrderId = o.Id
        JOIN dbo.DimOrderStatus AS s ON s.OrderStateTypeId = o.OrderStateTypeId
        LEFT JOIN dbo.DimDate AS d
            ON d.FullDate = DATEADD(
                DAY,
                -((DATEDIFF(DAY, '19000101', CAST(o.CreatedOn AS DATE)) % 7 + 7) % 7),
                CAST(o.CreatedOn AS DATE)
            )
        WHERE s.StateName = N'Delivered' AND d.DateKey IS NULL
    ) THROW 51020, 'DimDate is missing a delivered order week.', 1;

    -- Guard 2: every delivered order must resolve to a known pharmacy.
    IF EXISTS (
        SELECT 1
        FROM stg.Orders AS o
        JOIN stg.OrderItems AS i ON i.OrderId = o.Id
        JOIN dbo.DimOrderStatus AS s ON s.OrderStateTypeId = o.OrderStateTypeId
        LEFT JOIN dbo.DimPharmacy AS p ON p.PharmacyBisKey = o.PharmacyBisKey
        WHERE s.StateName = N'Delivered' AND p.PharmacyKey IS NULL
    ) THROW 51021, 'DimPharmacy missing a delivered order pharmacy.', 1;

    -- Stage aggregation exactly ONCE to avoid repeating large source joins.
    -- Multiple lines per order: SUM all lines, COUNT that order only once.
    SELECT
        d.DateKey AS WeekStartDateKey,
        p.PharmacyKey,
        COUNT(DISTINCT o.Id) AS TotalOrders,
        CAST(
            SUM(CAST(i.Price AS DECIMAL(28,4)) * CAST(i.Quantity AS DECIMAL(18,4)))
            AS DECIMAL(38,2)
        ) AS TotalSales
    INTO #WeeklySales
    FROM stg.Orders AS o
    JOIN stg.OrderItems AS i ON i.OrderId = o.Id
    JOIN dbo.DimOrderStatus AS s ON s.OrderStateTypeId = o.OrderStateTypeId
    JOIN dbo.DimPharmacy AS p ON p.PharmacyBisKey = o.PharmacyBisKey
    JOIN dbo.DimDate AS d
      ON d.FullDate = DATEADD(
          DAY,
          -((DATEDIFF(DAY, '19000101', CAST(o.CreatedOn AS DATE)) % 7 + 7) % 7),
          CAST(o.CreatedOn AS DATE)
      )
    WHERE s.StateName = N'Delivered'
    GROUP BY d.DateKey, p.PharmacyKey;

    CREATE UNIQUE CLUSTERED INDEX IX_WeeklySales_Grain
        ON #WeeklySales (WeekStartDateKey, PharmacyKey);

    BEGIN TRY
        BEGIN TRANSACTION;

        -- UPDATE: refresh existing pharmacy-week rows if the measures changed.
        UPDATE f
           SET f.TotalOrders = w.TotalOrders,
               f.TotalSales  = w.TotalSales
        FROM dbo.FactWeeklyPharmacySales AS f
        JOIN #WeeklySales AS w
          ON f.PharmacyKey = w.PharmacyKey
         AND f.WeekStartDateKey = w.WeekStartDateKey
        WHERE f.TotalOrders <> w.TotalOrders OR f.TotalSales <> w.TotalSales;

        -- INSERT: add pharmacy-weeks that are not present yet.
        INSERT INTO dbo.FactWeeklyPharmacySales
            (WeekStartDateKey, PharmacyKey, TotalOrders, TotalSales)
        SELECT w.WeekStartDateKey, w.PharmacyKey, w.TotalOrders, w.TotalSales
        FROM #WeeklySales AS w
        WHERE NOT EXISTS (
            SELECT 1 FROM dbo.FactWeeklyPharmacySales AS f WITH (UPDLOCK, HOLDLOCK)
            WHERE f.WeekStartDateKey = w.WeekStartDateKey
              AND f.PharmacyKey = w.PharmacyKey
        );

        -- DELETE: remove old pharmacy-weeks that no longer have delivered lines.
        -- IMPORTANT: full-snapshot source required; never run with partial feeds.
        DELETE f
        FROM dbo.FactWeeklyPharmacySales AS f
        WHERE NOT EXISTS (
            SELECT 1 FROM #WeeklySales AS w
            WHERE w.WeekStartDateKey = f.WeekStartDateKey
              AND w.PharmacyKey = f.PharmacyKey
        );

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO
