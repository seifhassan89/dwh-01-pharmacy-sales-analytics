/*
===============================================================================
  WEEKLY PHARMACY SALES DATA WAREHOUSE
  Script : 01_create_dimensions.sql
  Goal   : Create date, pharmacy and order-status lookup dimensions.
  Model  : Kimball dimensional warehouse + dedicated staging area
  Grain  : One pharmacy per Monday-starting calendar week 
  Rules  : Currently Delivered orders; week derived from Orders.CreatedOn
===============================================================================
*/

USE WeeklySalesPharmacyDWH;
GO

-- Date dimension: one row per calendar DAY. The weekly fact references Monday.
IF OBJECT_ID(N'dbo.DimDate', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.DimDate
    (
        DateKey      INT          NOT NULL PRIMARY KEY,
        FullDate     DATE         NOT NULL UNIQUE,
        DayOfMonth   TINYINT      NOT NULL,
        DayName      NVARCHAR(20) NOT NULL,
        WeekOfYear   TINYINT      NOT NULL,
        MonthNumber  TINYINT      NOT NULL,
        MonthName    NVARCHAR(20) NOT NULL,
        [Quarter]    TINYINT      NOT NULL,
        [Year]       SMALLINT     NOT NULL,
        IsWeekend    BIT          NOT NULL
    );
END;
GO

-- Pharmacy dimension: one row per source pharmacy (Type 1 overwrite).
IF OBJECT_ID(N'dbo.DimPharmacy', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.DimPharmacy
    (
        PharmacyKey      INT           NOT NULL PRIMARY KEY,
        PharmacyBisKey   NVARCHAR(200) NOT NULL UNIQUE,
        CreatedOn        DATETIME      NOT NULL,
        TestFlag         BIT           NOT NULL
    );
END;
GO

-- Status is an ETL lookup, not a foreign-key dimension of the weekly fact.
IF OBJECT_ID(N'dbo.DimOrderStatus', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.DimOrderStatus
    (
        OrderStatusKey     INT           NOT NULL PRIMARY KEY,
        OrderStateTypeId   INT           NOT NULL UNIQUE,
        StateName          NVARCHAR(200) NOT NULL
    );
END;
GO
