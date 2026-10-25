/*
===============================================================================
  WEEKLY PHARMACY SALES DATA WAREHOUSE
  Script : 01_create_database.sql
  Goal   : Create the database and switch context.
  Model  : Kimball dimensional warehouse + dedicated staging area
  Grain  : One pharmacy per Monday-starting calendar week 
  Rules  : Currently Delivered orders; week derived from Orders.CreatedOn
===============================================================================
*/

-- Create once. Running the script again will not delete your data.
IF DB_ID(N'WeeklySalesPharmacyDWH') IS NULL
BEGIN
    CREATE DATABASE WeeklySalesPharmacyDWH;
END;
GO

USE WeeklySalesPharmacyDWH;
GO
