/*
============================================================
NEXMART ENTERPRISE DATA WAREHOUSE
SILVER LAYER — SALES
============================================================

PURPOSE:
Create and transform the Sales_Silver table from the Bronze
staging table.

This script contains the Silver-layer work performed for the
NexMart project. Bronze data is kept unchanged; cleansing,
standardization, deduplication, validation, and data-quality
classification are handled here.

PREREQUISITES:
1. Database: NexMartDW
2. Bronze source table: stg.Sales_Raw
3. The Bronze layer must already be loaded.
4. Required related Silver tables must exist for cross-table
   validation performed by this script.

RE-RUN BEHAVIOUR:
The existing dbo.Sales_Silver table is dropped and recreated
from Bronze so the script can be rerun during development.

NOTE:
Run the Silver scripts in dependency order when executing the
complete warehouse. Cross-table validation queries require the
related Silver tables to exist.
============================================================
*/

use NexMartDW ;



/* ============================================================
   QUERY 1 — ************************************* RULE S01 � DUPLICATE SALES RECORDS . *******************************************
   Used to identify duplicate records before cleansing.
   ============================================================ */

WITH DeduplicatedSales AS
(
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY TransactionID
            ORDER BY (SELECT NULL)
        ) AS rn
    FROM stg.Sales_Raw
)
SELECT
    TransactionID,
    OrderID,
    OrderLineNumber,
    rn
FROM DeduplicatedSales
WHERE rn > 1;




/* ============================================================
   QUERY 2 — MAKING SILVER_SALES TABLE
   Used to perform the making silver_sales table step in the Silver transformation.
   ============================================================ */


WITH DeduplicatedSales AS
(
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY TransactionID
            ORDER BY (SELECT NULL)
        ) AS rn
    FROM stg.Sales_Raw
)
SELECT
    TransactionID,
    OrderID,
    OrderLineNumber,
    OrderDate,
    CustomerID,
    ProductID,
    StoreID,
    EmployeeID,
    Quantity,
    UnitPrice,
    DiscountPercent,
    TaxPercent,
    PaymentMethod,
    SalesChannel,
    OrderStatus
INTO dbo.Sales_Silver
FROM DeduplicatedSales
WHERE rn = 1;



/* ============================================================
   QUERY 3 — NOW CHEKING THE STATUS OF BOTH TABLE
   Used to standardize and validate status values.
   ============================================================ */

SELECT
    (SELECT COUNT(*) FROM stg.Sales_Raw) AS RawRows,
    (SELECT COUNT(*) FROM dbo.Sales_Silver) AS SilverRows,
    (SELECT COUNT(*) FROM stg.Sales_Raw)
      - (SELECT COUNT(*) FROM dbo.Sales_Silver) AS RowsRemoved;


/* ============================================================
   QUERY 4 — CHECK DUBLICATE TRUNSACTION ID IN SILVER SALES
   Used to perform the check dublicate trunsaction id in silver sales step in the Silver transformation.
   ============================================================ */

SELECT
    TransactionID,
    COUNT(*) AS RecordCount
FROM dbo.Sales_Silver
GROUP BY TransactionID
HAVING COUNT(*) > 1
ORDER BY RecordCount DESC, TransactionID;



-- ********************************** Rule S02 � CustomerID quality classification . *******************************************************



/* ============================================================
   QUERY 5 — � CHECK MISSING CUSTOMERID IN SILVER
   Used to identify incomplete values before transformation.
   ============================================================ */

SELECT COUNT(*) AS MissingCustomerID
FROM dbo.Sales_Silver
WHERE CustomerID IS NULL;


/* ============================================================
   QUERY 6 — INVALID CUSTOMERIDS.
   Used to identify values that do not meet the expected data rules.
   ============================================================ */

SELECT COUNT(*) AS InvalidCustomerID
FROM dbo.Sales_Silver s
WHERE s.CustomerID IS NOT NULL
  AND NOT EXISTS (
      SELECT 1
      FROM stg.Customers_Raw c
      WHERE c.CustomerID = s.CustomerID
  );


/* ============================================================
   QUERY 7 — LET'S IDENTIFY EXACTLY WHICH CUSTOMERIDS ARE INVALID IN SILVER
   Used to identify values that do not meet the expected data rules.
   ============================================================ */

SELECT
    s.CustomerID,
    COUNT(*) AS SalesRecordCount
FROM dbo.Sales_Silver s
WHERE s.CustomerID IS NOT NULL
  AND NOT EXISTS (
      SELECT 1
      FROM stg.Customers_Raw c
      WHERE c.CustomerID = s.CustomerID
  )
GROUP BY s.CustomerID
ORDER BY SalesRecordCount DESC, s.CustomerID;




--Add a quality-status column

ALTER TABLE dbo.Sales_Silver
ADD CustomerQualityStatus VARCHAR(30);


/* ============================================================
   QUERY 8 — CLASSIFY EVERY CUSTOMERID BY VALID ,INVALID,MISSING
   Used to identify incomplete values before transformation.
   ============================================================ */

UPDATE s
SET CustomerQualityStatus =
    CASE
        WHEN s.CustomerID IS NULL
            THEN 'Missing CustomerID'

        WHEN NOT EXISTS (
            SELECT 1
            FROM stg.Customers_Raw c
            WHERE c.CustomerID = s.CustomerID
        )
            THEN 'Invalid CustomerID'

        ELSE 'Valid CustomerID'
    END
FROM dbo.Sales_Silver s;



/* ============================================================
   QUERY 9 — VALIDATE THE CLASSIFICATION
   Used to validate the transformed data against expected rules.
   ============================================================ */


SELECT
    CustomerQualityStatus,
    COUNT(*) AS RecordCount
FROM dbo.Sales_Silver
GROUP BY CustomerQualityStatus
ORDER BY RecordCount DESC;






/* ============================================================
   QUERY 10 — ************************************** RULE S03 � PRODUCTID QUALITY CLASSIFICATION . ************************************************
   Used to classify records according to data-quality conditions.
   ============================================================ */

/* ============================================================
   QUERY 11 — MISSING PRODUCTID
   Used to identify incomplete values before transformation.
   ============================================================ */


SELECT COUNT(*) AS MissingProductID
FROM dbo.Sales_Silver
WHERE ProductID IS NULL;




/* ============================================================
   QUERY 12 — INVALID PRODUCTID
   Used to identify values that do not meet the expected data rules.
   ============================================================ */

SELECT COUNT(*) AS InvalidProductID
FROM dbo.Sales_Silver s
WHERE s.ProductID IS NOT NULL
  AND NOT EXISTS (
      SELECT 1
      FROM stg.Products_Raw p
      WHERE p.ProductID = s.ProductID
  );

/* ============================================================
   QUERY 13 — WHICH ID IS RESPONSIBLE  FOR INVALID ID CHEKING
   Used to identify values that do not meet the expected data rules.
   ============================================================ */

SELECT
    s.ProductID,
    COUNT(*) AS SalesRecordCount
FROM dbo.Sales_Silver s
WHERE s.ProductID IS NOT NULL
  AND NOT EXISTS (
      SELECT 1
      FROM stg.Products_Raw p
      WHERE p.ProductID = s.ProductID
  )
GROUP BY s.ProductID
ORDER BY SalesRecordCount DESC, s.ProductID;



-- Add the product Quality column 

ALTER TABLE dbo.Sales_Silver
ADD ProductQualityStatus VARCHAR(30);


/* ============================================================
   QUERY 14 — POPULATE PRODUCTQUALITYSTATUS
   Used to classify records according to data-quality conditions.
   ============================================================ */


UPDATE s
SET ProductQualityStatus =
    CASE
        WHEN s.ProductID IS NULL
            THEN 'Missing ProductID'

        WHEN NOT EXISTS (
            SELECT 1
            FROM stg.Products_Raw p
            WHERE p.ProductID = s.ProductID
        )
            THEN 'Invalid ProductID'

        ELSE 'Valid ProductID'
    END
FROM dbo.Sales_Silver s;



/* ============================================================
   QUERY 15 — CHEKING THE UPDATED PRODUCT QUALITY STATUS
   Used to classify records according to data-quality conditions.
   ============================================================ */

SELECT
    ProductQualityStatus,
    COUNT(*) AS RecordCount
FROM dbo.Sales_Silver
GROUP BY ProductQualityStatus
ORDER BY RecordCount DESC;



/* ============================================================
   QUERY 16 — *************************************** RULE S04 � STOREID QUALITY CLASSIFICATION .********************************************
   Used to classify records according to data-quality conditions.
   ============================================================ */

/* ============================================================
   QUERY 17 — CHEKING NULL STOREID
   Used to identify NULL values that require data-quality handling.
   ============================================================ */

select count(*) as Missingstoreid
from dbo.Sales_Silver 
where StoreID is null;


/* ============================================================
   QUERY 18 — CHECK INVALID STOREID REFERENCES
   Used to identify values that do not meet the expected data rules.
   ============================================================ */


SELECT COUNT(*) AS InvalidStoreID
FROM dbo.Sales_Silver s
WHERE s.StoreID IS NOT NULL
  AND NOT EXISTS (
      SELECT 1
      FROM stg.Stores_Raw st
      WHERE st.StoreID = s.StoreID
  );



/* ============================================================
   QUERY 19 — FINDING WHICH STORE ARE INVALID
   Used to identify values that do not meet the expected data rules.
   ============================================================ */


SELECT
    s.StoreID,
    COUNT(*) AS SalesRecordCount
FROM dbo.Sales_Silver s
WHERE s.StoreID IS NOT NULL
  AND NOT EXISTS (
      SELECT 1
      FROM stg.Stores_Raw st
      WHERE st.StoreID = s.StoreID
  )
GROUP BY s.StoreID
ORDER BY SalesRecordCount DESC, s.StoreID;



-- Add the storeID quaity column

ALTER TABLE dbo.Sales_Silver
ADD StoreQualityStatus VARCHAR(30);



/* ============================================================
   QUERY 20 — POPULATE STOREIDQUALITYSTATUS
   Used to classify records according to data-quality conditions.
   ============================================================ */


UPDATE s
SET StoreQualityStatus =
    CASE
        WHEN s.StoreID IS NULL
            THEN 'Missing StoreID'

        WHEN NOT EXISTS (
            SELECT 1
            FROM stg.Stores_Raw st
            WHERE st.StoreID = s.StoreID
        )
            THEN 'Invalid StoreID'

        ELSE 'Valid StoreID'
    END
FROM dbo.Sales_Silver s;



/* ============================================================
   QUERY 21 — CHEKING THE UPDATED DETAILS
   Used to standardize or validate date values for analysis.
   ============================================================ */

SELECT
    StoreQualityStatus,
    COUNT(*) AS RecordCount
FROM dbo.Sales_Silver
GROUP BY StoreQualityStatus
ORDER BY RecordCount DESC;




/* ============================================================
   QUERY 22 — *************************************** RULE S05 � EMPLOYEEID QUALITY CLASSIFICATION . **********************************************
   Used to classify records according to data-quality conditions.
   ============================================================ */


/* ============================================================
   QUERY 23 — FIND MISSING EMPLOYEEID
   Used to identify incomplete values before transformation.
   ============================================================ */

SELECT COUNT(*) AS MissingEmployeeID
FROM dbo.Sales_Silver
WHERE EmployeeID IS NULL;



/* ============================================================
   QUERY 24 — FIND INVALID EMPLOYEEID
   Used to identify values that do not meet the expected data rules.
   ============================================================ */

SELECT COUNT(*) AS InvalidEmployeeID
FROM dbo.Sales_Silver s
WHERE s.EmployeeID IS NOT NULL
  AND NOT EXISTS (
      SELECT 1
      FROM stg.Employees_Raw e
      WHERE e.EmployeeID = s.EmployeeID
  );


/* ============================================================
   QUERY 25 — FIND THE INVALID EMPLOYEEID
   Used to identify values that do not meet the expected data rules.
   ============================================================ */

SELECT
    s.EmployeeID,
    COUNT(*) AS SalesRecordCount
FROM dbo.Sales_Silver s
WHERE s.EmployeeID IS NOT NULL
  AND NOT EXISTS (
      SELECT 1
      FROM stg.Employees_Raw e
      WHERE e.EmployeeID = s.EmployeeID
  )
GROUP BY s.EmployeeID
ORDER BY SalesRecordCount DESC, s.EmployeeID;


-- ADD The quality column for employeeId

ALTER TABLE dbo.Sales_Silver
ADD EmployeeQualityStatus VARCHAR(30);




/* ============================================================
   QUERY 26 — UPDATE THE REFERENCE AS VALID ,INVALID,MISSING
   Used to identify incomplete values before transformation.
   ============================================================ */

UPDATE s
SET EmployeeQualityStatus =
    CASE
        WHEN s.EmployeeID IS NULL
            THEN 'Missing EmployeeID'

        WHEN NOT EXISTS (
            SELECT 1
            FROM stg.Employees_Raw e
            WHERE e.EmployeeID = s.EmployeeID
        )
            THEN 'Invalid EmployeeID'

        ELSE 'Valid EmployeeID'
    END
FROM dbo.Sales_Silver s;



/* ============================================================
   QUERY 27 — VALIDATE THE EMPLOYEEID STATUS/CHEKING
   Used to validate the transformed data against expected rules.
   ============================================================ */


SELECT
    EmployeeQualityStatus,
    COUNT(*) AS RecordCount
FROM dbo.Sales_Silver
GROUP BY EmployeeQualityStatus
ORDER BY RecordCount DESC;




/* ============================================================
   QUERY 28 — CHEKING ANY MISSING PRESENT OR NOT FOR STOREID JUST FOR CONFIRMATION NOT NEED AS WE ALREADY KNOW DATA IS FINE ACCORDING BUSINESS RULES
   Used to identify incomplete values before transformation.
   ============================================================ */

SELECT
    COUNT(*) AS MissingOrderID
FROM dbo.Sales_Silver
WHERE OrderID IS NULL
   OR LTRIM(RTRIM(OrderID)) = '';



/* ============================================================
   QUERY 29 — ************************************** RULE S06 � ORDERLINENUMBER CHEKING CLASSIFICATION. *****************************************
   Used to perform the ************************************** rule s06 � orderlinenumber cheking classification. ***************************************** step in the Silver transformation.
   ============================================================ */


/* ============================================================
   QUERY 30 — CEKHING ANY MISSING VALUE
   Used to identify incomplete values before transformation.
   ============================================================ */

SELECT COUNT(*) AS NonNumericOrderLineNumber
FROM dbo.Sales_Silver
WHERE OrderLineNumber IS NOT NULL
  AND TRY_CONVERT(INT, OrderLineNumber) IS NULL;



/* ============================================================
   QUERY 31 — CHEKING NON POSITIVE VALUE
   Used to perform the cheking non positive value step in the Silver transformation.
   ============================================================ */

SELECT COUNT(*) AS NonPositiveOrderLineNumber
FROM dbo.Sales_Silver
WHERE TRY_CONVERT(INT, OrderLineNumber) <= 0;



-- Convert the column to INT as this colun represents int value s varchar would be wrong 


ALTER TABLE dbo.Sales_Silver
ALTER COLUMN OrderLineNumber INT NOT NULL;



/* ============================================================
   QUERY 32 — CHIKNG THE SILVER TABLE DATA TYPE FOR CONFIRMATRION
   Used to perform the chikng the silver table data type for confirmatrion step in the Silver transformation.
   ============================================================ */

SELECT
    COLUMN_NAME,
    DATA_TYPE,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dbo'
  AND TABLE_NAME = 'Sales_Silver'
  AND COLUMN_NAME = 'OrderLineNumber';







-- ******************************* Rule S07 - OrderDate Quality Classification . **********************************************************


/* ============================================================
   QUERY 33 — CHECK WHETHER ANY SILVER ORDERDATE IS UNPARSEABLE
   Used to standardize or validate date values for analysis.
   ============================================================ */


SELECT COUNT(*) AS UnparseableOrderDate
FROM dbo.Sales_Silver
WHERE TRY_CONVERT(date, OrderDate, 23) IS NULL
  AND TRY_CONVERT(date, OrderDate, 103) IS NULL;



/* ============================================================
   QUERY 34 — PREVIEW THE DATE CONVERSION
   Used to standardize or validate date values for analysis.
   ============================================================ */

SELECT TOP 20
    OrderDate AS OriginalOrderDate,
    COALESCE(
        TRY_CONVERT(date, OrderDate, 23),
        TRY_CONVERT(date, OrderDate, 103)
    ) AS CleanOrderDate
FROM dbo.Sales_Silver
ORDER BY OrderDate;


--create the clean DATE column


ALTER TABLE dbo.Sales_Silver
ADD CleanOrderDate DATE;



UPDATE dbo.Sales_Silver
SET CleanOrderDate =
    COALESCE(
        TRY_CONVERT(date, OrderDate, 23),
        TRY_CONVERT(date, OrderDate, 103)
    );


/* ============================================================
   QUERY 35 — CHEKING THE VALIDATED VALUE
   Used to validate the transformed data against expected rules.
   ============================================================ */


SELECT
    COUNT(*) AS TotalRows,
    COUNT(CleanOrderDate) AS ValidCleanDates,
    MIN(CleanOrderDate) AS EarliestOrderDate,
    MAX(CleanOrderDate) AS LatestOrderDate
FROM dbo.Sales_Silver;



/* ============================================================
   QUERY 36 — NOW DATE COLUM SUCESSFULY PARSED SO DELETE THE OLD ORDERDATE COLUMN
   Used to standardize or validate date values for analysis.
   ============================================================ */


ALTER TABLE dbo.Sales_Silver
DROP COLUMN OrderDate;



-- now Rename exactly like before (Exec stand for execute sql store procedure ,)


EXEC sp_rename
    'dbo.Sales_Silver.CleanOrderDate',
    'OrderDate',
    'COLUMN';


/* ============================================================
   QUERY 37 — NOW SEE THE CORRECT CHANGING COLUM NAME IN SILVER
   Used to perform the now see the correct changing colum name in silver step in the Silver transformation.
   ============================================================ */

SELECT
    COLUMN_NAME,
    DATA_TYPE,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dbo'
  AND TABLE_NAME = 'Sales_Silver'
  AND COLUMN_NAME = 'OrderDate';



/* ============================================================
   QUERY 38 — *********************************************** RULE S08 - QUANTITY QUALITY CLASSIFICATION .**************************************************
   Used to classify records according to data-quality conditions.
   ============================================================ */

/* ============================================================
   QUERY 39 — CHEKING INVALID VALUE FOR COMPLTE ORDER
   Used to identify values that do not meet the expected data rules.
   ============================================================ */

SELECT
    COUNT(*) AS InvalidCompletedQuantity
FROM dbo.Sales_Silver
WHERE OrderStatus = 'Completed'
  AND (
        TRY_CONVERT(INT, Quantity) IS NULL
        OR TRY_CONVERT(INT, Quantity) <= 0
      );


/* ============================================================
   QUERY 40 — CHEKING WHAQT TYPE OF INVALID VALUE PRESENT IN THIS
   Used to identify values that do not meet the expected data rules.
   ============================================================ */

SELECT
    CASE
        WHEN Quantity IS NULL THEN 'NULL'
        WHEN TRY_CONVERT(INT, Quantity) < 0 THEN 'Negative'
        WHEN TRY_CONVERT(INT, Quantity) = 0 THEN 'Zero'
        WHEN TRY_CONVERT(INT, Quantity) IS NULL THEN 'Non-numeric'
        ELSE 'Other'
    END AS QuantityProblem,
    COUNT(*) AS ProblemRows
FROM dbo.Sales_Silver
WHERE OrderStatus = 'Completed'
  AND (
        TRY_CONVERT(INT, Quantity) IS NULL
        OR TRY_CONVERT(INT, Quantity) <= 0
      )
GROUP BY
    CASE
        WHEN Quantity IS NULL THEN 'NULL'
        WHEN TRY_CONVERT(INT, Quantity) < 0 THEN 'Negative'
        WHEN TRY_CONVERT(INT, Quantity) = 0 THEN 'Zero'
        WHEN TRY_CONVERT(INT, Quantity) IS NULL THEN 'Non-numeric'
        ELSE 'Other'
    END
ORDER BY ProblemRows DESC;



/* ============================================================
   QUERY 41 — INSPECT THE INVALID ROWS
   Used to identify values that do not meet the expected data rules.
   ============================================================ */

SELECT TOP 50
    TransactionID,
    OrderID,
    OrderLineNumber,
    OrderDate,
    Quantity,
    UnitPrice,
    DiscountPercent,
    PaymentMethod,
    SalesChannel,
    OrderStatus
FROM dbo.Sales_Silver
WHERE OrderStatus = 'Completed'
  AND (
        TRY_CONVERT(INT, Quantity) IS NULL
        OR TRY_CONVERT(INT, Quantity) <= 0
      )
ORDER BY
    CASE
        WHEN Quantity IS NULL THEN 1
        WHEN TRY_CONVERT(INT, Quantity) = 0 THEN 2
        WHEN TRY_CONVERT(INT, Quantity) < 0 THEN 3
        ELSE 4
    END,
    TransactionID;



/* ============================================================
   QUERY 42 — CHEKING UNIT WHICH IS COMPLETED AND NEGATIVE UNIT PRICE
   Used to validate and standardize product price values.
   ============================================================ */

SELECT TOP 30
    TransactionID,
    OrderID,
    OrderLineNumber,
    OrderDate,
    Quantity,
    UnitPrice,
    DiscountPercent,
    PaymentMethod,
    SalesChannel,
    OrderStatus
FROM dbo.Sales_Silver
WHERE OrderStatus = 'Completed'
  AND TRY_CONVERT(INT, Quantity) < 0
ORDER BY TransactionID;




/* ============================================================
   QUERY 43 — NOW INVESTIGATE COMPLETE + 0 VALUES
   Used to perform the now investigate complete + 0 values step in the Silver transformation.
   ============================================================ */

SELECT TOP 30
    TransactionID,
    OrderID,
    OrderLineNumber,
    OrderDate,
    Quantity,
    UnitPrice,
    DiscountPercent,
    PaymentMethod,
    SalesChannel,
    OrderStatus
FROM dbo.Sales_Silver
WHERE OrderStatus = 'Completed'
  AND TRY_CONVERT(INT, Quantity) = 0
ORDER BY TransactionID;

/* ============================================================
   QUERY 44 — CHENING OVERALL SILVER TABLE INVALID QUANTITY OVER ORDER STATUS
   Used to identify values that do not meet the expected data rules.
   ============================================================ */

SELECT
    OrderStatus,
    COUNT(*) AS InvalidQuantityRows
FROM dbo.Sales_Silver
WHERE TRY_CONVERT(INT, Quantity) IS NULL
   OR TRY_CONVERT(INT, Quantity) <= 0
GROUP BY OrderStatus
ORDER BY OrderStatus;



/* ============================================================
   QUERY 45 — NOW CHEKING CANCELLED STATUS QUANTITY
   Used to validate sales quantity values.
   ============================================================ */


SELECT
    Quantity,
    COUNT(*) AS RowsCount
FROM dbo.Sales_Silver
WHERE OrderStatus = 'Cancelled'
GROUP BY Quantity
ORDER BY
    TRY_CONVERT(INT, Quantity);



/* ============================================================
   QUERY 46 — NOW INVESTIGATE RETURNED STATUS AND QUANTITY VERIFY
   Used to validate sales quantity values.
   ============================================================ */

SELECT
    Quantity,
    COUNT(*) AS RowsCount
FROM dbo.Sales_Silver
WHERE OrderStatus = 'Returned'
GROUP BY Quantity
ORDER BY
    TRY_CONVERT(INT, Quantity);


/* ============================================================
   QUERY 47 — CHEKING THE RETUREND + -1 VALUE WHAT CONTAINS
   Used to perform the cheking the returend + -1 value what contains step in the Silver transformation.
   ============================================================ */


SELECT TOP 30
    TransactionID,
    OrderID,
    OrderLineNumber,
    OrderDate,
    Quantity,
    UnitPrice,
    DiscountPercent,
    PaymentMethod,
    SalesChannel,
    OrderStatus
FROM dbo.Sales_Silver
WHERE OrderStatus = 'Returned'
  AND TRY_CONVERT(INT, Quantity) < 0
ORDER BY TransactionID;



/* ============================================================
   QUERY 48 — CHEKING IS SALES_SILVER EVERY QUANTITY VALUE CAN BE SUCCESSFULLY COVERTED TO INT
   Used to validate sales quantity values.
   ============================================================ */

SELECT
    COUNT(*) AS NonNumericQuantity
FROM dbo.Sales_Silver
WHERE Quantity IS NOT NULL
  AND TRY_CONVERT(INT, Quantity) IS NULL;


-- changing the quantity column data type 

ALTER TABLE dbo.Sales_Silver
ALTER COLUMN Quantity INT NULL;



/* ============================================================
   QUERY 49 — CHEKING THE VALIDATED COLUMN
   Used to validate the transformed data against expected rules.
   ============================================================ */

SELECT
    COLUMN_NAME,
    DATA_TYPE,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dbo'
  AND TABLE_NAME = 'Sales_Silver'
  AND COLUMN_NAME = 'Quantity';



-- add quantity-status column in silver

ALTER TABLE dbo.Sales_Silver
ADD QuantityQualityStatus VARCHAR(30);



/* ============================================================
   QUERY 50 — UPDATED VALUES FOR COMPLETE STATUS IN QUANTITY STATUS VALUES
   Used to standardize or validate date values for analysis.
   ============================================================ */

UPDATE dbo.Sales_Silver
SET QuantityQualityStatus =
    CASE
        WHEN OrderStatus = 'Completed'
             AND (Quantity IS NULL OR Quantity <= 0)
            THEN 'Invalid Quantity'

        WHEN OrderStatus = 'Completed'
             AND Quantity > 0
            THEN 'Valid Quantity'

        ELSE 'Not Evaluated'
    END;



/* ============================================================
   QUERY 51 — CHEKING THE STATUS
   Used to standardize and validate status values.
   ============================================================ */

SELECT
    QuantityQualityStatus,
    COUNT(*) AS RowsCount
FROM dbo.Sales_Silver
GROUP BY QuantityQualityStatus
ORDER BY QuantityQualityStatus;



/* ============================================================
   QUERY 52 — *********************************************** RULE S09 - UNITPRICE QUALITY CLASSIFICATION .**************************************************
   Used to classify records according to data-quality conditions.
   ============================================================ */


/* ============================================================
   QUERY 53 — CAN EVERY NON-NULL UNITPRICE SAFELY BE CONVERTED INTO A NUMERIC MONETARY VALUE?
   Used to identify NULL values that require data-quality handling.
   ============================================================ */

SELECT
    COUNT(*) AS NonNumericUnitPrice
FROM dbo.Sales_Silver
WHERE UnitPrice IS NOT NULL
  AND TRY_CONVERT(DECIMAL(18,2), UnitPrice) IS NULL;


/* ============================================================
   QUERY 54 — WE'RE CHECKING NULL, 0, NEGATIVE, AND POSITIVE VALUES.
   Used to identify NULL values that require data-quality handling.
   ============================================================ */

SELECT
    CASE
        WHEN UnitPrice IS NULL THEN 'NULL'
        WHEN TRY_CONVERT(DECIMAL(18,2), UnitPrice) = 0 THEN 'Zero'
        WHEN TRY_CONVERT(DECIMAL(18,2), UnitPrice) < 0 THEN 'Negative'
        ELSE 'Positive'
    END AS UnitPriceProblem,
    COUNT(*) AS RowsCount
FROM dbo.Sales_Silver
GROUP BY
    CASE
        WHEN UnitPrice IS NULL THEN 'NULL'
        WHEN TRY_CONVERT(DECIMAL(18,2), UnitPrice) = 0 THEN 'Zero'
        WHEN TRY_CONVERT(DECIMAL(18,2), UnitPrice) < 0 THEN 'Negative'
        ELSE 'Positive'
    END
ORDER BY RowsCount DESC;


/* ============================================================
   QUERY 55 — INSPECT THE 100 ZERO-PRICE ROWS
   Used to validate and standardize product price values.
   ============================================================ */

SELECT
    OrderStatus,
    SalesChannel,
    COUNT(*) AS RowsCount
FROM dbo.Sales_Silver
WHERE TRY_CONVERT(DECIMAL(18,2), UnitPrice) = 0
GROUP BY
    OrderStatus,
    SalesChannel
ORDER BY
    OrderStatus,
    SalesChannel;



/* ============================================================
   QUERY 56 — MISSING UNITPRICE
   Used to identify incomplete values before transformation.
   ============================================================ */

SELECT
    OrderStatus,
    SalesChannel,
    COUNT(*) AS RowsCount
FROM dbo.Sales_Silver
WHERE UnitPrice IS NULL
GROUP BY
    OrderStatus,
    SalesChannel
ORDER BY
    OrderStatus,
    SalesChannel;


/* ============================================================
   QUERY 57 — INSPECT THE ACTUAL PRECISION/SCALE OF THE EXISTING NUMERIC VALUES SO WE CHOOSE AN APPROPRIATE DATATYPE RATHER THAN BLINDLY PICKING ONE.
   Used to perform the inspect the actual precision/scale of the existing numeric values so we choose an appropriate datatype rather than blindly picking one. step in the Silver transformation.
   ============================================================ */

SELECT
    MAX(TRY_CONVERT(DECIMAL(18,2), UnitPrice)) AS MaxUnitPrice,
    MIN(TRY_CONVERT(DECIMAL(18,2), UnitPrice)) AS MinUnitPrice
FROM dbo.Sales_Silver
WHERE UnitPrice IS NOT NULL;


-- unitprice datatype changing to decimal

ALTER TABLE dbo.Sales_Silver
ALTER COLUMN UnitPrice DECIMAL(18,2) NULL;

/* ============================================================
   QUERY 58 — VERIFY THE CHANGING STATUS
   Used to standardize and validate status values.
   ============================================================ */

SELECT
    COLUMN_NAME,
    DATA_TYPE,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dbo'
  AND TABLE_NAME = 'Sales_Silver'
  AND COLUMN_NAME = 'UnitPrice';



/* ============================================================
   QUERY 59 — *********************************************** RULE S10 - DISCOUNTPERCENT QUALITY CLASSIFICATION .**************************************************
   Used to classify records according to data-quality conditions.
   ============================================================ */

/* ============================================================
   QUERY 60 — DISCOUNTPERCENT DATATYPE CHECK.
   Used to perform the discountpercent datatype check. step in the Silver transformation.
   ============================================================ */

SELECT
    COUNT(*) AS NonNumericDiscount
FROM dbo.Sales_Silver
WHERE DiscountPercent IS NOT NULL
  AND TRY_CONVERT(DECIMAL(5,2), DiscountPercent) IS NULL;




SELECT
    DiscountPercent,
    COUNT(*) AS RowsCount
FROM dbo.Sales_Silver
GROUP BY DiscountPercent
ORDER BY
    TRY_CONVERT(DECIMAL(5,2), DiscountPercent);



--convert DiscountPercent data types


ALTER TABLE dbo.Sales_Silver
ALTER COLUMN DiscountPercent DECIMAL(5,2) NULL;


/* ============================================================
   QUERY 61 — CHEKING THE CHANGING DATABASE
   Used to perform the cheking the changing database step in the Silver transformation.
   ============================================================ */

SELECT
    COLUMN_NAME,
    DATA_TYPE,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dbo'
  AND TABLE_NAME = 'Sales_Silver'
  AND COLUMN_NAME = 'DiscountPercent';



/* ============================================================
   QUERY 62 — *********************************************** RULE S11 - TAXPERCENT QUALITY CLASSIFICATION .**************************************************
   Used to classify records according to data-quality conditions.
   ============================================================ */

/* ============================================================
   QUERY 63 — LET'S CHECK WHETHER EVERY NON-NULL TAXPERCENT CAN SAFELY BE CONVERTED TO A NUMERIC PERCENTAGE
   Used to identify NULL values that require data-quality handling.
   ============================================================ */

SELECT
    COUNT(*) AS NonNumericTax
FROM dbo.Sales_Silver
WHERE TaxPercent IS NOT NULL
  AND TRY_CONVERT(DECIMAL(5,2), TaxPercent) IS NULL;


/* ============================================================
   QUERY 64 — CHEKING NO DATATYPE CONVERSION PROBLEM
   Used to perform the cheking no datatype conversion problem step in the Silver transformation.
   ============================================================ */

SELECT
    TaxPercent,
    COUNT(*) AS RowsCount
FROM dbo.Sales_Silver
GROUP BY TaxPercent
ORDER BY
    TRY_CONVERT(DECIMAL(5,2), TaxPercent);




--convert TaxPercent to DECIMAL


ALTER TABLE dbo.Sales_Silver
ALTER COLUMN TaxPercent DECIMAL(5,2) NULL;




SELECT
    COLUMN_NAME,
    DATA_TYPE,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dbo'
  AND TABLE_NAME = 'Sales_Silver'
  AND COLUMN_NAME = 'TaxPercent';





SELECT
    PaymentMethod,
    COUNT(*) AS RowsCount
FROM dbo.Sales_Silver
GROUP BY PaymentMethod
ORDER BY RowsCount DESC;




SELECT
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dbo'
  AND TABLE_NAME = 'Sales_Silver'
  AND COLUMN_NAME = 'PaymentMethod';





SELECT
    SalesChannel,
    COUNT(*) AS RowsCount
FROM dbo.Sales_Silver
GROUP BY SalesChannel
ORDER BY RowsCount DESC;




SELECT
    OrderStatus,
    COUNT(*) AS RowsCount
FROM dbo.Sales_Silver
GROUP BY OrderStatus
ORDER BY RowsCount DESC;



SELECT
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dbo'
  AND TABLE_NAME = 'Sales_Silver'
  AND COLUMN_NAME = 'OrderStatus';




SELECT
    COUNT(*) AS MissingTransactionID
FROM dbo.Sales_Silver
WHERE TransactionID IS NULL
   OR LTRIM(RTRIM(TransactionID)) = '';


/* ============================================================
   QUERY 65 — CHEKING DUBLICATE TRANSACTION ID
   Used to perform the cheking dublicate transaction id step in the Silver transformation.
   ============================================================ */

SELECT
    COUNT(*) AS DuplicateTransactionGroups
FROM
(
    SELECT TransactionID
    FROM dbo.Sales_Silver
    GROUP BY TransactionID
    HAVING COUNT(*) > 1
) AS Duplicates;





SELECT
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dbo'
  AND TABLE_NAME = 'Sales_Silver'
  AND COLUMN_NAME = 'TransactionID';



SELECT
    COUNT(*) AS MissingOrderID
FROM dbo.Sales_Silver
WHERE OrderID IS NULL
   OR LTRIM(RTRIM(OrderID)) = '';



SELECT
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dbo'
  AND TABLE_NAME = 'Sales_Silver'
  AND COLUMN_NAME = 'OrderID';



SELECT
    CustomerQualityStatus,
    COUNT(*) AS RowsCount
FROM dbo.Sales_Silver
GROUP BY CustomerQualityStatus
ORDER BY CustomerQualityStatus;




SELECT
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dbo'
  AND TABLE_NAME = 'Sales_Silver'
  AND COLUMN_NAME = 'CustomerID';



SELECT
    ProductQualityStatus,
    COUNT(*) AS RowsCount
FROM dbo.Sales_Silver
GROUP BY ProductQualityStatus
ORDER BY ProductQualityStatus;




SELECT
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dbo'
  AND TABLE_NAME = 'Sales_Silver'
  AND COLUMN_NAME = 'ProductID';



SELECT
    StoreQualityStatus,
    COUNT(*) AS RowsCount
FROM dbo.Sales_Silver
GROUP BY StoreQualityStatus
ORDER BY StoreQualityStatus;



SELECT
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dbo'
  AND TABLE_NAME = 'Sales_Silver'
  AND COLUMN_NAME = 'StoreID';


SELECT
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dbo'
  AND TABLE_NAME = 'Sales_Silver'
  AND COLUMN_NAME = 'EmployeeID';




SELECT
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH,
    NUMERIC_PRECISION,
    NUMERIC_SCALE,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dbo'
  AND TABLE_NAME = 'Sales_Silver'
ORDER BY ORDINAL_POSITION;




/* ============================================================
   QUERY 66 — ACCORDING TO PROPOSED BUSINESS LOGIC WE SET THE REMAINING QUALITY
   Used to classify records according to data-quality conditions.
   ============================================================ */


UPDATE dbo.Sales_Silver
SET QuantityQualityStatus =
    CASE
        WHEN Quantity IS NULL OR Quantity <= 0
            THEN 'Invalid Quantity'
        WHEN Quantity > 0
            THEN 'Valid Quantity'
        ELSE 'Not Evaluated'
    END
WHERE OrderStatus IN ('Completed', 'Cancelled', 'Returned');



/* ============================================================
   QUERY 67 — VERIFY THE FINAL QUANTITY QUALITY STATUS
   Used to classify records according to data-quality conditions.
   ============================================================ */

SELECT
    QuantityQualityStatus,
    COUNT(*) 
FROM dbo.Sales_Silver
GROUP BY QuantityQualityStatus
ORDER BY QuantityQualityStatus;



--create the quality-status column

ALTER TABLE dbo.Sales_Silver
ADD UnitPriceQualityStatus VARCHAR(30);



/* ============================================================
   QUERY 68 — SET STAUS FOR  UNITPRICEQUALITYSTATUS .
   Used to classify records according to data-quality conditions.
   ============================================================ */


UPDATE dbo.Sales_Silver
SET UnitPriceQualityStatus =
    CASE
        WHEN UnitPrice IS NULL
            THEN 'Missing UnitPrice'
        WHEN UnitPrice = 0
            THEN 'Zero UnitPrice'
        WHEN UnitPrice < 0
            THEN 'Invalid UnitPrice'
        WHEN UnitPrice > 0
            THEN 'Valid UnitPrice'
        ELSE 'Not Evaluated'
    END;



/* ============================================================
   QUERY 69 — CHEKING THE UPDATED STATUS
   Used to standardize or validate date values for analysis.
   ============================================================ */

SELECT
    UnitPriceQualityStatus,
    COUNT(*)
FROM dbo.Sales_Silver
GROUP BY UnitPriceQualityStatus;



/* ============================================================
   QUERY 70 — STANDARDIZE ORDERSTATUS AS WE FOUND EARLIER CASE SENSITIVE CASE
   Used to make values consistent for downstream analysis.
   ============================================================ */

UPDATE dbo.Sales_Silver
SET OrderStatus =
    CASE
        WHEN LOWER(LTRIM(RTRIM(OrderStatus))) = 'completed'
            THEN 'Completed'
        WHEN LOWER(LTRIM(RTRIM(OrderStatus))) = 'cancelled'
            THEN 'Cancelled'
        WHEN LOWER(LTRIM(RTRIM(OrderStatus))) = 'returned'
            THEN 'Returned'
        ELSE OrderStatus
    END;

/* ============================================================
   QUERY 71 — CHEKING THE UPDATED STATUS
   Used to standardize or validate date values for analysis.
   ============================================================ */

    SELECT
        OrderStatus,
        COUNT(*)
    FROM dbo.Sales_Silver
    GROUP BY OrderStatus
    ORDER BY OrderStatus;

/* ============================================================
   QUERY 72 — BEFORE SAYING SIVER SALES IS COMPLETED WE HAVE TO CROSS VERY EVERYTHING
   Used to perform the before saying siver sales is completed we have to cross very everything step in the Silver transformation.
   ============================================================ */
/* ============================================================
   QUERY 73 — CHECK FOR DUPLICATE TRANSACTIONIDS IN SILVER
   Used to identify duplicate records before cleansing.
   ============================================================ */

SELECT
    TransactionID,
    COUNT(*) AS DuplicateCount
FROM dbo.Sales_Silver
GROUP BY TransactionID
HAVING COUNT(*) > 1;


/* ============================================================
   QUERY 74 — VERIFY THE SILVER ROWS
   Used to perform the verify the silver rows step in the Silver transformation.
   ============================================================ */

SELECT COUNT(*) AS TotalSilverRows
FROM dbo.Sales_Silver;

