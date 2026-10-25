/*
===============================================================================
TEST 01 | DATA QUALITY CHECKS
===============================================================================
Purpose:
    Check the integrity of the staging and dimensional warehouse data.

Test strategy:
    Read-only. Each failed assertion stops execution with a clear error.

Run after:
    03_scripts/06_orchestration/02_execute_pipeline.sql

Expected result:
    PASS: grain, calendar, positive orders, references and staged item validation.
===============================================================================
*/
USE WeeklySalesPharmacyDWH;
GO

-- =============================================================================
-- 1. FACT GRAIN: ONE ROW PER PHARMACY PER WEEK
-- =============================================================================
-- The composite primary key also enforces this rule. Keeping the check here
-- makes our business grain explicit to readers of the test suite.
IF EXISTS
(
    SELECT 1
    FROM dbo.FactWeeklyPharmacySales
    GROUP BY PharmacyKey, WeekStartDateKey
    HAVING COUNT(*) > 1
)
    THROW 52001, 'Duplicate fact grain.', 1;


-- =============================================================================
-- 2. CALENDAR RULE: EACH FACT WEEK MUST START ON MONDAY
-- =============================================================================
-- 1900-01-01 was a Monday. Normalize the modulo to support older dates too.
IF EXISTS
(
    SELECT 1
    FROM dbo.FactWeeklyPharmacySales AS f
    INNER JOIN dbo.DimDate AS d
        ON d.DateKey = f.WeekStartDateKey
    WHERE ((DATEDIFF(DAY, '19000101', d.FullDate) % 7 + 7) % 7) <> 0
)
    THROW 52002, 'A fact week starts on a day other than Monday.', 1;


-- =============================================================================
-- 3. BUSINESS RULE: A FACT ROW NEEDS AT LEAST ONE DELIVERED ORDER
-- =============================================================================
IF EXISTS
(
    SELECT 1
    FROM dbo.FactWeeklyPharmacySales
    WHERE TotalOrders <= 0
)
    THROW 52003, 'Unexpected empty weekly sales row.', 1;


-- =============================================================================
-- 4. REFERENTIAL INTEGRITY: FACT KEYS MUST MATCH DIMENSIONS
-- =============================================================================
IF EXISTS
(
    SELECT 1
    FROM dbo.FactWeeklyPharmacySales AS f
    LEFT JOIN dbo.DimDate AS d
        ON d.DateKey = f.WeekStartDateKey
    WHERE d.DateKey IS NULL
)
    THROW 52004, 'Missing date dimension row.', 1;

IF EXISTS
(
    SELECT 1
    FROM dbo.FactWeeklyPharmacySales AS f
    LEFT JOIN dbo.DimPharmacy AS p
        ON p.PharmacyKey = f.PharmacyKey
    WHERE p.PharmacyKey IS NULL
)
    THROW 52005, 'Missing pharmacy dimension row.', 1;


-- =============================================================================
-- 5. STAGING VALUES: REJECT MISSING OR INVALID ITEM MEASURES
-- =============================================================================
-- Prices must be non-negative, quantities must be greater than zero.
IF EXISTS
(
    SELECT 1
    FROM stg.OrderItems
    WHERE Price IS NULL
       OR Quantity IS NULL
       OR Quantity <= 0
       OR Price < 0
)
    THROW 52006, 'Staging has invalid monetary or quantity values.', 1;

PRINT 'PASS: grain, calendar, positive orders, references and staged item validation.';
GO
