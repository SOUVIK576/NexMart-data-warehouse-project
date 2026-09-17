/*
============================================================
NEXMART ENTERPRISE DATA WAREHOUSE
SILVER LAYER — EMPLOYEES
============================================================

PURPOSE:
Create and transform the Employees_Silver table from the Bronze
staging table.

This script contains the Silver-layer work performed for the
NexMart project. Bronze data is kept unchanged; cleansing,
standardization, deduplication, validation, and data-quality
classification are handled here.

PREREQUISITES:
1. Database: NexMartDW
2. Bronze source table: stg.Employees_Raw
3. The Bronze layer must already be loaded.
4. If this script contains cross-table validation, the required
   related Silver tables must already exist.

RE-RUN BEHAVIOUR:
The existing dbo.Employees_Silver table is dropped and recreated
from Bronze so the script can be rerun during development.

NOTE:
Run the Silver scripts in dependency order when executing the
complete warehouse. Cross-table validation queries require the
related Silver tables to exist.
============================================================
*/

﻿
Use NexMartDW ;


/* ============================================================
   QUERY 1 — CREATE THE SILVER TABLE FOR EMPLOYEE
   Used to validate employee-related values in the Silver data.
   ============================================================ */

SELECT *
INTO dbo.Employees_Silver
FROM stg.Employees_Raw;


/* ============================================================
   QUERY 2 — INVESTIGATE DUPLICATE EMPLOYEEIDS
   Used to identify duplicate records before cleansing.
   ============================================================ */

SELECT
    EmployeeID,
    COUNT(*) AS RecordCount
FROM dbo.Employees_Silver
GROUP BY EmployeeID
HAVING COUNT(*) > 1
ORDER BY EmployeeID;


/* ============================================================
   QUERY 3 — INSPECT EVERY DUPLICATE RECORDS
   Used to identify duplicate records before cleansing.
   ============================================================ */

SELECT *
FROM dbo.Employees_Silver
WHERE EmployeeID IN (
    'EMP0005',
    'EMP0016',
    'EMP0028',
    'EMP0063',
    'EMP0082',
    'EMP0193',
    'EMP0228',
    'EMP0233',
    'EMP0289',
    'EMP0300'
)
ORDER BY EmployeeID;


/* ============================================================
   QUERY 4 — STANDARDIZE EMPLOYEENAME
   Used to make values consistent for downstream analysis.
   ============================================================ */

UPDATE dbo.Employees_Silver
SET EmployeeName = UPPER(LTRIM(RTRIM(EmployeeName)));



/* ============================================================
   QUERY 5 — CHEKING AGIAN THE THE DUPLICATE FOR DEDUPLICATIONS PREVIOUS QUERY
   Used to identify duplicate records before cleansing.
   ============================================================ */

/* ============================================================
   QUERY 6 — REMOVE THE REDUNDANT EMPLOYEE RECORDS
   Used to validate employee-related values in the Silver data.
   ============================================================ */

WITH DuplicateEmployees AS
(
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY EmployeeID
            ORDER BY (SELECT NULL)
        ) AS rn
    FROM dbo.Employees_Silver
)
DELETE FROM DuplicateEmployees
WHERE rn > 1;



/* ============================================================
   QUERY 7 — PROVE EMPLOYEEID UNIQUENESS
   Used to validate employee-related values in the Silver data.
   ============================================================ */

SELECT
    EmployeeID,
    COUNT(*) AS DuplicateCount
FROM dbo.Employees_Silver
GROUP BY EmployeeID
HAVING COUNT(*) > 1;




/* ============================================================
   QUERY 8 — WE NEED TO ESTABLISH WHETHER EMPLOYEEID CONTAINS NULL OR BLANK VALUES.
   Used to identify NULL values that require data-quality handling.
   ============================================================ */

SELECT COUNT(*) AS MissingOrBlankEmployeeID
FROM dbo.Employees_Silver
WHERE EmployeeID IS NULL
   OR LTRIM(RTRIM(EmployeeID)) = '';


-- Strengthen the Silver schema by adding employeeid column not null

ALTER TABLE dbo.Employees_Silver
ALTER COLUMN EmployeeID VARCHAR(20) NOT NULL;



/* ============================================================
   QUERY 9 — VALIDATE EMPLOYEENAME COMPLETENESS
   Used to validate the transformed data against expected rules.
   ============================================================ */


SELECT COUNT(*) AS MissingOrBlankEmployeeName
FROM dbo.Employees_Silver
WHERE EmployeeName IS NULL
   OR LTRIM(RTRIM(EmployeeName)) = '';


/* ============================================================
   QUERY 10 — VALIDATE GENDER
   Used to validate the transformed data against expected rules.
   ============================================================ */


SELECT
    Gender,
    COUNT(*)
FROM dbo.Employees_Silver
GROUP BY Gender
ORDER BY Gender;


/* ============================================================
   QUERY 11 — JOBTITLE
   Used to perform the jobtitle step in the Silver transformation.
   ============================================================ */

SELECT
    JobTitle,
    COUNT(*) AS EmployeeCount
FROM dbo.Employees_Silver
GROUP BY JobTitle
ORDER BY JobTitle;



/* ============================================================
   QUERY 12 — DEPARTMENT
   Used to perform the department step in the Silver transformation.
   ============================================================ */


SELECT
    Department,
    COUNT(*) AS EmployeeCount
FROM dbo.Employees_Silver
GROUP BY Department
ORDER BY Department;



/* ============================================================
   QUERY 13 — HIRE DATE MISSING OR BLANK CHEKING
   Used to identify incomplete values before transformation.
   ============================================================ */


SELECT
    COUNT(*) AS MissingOrBlankHireDate
FROM dbo.Employees_Silver
WHERE HireDate IS NULL
   OR LTRIM(RTRIM(HireDate)) = '';


/* ============================================================
   QUERY 14 — VERIFY THE HIREDATE DATA TYPE
   Used to standardize or validate date values for analysis.
   ============================================================ */

SELECT
    COLUMN_NAME,
    DATA_TYPE,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dbo'
  AND TABLE_NAME = 'Employees_Silver'
  AND COLUMN_NAME = 'HireDate';



/* ============================================================
   QUERY 15 — WE SHOULD CONVERT IT SAFELY RATHER THAN DIRECTLY ALTERING VARCHAR → DATE.
   Used to standardize or validate date values for analysis.
   ============================================================ */


SELECT
    COUNT(*) AS InvalidHireDateConversion
FROM dbo.Employees_Silver
WHERE TRY_CONVERT(DATE, HireDate, 23) IS NULL
  AND HireDate IS NOT NULL;



-- convert HireDate to DATE


ALTER TABLE dbo.Employees_Silver
ADD CleanHireDate DATE NULL;


/* ============================================================
   QUERY 16 — WE POPULATE THE TEMPORARY DATE COLUMN FROM THE ORIGINAL VARCHAR COLUMN.
   Used to standardize or validate date values for analysis.
   ============================================================ */

UPDATE dbo.Employees_Silver
SET CleanHireDate = TRY_CONVERT(DATE, HireDate, 23);



SELECT
    COUNT(*) AS InvalidCleanHireDate
FROM dbo.Employees_Silver
WHERE CleanHireDate IS NULL;



ALTER TABLE dbo.Employees_Silver
DROP COLUMN HireDate;


EXEC sp_rename
    'dbo.Employees_Silver.CleanHireDate',
    'HireDate',
    'COLUMN';


SELECT
    COLUMN_NAME,
    DATA_TYPE,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dbo'
  AND TABLE_NAME = 'Employees_Silver'
  AND COLUMN_NAME = 'HireDate';




SELECT
    EmploymentStatus,
    COUNT(*) AS EmployeeCount
FROM dbo.Employees_Silver
GROUP BY EmploymentStatus
ORDER BY EmploymentStatus;




SELECT
    COUNT(*) AS MissingOrBlankStoreID
FROM dbo.Employees_Silver
WHERE StoreID IS NULL
   OR LTRIM(RTRIM(StoreID)) = '';



/* ============================================================
   QUERY 17 — MISSING STOREID RECORDS
   Used to identify incomplete values before transformation.
   ============================================================ */

SELECT
    EmployeeID,
    EmployeeName,
    Gender,
    JobTitle,
    Department,
    HireDate,
    EmploymentStatus,
    StoreID
FROM dbo.Employees_Silver
WHERE StoreID IS NULL
   OR LTRIM(RTRIM(StoreID)) = '';



/* ============================================================
   QUERY 18 — WE VERIFIYING IT IS ACTUALLY PRESENT IN RAW OR NOT
   Used to perform the we verifiying it is actually present in raw or not step in the Silver transformation.
   ============================================================ */


SELECT
    EmployeeID,
    EmployeeName,
    JobTitle,
    Department,
    EmploymentStatus,
    StoreID
FROM stg.Employees_Raw
WHERE EmployeeID = 'EMP0058';


/* ============================================================
   QUERY 19 — WE FOUND ONE MISSING STOREID. NOW WE NEED TO DETERMINE WHETHER ANY NON-NULL STOREIDS DON'T EXIST IN STORES_SILVER.
   Used to identify incomplete values before transformation.
   ============================================================ */

SELECT
    COUNT(*) AS InvalidStoreIDs
FROM dbo.Employees_Silver e
WHERE e.StoreID IS NOT NULL
  AND NOT EXISTS
  (
      SELECT 1
      FROM dbo.Stores_Silver s
      WHERE s.StoreID = e.StoreID
  );


/* ============================================================
   QUERY 20 — ANY SALES TRANSACTIONS POINT TO AN EMPLOYEEID THAT DOESN'T EXIST IN EMPLOYEES_SILVER.
   Used to validate employee-related values in the Silver data.
   ============================================================ */

SELECT
    COUNT(*) AS InvalidEmployeeIDs
FROM dbo.Sales_Silver s
WHERE s.EmployeeID IS NOT NULL
  AND NOT EXISTS
  (
      SELECT 1
      FROM dbo.Employees_Silver e
      WHERE e.EmployeeID = s.EmployeeID
  );



SELECT
    s.EmployeeID,
    COUNT(*) AS TransactionCount
FROM dbo.Sales_Silver s
WHERE s.EmployeeID IS NOT NULL
  AND NOT EXISTS
  (
      SELECT 1
      FROM dbo.Employees_Silver e
      WHERE e.EmployeeID = s.EmployeeID
  )
GROUP BY s.EmployeeID
ORDER BY TransactionCount DESC;




SELECT
    EmployeeID,
    COUNT(*) AS RawRecordCount
FROM stg.Sales_Raw
WHERE EmployeeID = 'EMP9999'
GROUP BY EmployeeID;


/* We know EMP9999 appears 75 times in Sales_Raw, but does not exist in Employees_Silver.
Now we need to check whether it exists anywhere in the employee source table. */

SELECT
    EmployeeID,
    EmployeeName,
    JobTitle,
    Department,
    StoreID,
    EmploymentStatus
FROM stg.Employees_Raw
WHERE EmployeeID = 'EMP9999';

/*  Stores → Employees, specifically whether every ManagerEmployeeID in Stores_Silver still points to a valid employee after our Employee cleanup.*/


SELECT
    COUNT(*) AS InvalidManagerEmployeeIDs
FROM dbo.Stores_Silver s
WHERE s.ManagerEmployeeID IS NOT NULL
  AND NOT EXISTS
  (
      SELECT 1
      FROM dbo.Employees_Silver e
      WHERE e.EmployeeID = s.ManagerEmployeeID
  );



SELECT
    COUNT(*) AS TotalEmployees,
    COUNT(DISTINCT EmployeeID) AS DistinctEmployeeIDs,
    SUM(CASE
            WHEN EmployeeID IS NULL
              OR LTRIM(RTRIM(EmployeeID)) = ''
            THEN 1
            ELSE 0
        END) AS MissingOrBlankEmployeeIDs
FROM dbo.Employees_Silver;




ALTER TABLE dbo.Employees_Silver
ADD StoreQualityStatus VARCHAR(30) NULL;



UPDATE e
SET StoreQualityStatus =
    CASE
        WHEN e.StoreID IS NULL
             OR LTRIM(RTRIM(e.StoreID)) = ''
            THEN 'Missing Store'

        WHEN EXISTS
        (
            SELECT 1
            FROM dbo.Stores_Silver s
            WHERE s.StoreID = e.StoreID
        )
            THEN 'Valid Store'

        ELSE 'Invalid Store'
    END
FROM dbo.Employees_Silver e;




SELECT
    StoreQualityStatus,
    COUNT(*) AS EmployeeCount
FROM dbo.Employees_Silver
GROUP BY StoreQualityStatus
ORDER BY StoreQualityStatus;