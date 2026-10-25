/*
===============================================================================
TEST 02 | WEEKLY SALES RECONCILIATION
===============================================================================
Purpose:
    Recalculate weekly pharmacy totals independently from staged source lines
    and compare them to the published FactWeeklyPharmacySales table.

Grain:
    One row per pharmacy per Monday-starting week.

Important:
    Includes test pharmacies: the Fact stores them, while the reporting view
    hides them. Revenue is item Price * Quantity; no delivery fees added.

Expected result:
    PASS: all pharmacy-week sales and order counts reconcile to staged source lines.
===============================================================================
*/
USE WeeklySalesPharmacyDWH;
GO

-- =============================================================================
-- 1. RECOMPUTE WEEKLY TOTALS INDEPENDENTLY FROM STAGING
-- =============================================================================
;WITH SourceWeeks AS
(
    SELECT
        p.PharmacyKey,
        CONVERT
        (
            INT,
            CONVERT
            (
                CHAR(8),
                DATEADD
                (
                    DAY,
                    -((DATEDIFF(DAY, '19000101', CAST(o.CreatedOn AS DATE)) % 7 + 7) % 7),
                    CAST(o.CreatedOn AS DATE)
                ),
                112
            )
        ) AS WeekStartDateKey,
        COUNT(DISTINCT o.Id) AS TotalOrders,
        CAST
        (
            SUM(CAST(i.Price AS DECIMAL(28,4)) * CAST(i.Quantity AS DECIMAL(18,4)))
            AS DECIMAL(38,2)
        ) AS TotalSales
    FROM stg.Orders AS o
    INNER JOIN stg.OrderItems AS i
        ON i.OrderId = o.Id
    INNER JOIN stg.OrderStateTypes AS s
        ON s.OrderStateTypeId = o.OrderStateTypeId
    INNER JOIN stg.Pharmacies AS p
        ON p.PharmacyBisKey = o.PharmacyBisKey
    WHERE s.StateName = N'Delivered'
    GROUP BY
        p.PharmacyKey,
        DATEADD
        (
            DAY,
            -((DATEDIFF(DAY, '19000101', CAST(o.CreatedOn AS DATE)) % 7 + 7) % 7),
            CAST(o.CreatedOn AS DATE)
        )
),
-- =============================================================================
-- 2. FIND MISSING ROWS AND DIFFERENT MEASURES IN EITHER DIRECTION
-- =============================================================================
Differences AS
(
    SELECT
        COALESCE(s.PharmacyKey, f.PharmacyKey) AS PharmacyKey,
        COALESCE(s.WeekStartDateKey, f.WeekStartDateKey) AS WeekStartDateKey
    FROM SourceWeeks AS s
    FULL OUTER JOIN dbo.FactWeeklyPharmacySales AS f
        ON f.PharmacyKey = s.PharmacyKey
       AND f.WeekStartDateKey = s.WeekStartDateKey
    WHERE s.PharmacyKey IS NULL
       OR f.PharmacyKey IS NULL
       OR s.TotalOrders <> f.TotalOrders
       OR s.TotalSales <> f.TotalSales
)
SELECT *
INTO #Diff
FROM Differences;

-- =============================================================================
-- 3. FAIL WITH THE PHARMACY/WEEK KEYS IF ANY MISMATCH EXISTS
-- =============================================================================
IF EXISTS (SELECT 1 FROM #Diff)
BEGIN
    SELECT *
    FROM #Diff
    ORDER BY WeekStartDateKey, PharmacyKey;

    THROW 52010, 'FAILED: Staging to warehouse fact reconciliation mismatch.', 1;
END;

PRINT 'PASS: all pharmacy-week sales and order counts reconcile to staged source lines.';
DROP TABLE #Diff;
GO
