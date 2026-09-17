/*
============================================================
NEXMART ENTERPRISE DATA WAREHOUSE
SILVER LAYER — STORES
============================================================

PURPOSE:
Create and transform the Stores_Silver table from the Bronze
staging table.

This script contains the Silver-layer work performed for the
NexMart project. Bronze data is kept unchanged; cleansing,
standardization, deduplication, validation, and data-quality
classification are handled here.

PREREQUISITES:
1. Database: NexMartDW
2. Bronze source table: stg.Stores_Raw
3. The Bronze layer must already be loaded.
4. If this script contains cross-table validation, the required
   related Silver tables must already exist.

RE-RUN BEHAVIOUR:
The existing dbo.Stores_Silver table is dropped and recreated
from Bronze so the script can be rerun during development.

NOTE:
Run the Silver scripts in dependency order when executing the
complete warehouse. Cross-table validation queries require the
related Silver tables to exist.
============================================================
*/

Use NexMartDW ;


/* ============================================================
   QUERY 1 — CREATE THE WORKING SILVER TABLE FOR SALES
   Used to perform the create the working silver table for sales step in the Silver transformation.
   ============================================================ */

SELECT *
INTO dbo.Stores_Silver
FROM stg.Stores_Raw;

/* ============================================================
   QUERY 2 — INVESTIGATE DUPLICATE STOREIDS
   Used to identify duplicate records before cleansing.
   ============================================================ */

SELECT *
FROM dbo.Stores_Silver
WHERE StoreID IN ('STORE017', 'STORE045')
ORDER BY StoreID;



/* ============================================================
   QUERY 3 — LET'S NORMALIZE THE STORENAME CONSISTENTLY.
   Used to validate store references used by the Silver data.
   ============================================================ */

UPDATE dbo.Stores_Silver
SET StoreName = UPPER(LTRIM(RTRIM(StoreName)));




/* ============================================================
   QUERY 4 — REMOVE THE REDUNDANT DUPLICATE FROM SILVER
   Used to identify duplicate records before cleansing.
   ============================================================ */

WITH DuplicateStores AS
(
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY StoreID
            ORDER BY (SELECT NULL)
        ) AS rn
    FROM dbo.Stores_Silver
)
DELETE FROM DuplicateStores
WHERE rn > 1;


/* ============================================================
   QUERY 5 — CHEKING THERE ARE NO DUPLICATE PRESENT
   Used to identify duplicate records before cleansing.
   ============================================================ */


SELECT
    StoreID,
    COUNT(*) AS DuplicateCount
FROM dbo.Stores_Silver
GROUP BY StoreID
HAVING COUNT(*) > 1;


/* ============================================================
   QUERY 6 — STORETYPE CAPITALIZATION
   Used to validate store references used by the Silver data.
   ============================================================ */


UPDATE dbo.Stores_Silver
SET StoreType =
    CASE
        WHEN LOWER(LTRIM(RTRIM(StoreType))) = 'standard'
            THEN 'Standard'
        WHEN LOWER(LTRIM(RTRIM(StoreType))) = 'flagship'
            THEN 'Flagship'
        WHEN LOWER(LTRIM(RTRIM(StoreType))) = 'express'
            THEN 'Express'
        WHEN LOWER(LTRIM(RTRIM(StoreType))) = 'outlet'
            THEN 'Outlet'
        ELSE StoreType
    END;



/* ============================================================
   QUERY 7 — VALIDATE STORETYPE
   Used to validate the transformed data against expected rules.
   ============================================================ */

SELECT
    StoreType,
    COUNT(*)
FROM dbo.Stores_Silver
GROUP BY StoreType
ORDER BY StoreType;


/* ============================================================
   QUERY 8 — REGION CAPITALIZATION
   Used to perform the region capitalization step in the Silver transformation.
   ============================================================ */

UPDATE dbo.Stores_Silver
SET Region =
    CASE
        WHEN LOWER(LTRIM(RTRIM(Region))) = 'north'
            THEN 'North'
        WHEN LOWER(LTRIM(RTRIM(Region))) = 'south'
            THEN 'South'
        WHEN LOWER(LTRIM(RTRIM(Region))) = 'east'
            THEN 'East'
        WHEN LOWER(LTRIM(RTRIM(Region))) = 'west'
            THEN 'West'
        ELSE Region
    END;


/* ============================================================
   QUERY 9 — VALIDATE REGION
   Used to validate the transformed data against expected rules.
   ============================================================ */

SELECT
    Region,
    COUNT(*)
FROM dbo.Stores_Silver
GROUP BY Region
ORDER BY Region;

/* ============================================================
   QUERY 10 — STORENAME QUALITY CHEKING
   Used to classify records according to data-quality conditions.
   ============================================================ */

SELECT COUNT(*) AS MissingOrBlankStoreName
FROM dbo.Stores_Silver
WHERE StoreName IS NULL
   OR LTRIM(RTRIM(StoreName)) = '';



/* ============================================================
   QUERY 11 — STORESTATUS CHEKING
   Used to standardize and validate status values.
   ============================================================ */

SELECT
    StoreStatus,
    COUNT(*)
FROM dbo.Stores_Silver
GROUP BY StoreStatus
ORDER BY StoreStatus;



/* ============================================================
   QUERY 12 — MANAGEREMPLOYEEID
   Used to validate employee-related values in the Silver data.
   ============================================================ */

SELECT COUNT(*) AS InvalidManagerEmployeeID
FROM dbo.Stores_Silver s
WHERE s.ManagerEmployeeID IS NULL
   OR NOT EXISTS
   (
       SELECT 1
       FROM stg.Employees_Raw e
       WHERE e.EmployeeID = s.ManagerEmployeeID
   );



/* ============================================================
   QUERY 13 — CHEKING ANY MISSING OR BLANK PRESENT IN IT
   Used to identify incomplete values before transformation.
   ============================================================ */

SELECT COUNT(*) AS MissingOrBlankStoreID
FROM dbo.Stores_Silver
WHERE StoreID IS NULL
   OR LTRIM(RTRIM(StoreID)) = '';



--Make StoreID mandatory not null does not approved


ALTER TABLE dbo.Stores_Silver
ALTER COLUMN StoreID VARCHAR(20) NOT NULL;


/* ============================================================
   QUERY 14 — NOW VERIFY THE  STATUS
   Used to standardize and validate status values.
   ============================================================ */

SELECT
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dbo'
  AND TABLE_NAME = 'Stores_Silver'
ORDER BY ORDINAL_POSITION;



/* ============================================================
   QUERY 15 — CHECK STORENAME LENGTH SUITABILITY
   Used to validate store references used by the Silver data.
   ============================================================ */

SELECT
    MAX(LEN(StoreName)) AS MaxStoreNameLength
FROM dbo.Stores_Silver;



/* ============================================================
   QUERY 16 — CHECK CITY AND STATE COMPLETENESS
   Used to perform the check city and state completeness step in the Silver transformation.
   ============================================================ */


SELECT
    SUM(CASE WHEN City IS NULL OR LTRIM(RTRIM(City)) = '' THEN 1 ELSE 0 END) AS MissingCity,
    SUM(CASE WHEN State IS NULL OR LTRIM(RTRIM(State)) = '' THEN 1 ELSE 0 END) AS MissingState
FROM dbo.Stores_Silver;



SELECT
    SalesChannel,
    COUNT(*)
FROM dbo.Stores_Silver
GROUP BY SalesChannel
ORDER BY SalesChannel;


/* ============================================================
   QUERY 17 — LET'S INVESTIGATE THE ACTUAL COMBINATIONS
   Used to perform the let's investigate the actual combinations step in the Silver transformation.
   ============================================================ */

SELECT
    s.SalesChannel AS SaleChannel,
    st.SalesChannel AS StoreChannel,
    COUNT(*) AS TransactionCount
FROM dbo.Sales_Silver s
INNER JOIN dbo.Stores_Silver st
    ON s.StoreID = st.StoreID
GROUP BY
    s.SalesChannel,
    st.SalesChannel
ORDER BY
    s.SalesChannel,
    st.SalesChannel;


/* ============================================================
   QUERY 18 — INVESTIGATE THE 73,556 EXCEPTIONS
   Used to perform the investigate the 73,556 exceptions step in the Silver transformation.
   ============================================================ */

SELECT
    s.StoreID,
    st.StoreName,
    st.StoreType,
    st.SalesChannel AS StoreChannel,
    COUNT(*) AS OnlineTransactionCount
FROM dbo.Sales_Silver s
INNER JOIN dbo.Stores_Silver st
    ON s.StoreID = st.StoreID
WHERE s.SalesChannel = 'Online'
  AND st.SalesChannel = 'Physical Store'
GROUP BY
    s.StoreID,
    st.StoreName,
    st.StoreType,
    st.SalesChannel
ORDER BY OnlineTransactionCount DESC;


/* ============================================================
   QUERY 19 — STORESTATUS VS SALES ACTIVITY
   Used to standardize and validate status values.
   ============================================================ */

SELECT
    st.StoreID,
    st.StoreName,
    st.StoreStatus,
    COUNT(*) AS TransactionCount
FROM dbo.Sales_Silver s
INNER JOIN dbo.Stores_Silver st
    ON s.StoreID = st.StoreID
WHERE st.StoreStatus = 'Temporarily Closed'
GROUP BY
    st.StoreID,
    st.StoreName,
    st.StoreStatus
ORDER BY TransactionCount DESC;



/* ============================================================
   QUERY 20 — STORE SALESCHANNEL ITSELF
   Used to validate store references used by the Silver data.
   ============================================================ */

SELECT
    SUM(CASE WHEN SalesChannel IS NULL THEN 1 ELSE 0 END) AS MissingSalesChannel,
    SUM(CASE WHEN LTRIM(RTRIM(SalesChannel)) = '' THEN 1 ELSE 0 END) AS BlankSalesChannel
FROM dbo.Stores_Silver;



SELECT DISTINCT
    City,
    State
FROM dbo.Stores_Silver
ORDER BY State, City;



SELECT
    COUNT(*) AS TotalStores,
    COUNT(DISTINCT StoreID) AS DistinctStoreIDs
FROM dbo.Stores_Silver;