/*
===============================================================================
TEST 03 | END-TO-END ETL INTEGRATION TESTS
===============================================================================
Purpose:
    Prove weekly aggregation, rerun safety, price changes, delivery status
    changes, stale-row deletion, insertion, and reporting filters.

Safety:
    Only run on the synthetic sample database on a disposable SQL Server.
    Sample signature and expected baseline are verified before mutations.

  DESTRUCTIVE TEST OPERATIONS (rolled back on success and failure).
  Run ONLY against the sample source on a disposable SQL Server instance,
  AFTER the setup scripts and 03_scripts/06_orchestration/02_execute_pipeline.sql.
  Source and warehouse must be in the same SQL Server instance.
  No changes are retained: the outer transaction is always rolled back.
===============================================================================
*/
USE WeeklySalesPharmacyDWH;
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;

-- =============================================================================
-- 1. SAFETY GATE: NEVER MUTATE AN UNRECOGNIZED SOURCE DATABASE
-- =============================================================================
-- Fail closed: do not exercise mutations against unfamiliar data.
IF DB_ID(N'OnlinePharmacyDB') IS NULL
   OR NOT EXISTS (SELECT 1 FROM OnlinePharmacyDB.sys.extended_properties
                  WHERE class=0 AND name=N'WeeklyPharmacyDemoOnly'
                    AND CONVERT(NVARCHAR(200), value)=N'Synthetic training data - safe to test')
   OR (SELECT COUNT(*) FROM OnlinePharmacyDB.dbo.Pharmacies) <> 3
   OR NOT EXISTS (SELECT 1 FROM OnlinePharmacyDB.dbo.Pharmacies WHERE Id=101 AND [Key]=N'PHARMACY-A')
   OR NOT EXISTS (SELECT 1 FROM OnlinePharmacyDB.dbo.Orders WHERE Id=1001 AND PharmacyKey=N'PHARMACY-A')
    THROW 53000, 'Sample data signature not found; refusing integration tests.', 1;

-- =============================================================================
-- 2. VERIFY THE EXPECTED SAMPLE BASELINE BEFORE STARTING
-- =============================================================================
-- Require a clean baseline, rather than mutate an unfamiliar dataset.
IF (SELECT COUNT(*) FROM OnlinePharmacyDB.dbo.Orders) <> 7
   OR (SELECT COUNT(*) FROM OnlinePharmacyDB.dbo.OrderItems) <> 8
   OR (SELECT COUNT(*) FROM dbo.FactWeeklyPharmacySales) <> 5
    THROW 53001, 'Demo baseline differs; use a fresh demo instance and run the ETL.', 1;

-- =============================================================================
-- 3. RUN THE SCENARIOS INSIDE ONE ROLLBACK-ONLY TRANSACTION
-- =============================================================================
BEGIN TRY
    BEGIN TRANSACTION;

    -- -------------------------------------------------------------------------
    -- TEST 1: Multiple items count as ONE order, and canceled orders do not count.
    IF NOT EXISTS (
        SELECT 1 FROM dbo.FactWeeklyPharmacySales
        WHERE PharmacyKey = 101 AND WeekStartDateKey = 20240304
          AND TotalOrders = 2 AND TotalSales = 325.00
    ) THROW 53002, 'FAIL: multi-item order / canceled order / aggregation.', 1;
    IF NOT EXISTS (
        SELECT 1 FROM dbo.FactWeeklyPharmacySales
        WHERE PharmacyKey = 102 AND WeekStartDateKey = 20240304
          AND TotalOrders = 1 AND TotalSales = 120.00
    ) THROW 53003, 'FAIL: pharmacy isolation.', 1;

    -- -------------------------------------------------------------------------
    -- TEST 2: Re-running load must not change row count or values.
    EXEC dbo.usp_Run_WeeklyPharmacyETL;
    IF (SELECT COUNT(*) FROM dbo.FactWeeklyPharmacySales) <> 5
       OR NOT EXISTS (SELECT 1 FROM dbo.FactWeeklyPharmacySales
                      WHERE PharmacyKey=101 AND WeekStartDateKey=20240304
                        AND TotalSales=325.00 AND TotalOrders=2)
        THROW 53004, 'FAIL: idempotent reload.', 1;

    -- -------------------------------------------------------------------------
    -- TEST 3: Price change recalculates the historical weekly total.
    UPDATE OnlinePharmacyDB.dbo.OrderItems SET Price = 110.00 WHERE Id=1;
    EXEC dbo.usp_Run_WeeklyPharmacyETL;
    IF NOT EXISTS (SELECT 1 FROM dbo.FactWeeklyPharmacySales
                   WHERE PharmacyKey=101 AND WeekStartDateKey=20240304
                     AND TotalSales=345.00 AND TotalOrders=2)
        THROW 53005, 'FAIL: price change not reflected.', 1;

    -- -------------------------------------------------------------------------
    -- TEST 4: Newly delivered order is included.
    UPDATE OnlinePharmacyDB.dbo.Orders SET OrderStateTypeId=20 WHERE Id=1005;
    EXEC dbo.usp_Run_WeeklyPharmacyETL;
    IF NOT EXISTS (SELECT 1 FROM dbo.FactWeeklyPharmacySales
                   WHERE PharmacyKey=101 AND WeekStartDateKey=20240304
                     AND TotalSales=1344.00 AND TotalOrders=3)
        THROW 53006, 'FAIL: newly delivered order.', 1;

    -- -------------------------------------------------------------------------
    -- TEST 5: Losing a pharmacy-week's last delivered order removes that fact row.
    UPDATE OnlinePharmacyDB.dbo.Orders SET OrderStateTypeId=30 WHERE Id=1004;
    EXEC dbo.usp_Run_WeeklyPharmacyETL;
    IF EXISTS (SELECT 1 FROM dbo.FactWeeklyPharmacySales
               WHERE PharmacyKey=101 AND WeekStartDateKey=20240311)
        THROW 53007, 'FAIL: stale pharmacy-week not removed.', 1;

    -- -------------------------------------------------------------------------
    -- TEST 6: New pharmacy-week is inserted.
    INSERT OnlinePharmacyDB.dbo.Orders (Id, PharmacyKey, OrderStateTypeId, CreatedOn)
    VALUES (2001, N'PHARMACY-B', 20, '2024-03-18T11:00:00');
    INSERT OnlinePharmacyDB.dbo.OrderItems (Id, OrderId, Price, Quantity)
    VALUES (2001, 2001, 25.00, 2);
    EXEC dbo.usp_Run_WeeklyPharmacyETL;
    IF NOT EXISTS (SELECT 1 FROM dbo.FactWeeklyPharmacySales
                   WHERE PharmacyKey=102 AND WeekStartDateKey=20240318
                     AND TotalSales=50.00 AND TotalOrders=1)
        THROW 53008, 'FAIL: new pharmacy-week not inserted.', 1;

    -- -------------------------------------------------------------------------
    -- TEST 7: Reporting view excludes test pharmacies but retains real pharmacies.
    IF EXISTS (SELECT 1 FROM dbo.vw_WeeklyPharmacySales WHERE Pharmacy=N'PHARMACY-TEST')
       OR NOT EXISTS (SELECT 1 FROM dbo.vw_WeeklyPharmacySales WHERE Pharmacy=N'PHARMACY-A')
        THROW 53009, 'FAIL: reporting filter.', 1;

    -- Keep the demo database unchanged for another test run.
    ROLLBACK TRANSACTION;
    PRINT 'PASS: 7 SQL integration scenarios. Test modifications were rolled back.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO
