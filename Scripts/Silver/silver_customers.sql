/*
============================================================
NEXMART ENTERPRISE DATA WAREHOUSE
SILVER LAYER — CUSTOMERS
============================================================

PURPOSE:
Create and transform the Customers_Silver table from the Bronze
staging table.

This script contains the Silver-layer work performed for the
NexMart project. Bronze data is kept unchanged; cleansing,
standardization, deduplication, validation, and data-quality
classification are handled here.

PREREQUISITES:
1. Database: NexMartDW
2. Bronze source table: stg.Customers_Raw
3. The Bronze layer must already be loaded.
4. If this script contains cross-table validation, the required
   related Silver tables must already exist.

RE-RUN BEHAVIOUR:
The existing dbo.Customers_Silver table is dropped and recreated
from Bronze so the script can be rerun during development.

NOTE:
Run the Silver scripts in dependency order when executing the
complete warehouse. Cross-table validation queries require the
related Silver tables to exist.
============================================================
*/

Use NexMartDW ;



/* ============================================================
   QUERY 1 — CREATE CUSTOMERS_SILVER
   Used to validate customer-related values in the Silver data.
   ============================================================ */


SELECT *
INTO dbo.Customers_Silver
FROM stg.Customers_Raw;


/* ============================================================
   QUERY 2 — CHECK DUPLICATE CUSTOMERID
   Used to identify duplicate records before cleansing.
   ============================================================ */

SELECT
    CustomerID,
    COUNT(*) AS RecordCount
FROM dbo.Customers_Silver
GROUP BY CustomerID
HAVING COUNT(*) > 1
ORDER BY CustomerID;




SELECT *
FROM dbo.Customers_Silver
WHERE CustomerID IN
(
    'CUST00022',
    'CUST00117',
    'CUST00138',
    'CUST00235',
    'CUST00243',
    'CUST00597',
    'CUST00860',
    'CUST00893',
    'CUST01048',
    'CUST01075'
)
ORDER BY CustomerID;




SELECT
    CustomerID,

    COUNT(DISTINCT CustomerName
        COLLATE Latin1_General_100_BIN2) AS NameVariants,

    COUNT(DISTINCT Gender
        COLLATE Latin1_General_100_BIN2) AS GenderVariants,

    COUNT(DISTINCT DateOfBirth) AS DateOfBirthVariants,

    COUNT(DISTINCT Email
        COLLATE Latin1_General_100_BIN2) AS EmailVariants,

    COUNT(DISTINCT Phone
        COLLATE Latin1_General_100_BIN2) AS PhoneVariants,

    COUNT(DISTINCT City
        COLLATE Latin1_General_100_BIN2) AS CityVariants,

    COUNT(DISTINCT State
        COLLATE Latin1_General_100_BIN2) AS StateVariants,

    COUNT(DISTINCT Region
        COLLATE Latin1_General_100_BIN2) AS RegionVariants,

    COUNT(DISTINCT SignupDate) AS SignupDateVariants,

    COUNT(DISTINCT CustomerSegment
        COLLATE Latin1_General_100_BIN2) AS SegmentVariants

FROM dbo.Customers_Silver
WHERE CustomerID IN
(
    SELECT CustomerID
    FROM dbo.Customers_Silver
    GROUP BY CustomerID
    HAVING COUNT(*) > 1
)
GROUP BY CustomerID
ORDER BY CustomerID;




WITH DuplicateComparison AS
(
    SELECT
        CustomerID,

        COUNT(DISTINCT CustomerName
            COLLATE Latin1_General_100_BIN2) AS NameVariants,

        COUNT(DISTINCT Gender
            COLLATE Latin1_General_100_BIN2) AS GenderVariants,

        COUNT(DISTINCT DateOfBirth) AS DateOfBirthVariants,

        COUNT(DISTINCT Email
            COLLATE Latin1_General_100_BIN2) AS EmailVariants,

        COUNT(DISTINCT Phone
            COLLATE Latin1_General_100_BIN2) AS PhoneVariants,

        COUNT(DISTINCT City
            COLLATE Latin1_General_100_BIN2) AS CityVariants,

        COUNT(DISTINCT State
            COLLATE Latin1_General_100_BIN2) AS StateVariants,

        COUNT(DISTINCT Region
            COLLATE Latin1_General_100_BIN2) AS RegionVariants,

        COUNT(DISTINCT SignupDate) AS SignupDateVariants,

        COUNT(DISTINCT CustomerSegment
            COLLATE Latin1_General_100_BIN2) AS SegmentVariants

    FROM dbo.Customers_Silver
    WHERE CustomerID IN
    (
        SELECT CustomerID
        FROM dbo.Customers_Silver
        GROUP BY CustomerID
        HAVING COUNT(*) > 1
    )
    GROUP BY CustomerID
)
SELECT
    NameVariants,
    GenderVariants,
    DateOfBirthVariants,
    EmailVariants,
    PhoneVariants,
    CityVariants,
    StateVariants,
    RegionVariants,
    SignupDateVariants,
    SegmentVariants,
    COUNT(*) AS DuplicateGroupCount
FROM DuplicateComparison
GROUP BY
    NameVariants,
    GenderVariants,
    DateOfBirthVariants,
    EmailVariants,
    PhoneVariants,
    CityVariants,
    StateVariants,
    RegionVariants,
    SignupDateVariants,
    SegmentVariants
ORDER BY DuplicateGroupCount DESC;




WITH DuplicateComparison AS
(
    SELECT
        CustomerID,

        COUNT(DISTINCT CustomerName
            COLLATE Latin1_General_100_BIN2) AS NameVariants,

        COUNT(DISTINCT Email
            COLLATE Latin1_General_100_BIN2) AS EmailVariants,

        COUNT(DISTINCT Phone
            COLLATE Latin1_General_100_BIN2) AS PhoneVariants,

        COUNT(DISTINCT CustomerSegment) AS CustomerSegmentVariants

    FROM dbo.Customers_Silver
    WHERE CustomerID IN
    (
        SELECT CustomerID
        FROM dbo.Customers_Silver
        GROUP BY CustomerID
        HAVING COUNT(*) > 1
    )
    GROUP BY CustomerID
)
SELECT
    CustomerID,
    NameVariants,
    EmailVariants,
    PhoneVariants,
    CustomerSegmentVariants
FROM DuplicateComparison
WHERE
    (NameVariants = 1 AND EmailVariants = 2)
    OR
    (NameVariants = 2 AND EmailVariants = 2 AND CustomerSegmentVariants = 0)
ORDER BY CustomerID;



SELECT *
FROM dbo.Customers_Silver
WHERE CustomerID = 'CUST05808'
ORDER BY CustomerID;



SELECT
    CustomerID,
    COUNT(*) AS RecordCount,
    COUNT(CustomerSegment) AS NonNullSegments
FROM dbo.Customers_Silver
GROUP BY CustomerID
HAVING COUNT(*) > 1
   AND COUNT(CustomerSegment) = 0
ORDER BY CustomerID;



SELECT *
FROM dbo.Customers_Silver
WHERE CustomerID = 'CUST12229'
ORDER BY CustomerID;



SELECT
    COUNT(*) AS MissingOrBlankCustomerID
FROM dbo.Customers_Silver
WHERE CustomerID IS NULL
   OR LTRIM(RTRIM(CustomerID)) = '';

/* ============================================================
   QUERY 3 — STANDARDIZE CUSTOMERNAME
   Used to make values consistent for downstream analysis.
   ============================================================ */


UPDATE dbo.Customers_Silver
SET CustomerName = UPPER(LTRIM(RTRIM(CustomerName)));


UPDATE dbo.Customers_Silver
SET Email = LOWER(LTRIM(RTRIM(Email)));



SELECT
    CustomerID,
    COUNT(*) AS RecordCount
FROM dbo.Customers_Silver
GROUP BY CustomerID
HAVING COUNT(*) > 1
ORDER BY CustomerID;


/* ============================================================
   QUERY 4 — DEDUPLICATE
   Used to identify duplicate records before cleansing.
   ============================================================ */

WITH DuplicateCustomers AS
(
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY CustomerID
            ORDER BY (SELECT NULL)
        ) AS rn
    FROM dbo.Customers_Silver
)
DELETE FROM DuplicateCustomers
WHERE rn > 1;



/* ============================================================
   QUERY 5 — CHEKING AFER DEDUPLICATION
   Used to perform the cheking afer deduplication step in the Silver transformation.
   ============================================================ */

SELECT
    CustomerID,
    COUNT(*) AS RecordCount
FROM dbo.Customers_Silver
GROUP BY CustomerID
HAVING COUNT(*) > 1
ORDER BY CustomerID;




SELECT
    COUNT(*) AS MissingOrBlankCustomerName
FROM dbo.Customers_Silver
WHERE CustomerName IS NULL
   OR LTRIM(RTRIM(CustomerName)) = '';



SELECT
    Gender,
    COUNT(*) AS CustomerCount
FROM dbo.Customers_Silver
GROUP BY Gender
ORDER BY Gender;



SELECT
    COUNT(*) AS BlankGenderCount
FROM dbo.Customers_Silver
WHERE Gender IS NOT NULL
  AND LTRIM(RTRIM(Gender)) = '';

--add the quality flag

ALTER TABLE dbo.Customers_Silver
ADD GenderQualityStatus VARCHAR(30) NULL;




UPDATE dbo.Customers_Silver
SET GenderQualityStatus =
    CASE
        WHEN Gender IS NULL
            THEN 'Missing Gender'
        ELSE 'Valid Gender'
    END;



SELECT
    GenderQualityStatus,
    COUNT(*) AS CustomerCount
FROM dbo.Customers_Silver
GROUP BY GenderQualityStatus
ORDER BY GenderQualityStatus;



SELECT
    COLUMN_NAME,
    DATA_TYPE,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dbo'
  AND TABLE_NAME = 'Customers_Silver'
  AND COLUMN_NAME = 'DateOfBirth';




SELECT
    COUNT(*) AS TotalCustomers,
    SUM(
        CASE
            WHEN DateOfBirth IS NULL THEN 1
            ELSE 0
        END
    ) AS NullDateOfBirth,
    SUM(
        CASE
            WHEN DateOfBirth IS NOT NULL
             AND LTRIM(RTRIM(DateOfBirth)) = ''
            THEN 1
            ELSE 0
        END
    ) AS BlankDateOfBirth,
    SUM(
        CASE
            WHEN DateOfBirth IS NOT NULL
             AND LTRIM(RTRIM(DateOfBirth)) <> ''
             AND TRY_CONVERT(DATE, DateOfBirth, 23) IS NULL
            THEN 1
            ELSE 0
        END
    ) AS InvalidDateOfBirth
FROM dbo.Customers_Silver;



SELECT
    COUNT(*) AS FutureDateOfBirth
FROM dbo.Customers_Silver
WHERE TRY_CONVERT(DATE, DateOfBirth, 23) > CAST(GETDATE() AS DATE);




ALTER TABLE dbo.Customers_Silver
ADD CleanDateOfBirth DATE NULL;



UPDATE dbo.Customers_Silver
SET CleanDateOfBirth = TRY_CONVERT(DATE, DateOfBirth, 23);




SELECT
    COUNT(*) AS TotalCustomers,
    COUNT(CleanDateOfBirth) AS ConvertedDateOfBirth,
    SUM(
        CASE
            WHEN DateOfBirth IS NOT NULL
             AND CleanDateOfBirth IS NULL
            THEN 1
            ELSE 0
        END
    ) AS FailedConversions
FROM dbo.Customers_Silver;





ALTER TABLE dbo.Customers_Silver
DROP COLUMN DateOfBirth;

EXEC sp_rename
    'dbo.Customers_Silver.CleanDateOfBirth',
    'DateOfBirth',
    'COLUMN';

/* ============================================================
   QUERY 6 — EMAIL COMPLETENESS
   Used to perform the email completeness step in the Silver transformation.
   ============================================================ */

SELECT
    SUM(CASE WHEN Email IS NULL THEN 1 ELSE 0 END) AS NullEmail,
    SUM(
        CASE
            WHEN Email IS NOT NULL
             AND LTRIM(RTRIM(Email)) = ''
            THEN 1
            ELSE 0
        END
    ) AS BlankEmail,
    COUNT(*) AS TotalCustomers
FROM dbo.Customers_Silver;



ALTER TABLE dbo.Customers_Silver
ADD EmailQualityStatus VARCHAR(30) NULL;



UPDATE dbo.Customers_Silver
SET EmailQualityStatus =
    CASE
        WHEN Email IS NULL
            THEN 'Missing Email'
        ELSE 'Present Email'
    END;



SELECT
    EmailQualityStatus,
    COUNT(*) AS CustomerCount
FROM dbo.Customers_Silver
GROUP BY EmailQualityStatus
ORDER BY EmailQualityStatus;





SELECT
    CASE
        WHEN Email IS NULL THEN 'NULL'
        WHEN CHARINDEX('@', Email) = 0 THEN 'No @ symbol'
        WHEN CHARINDEX('@', Email) = 1 THEN '@ at beginning'
        WHEN CHARINDEX('@', Email) = LEN(Email) THEN '@ at end'
        ELSE 'Contains @'
    END AS EmailPattern,
    COUNT(*) AS CustomerCount
FROM dbo.Customers_Silver
GROUP BY
    CASE
        WHEN Email IS NULL THEN 'NULL'
        WHEN CHARINDEX('@', Email) = 0 THEN 'No @ symbol'
        WHEN CHARINDEX('@', Email) = 1 THEN '@ at beginning'
        WHEN CHARINDEX('@', Email) = LEN(Email) THEN '@ at end'
        ELSE 'Contains @'
    END
ORDER BY CustomerCount DESC;




SELECT TOP 50
    CustomerID,
    CustomerName,
    Email
FROM dbo.Customers_Silver
WHERE Email IS NOT NULL
  AND CHARINDEX('@', Email) = 0
ORDER BY CustomerID;



SELECT
    LOWER(
        SUBSTRING(
            Email,
            CHARINDEX('@', Email) + 1,
            LEN(Email)
        )
    ) AS EmailDomain,
    COUNT(*) AS CustomerCount
FROM dbo.Customers_Silver
WHERE Email IS NOT NULL
  AND CHARINDEX('@', Email) > 0
GROUP BY
    LOWER(
        SUBSTRING(
            Email,
            CHARINDEX('@', Email) + 1,
            LEN(Email)
        )
    )
ORDER BY CustomerCount DESC;




SELECT TOP 50
    CustomerID,
    CustomerName,
    Email,
    LOWER(
        REPLACE(CustomerName, ' ', '.')
    ) AS ExpectedNamePattern
FROM dbo.Customers_Silver
WHERE Email IS NOT NULL
  AND CHARINDEX('@', Email) = 0
ORDER BY CustomerID;



SELECT
    COUNT(*) AS TotalIncompleteEmails,
    SUM(
        CASE
            WHEN LOWER(Email) =
                 LOWER(REPLACE(CustomerName, ' ', '.'))
                 + RIGHT(
                     CustomerID,
                     LEN(CustomerID) - 4
                   )
            THEN 1
            ELSE 0
        END
    ) AS MatchingNameIDPattern,
    SUM(
        CASE
            WHEN LOWER(Email) <>
                 LOWER(REPLACE(CustomerName, ' ', '.'))
                 + RIGHT(
                     CustomerID,
                     LEN(CustomerID) - 4
                   )
            THEN 1
            ELSE 0
        END
    ) AS NonMatchingPattern
FROM dbo.Customers_Silver
WHERE Email IS NOT NULL
  AND CHARINDEX('@', Email) = 0;




SELECT TOP 50
    CustomerID,
    CustomerName,
    Email,
    LOWER(REPLACE(CustomerName, ' ', '.')) AS NamePattern,
    RIGHT(CustomerID, LEN(CustomerID) - 4) AS IDNumberPart
FROM dbo.Customers_Silver
WHERE Email IS NOT NULL
  AND CHARINDEX('@', Email) = 0
  AND LOWER(Email) <>
      LOWER(REPLACE(CustomerName, ' ', '.'))
      + RIGHT(CustomerID, LEN(CustomerID) - 4)
ORDER BY CustomerID;



SELECT
    COUNT(*) AS TotalIncompleteEmails,

    SUM(
        CASE
            WHEN LOWER(Email) =
                 LOWER(REPLACE(CustomerName, ' ', '.'))
                 + CAST(
                     CAST(SUBSTRING(CustomerID, 5, LEN(CustomerID) - 4) AS INT)
                     AS VARCHAR(20)
                   )
            THEN 1
            ELSE 0
        END
    ) AS MatchingPattern,

    SUM(
        CASE
            WHEN LOWER(Email) <>
                 LOWER(REPLACE(CustomerName, ' ', '.'))
                 + CAST(
                     CAST(SUBSTRING(CustomerID, 5, LEN(CustomerID) - 4) AS INT)
                     AS VARCHAR(20)
                   )
            THEN 1
            ELSE 0
        END
    ) AS NonMatchingPattern

FROM dbo.Customers_Silver
WHERE Email IS NOT NULL
  AND CHARINDEX('@', Email) = 0;




SELECT
    CustomerID,
    CustomerName,
    Email AS CurrentEmail,
    LOWER(REPLACE(CustomerName, ' ', '.'))
        + CAST(
            CAST(SUBSTRING(CustomerID, 5, LEN(CustomerID) - 4) AS INT)
            AS VARCHAR(20)
          )
        + '@example.com' AS ProposedEmail
FROM dbo.Customers_Silver
WHERE Email IS NOT NULL
  AND CHARINDEX('@', Email) = 0
ORDER BY CustomerID;




UPDATE dbo.Customers_Silver
SET Email =
    LOWER(REPLACE(CustomerName, ' ', '.'))
    + CAST(
        CAST(SUBSTRING(CustomerID, 5, LEN(CustomerID) - 4) AS INT)
        AS VARCHAR(20)
      )
    + '@example.com'
WHERE Email IS NOT NULL
  AND CHARINDEX('@', Email) = 0;




SELECT
    COUNT(*) AS EmailsWithoutAtSymbol
FROM dbo.Customers_Silver
WHERE Email IS NOT NULL
  AND CHARINDEX('@', Email) = 0;



SELECT
    EmailQualityStatus,
    COUNT(*) AS CustomerCount
FROM dbo.Customers_Silver
GROUP BY EmailQualityStatus
ORDER BY EmailQualityStatus;


UPDATE dbo.Customers_Silver
SET EmailQualityStatus =
    CASE
        WHEN Email IS NULL
            THEN 'Missing Email'
        WHEN CHARINDEX('@', Email) > 0
             AND EmailQualityStatus = 'Present Email'
            THEN 'Valid Email'
        ELSE EmailQualityStatus
    END;



SELECT
    CASE
        WHEN Phone IS NULL THEN 'NULL'
        WHEN LTRIM(RTRIM(Phone)) = '' THEN 'Blank'
        ELSE 'Present'
    END AS PhonePattern,
    COUNT(*) AS CustomerCount
FROM dbo.Customers_Silver
GROUP BY
    CASE
        WHEN Phone IS NULL THEN 'NULL'
        WHEN LTRIM(RTRIM(Phone)) = '' THEN 'Blank'
        ELSE 'Present'
    END
ORDER BY CustomerCount DESC;





SELECT
    LEN(LTRIM(RTRIM(Phone))) AS PhoneLength,
    COUNT(*) AS CustomerCount
FROM dbo.Customers_Silver
WHERE Phone IS NOT NULL
  AND LTRIM(RTRIM(Phone)) <> ''
GROUP BY LEN(LTRIM(RTRIM(Phone)))
ORDER BY PhoneLength;




SELECT
    SUM(
        CASE
            WHEN Phone IS NOT NULL
             AND LTRIM(RTRIM(Phone)) <> ''
             AND Phone NOT LIKE '%[^0-9]%'
            THEN 1
            ELSE 0
        END
    ) AS NumericPhones,

    SUM(
        CASE
            WHEN Phone IS NOT NULL
             AND LTRIM(RTRIM(Phone)) <> ''
             AND Phone LIKE '%[^0-9]%'
            THEN 1
            ELSE 0
        END
    ) AS NonNumericPhones
FROM dbo.Customers_Silver;



ALTER TABLE dbo.Customers_Silver
ADD PhoneQualityStatus VARCHAR(30) NULL;



UPDATE dbo.Customers_Silver
SET PhoneQualityStatus =
    CASE
        WHEN Phone IS NULL
            THEN 'Missing Phone'
        ELSE 'Valid Phone'
    END;



SELECT
    PhoneQualityStatus,
    COUNT(*) AS CustomerCount
FROM dbo.Customers_Silver
GROUP BY PhoneQualityStatus
ORDER BY PhoneQualityStatus;




SELECT
    CASE
        WHEN City IS NULL THEN 'NULL'
        WHEN LTRIM(RTRIM(City)) = '' THEN 'Blank'
        ELSE 'Present'
    END AS CityPattern,
    COUNT(*) AS CustomerCount
FROM dbo.Customers_Silver
GROUP BY
    CASE
        WHEN City IS NULL THEN 'NULL'
        WHEN LTRIM(RTRIM(City)) = '' THEN 'Blank'
        ELSE 'Present'
    END
ORDER BY CustomerCount DESC;




SELECT
    City,
    COUNT(*) AS CustomerCount
FROM dbo.Customers_Silver
GROUP BY City
ORDER BY CustomerCount DESC, City;




SELECT
    City COLLATE Latin1_General_100_BIN2 as city,
    COUNT(*) AS CustomerCount
FROM dbo.Customers_Silver
GROUP BY City COLLATE Latin1_General_100_BIN2
ORDER BY City COLLATE Latin1_General_100_BIN2;




SELECT
    COUNT(*) AS CityWithExtraSpaces
FROM dbo.Customers_Silver
WHERE City <> LTRIM(RTRIM(City));



SELECT
    CASE
        WHEN State IS NULL THEN 'NULL'
        WHEN LTRIM(RTRIM(State)) = '' THEN 'Blank'
        ELSE 'Present'
    END AS StatePattern,
    COUNT(*) AS CustomerCount
FROM dbo.Customers_Silver
GROUP BY
    CASE
        WHEN State IS NULL THEN 'NULL'
        WHEN LTRIM(RTRIM(State)) = '' THEN 'Blank'
        ELSE 'Present'
    END
ORDER BY CustomerCount DESC;



SELECT
    State,
    COUNT(*) AS CustomerCount
FROM dbo.Customers_Silver
GROUP BY State
ORDER BY CustomerCount DESC, State;


SELECT
    State COLLATE Latin1_General_100_BIN2 AS State,
    COUNT(*) AS CustomerCount
FROM dbo.Customers_Silver
GROUP BY State COLLATE Latin1_General_100_BIN2
ORDER BY State;




SELECT
    CASE
        WHEN Region IS NULL THEN 'NULL'
        WHEN LTRIM(RTRIM(Region)) = '' THEN 'Blank'
        ELSE 'Present'
    END AS RegionPattern,
    COUNT(*) AS CustomerCount
FROM dbo.Customers_Silver
GROUP BY
    CASE
        WHEN Region IS NULL THEN 'NULL'
        WHEN LTRIM(RTRIM(Region)) = '' THEN 'Blank'
        ELSE 'Present'
    END
ORDER BY CustomerCount DESC;



SELECT
    Region,
    COUNT(*) AS CustomerCount
FROM dbo.Customers_Silver
GROUP BY Region
ORDER BY CustomerCount DESC, Region;



SELECT
    COLUMN_NAME,
    DATA_TYPE,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dbo'
  AND TABLE_NAME = 'Customers_Silver'
  AND COLUMN_NAME = 'SignupDate';




SELECT
    COUNT(*) AS TotalCustomers,
    SUM(
        CASE
            WHEN SignupDate IS NULL THEN 1
            ELSE 0
        END
    ) AS NullSignupDate,
    SUM(
        CASE
            WHEN SignupDate IS NOT NULL
             AND LTRIM(RTRIM(SignupDate)) = ''
            THEN 1
            ELSE 0
        END
    ) AS BlankSignupDate,
    SUM(
        CASE
            WHEN SignupDate IS NOT NULL
             AND LTRIM(RTRIM(SignupDate)) <> ''
             AND TRY_CONVERT(DATE, SignupDate, 23) IS NULL
            THEN 1
            ELSE 0
        END
    ) AS InvalidSignupDate
FROM dbo.Customers_Silver;


ALTER TABLE dbo.Customers_Silver
ADD CleanSignupDate DATE NULL;


UPDATE dbo.Customers_Silver
SET CleanSignupDate = TRY_CONVERT(DATE, SignupDate, 23);



SELECT
    COUNT(*) AS TotalCustomers,
    COUNT(CleanSignupDate) AS ConvertedSignupDates,
    SUM(
        CASE
            WHEN SignupDate IS NOT NULL
             AND CleanSignupDate IS NULL
            THEN 1
            ELSE 0
        END
    ) AS FailedConversions
FROM dbo.Customers_Silver;


ALTER TABLE dbo.Customers_Silver
DROP COLUMN SignupDate;

EXEC sp_rename
    'dbo.Customers_Silver.CleanSignupDate',
    'SignupDate',
    'COLUMN';



SELECT
    COLUMN_NAME,
    DATA_TYPE,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dbo'
  AND TABLE_NAME = 'Customers_Silver'
  AND COLUMN_NAME = 'CustomerSegment';


SELECT
    CASE
        WHEN CustomerSegment IS NULL THEN 'NULL'
        WHEN LTRIM(RTRIM(CustomerSegment)) = '' THEN 'Blank'
        ELSE CustomerSegment
    END AS CustomerSegmentPattern,
    COUNT(*) AS CustomerCount
FROM dbo.Customers_Silver
GROUP BY
    CASE
        WHEN CustomerSegment IS NULL THEN 'NULL'
        WHEN LTRIM(RTRIM(CustomerSegment)) = '' THEN 'Blank'
        ELSE CustomerSegment
    END
ORDER BY CustomerCount DESC;




ALTER TABLE dbo.Customers_Silver
ADD CustomerSegmentQualityStatus VARCHAR(30) NULL;



UPDATE dbo.Customers_Silver
SET CustomerSegmentQualityStatus =
    CASE
        WHEN CustomerSegment IS NULL THEN 'Missing Customer Segment'
        ELSE 'Valid Customer Segment'
    END;



SELECT
    CustomerSegmentQualityStatus,
    COUNT(*) AS CustomerCount
FROM dbo.Customers_Silver
GROUP BY CustomerSegmentQualityStatus
ORDER BY CustomerCount DESC;



SELECT
    CustomerSegment,
    COUNT(*) AS CustomerCount
FROM dbo.Customers_Silver
WHERE CustomerSegment IS NOT NULL
GROUP BY CustomerSegment
ORDER BY CustomerCount DESC;



SELECT
    Email,
    COUNT(*) AS CustomerCount
FROM dbo.Customers_Silver
WHERE Email IS NOT NULL
GROUP BY Email
HAVING COUNT(*) > 1
ORDER BY CustomerCount DESC, Email;



SELECT
    COUNT(*) AS TotalCustomers,
    COUNT(DISTINCT CustomerID) AS DistinctCustomerIDs,
    COUNT(*) - COUNT(DISTINCT CustomerID) AS DuplicateCustomerIDs
FROM dbo.Customers_Silver;




/* ============================================================
   QUERY 7 — ******************************************** OVERALL CHEKING ***************************************************************************
   Used to perform the ******************************************** overall cheking *************************************************************************** step in the Silver transformation.
   ============================================================ */


SELECT 'Customers_Silver' AS TableName, COUNT(*) AS NumberCount
FROM dbo.Customers_Silver

UNION ALL

SELECT 'Products_Silver', COUNT(*)
FROM dbo.Products_Silver

UNION ALL

SELECT 'Stores_Silver', COUNT(*)
FROM dbo.Stores_Silver

UNION ALL

SELECT 'Employees_Silver', COUNT(*)
FROM dbo.Employees_Silver

UNION ALL

SELECT 'Sales_Silver', COUNT(*)
FROM dbo.Sales_Silver;