/*
===============================================================================
  WEEKLY PHARMACY SALES DATA WAREHOUSE
  Script : 05_load_dim_order_status.sql
  Goal   : Refresh the Delivered status lookup.
  Model  : Kimball dimensional warehouse + dedicated staging area
  Grain  : One pharmacy per Monday-starting calendar week 
  Rules  : Currently Delivered orders; week derived from Orders.CreatedOn
===============================================================================
*/

USE WeeklySalesPharmacyDWH;
GO
CREATE OR ALTER PROCEDURE dbo.usp_Load_DimOrderStatus
AS
BEGIN
    SET NOCOUNT ON;

    -- The status lookup is refreshed before the fact is calculated.
    UPDATE d
       SET d.OrderStateTypeId = s.OrderStateTypeId,
           d.StateName        = s.StateName
    FROM dbo.DimOrderStatus AS d
    INNER JOIN stg.OrderStateTypes AS s ON s.Id = d.OrderStatusKey
    WHERE d.OrderStateTypeId <> s.OrderStateTypeId
       OR d.StateName <> s.StateName;

    INSERT INTO dbo.DimOrderStatus
        (OrderStatusKey, OrderStateTypeId, StateName)
    SELECT s.Id, s.OrderStateTypeId, s.StateName
    FROM stg.OrderStateTypes AS s
    WHERE NOT EXISTS (
        SELECT 1 FROM dbo.DimOrderStatus AS d WHERE d.OrderStatusKey = s.Id
    );
END;
GO
