/*
===============================================================================
  WEEKLY PHARMACY SALES DATA WAREHOUSE
  Script : 01_create_staging_tables.sql
  Goal   : Define full-source-snapshot staging tables.
  Model  : Kimball dimensional warehouse + dedicated staging area
  Grain  : One pharmacy per Monday-starting calendar week 
  Rules  : Currently Delivered orders; week derived from Orders.CreatedOn
  Staging : Replaced each run; not itself a history archive.
===============================================================================
*/

USE WeeklySalesPharmacyDWH;
GO

-- Pharmacies: One record per source pharmacy; PharmacyBisKey is the order-facing identifier.
IF OBJECT_ID(N'stg.Pharmacies', N'U') IS NULL
BEGIN
    CREATE TABLE stg.Pharmacies
    (
        Id                  INT            NOT NULL PRIMARY KEY,
        PharmacyBisKey      NVARCHAR(200)  NOT NULL,
        CreatedOn           DATETIME       NOT NULL,
        TestFlag            BIT            NOT NULL
    );
END;
GO

-- OrderStateTypes: Keep status identifiers and names; Delivered is evaluated later.
IF OBJECT_ID(N'stg.OrderStateTypes', N'U') IS NULL
BEGIN
    CREATE TABLE stg.OrderStateTypes
    (
        Id                  INT            NOT NULL PRIMARY KEY,
        OrderStateTypeId    INT            NOT NULL,
        StateName           NVARCHAR(200)  NOT NULL
    );
END;
GO

-- Orders: One row per order; CreatedOn assigns the order to a reporting week.
IF OBJECT_ID(N'stg.Orders', N'U') IS NULL
BEGIN
    CREATE TABLE stg.Orders
    (
        Id                  INT            NOT NULL PRIMARY KEY,
        PharmacyBisKey      NVARCHAR(200)  NOT NULL,
        OrderStateTypeId    INT            NOT NULL,
        CreatedOn           DATETIME       NOT NULL
    );
END;
GO

-- OrderItems: One row per order line. NULL amount fields allow validation after TRY_CONVERT.
IF OBJECT_ID(N'stg.OrderItems', N'U') IS NULL
BEGIN
    CREATE TABLE stg.OrderItems
    (
        Id                  INT            NOT NULL PRIMARY KEY,
        OrderId             INT            NOT NULL,
        Price               DECIMAL(28,4)  NULL,
        Quantity            DECIMAL(18,4)  NULL
    );
END;
GO
