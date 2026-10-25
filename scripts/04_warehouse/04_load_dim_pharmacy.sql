/*
===============================================================================
  WEEKLY PHARMACY SALES DATA WAREHOUSE
  Script : 04_load_dim_pharmacy.sql
  Goal   : Synchronize pharmacy attributes (Type 1).
  Model  : Kimball dimensional warehouse + dedicated staging area
  Grain  : One pharmacy per Monday-starting calendar week 
  Rules  : Currently Delivered orders; week derived from Orders.CreatedOn
===============================================================================
*/

USE WeeklySalesPharmacyDWH;
GO
CREATE OR ALTER PROCEDURE dbo.usp_Load_DimPharmacy
AS
BEGIN
    SET NOCOUNT ON;

    -- Type 1 dimension: overwrite attributes for pharmacies already loaded.
    UPDATE d
       SET d.PharmacyBisKey = s.PharmacyBisKey,
           d.CreatedOn      = s.CreatedOn,
           d.TestFlag       = s.TestFlag
    FROM dbo.DimPharmacy AS d
    INNER JOIN stg.Pharmacies AS s ON s.Id = d.PharmacyKey
    WHERE d.PharmacyBisKey <> s.PharmacyBisKey
       OR d.CreatedOn <> s.CreatedOn
       OR d.TestFlag <> s.TestFlag;

    -- Insert newly discovered source pharmacies.
    INSERT INTO dbo.DimPharmacy
        (PharmacyKey, PharmacyBisKey, CreatedOn, TestFlag)
    SELECT s.Id, s.PharmacyBisKey, s.CreatedOn, s.TestFlag
    FROM stg.Pharmacies AS s
    WHERE NOT EXISTS (
        SELECT 1 FROM dbo.DimPharmacy AS d WHERE d.PharmacyKey = s.Id
    );
END;
GO
