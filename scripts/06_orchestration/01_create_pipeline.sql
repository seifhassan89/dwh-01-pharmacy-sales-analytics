/*
===============================================================================
  WEEKLY PHARMACY SALES DATA WAREHOUSE
  Script : 01_create_pipeline.sql
  Goal   : Define end-to-end source-to-report orchestration.
  Model  : Kimball dimensional warehouse + dedicated staging area
  Grain  : One pharmacy per Monday-starting calendar week 
  Rules  : Currently Delivered orders; week derived from Orders.CreatedOn
  Prereq : All previous DDL and procedures must have been created.
===============================================================================
*/

USE WeeklySalesPharmacyDWH;
GO
CREATE OR ALTER PROCEDURE dbo.usp_Run_WeeklyPharmacyETL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    -- Serialize full loads so two sessions cannot overwrite each other.
    DECLARE @LockResult INT;
    EXEC @LockResult = sys.sp_getapplock
        @Resource = N'WeeklyPharmacyFullETL',
        @LockMode = N'Exclusive',
        @LockOwner = N'Session',
        @LockTimeout = 10000;

    IF @LockResult < 0
        THROW 51030, 'Could not acquire weekly pharmacy ETL lock.', 1;

    BEGIN TRY
        -- 1. Snapshot all source tables into staging.
        EXEC stg.usp_Load_SourceSnapshot;

        -- 2. Validate the snapshot BEFORE loading analytical tables.
        EXEC stg.usp_Validate_SourceSnapshot;

        -- 3. Ensure the calendar contains the intended date range.
        EXEC dbo.usp_Load_DimDate;

        -- 4. Apply dimension and fact changes together.
        BEGIN TRANSACTION;
            EXEC dbo.usp_Load_DimPharmacy;
            EXEC dbo.usp_Load_DimOrderStatus;
            EXEC dbo.usp_Load_FactWeeklyPharmacySales;
        COMMIT TRANSACTION;

        EXEC sys.sp_releaseapplock
            @Resource = N'WeeklyPharmacyFullETL',
            @LockOwner = N'Session';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        EXEC sys.sp_releaseapplock
            @Resource = N'WeeklyPharmacyFullETL',
            @LockOwner = N'Session';
        THROW;
    END CATCH;
END;
GO
