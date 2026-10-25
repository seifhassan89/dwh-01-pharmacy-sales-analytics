/*
===============================================================================
  WEEKLY PHARMACY SALES DATA WAREHOUSE
  Script : 02_execute_pipeline.sql
  Goal   : Run the full ETL, then display weekly sales.
  Model  : Kimball dimensional warehouse + dedicated staging area
  Grain  : One pharmacy per Monday-starting calendar week 
  Rules  : Currently Delivered orders; week derived from Orders.CreatedOn
===============================================================================
*/

USE WeeklySalesPharmacyDWH;
GO

-- Requires the source database and all previous scripts.
EXEC dbo.usp_Run_WeeklyPharmacyETL;
GO

SELECT
    Pharmacy,
    WeekStart,
    WeekEnd,
    TotalOrders,
    TotalSales
FROM dbo.vw_WeeklyPharmacySales
ORDER BY WeekStart, Pharmacy;
GO
