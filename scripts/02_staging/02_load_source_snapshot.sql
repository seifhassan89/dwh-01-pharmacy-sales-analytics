/*
===============================================================================
  WEEKLY PHARMACY SALES DATA WAREHOUSE
  Script : 02_load_source_snapshot.sql
  Goal   : Replace all four staging tables from OnlinePharmacyDB.
  Model  : Kimball dimensional warehouse + dedicated staging area
  Grain  : One pharmacy per Monday-starting calendar week 
  Rules  : Currently Delivered orders; week derived from Orders.CreatedOn
  Safety  : Use only with a COMPLETE operational snapshot.
===============================================================================
*/

USE WeeklySalesPharmacyDWH;
GO

CREATE OR ALTER PROCEDURE stg.usp_Load_SourceSnapshot
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Delete child rows first: this is a complete snapshot replacement.
        -- Never run with a partial upstream feed.
        DELETE FROM stg.OrderItems;
        DELETE FROM stg.Orders;
        DELETE FROM stg.Pharmacies;
        DELETE FROM stg.OrderStateTypes;

        -- Preserve the business keys from the operational database.
        INSERT INTO stg.Pharmacies (Id, PharmacyBisKey, CreatedOn, TestFlag)
        SELECT Id, [Key], CreatedOn, TestFlag
        FROM OnlinePharmacyDB.dbo.Pharmacies;

        INSERT INTO stg.OrderStateTypes (Id, OrderStateTypeId, StateName)
        SELECT Id, OrderStateTypeId, StateName
        FROM OnlinePharmacyDB.dbo.OrderStateTypes;

        INSERT INTO stg.Orders (Id, PharmacyBisKey, OrderStateTypeId, CreatedOn)
        SELECT Id, PharmacyKey, OrderStateTypeId, CreatedOn
        FROM OnlinePharmacyDB.dbo.Orders;

        -- Keep invalid numeric conversions as NULL; the validation step
        -- rejects these BEFORE modifying dimensions or the weekly fact.
        INSERT INTO stg.OrderItems (Id, OrderId, Price, Quantity)
        SELECT
            Id,
            OrderId,
            TRY_CONVERT(DECIMAL(28,4), Price),
            TRY_CONVERT(DECIMAL(18,4), Quantity)
        FROM OnlinePharmacyDB.dbo.OrderItems;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO
