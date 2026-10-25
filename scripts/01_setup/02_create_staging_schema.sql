/*
===============================================================================
  WEEKLY PHARMACY SALES DATA WAREHOUSE
  Script : 02_create_staging_schema.sql
  Goal   : Create the dedicated staging namespace.
  Model  : Kimball dimensional warehouse + dedicated staging area
  Grain  : One pharmacy per Monday-starting calendar week 
  Rules  : Currently Delivered orders; week derived from Orders.CreatedOn
===============================================================================
*/

USE WeeklySalesPharmacyDWH;
GO

-- A staging schema separates the raw source snapshot from analytical tables.
IF SCHEMA_ID(N'stg') IS NULL
BEGIN
    EXEC(N'CREATE SCHEMA stg');
END;
GO
