/*
===============================================================================
  WEEKLY PHARMACY SALES DATA WAREHOUSE
  Script : 03_load_dim_date.sql
  Goal   : Generate reusable daily calendar records.
  Model  : Kimball dimensional warehouse + dedicated staging area
  Grain  : One pharmacy per Monday-starting calendar week 
  Rules  : Currently Delivered orders; week derived from Orders.CreatedOn
===============================================================================
*/

USE WeeklySalesPharmacyDWH;
GO
CREATE OR ALTER PROCEDURE dbo.usp_Load_DimDate
    @StartDate DATE = '2020-01-01',
    @EndDate DATE = '2030-12-31'
AS
BEGIN
    SET NOCOUNT ON;
    IF @StartDate > @EndDate
        THROW 51010, 'Calendar date range reversed.', 1;

    DECLARE @Date DATE = @StartDate;
    WHILE @Date <= @EndDate
    BEGIN
        -- DateKey uses the YYYYMMDD convention (e.g. 20261005).
        INSERT INTO dbo.DimDate
        (
            DateKey, FullDate, DayOfMonth, DayName, WeekOfYear,
            MonthNumber, MonthName, [Quarter], [Year], IsWeekend
        )
        SELECT
            CONVERT(INT, CONVERT(CHAR(8), @Date, 112)),
            @Date,
            DAY(@Date),
            DATENAME(WEEKDAY, @Date),
            DATEPART(ISO_WEEK, @Date),
            MONTH(@Date),
            DATENAME(MONTH, @Date),
            DATEPART(QUARTER, @Date),
            YEAR(@Date),
            -- In this project, Egyptian weekend = Friday and Saturday.
            CASE WHEN ((DATEDIFF(DAY, '19000106', @Date) % 7 + 7) % 7)
                      IN (0, 6) THEN 1 ELSE 0 END
        WHERE NOT EXISTS (SELECT 1 FROM dbo.DimDate WHERE FullDate = @Date);

        SET @Date = DATEADD(DAY, 1, @Date);
    END;
END;
GO
