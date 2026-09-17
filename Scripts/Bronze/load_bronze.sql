/*
============================================================
NEXMART ENTERPRISE DATA WAREHOUSE
BRONZE LAYER — RAW DATA LOAD
============================================================

PURPOSE:
Load the raw source files into the Bronze layer without applying
cleaning, standardization, or business rules.

The Bronze layer preserves the source data so that all Silver-layer
transformations can be traced back to the original source files.

SOURCE FILES:
Datasets/Sources/
    - NexMart_Customers_Raw.csv
    - NexMart_Employees_Raw.csv
    - NexMart_Products_Raw.csv
    - NexMart_Stores_Raw.csv
    - NexMart_Sales_Raw.csv

IMPORTANT:
Update @SourcePath below to the local path of your cloned GitHub
repository before executing the script.
============================================================
*/

USE NexMartDW;
GO


/* ============================================================
   STEP 1 — SET SOURCE FILE PATH

   PURPOSE:
   Store the local folder containing the raw CSV source files in
   one variable so the file location does not have to be repeated
   throughout the loading script.
   ============================================================ */

DECLARE @SourcePath NVARCHAR(4000) =
    N'C:\Path\To\NexMart-data-warehouse-project\Datasets\Sources\';
GO


/* ============================================================
   STEP 2 — CLEAR EXISTING BRONZE DATA

   PURPOSE:
   Remove previously loaded records before a new raw-data load.
   This prevents duplicate records when the load is executed again.

   NOTE:
   TRUNCATE removes rows but keeps the Bronze table structure.
   ============================================================ */

TRUNCATE TABLE stg.Customers_Raw;
TRUNCATE TABLE stg.Employees_Raw;
TRUNCATE TABLE stg.Products_Raw;
TRUNCATE TABLE stg.Stores_Raw;
TRUNCATE TABLE stg.Sales_Raw;
GO


/* ============================================================
   STEP 3 — LOAD RAW CUSTOMERS DATA

   PURPOSE:
   Load the Customers source file into the Bronze Customers table
   while preserving the source values exactly as received.

   No data cleansing or business rules are applied in Bronze.
   ============================================================ */

BULK INSERT stg.Customers_Raw
FROM 'C:\Path\To\NexMart-data-warehouse-project\Datasets\Sources\NexMart_Customers_Raw.csv'
WITH
(
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    CODEPAGE = '65001',
    TABLOCK
);
GO


/* ============================================================
   STEP 4 — LOAD RAW EMPLOYEES DATA

   PURPOSE:
   Load the Employees source file into the Bronze Employees table
   without applying transformations or data-quality corrections.
   ============================================================ */

BULK INSERT stg.Employees_Raw
FROM 'C:\Path\To\NexMart-data-warehouse-project\Datasets\Sources\NexMart_Employees_Raw.csv'
WITH
(
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    CODEPAGE = '65001',
    TABLOCK
);
GO


/* ============================================================
   STEP 5 — LOAD RAW PRODUCTS DATA

   PURPOSE:
   Load the Products source file into the Bronze Products table
   while preserving the original source values.
   ============================================================ */

BULK INSERT stg.Products_Raw
FROM 'C:\Path\To\NexMart-data-warehouse-project\Datasets\Sources\NexMart_Products_Raw.csv'
WITH
(
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    CODEPAGE = '65001',
    TABLOCK
);
GO


/* ============================================================
   STEP 6 — LOAD RAW STORES DATA

   PURPOSE:
   Load the Stores source file into the Bronze Stores table
   without correcting StoreID or other source-data issues.

   StoreID quality and relationship issues will be investigated
   during profiling and handled according to the Silver rules.
   ============================================================ */

BULK INSERT stg.Stores_Raw
FROM 'C:\Path\To\NexMart-data-warehouse-project\Datasets\Sources\NexMart_Stores_Raw.csv'
WITH
(
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    CODEPAGE = '65001',
    TABLOCK
);
GO


/* ============================================================
   STEP 7 — LOAD RAW SALES DATA

   PURPOSE:
   Load the Sales source file into the Bronze Sales table.

   The Sales dataset is the largest source file, so BULK INSERT
   is used to load the file efficiently.

   No duplicate removal, NULL handling, or business-rule
   transformations are performed at this stage.
   ============================================================ */

BULK INSERT stg.Sales_Raw
FROM 'C:\Path\To\NexMart-data-warehouse-project\Datasets\Sources\NexMart_Sales_Raw.csv'
WITH
(
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    CODEPAGE = '65001',
    TABLOCK
);
GO


/* ============================================================
   STEP 8 — VALIDATE BRONZE LOAD ROW COUNTS

   PURPOSE:
   Confirm that records were loaded into each Bronze table.

   Row counts provide a basic ingestion check before moving to
   profiling and Silver-layer transformations.
   ============================================================ */

SELECT
    'Customers' AS TableName,
    COUNT(*) AS RowCount
FROM stg.Customers_Raw

UNION ALL

SELECT
    'Employees',
    COUNT(*)
FROM stg.Employees_Raw

UNION ALL

SELECT
    'Products',
    COUNT(*)
FROM stg.Products_Raw

UNION ALL

SELECT
    'Stores',
    COUNT(*)
FROM stg.Stores_Raw

UNION ALL

SELECT
    'Sales',
    COUNT(*)
FROM stg.Sales_Raw;
GO


/* ============================================================
   STEP 9 — REVIEW RAW BRONZE DATA

   PURPOSE:
   Display a small sample from each Bronze table to confirm that
   the source columns and values were loaded as expected.

   This is a visual sanity check only. Data-quality corrections
   belong to the Silver layer.
   ============================================================ */

SELECT TOP 20 *
FROM stg.Customers_Raw;

SELECT TOP 20 *
FROM stg.Employees_Raw;

SELECT TOP 20 *
FROM stg.Products_Raw;

SELECT TOP 20 *
FROM stg.Stores_Raw;

SELECT TOP 20 *
FROM stg.Sales_Raw;
GO
