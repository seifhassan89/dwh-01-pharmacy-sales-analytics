/*
===============================================================================
  WEEKLY PHARMACY SALES DATA WAREHOUSE
  Script : 01_validate_source_snapshot.sql
  Goal   : Reject duplicate lookups, invalid items and missing references.
  Model  : Kimball dimensional warehouse + dedicated staging area
  Grain  : One pharmacy per Monday-starting calendar week 
  Rules  : Currently Delivered orders; week derived from Orders.CreatedOn
===============================================================================
*/

USE WeeklySalesPharmacyDWH;
GO
CREATE OR ALTER PROCEDURE stg.usp_Validate_SourceSnapshot
AS
BEGIN
    SET NOCOUNT ON;

    -- Duplicate lookup keys would multiply the number of joined sales rows.
    IF EXISTS (
        SELECT PharmacyBisKey FROM stg.Pharmacies
        GROUP BY PharmacyBisKey HAVING COUNT(*) > 1
    ) THROW 51001, 'Duplicate pharmacy business keys in staging.', 1;

    IF EXISTS (
        SELECT OrderStateTypeId FROM stg.OrderStateTypes
        GROUP BY OrderStateTypeId HAVING COUNT(*) > 1
    ) THROW 51002, 'Duplicate status business keys in staging.', 1;

    -- Reject incomplete, negative or zero-quantity order lines.
    IF EXISTS (
        SELECT 1 FROM stg.OrderItems
        WHERE Price IS NULL OR Quantity IS NULL OR Price < 0 OR Quantity <= 0
    ) THROW 51003, 'Invalid or unconvertible item price/quantity in staging.', 1;

    -- Orphans may indicate missing records in the input source snapshot.
    IF EXISTS (
        SELECT 1 FROM stg.OrderItems AS i
        LEFT JOIN stg.Orders AS o ON o.Id = i.OrderId
        WHERE o.Id IS NULL
    ) THROW 51004, 'Orphaned order item in staging.', 1;

    IF EXISTS (
        SELECT 1 FROM stg.Orders AS o
        LEFT JOIN stg.Pharmacies AS p ON p.PharmacyBisKey = o.PharmacyBisKey
        WHERE p.Id IS NULL
    ) THROW 51005, 'Order references unknown pharmacy.', 1;

    IF EXISTS (
        SELECT 1 FROM stg.Orders AS o
        LEFT JOIN stg.OrderStateTypes AS s ON s.OrderStateTypeId = o.OrderStateTypeId
        WHERE s.Id IS NULL
    ) THROW 51006, 'Order references unknown status.', 1;

    IF NOT EXISTS (
        SELECT 1 FROM stg.OrderStateTypes WHERE StateName = N'Delivered'
    ) THROW 51007, 'Delivered status missing in source snapshot.', 1;
END;
GO
