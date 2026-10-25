/*
===============================================================================
  WEEKLY PHARMACY SALES DATA WAREHOUSE
  Script : 02_create_weekly_fact.sql
  Goal   : Create the aggregated pharmacy-week fact and grain constraints.
  Model  : Kimball dimensional warehouse + dedicated staging area
  Grain  : One pharmacy per Monday-starting calendar week 
  Rules  : Currently Delivered orders; week derived from Orders.CreatedOn
===============================================================================
*/

USE WeeklySalesPharmacyDWH;
GO

-- Fact grain: ONE row per pharmacy per Monday-starting week.
-- Zero-order weeks are not stored; TotalSales excludes delivery fees.
IF OBJECT_ID(N'dbo.FactWeeklyPharmacySales', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.FactWeeklyPharmacySales
    (
        WeekStartDateKey INT           NOT NULL,
        PharmacyKey      INT           NOT NULL,
        TotalOrders      INT           NOT NULL,
        TotalSales       DECIMAL(38,2) NOT NULL,

        CONSTRAINT PK_FactWeeklyPharmacySales
            PRIMARY KEY (WeekStartDateKey, PharmacyKey),
        CONSTRAINT FK_WeeklySales_Date
            FOREIGN KEY (WeekStartDateKey) REFERENCES dbo.DimDate(DateKey),
        CONSTRAINT FK_WeeklySales_Pharmacy
            FOREIGN KEY (PharmacyKey) REFERENCES dbo.DimPharmacy(PharmacyKey),
        CONSTRAINT CK_WeeklySales_Orders
            CHECK (TotalOrders > 0)
    );
END;
GO
