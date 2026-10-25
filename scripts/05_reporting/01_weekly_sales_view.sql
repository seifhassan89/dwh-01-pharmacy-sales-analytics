/*
===============================================================================
  WEEKLY PHARMACY SALES DATA WAREHOUSE
  Script : 01_weekly_sales_view.sql
  Goal   : Expose analyst-friendly pharmacy-week metrics.
  Model  : Kimball dimensional warehouse + dedicated staging area
  Grain  : One pharmacy per Monday-starting calendar week 
  Rules  : Currently Delivered orders; week derived from Orders.CreatedOn
===============================================================================
*/

USE WeeklySalesPharmacyDWH;
GO

-- Views do not aggregate order lines: the fact ALREADY stores weekly totals.
-- Test pharmacies are hidden only from reporting, not from the warehouse.
CREATE OR ALTER VIEW dbo.vw_WeeklyPharmacySales
AS
SELECT
    p.PharmacyBisKey AS Pharmacy,
    d.FullDate AS WeekStart,
    DATEADD(DAY, 6, d.FullDate) AS WeekEnd,
    f.TotalOrders,
    f.TotalSales
FROM dbo.FactWeeklyPharmacySales AS f
JOIN dbo.DimDate AS d ON d.DateKey = f.WeekStartDateKey
JOIN dbo.DimPharmacy AS p ON p.PharmacyKey = f.PharmacyKey
WHERE p.TestFlag = 0;
GO
