/*
============================================================
NEXMART ENTERPRISE DATA WAREHOUSE
SILVER LAYER — PRODUCTS
============================================================

PURPOSE:
Create and transform the Products_Silver table from the Bronze
staging table.

This script contains the Silver-layer work performed for the
NexMart project. Bronze data is kept unchanged; cleansing,
standardization, deduplication, validation, and data-quality
classification are handled here.

PREREQUISITES:
1. Database: NexMartDW
2. Bronze source table: stg.Products_Raw
3. The Bronze layer must already be loaded.
4. If this script contains cross-table validation, the required
   related Silver tables must already exist.

RE-RUN BEHAVIOUR:
The existing dbo.Products_Silver table is dropped and recreated
from Bronze so the script can be rerun during development.

NOTE:
Run the Silver scripts in dependency order when executing the
complete warehouse. Cross-table validation queries require the
related Silver tables to exist.
============================================================
*/

Use NexMartDW ;



/* ============================================================
   QUERY 1 — CREATE PRODUCTS_SILVER
   Used to validate product-related values in the Silver data.
   ============================================================ */

SELECT *
INTO dbo.Products_Silver
FROM stg.Products_Raw;


/* ============================================================
   QUERY 2 — CHECK DUPLICATE PRODUCTIDS
   Used to identify duplicate records before cleansing.
   ============================================================ */

SELECT
    ProductID,
    COUNT(*) AS RecordCount
FROM dbo.Products_Silver
GROUP BY ProductID
HAVING COUNT(*) > 1
ORDER BY ProductID;

/* ============================================================
   QUERY 3 — INSPECT THE DUPLICATE PRODUCTS
   Used to identify duplicate records before cleansing.
   ============================================================ */


SELECT *
FROM dbo.Products_Silver
WHERE ProductID IN (
    'PROD00017',
    'PROD00047',
    'PROD00053',
    'PROD00088',
    'PROD00107',
    'PROD00156',
    'PROD00161',
    'PROD00247',
    'PROD00250',
    'PROD00311',
    'PROD00331',
    'PROD00340',
    'PROD00355',
    'PROD00444',
    'PROD00454'
)
ORDER BY ProductID;





SELECT
    ProductID,
    COUNT(DISTINCT ProductName) AS ProductNameVariants,
    COUNT(DISTINCT Category) AS CategoryVariants,
    COUNT(DISTINCT SubCategory) AS SubCategoryVariants,
    COUNT(DISTINCT Brand) AS BrandVariants,
    COUNT(DISTINCT UnitCost) AS UnitCostVariants,
    COUNT(DISTINCT UnitPrice) AS UnitPriceVariants,
    COUNT(DISTINCT Supplier) AS SupplierVariants,
    COUNT(DISTINCT LaunchDate) AS LaunchDateVariants,
    COUNT(DISTINCT ProductStatus) AS ProductStatusVariants
FROM dbo.Products_Silver
WHERE ProductID IN (
    'PROD00017','PROD00047','PROD00053','PROD00088','PROD00107',
    'PROD00156','PROD00161','PROD00247','PROD00250','PROD00311',
    'PROD00331','PROD00340','PROD00355','PROD00444','PROD00454'
)
GROUP BY ProductID
ORDER BY ProductID;




SELECT
    ProductID,
    COUNT(*) AS RecordCount,
    COUNT(DISTINCT ProductName COLLATE Latin1_General_100_BIN2) AS ExactProductNameVariants
FROM dbo.Products_Silver
WHERE ProductID IN (
    'PROD00017','PROD00047','PROD00053','PROD00088','PROD00107',
    'PROD00156','PROD00161','PROD00247','PROD00250','PROD00311',
    'PROD00331','PROD00340','PROD00355','PROD00444','PROD00454'
)
GROUP BY ProductID
ORDER BY ProductID;



SELECT
    ProductID,
    COUNT(DISTINCT ProductName COLLATE Latin1_General_100_BIN2) AS ProductNameVariants,
    COUNT(DISTINCT Category COLLATE Latin1_General_100_BIN2) AS CategoryVariants,
    COUNT(DISTINCT SubCategory COLLATE Latin1_General_100_BIN2) AS SubCategoryVariants,
    COUNT(DISTINCT Brand COLLATE Latin1_General_100_BIN2) AS BrandVariants,
    COUNT(DISTINCT UnitCost) AS UnitCostVariants,
    COUNT(DISTINCT UnitPrice) AS UnitPriceVariants,
    COUNT(DISTINCT Supplier COLLATE Latin1_General_100_BIN2) AS SupplierVariants,
    COUNT(DISTINCT LaunchDate) AS LaunchDateVariants,
    COUNT(DISTINCT ProductStatus COLLATE Latin1_General_100_BIN2) AS ProductStatusVariants
FROM dbo.Products_Silver
WHERE ProductID IN (
    'PROD00017',
    'PROD00047',
    'PROD00053',
    'PROD00088',
    'PROD00107',
    'PROD00156',
    'PROD00162',
    'PROD00247',
    'PROD00250',
    'PROD00311',
    'PROD00331',
    'PROD00340',
    'PROD00355',
    'PROD00444',
    'PROD00454'
)
GROUP BY ProductID
ORDER BY ProductID;


/* ============================================================
   QUERY 4 — STANDARDIZE PRODUCTNAME
   Used to make values consistent for downstream analysis.
   ============================================================ */

UPDATE dbo.Products_Silver
SET ProductName = UPPER(LTRIM(RTRIM(ProductName)));


/* ============================================================
   QUERY 5 — REMOVE THE REDUNDANT DUPLICATE PRODUCT ROWS
   Used to identify duplicate records before cleansing.
   ============================================================ */

WITH DuplicateProducts AS
(
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY ProductID
            ORDER BY (SELECT NULL)
        ) AS rn
    FROM dbo.Products_Silver
)
DELETE FROM DuplicateProducts
WHERE rn > 1;


/* ============================================================
   QUERY 6 — CHEKING ITS WORKING OR NOT
   Used to perform the cheking its working or not step in the Silver transformation.
   ============================================================ */


SELECT
    ProductID,
    COUNT(*) AS DuplicateCount
FROM dbo.Products_Silver
GROUP BY ProductID
HAVING COUNT(*) > 1
ORDER BY ProductID;


/* ============================================================
   QUERY 7 — PRODUCTID COMPLETENESS
   Used to validate product-related values in the Silver data.
   ============================================================ */

SELECT
    COUNT(*) AS MissingOrBlankProductID
FROM dbo.Products_Silver
WHERE ProductID IS NULL
   OR LTRIM(RTRIM(ProductID)) = '';


-- we'll strengthen the schema so SQL Server itself enforces that ProductID cannot be NULL.

ALTER TABLE dbo.Products_Silver
ALTER COLUMN ProductID VARCHAR(20) NOT NULL;


/* ============================================================
   QUERY 8 — WE NEED TO VERIFY WHETHER ANY PRODUCT NAME IS MISSING OR BLANK.
   Used to identify incomplete values before transformation.
   ============================================================ */

SELECT
    COUNT(*) AS MissingOrBlankProductName
FROM dbo.Products_Silver
WHERE ProductName IS NULL
   OR LTRIM(RTRIM(ProductName)) = '';


/* ============================================================
   QUERY 9 — PRODUCT CATEGORY
   Used to validate product-related values in the Silver data.
   ============================================================ */

SELECT
    Category,
    COUNT(*) AS ProductCount
FROM dbo.Products_Silver
GROUP BY Category
ORDER BY Category;



SELECT
    COUNT(*) AS MissingOrBlankCategory
FROM dbo.Products_Silver
WHERE Category IS NULL
   OR LTRIM(RTRIM(Category)) = '';


/* ============================================================
   QUERY 10 — SUB CATEGORY
   Used to perform the sub category step in the Silver transformation.
   ============================================================ */


SELECT
    SubCategory,
    COUNT(*) AS ProductCount
FROM dbo.Products_Silver
GROUP BY SubCategory
ORDER BY SubCategory;



SELECT
    COUNT(*) AS MissingOrBlankSubCategory
FROM dbo.Products_Silver
WHERE SubCategory IS NULL
   OR LTRIM(RTRIM(SubCategory)) = '';


/* ============================================================
   QUERY 11 — BRAND
   Used to perform the brand step in the Silver transformation.
   ============================================================ */

SELECT
    Brand,
    COUNT(*) AS ProductCount
FROM dbo.Products_Silver
GROUP BY Brand
ORDER BY Brand;



SELECT
    COUNT(*) AS MissingOrBlankBrand
FROM dbo.Products_Silver
WHERE Brand IS NULL
   OR LTRIM(RTRIM(Brand)) = '';



SELECT
    COLUMN_NAME,
    DATA_TYPE,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dbo'
  AND TABLE_NAME = 'Products_Silver'
  AND COLUMN_NAME = 'UnitCost';



SELECT
    COUNT(*) AS InvalidUnitCostConversion
FROM dbo.Products_Silver
WHERE TRY_CONVERT(DECIMAL(18,2), UnitCost) IS NULL
  AND UnitCost IS NOT NULL;



SELECT
    SUM(CASE WHEN UnitCost IS NULL THEN 1 ELSE 0 END) AS MissingUnitCost,
    SUM(CASE WHEN TRY_CONVERT(DECIMAL(18,2), UnitCost) = 0 THEN 1 ELSE 0 END) AS ZeroUnitCost,
    SUM(CASE WHEN TRY_CONVERT(DECIMAL(18,2), UnitCost) < 0 THEN 1 ELSE 0 END) AS NegativeUnitCost,
    SUM(CASE WHEN TRY_CONVERT(DECIMAL(18,2), UnitCost) > 0 THEN 1 ELSE 0 END) AS PositiveUnitCost
FROM dbo.Products_Silver;



ALTER TABLE dbo.Products_Silver
ADD CleanUnitCost DECIMAL(18,2) NULL;



UPDATE dbo.Products_Silver
SET CleanUnitCost = TRY_CONVERT(DECIMAL(18,2), UnitCost);



SELECT
    COUNT(*) AS TotalProducts,
    COUNT(CleanUnitCost) AS ConvertedUnitCosts,
    SUM(CASE
            WHEN UnitCost IS NULL
             AND CleanUnitCost IS NULL
            THEN 1 ELSE 0
        END) AS PreservedMissingUnitCosts
FROM dbo.Products_Silver;




ALTER TABLE dbo.Products_Silver
DROP COLUMN UnitCost;



EXEC sp_rename
    'dbo.Products_Silver.CleanUnitCost',
    'UnitCost',
    'COLUMN';



SELECT
    COLUMN_NAME,
    DATA_TYPE,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dbo'
  AND TABLE_NAME = 'Products_Silver'
  AND COLUMN_NAME = 'UnitCost';



SELECT
    COLUMN_NAME,
    DATA_TYPE,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dbo'
  AND TABLE_NAME = 'Products_Silver'
  AND COLUMN_NAME = 'UnitPrice';



SELECT
    COUNT(*) AS InvalidUnitPriceConversion
FROM dbo.Products_Silver
WHERE TRY_CONVERT(DECIMAL(18,2), UnitPrice) IS NULL
  AND UnitPrice IS NOT NULL;



SELECT
    SUM(CASE WHEN UnitPrice IS NULL THEN 1 ELSE 0 END) AS MissingUnitPrice,
    SUM(CASE WHEN TRY_CONVERT(DECIMAL(18,2), UnitPrice) = 0 THEN 1 ELSE 0 END) AS ZeroUnitPrice,
    SUM(CASE WHEN TRY_CONVERT(DECIMAL(18,2), UnitPrice) < 0 THEN 1 ELSE 0 END) AS NegativeUnitPrice,
    SUM(CASE WHEN TRY_CONVERT(DECIMAL(18,2), UnitPrice) > 0 THEN 1 ELSE 0 END) AS PositiveUnitPrice
FROM dbo.Products_Silver;



ALTER TABLE dbo.Products_Silver
ADD CleanUnitPrice DECIMAL(18,2) NULL;



UPDATE dbo.Products_Silver
SET CleanUnitPrice = TRY_CONVERT(DECIMAL(18,2), UnitPrice);



SELECT
    COUNT(*) AS TotalProducts,
    COUNT(CleanUnitPrice) AS ConvertedUnitPrices,
    SUM(CASE
            WHEN UnitPrice IS NOT NULL
             AND CleanUnitPrice IS NULL
            THEN 1 ELSE 0
        END) AS FailedConversions
FROM dbo.Products_Silver;



ALTER TABLE dbo.Products_Silver
DROP COLUMN UnitPrice;


EXEC sp_rename
    'dbo.Products_Silver.CleanUnitPrice',
    'UnitPrice',
    'COLUMN';



SELECT
    COLUMN_NAME,
    DATA_TYPE,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dbo'
  AND TABLE_NAME = 'Products_Silver'
  AND COLUMN_NAME = 'UnitPrice';





SELECT
    Supplier,
    COUNT(*) AS ProductCount
FROM dbo.Products_Silver
GROUP BY Supplier
ORDER BY Supplier;



SELECT
    SUM(CASE WHEN Supplier IS NULL THEN 1 ELSE 0 END) AS NullSupplier,
    SUM(CASE
            WHEN Supplier IS NOT NULL
             AND LTRIM(RTRIM(Supplier)) = ''
            THEN 1 ELSE 0
        END) AS BlankSupplier,
    COUNT(*) AS TotalProducts
FROM dbo.Products_Silver;




SELECT
    ProductID,
    ProductName,
    Category,
    SubCategory,
    Brand,
    UnitCost,
    UnitPrice,
    Supplier,
    LaunchDate,
    ProductStatus
FROM dbo.Products_Silver
WHERE Supplier IS NULL;




SELECT
    COLUMN_NAME,
    DATA_TYPE,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dbo'
  AND TABLE_NAME = 'Products_Silver'
  AND COLUMN_NAME = 'LaunchDate';



SELECT
    COUNT(*) AS MissingLaunchDate
FROM dbo.Products_Silver
WHERE LaunchDate IS NULL;


SELECT
    COUNT(*) AS FutureLaunchDates
FROM dbo.Products_Silver
WHERE LaunchDate > CAST(GETDATE() AS DATE);




ALTER TABLE dbo.Products_Silver
ADD UnitCostQualityStatus VARCHAR(30) NULL;



UPDATE dbo.Products_Silver
SET UnitCostQualityStatus =
    CASE
        WHEN UnitCost IS NULL
            THEN 'Missing UnitCost'
        ELSE 'Valid UnitCost'
    END;




SELECT
    UnitCostQualityStatus,
    COUNT(*) AS ProductCount
FROM dbo.Products_Silver
GROUP BY UnitCostQualityStatus
ORDER BY UnitCostQualityStatus;



ALTER TABLE dbo.Products_Silver
ADD SupplierQualityStatus VARCHAR(30) NULL;



UPDATE dbo.Products_Silver
SET SupplierQualityStatus =
    CASE
        WHEN Supplier IS NULL
            THEN 'Missing Supplier'
        ELSE 'Valid Supplier'
    END;




SELECT
    SupplierQualityStatus,
    COUNT(*) AS ProductCount
FROM dbo.Products_Silver
GROUP BY SupplierQualityStatus
ORDER BY SupplierQualityStatus;




SELECT
    ProductStatus,
    COUNT(*) AS ProductCount
FROM dbo.Products_Silver
GROUP BY ProductStatus
ORDER BY ProductStatus;




SELECT
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dbo'
  AND TABLE_NAME = 'Products_Silver'
ORDER BY ORDINAL_POSITION;



ALTER TABLE dbo.Products_Silver
ALTER COLUMN ProductID VARCHAR(20) NOT NULL;



SELECT
    COUNT(*) AS TotalProducts,
    SUM(
        CASE
            WHEN TRY_CONVERT(DATE, LaunchDate, 23) IS NULL
                 AND LaunchDate IS NOT NULL
            THEN 1
            ELSE 0
        END
    ) AS InvalidLaunchDates,
    MIN(TRY_CONVERT(DATE, LaunchDate, 23)) AS EarliestLaunchDate,
    MAX(TRY_CONVERT(DATE, LaunchDate, 23)) AS LatestLaunchDate
FROM dbo.Products_Silver;



ALTER TABLE dbo.Products_Silver
ADD CleanLaunchDate DATE NULL;



UPDATE dbo.Products_Silver
SET CleanLaunchDate = TRY_CONVERT(DATE, LaunchDate, 23);




SELECT
    COUNT(*) AS TotalProducts,
    COUNT(CleanLaunchDate) AS ConvertedLaunchDates,
    SUM(
        CASE
            WHEN LaunchDate IS NOT NULL
             AND CleanLaunchDate IS NULL
            THEN 1
            ELSE 0
        END
    ) AS FailedConversions
FROM dbo.Products_Silver;



ALTER TABLE dbo.Products_Silver
DROP COLUMN LaunchDate;

EXEC sp_rename
    'dbo.Products_Silver.CleanLaunchDate',
    'LaunchDate',
    'COLUMN';



SELECT
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dbo'
  AND TABLE_NAME = 'Products_Silver'
ORDER BY ORDINAL_POSITION;




SELECT
    COLUMN_NAME,
    DATA_TYPE,
    NUMERIC_PRECISION,
    NUMERIC_SCALE,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dbo'
  AND TABLE_NAME = 'Products_Silver'
  AND COLUMN_NAME IN ('UnitCost', 'UnitPrice');


