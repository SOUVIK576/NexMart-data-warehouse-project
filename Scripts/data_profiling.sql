-- NexMart Enterprise Data Warehouse
-- Source Data Profiling and Data Quality Investigation
-- Each query is preceded by its purpose: why the query is used and what decision it supports.

USE NexMartDW;

/* ============================================================
   QUERY 1 — CHECK FOR DUPLICATE TRANSACTION IDS
   ============================================================ */

SELECT
    TransactionID,
    COUNT(*) AS DuplicateCount
FROM stg.Sales_Raw
GROUP BY TransactionID
HAVING COUNT(*) > 1
ORDER BY DuplicateCount DESC;


/* ============================================================
   QUERY 2 — CHECK QUANTITY VALUES
   ============================================================ */

SELECT
    COUNT(*) AS TotalRows,

    SUM(CASE WHEN TransactionID IS NULL THEN 1 ELSE 0 END) AS MissingTransactionID,
    SUM(CASE WHEN OrderID IS NULL THEN 1 ELSE 0 END) AS MissingOrderID,
    SUM(CASE WHEN OrderDate IS NULL THEN 1 ELSE 0 END) AS MissingOrderDate,
    SUM(CASE WHEN CustomerID IS NULL THEN 1 ELSE 0 END) AS MissingCustomerID,
    SUM(CASE WHEN ProductID IS NULL THEN 1 ELSE 0 END) AS MissingProductID,
    SUM(CASE WHEN StoreID IS NULL THEN 1 ELSE 0 END) AS MissingStoreID,
    SUM(CASE WHEN EmployeeID IS NULL THEN 1 ELSE 0 END) AS MissingEmployeeID,
    SUM(CASE WHEN Quantity IS NULL THEN 1 ELSE 0 END) AS MissingQuantity,
    SUM(CASE WHEN UnitPrice IS NULL THEN 1 ELSE 0 END) AS MissingUnitPrice
FROM stg.Sales_Raw;


/* ============================================================
   QUERY 3 — CHECK QUANTITY VALUES
   ============================================================ */

SELECT
    Quantity,
    COUNT(*) AS RecordCount
FROM stg.Sales_Raw
WHERE TRY_CONVERT(INT, Quantity) <= 0
GROUP BY Quantity
ORDER BY Quantity;


/* ============================================================
   QUERY 4 — CHECK UNIT PRICE VALUES
   ============================================================ */

SELECT
    COUNT(*) AS InvalidPriceRows
FROM stg.Sales_Raw
WHERE TRY_CONVERT(DECIMAL(18,2), UnitPrice) <= 0;


/* ============================================================
   QUERY 5 — CHECK CUSTOMER REFERENCES
   ============================================================ */

SELECT COUNT(*) AS InvalidCustomerReferences
FROM stg.Sales_Raw s
WHERE s.CustomerID IS NOT NULL
  AND NOT EXISTS
  (
      SELECT 1
      FROM stg.Customers_Raw c
      WHERE c.CustomerID = s.CustomerID
  );


/* ============================================================
   QUERY 6 — CHECK PRODUCT REFERENCES
   ============================================================ */

SELECT COUNT(*) AS InvalidProductReferences
FROM stg.Sales_Raw s
WHERE s.ProductID IS NOT NULL
  AND NOT EXISTS
  (
      SELECT 1
      FROM stg.Products_Raw p
      WHERE p.ProductID = s.ProductID
  );


/* ============================================================
   QUERY 7 — CHECK STORE REFERENCES
   ============================================================ */

SELECT COUNT(*) AS InvalidStoreReferences
FROM stg.Sales_Raw s
WHERE s.StoreID IS NOT NULL
  AND NOT EXISTS
  (
      SELECT 1
      FROM stg.Stores_Raw st
      WHERE st.StoreID = s.StoreID
  );


/* ============================================================
   QUERY 8 — CHECK EMPLOYEE REFERENCES
   ============================================================ */

SELECT COUNT(*) AS InvalidEmployeeReferences
FROM stg.Sales_Raw s
WHERE s.EmployeeID IS NOT NULL
  AND NOT EXISTS
  (
      SELECT 1
      FROM stg.Employees_Raw e
      WHERE e.EmployeeID = s.EmployeeID
  );


/* ============================================================
   QUERY 9 — CHECK ORDER DATE VALUES
   ============================================================ */

SELECT
    OrderDate,
    COUNT(*) AS RecordCount
FROM stg.Sales_Raw
WHERE OrderDate LIKE '%/%'
   OR OrderDate LIKE '% %'
GROUP BY OrderDate
ORDER BY RecordCount DESC;


/* ============================================================
   QUERY 10 — CHECK ORDER STATUS VALUES
   ============================================================ */

SELECT
    OrderStatus,
    COUNT(*) AS RecordCount
FROM stg.Sales_Raw
GROUP BY OrderStatus
ORDER BY RecordCount DESC;


/* ============================================================
   QUERY 11 — CHECK QUANTITY VALUES
   ============================================================ */

SELECT
    OrderStatus,
    Quantity,
    COUNT(*) AS RecordCount
FROM stg.Sales_Raw
WHERE TRY_CONVERT(INT, Quantity) <= 0
GROUP BY
    OrderStatus,
    Quantity
ORDER BY
    OrderStatus,
    Quantity;


/* ============================================================
   QUERY 12 — CHECK UNIT PRICE VALUES
   ============================================================ */

SELECT
    OrderStatus,
    COUNT(*) AS InvalidPriceRows
FROM stg.Sales_Raw
WHERE TRY_CONVERT(DECIMAL(18,2), UnitPrice) <= 0
GROUP BY OrderStatus;


/* ============================================================
   QUERY 13 — CHECK CUSTOMER REFERENCES
   ============================================================ */

SELECT
    TransactionID,
    CustomerID,
    CASE
        WHEN CustomerID IS NULL
            THEN 'Missing CustomerID'

        WHEN NOT EXISTS
        (
            SELECT 1
            FROM stg.Customers_Raw c
            WHERE c.CustomerID = stg.Sales_Raw.CustomerID
        )
            THEN 'Invalid CustomerID'

        ELSE 'Valid CustomerID'
    END AS CustomerQualityStatus
FROM stg.Sales_Raw;


/* ============================================================
   QUERY 14 — CHECK STORE REFERENCES
   ============================================================ */

SELECT 
    s.TransactionID,
    s.StoreID,
    CASE
        WHEN s.StoreID IS NULL
            THEN 'Missing StoreID'

        WHEN NOT EXISTS
        (
            SELECT 1
            FROM stg.Stores_Raw st
            WHERE st.StoreID = s.StoreID
        )
            THEN 'Invalid StoreID'

        ELSE 'Valid StoreID'
    END AS StoreQualityStatus
FROM stg.Sales_Raw s
WHERE s.StoreID IS NULL
   OR NOT EXISTS
   (
       SELECT 1
       FROM stg.Stores_Raw st
       WHERE st.StoreID = s.StoreID
   );


/* ============================================================
   QUERY 15 — CHECK SALES CHANNEL VALUES
   ============================================================ */

SELECT
    SalesChannel,
    COUNT(*) AS TotalRows,
    SUM(CASE WHEN EmployeeID IS NULL THEN 1 ELSE 0 END) AS MissingEmployeeID
FROM stg.Sales_Raw
GROUP BY SalesChannel
ORDER BY SalesChannel;


/* ============================================================
   QUERY 16 — CHECK EMPLOYEE REFERENCES
   ============================================================ */

SELECT
    s.SalesChannel,
    COUNT(*) AS InvalidEmployeeRows
FROM stg.Sales_Raw s
WHERE s.EmployeeID IS NOT NULL
  AND NOT EXISTS
  (
      SELECT 1
      FROM stg.Employees_Raw e
      WHERE e.EmployeeID = s.EmployeeID
  )
GROUP BY s.SalesChannel
ORDER BY InvalidEmployeeRows DESC;


/* ============================================================
   QUERY 17 — CHECK QUANTITY VALUES
   ============================================================ */

SELECT
    OrderStatus,
    Quantity,
    COUNT(*) AS RecordCount
FROM stg.Sales_Raw
WHERE TRY_CONVERT(INT, Quantity) < 0
GROUP BY OrderStatus, Quantity
ORDER BY OrderStatus, Quantity;


/* ============================================================
   QUERY 18 — CHECK QUANTITY VALUES
   ============================================================ */

SELECT
    OrderStatus,
    Quantity,
    COUNT(*) AS RecordCount
FROM stg.Sales_Raw
WHERE TRY_CONVERT(INT, Quantity) = 0
GROUP BY OrderStatus, Quantity
ORDER BY OrderStatus, Quantity;


/* ============================================================
   QUERY 19 — CHECK QUANTITY VALUES
   ============================================================ */

SELECT
    OrderStatus,
    COUNT(*) AS MissingQuantityRows
FROM stg.Sales_Raw
WHERE Quantity IS NULL
GROUP BY OrderStatus
ORDER BY MissingQuantityRows DESC;


/* ============================================================
   QUERY 20 — CHECK UNIT PRICE VALUES
   ============================================================ */

SELECT
    OrderStatus,
    DiscountPercent,
    UnitPrice,
    COUNT(*) AS RecordCount
FROM stg.Sales_Raw
WHERE TRY_CONVERT(DECIMAL(18,2), UnitPrice) <= 0
GROUP BY
    OrderStatus,
    DiscountPercent,
    UnitPrice
ORDER BY
    OrderStatus,
    DiscountPercent,
    UnitPrice;


/* ============================================================
   QUERY 21 — CHECK ORDER DATE VALUES
   ============================================================ */

SELECT
    COUNT(*) AS FutureOrderDates
FROM stg.Sales_Raw
WHERE OrderDate > CAST(GETDATE() AS DATE);


/* ============================================================
   QUERY 22 — CHECK ORDER DATE VALUES
   ============================================================ */

SELECT TOP 50
    OrderDate
FROM stg.Sales_Raw
ORDER BY OrderDate;


/* ============================================================
   QUERY 23 — CHECK ORDER DATE VALUES
   ============================================================ */

SELECT
    COUNT(*) AS InvalidOrderDateRows
FROM stg.Sales_Raw
WHERE OrderDate IS NOT NULL
  AND TRY_CONVERT(DATE, OrderDate) IS NULL;


/* ============================================================
   QUERY 24 — CHECK ORDER DATE VALUES
   ============================================================ */

SELECT TOP 100
    OrderDate
FROM stg.Sales_Raw
WHERE OrderDate IS NOT NULL
  AND TRY_CONVERT(DATE, OrderDate) IS NULL;


/* ============================================================
   QUERY 25 — CHECK ORDER DATE VALUES
   ============================================================ */

SELECT
    OrderDate,
    COUNT(*) AS RecordCount
FROM stg.Sales_Raw
WHERE OrderDate IS NOT NULL
  AND TRY_CONVERT(DATE, OrderDate) IS NULL
GROUP BY OrderDate
ORDER BY RecordCount DESC;


/* ============================================================
   QUERY 26 — CHECK ORDER DATE VALUES
   ============================================================ */

SELECT
    COUNT(*) AS InvalidOrderDateRows
FROM stg.Sales_Raw
WHERE OrderDate IS NOT NULL
  AND TRY_CONVERT(DATE, OrderDate, 103) IS NULL;


/* ============================================================
   QUERY 27 — CHECK ORDER DATE VALUES
   ============================================================ */

SELECT
    MIN(TRY_CONVERT(DATE, OrderDate, 103)) AS EarliestOrderDate,
    MAX(TRY_CONVERT(DATE, OrderDate, 103)) AS LatestOrderDate
FROM stg.Sales_Raw
WHERE OrderDate IS NOT NULL;


/* ============================================================
   QUERY 28 — CHECK ORDER DATE VALUES
   ============================================================ */

SELECT
    COUNT(*) AS TotalRows,

    SUM(
        CASE
            WHEN TRY_CONVERT(DATE, OrderDate, 101) IS NOT NULL
            THEN 1
            ELSE 0
        END
    ) AS Valid_MMDDYYYY,

    SUM(
        CASE
            WHEN TRY_CONVERT(DATE, OrderDate, 103) IS NOT NULL
            THEN 1
            ELSE 0
        END
    ) AS Valid_DDMMYYYY

FROM stg.Sales_Raw
WHERE OrderDate IS NOT NULL;


/* ============================================================
   QUERY 29 — CHECK ORDER DATE VALUES
   ============================================================ */

SELECT
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'stg'
  AND TABLE_NAME = 'Sales_Raw'
  AND COLUMN_NAME = 'OrderDate';


/* ============================================================
   QUERY 30 — CHECK ORDER DATE VALUES
   ============================================================ */

SELECT TOP 30
    OrderDate,
    COUNT(*) AS RecordCount
FROM stg.Sales_Raw
WHERE OrderDate IS NOT NULL
GROUP BY OrderDate
ORDER BY RecordCount DESC;


/* ============================================================
   QUERY 31 — CHECK ORDER DATE VALUES
   ============================================================ */

SELECT
    COUNT(*) AS InvalidOrderDateRows
FROM stg.Sales_Raw
WHERE OrderDate IS NOT NULL
  AND TRY_CONVERT(DATE, OrderDate, 23) IS NULL;


/* ============================================================
   QUERY 32 — CHECK ORDER DATE VALUES
   ============================================================ */

SELECT
    OrderDate,
    COUNT(*) AS RecordCount
FROM stg.Sales_Raw
WHERE OrderDate IS NOT NULL
  AND TRY_CONVERT(DATE, OrderDate, 23) IS NULL
GROUP BY OrderDate
ORDER BY RecordCount DESC;


/* ============================================================
   QUERY 33 — CHECK ORDER DATE VALUES
   ============================================================ */

SELECT
    COUNT(*) AS TotalRows,

    SUM(
        CASE
            WHEN COALESCE(
                TRY_CONVERT(DATE, OrderDate, 23),
                TRY_CONVERT(DATE, OrderDate, 103)
            ) IS NOT NULL
            THEN 1
            ELSE 0
        END
    ) AS SuccessfullyConverted,

    SUM(
        CASE
            WHEN COALESCE(
                TRY_CONVERT(DATE, OrderDate, 23),
                TRY_CONVERT(DATE, OrderDate, 103)
            ) IS NULL
            THEN 1
            ELSE 0
        END
    ) AS StillInvalid

FROM stg.Sales_Raw
WHERE OrderDate IS NOT NULL;


/* ============================================================
   QUERY 34 — CHECK ORDER DATE VALUES
   ============================================================ */

SELECT
    MIN(
        COALESCE(
            TRY_CONVERT(DATE, OrderDate, 23),
            TRY_CONVERT(DATE, OrderDate, 103)
        )
    ) AS TrueEarliestOrderDate,

    MAX(
        COALESCE(
            TRY_CONVERT(DATE, OrderDate, 23),
            TRY_CONVERT(DATE, OrderDate, 103)
        )
    ) AS TrueLatestOrderDate
FROM stg.Sales_Raw
WHERE OrderDate IS NOT NULL;


/* ============================================================
   QUERY 35 — CHECK ORDER DATE VALUES
   ============================================================ */

SELECT
    COUNT(*) AS FutureOrderDates
FROM stg.Sales_Raw
WHERE COALESCE(
          TRY_CONVERT(DATE, OrderDate, 23),
          TRY_CONVERT(DATE, OrderDate, 103)
      ) > CAST(GETDATE() AS DATE);


/* ============================================================
   QUERY 36 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT
    DiscountPercent,
    COUNT(*) AS RecordCount
FROM stg.Sales_Raw
GROUP BY DiscountPercent
ORDER BY DiscountPercent;


/* ============================================================
   QUERY 37 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT
    TaxPercent,
    COUNT(*) AS RecordCount
FROM stg.Sales_Raw
GROUP BY TaxPercent
ORDER BY TaxPercent;


/* ============================================================
   QUERY 38 — CHECK PAYMENT METHOD VALUES
   ============================================================ */

SELECT
    PaymentMethod,
    LEN(PaymentMethod) AS PaymentMethodLength,
    COUNT(*) AS RecordCount
FROM stg.Sales_Raw
GROUP BY
    PaymentMethod,
    LEN(PaymentMethod)
ORDER BY
    RecordCount DESC;


/* ============================================================
   QUERY 39 — CHECK PAYMENT METHOD VALUES
   ============================================================ */

SELECT
    COUNT(*) AS TotalRows,
    COUNT(PaymentMethod) AS NonNullPaymentMethods,
    COUNT(DISTINCT PaymentMethod) AS DistinctPaymentMethods,
    SUM(
        CASE
            WHEN LTRIM(RTRIM(PaymentMethod)) = ''
                THEN 1
            ELSE 0
        END
    ) AS BlankOrSpaces
FROM stg.Sales_Raw;


/* ============================================================
   QUERY 40 — CHECK SALES CHANNEL VALUES
   ============================================================ */

SELECT
    SalesChannel,
    COUNT(*) AS RecordCount
FROM stg.Sales_Raw
WHERE SalesChannel NOT IN ('Online', 'Physical Store')
GROUP BY SalesChannel;


/* ============================================================
   QUERY 41 — CHECK SALES CHANNEL VALUES
   ============================================================ */

SELECT
    SalesChannel COLLATE Latin1_General_100_BIN2 AS SalesChannel,
    COUNT(*) AS RecordCount
FROM stg.Sales_Raw
GROUP BY SalesChannel COLLATE Latin1_General_100_BIN2
ORDER BY RecordCount DESC;


/* ============================================================
   QUERY 42 — CHECK ORDER STATUS VALUES
   ============================================================ */

SELECT
    COUNT(*) AS TotalRows,
    COUNT(OrderStatus) AS NonNullOrderStatus,
    COUNT(DISTINCT OrderStatus) AS DistinctOrderStatuses
FROM stg.Sales_Raw;


/* ============================================================
   QUERY 43 — CHECK ORDER STATUS VALUES
   ============================================================ */

SELECT
    COUNT(*) AS TotalRows,

    SUM(CASE
        WHEN OrderStatus = 'Completed' THEN 1
        ELSE 0
    END) AS CompletedRows,

    SUM(CASE
        WHEN OrderStatus = 'Cancelled' THEN 1
        ELSE 0
    END) AS CancelledRows,

    SUM(CASE
        WHEN OrderStatus = 'Returned' THEN 1
        ELSE 0
    END) AS ReturnedRows,

    SUM(CASE
        WHEN OrderStatus IS NULL THEN 1
        ELSE 0
    END) AS MissingRows,

    SUM(CASE
        WHEN OrderStatus NOT IN
             ('Completed', 'Cancelled', 'Returned')
        THEN 1
        ELSE 0
    END) AS UnexpectedRows

FROM stg.Sales_Raw;


/* ============================================================
   QUERY 44 — CHECK QUANTITY VALUES
   ============================================================ */

SELECT
    COUNT(*) AS InvalidCompletedQuantityRows
FROM stg.Sales_Raw
WHERE OrderStatus = 'Completed'
  AND (
        Quantity IS NULL
        OR TRY_CONVERT(INT, Quantity) <= 0
      );


/* ============================================================
   QUERY 45 — CHECK QUANTITY VALUES
   ============================================================ */

SELECT
    SalesChannel,
    COUNT(*) AS InvalidCompletedQuantityRows
FROM stg.Sales_Raw
WHERE OrderStatus = 'Completed'
  AND (
        Quantity IS NULL
        OR TRY_CONVERT(INT, Quantity) <= 0
      )
GROUP BY SalesChannel
ORDER BY InvalidCompletedQuantityRows DESC;


/* ============================================================
   QUERY 46 — CHECK QUANTITY VALUES
   ============================================================ */

SELECT
    Quantity,
    COUNT(*) AS RecordCount
FROM stg.Sales_Raw
WHERE OrderStatus = 'Completed'
GROUP BY Quantity
HAVING Quantity IS NULL
    OR TRY_CONVERT(INT, Quantity) <= 0
ORDER BY Quantity;


/* ============================================================
   QUERY 47 — CHECK QUANTITY VALUES
   ============================================================ */

SELECT
    Quantity,
    COUNT(*) AS RecordCount
FROM stg.Sales_Raw
WHERE OrderStatus = 'Returned'
GROUP BY Quantity
ORDER BY Quantity;


/* ============================================================
   QUERY 48 — CHECK ORDER STATUS VALUES
   ============================================================ */

SELECT
    OrderStatus COLLATE Latin1_General_100_BIN2 AS OrderStatus,
    COUNT(*) AS RecordCount
FROM stg.Sales_Raw
GROUP BY OrderStatus COLLATE Latin1_General_100_BIN2
ORDER BY RecordCount DESC;


/* ============================================================
   QUERY 49 — CHECK ORDER STATUS VALUES
   ============================================================ */

SELECT
    OrderStatus,
    COUNT(*) AS RecordCount
FROM stg.Sales_Raw
WHERE OrderStatus <> LTRIM(RTRIM(OrderStatus))
GROUP BY OrderStatus
ORDER BY RecordCount DESC;


/* ============================================================
   QUERY 50 — CHECK QUANTITY VALUES
   ============================================================ */

SELECT
    COUNT(*) AS InvalidCancelledQuantityRows
FROM stg.Sales_Raw
WHERE OrderStatus = 'Cancelled'
  AND (
        Quantity IS NULL
        OR TRY_CONVERT(INT, Quantity) <= 0
      );


/* ============================================================
   QUERY 51 — CHECK QUANTITY VALUES
   ============================================================ */

SELECT
    CASE
        WHEN Quantity IS NULL
            THEN 'Missing Quantity'
        WHEN TRY_CONVERT(INT, Quantity) <= 0
            THEN 'Invalid Quantity'
    END AS QuantityQualityStatus,
    COUNT(*) AS RecordCount
FROM stg.Sales_Raw
WHERE OrderStatus = 'Cancelled'
  AND (
        Quantity IS NULL
        OR TRY_CONVERT(INT, Quantity) <= 0
      )
GROUP BY
    CASE
        WHEN Quantity IS NULL
            THEN 'Missing Quantity'
        WHEN TRY_CONVERT(INT, Quantity) <= 0
            THEN 'Invalid Quantity'
    END
ORDER BY RecordCount DESC;


/* ============================================================
   QUERY 52 — CHECK UNIT PRICE VALUES
   ============================================================ */

SELECT
    DiscountPercent,
    COUNT(*) AS RecordCount
FROM stg.Sales_Raw
WHERE TRY_CONVERT(DECIMAL(18,2), UnitPrice) = 0
GROUP BY DiscountPercent
ORDER BY DiscountPercent;


/* ============================================================
   QUERY 53 — CHECK QUANTITY VALUES
   ============================================================ */

SELECT 
    OrderStatus,
    Quantity,
    UnitPrice,
    DiscountPercent
FROM stg.Sales_Raw
ORDER BY
    UnitPrice,
    DiscountPercent;


/* ============================================================
   QUERY 54 — CHECK UNIT PRICE VALUES
   ============================================================ */

SELECT
    OrderStatus,
    UnitPrice,
    COUNT(*) AS RecordCount
FROM stg.Sales_Raw
WHERE TRY_CONVERT(DECIMAL(18,2), UnitPrice) < 0
GROUP BY
    OrderStatus,
    UnitPrice
ORDER BY
    OrderStatus,
    UnitPrice;


/* ============================================================
   QUERY 55 — CHECK UNIT PRICE VALUES
   ============================================================ */

SELECT
    OrderStatus,
    COUNT(*) AS MissingUnitPriceRows
FROM stg.Sales_Raw
WHERE UnitPrice IS NULL
GROUP BY OrderStatus
ORDER BY MissingUnitPriceRows DESC;


/* ============================================================
   QUERY 56 — CHECK UNIT PRICE VALUES
   ============================================================ */

SELECT
    OrderStatus,
    COUNT(*) AS ZeroUnitPriceRows
FROM stg.Sales_Raw
WHERE TRY_CONVERT(DECIMAL(18,2), UnitPrice) = 0
GROUP BY OrderStatus
ORDER BY ZeroUnitPriceRows DESC;


/* ============================================================
   QUERY 57 — CHECK QUANTITY VALUES
   ============================================================ */

SELECT
    DiscountPercent,
    Quantity,
    COUNT(*) AS RecordCount
FROM stg.Sales_Raw
WHERE OrderStatus = 'Completed'
  AND TRY_CONVERT(DECIMAL(18,2), UnitPrice) = 0
GROUP BY
    DiscountPercent,
    Quantity
ORDER BY
    DiscountPercent,
    Quantity;


/* ============================================================
   QUERY 58 — CHECK QUANTITY VALUES
   ============================================================ */

SELECT
    Quantity,
    DiscountPercent,
    COUNT(*) AS RecordCount
FROM stg.Sales_Raw
WHERE OrderStatus = 'Completed'
  AND UnitPrice IS NULL
GROUP BY
    Quantity,
    DiscountPercent
ORDER BY
    DiscountPercent,
    Quantity;


/* ============================================================
   QUERY 59 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT
    DiscountPercent,
    COUNT(*) AS RecordCount
FROM stg.Sales_Raw
GROUP BY DiscountPercent
ORDER BY DiscountPercent;


/* ============================================================
   QUERY 60 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT
    COUNT(*) AS InvalidDiscountRows
FROM stg.Sales_Raw
WHERE DiscountPercent IS NULL
   OR TRY_CONVERT(DECIMAL(5,2), DiscountPercent)
      NOT IN (0, 5, 10, 15, 20, 25);


/* ============================================================
   QUERY 61 — CHECK QUANTITY VALUES
   ============================================================ */

SELECT
    Quantity,
    COUNT(*) AS RecordCount
FROM stg.Sales_Raw
WHERE OrderStatus = 'Completed'
  AND TRY_CONVERT(DECIMAL(18,2), UnitPrice) = 0
GROUP BY Quantity
ORDER BY Quantity;


/* ============================================================
   QUERY 62 — CHECK PAYMENT METHOD VALUES
   ============================================================ */

SELECT
    COUNT(*) AS MissingPaymentMethod
FROM stg.Sales_Raw
WHERE PaymentMethod IS NULL;


/* ============================================================
   QUERY 63 — CHECK PAYMENT METHOD VALUES
   ============================================================ */

SELECT
    PaymentMethod,
    COUNT(*) AS RecordCount
FROM stg.Sales_Raw
WHERE PaymentMethod NOT IN
      (
          'UPI',
          'Credit Card',
          'Debit Card',
          'EMI',
          'Net Banking',
          'Cash'
      )
GROUP BY PaymentMethod
ORDER BY RecordCount DESC;


/* ============================================================
   QUERY 64 — CHECK PAYMENT METHOD VALUES
   ============================================================ */

SELECT
    PaymentMethod,
    COUNT(*) AS RecordCount
FROM stg.Sales_Raw
WHERE PaymentMethod <> LTRIM(RTRIM(PaymentMethod))
GROUP BY PaymentMethod
ORDER BY RecordCount DESC;


/* ============================================================
   QUERY 65 — CHECK FOR DUPLICATE TRANSACTION IDS
   ============================================================ */

SELECT
    TransactionID,
    COUNT(*) AS RecordCount
FROM stg.Sales_Raw
GROUP BY TransactionID
HAVING COUNT(*) > 1
ORDER BY RecordCount DESC;


/* ============================================================
   QUERY 66 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT COUNT(*) AS MissingTransactionID
FROM stg.Sales_Raw
WHERE TransactionID IS NULL;


/* ============================================================
   QUERY 67 — CHECK FOR DUPLICATE TRANSACTION IDS
   ============================================================ */

SELECT
    TransactionID,
    COUNT(*) AS RecordCount
FROM stg.Sales_Raw
GROUP BY TransactionID
HAVING COUNT(*) > 1
ORDER BY RecordCount DESC;


/* ============================================================
   QUERY 68 — CHECK FOR DUPLICATE TRANSACTION IDS
   ============================================================ */

SELECT
    COUNT(*) AS DuplicateTransactionIDs,
    SUM(RecordCount) AS RowsWithDuplicateTransactionID
FROM (
    SELECT
        TransactionID,
        COUNT(*) AS RecordCount
    FROM stg.Sales_Raw
    GROUP BY TransactionID
    HAVING COUNT(*) > 1
) d;


/* ============================================================
   QUERY 69 — CHECK FOR DUPLICATE TRANSACTION IDS
   ============================================================ */

SELECT
    TransactionID,
    CustomerID,
    ProductID,
    StoreID,
    EmployeeID,
    OrderDate,
    Quantity,
    UnitPrice,
    DiscountPercent,
    SalesChannel,
    PaymentMethod,
    OrderStatus
FROM stg.Sales_Raw
WHERE TransactionID IN (
    SELECT TransactionID
    FROM stg.Sales_Raw
    GROUP BY TransactionID
    HAVING COUNT(*) > 1
)
ORDER BY TransactionID;


/* ============================================================
   QUERY 70 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT
    CustomerID,
    COUNT(*) AS RecordCount
FROM stg.Sales_Raw
WHERE CustomerID IS NOT NULL
  AND CustomerID NOT LIKE 'CUST%'
GROUP BY CustomerID
ORDER BY RecordCount DESC;


/* ============================================================
   QUERY 71 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT
    ProductID,
    COUNT(*) AS RecordCount
FROM stg.Sales_Raw
WHERE ProductID IS NOT NULL
  AND ProductID NOT LIKE 'PROD%'
GROUP BY ProductID
ORDER BY RecordCount DESC;


/* ============================================================
   QUERY 72 — CHECK QUANTITY VALUES
   ============================================================ */

SELECT
    COUNT(*) AS ExactDuplicateGroups,
    SUM(RecordCount) AS RowsInExactDuplicates
FROM (
    SELECT
        TransactionID,
        CustomerID,
        ProductID,
        StoreID,
        EmployeeID,
        OrderDate,
        Quantity,
        UnitPrice,
        DiscountPercent,
        SalesChannel,
        PaymentMethod,
        OrderStatus,
        COUNT(*) AS RecordCount
    FROM stg.Sales_Raw
    GROUP BY
        TransactionID,
        CustomerID,
        ProductID,
        StoreID,
        EmployeeID,
        OrderDate,
        Quantity,
        UnitPrice,
        DiscountPercent,
        SalesChannel,
        PaymentMethod,
        OrderStatus
    HAVING COUNT(*) > 1
) d;


/* ============================================================
   QUERY 73 — CHECK FOR DUPLICATE TRANSACTION IDS
   ============================================================ */

SELECT
    RecordCount,
    COUNT(*) AS TransactionIDCount
FROM (
    SELECT
        TransactionID,
        COUNT(*) AS RecordCount
    FROM stg.Sales_Raw
    GROUP BY TransactionID
    HAVING COUNT(*) > 1
) d
GROUP BY RecordCount
ORDER BY RecordCount;


/* ============================================================
   QUERY 74 — CHECK QUANTITY VALUES
   ============================================================ */

SELECT
    UPPER(OrderStatus) AS OrderStatus,
    Quantity,
    COUNT(*) AS RecordCount
FROM stg.Sales_Raw
WHERE UPPER(OrderStatus) = 'CANCELLED'
  AND (
        Quantity IS NULL
        OR TRY_CONVERT(INT, Quantity) <= 0
      )
GROUP BY
    UPPER(OrderStatus),
    Quantity
ORDER BY Quantity;


/* ============================================================
   QUERY 75 — CHECK QUANTITY VALUES
   ============================================================ */

SELECT
    UPPER(OrderStatus) AS OrderStatus,
    Quantity,
    COUNT(*) AS RecordCount
FROM stg.Sales_Raw
WHERE UPPER(OrderStatus) = 'RETURNED'
  AND (
        Quantity IS NULL
        OR TRY_CONVERT(INT, Quantity) <= 0
      )
GROUP BY
    UPPER(OrderStatus),
    Quantity
ORDER BY Quantity;


/* ============================================================
   QUERY 76 — CHECK UNIT PRICE VALUES
   ============================================================ */

SELECT
    UnitPrice,
    COUNT(*) AS RecordCount
FROM stg.Sales_Raw
WHERE UnitPrice IS NOT NULL
  AND TRY_CONVERT(DECIMAL(18,2), UnitPrice) IS NULL
GROUP BY UnitPrice
ORDER BY RecordCount DESC;


/* ============================================================
   QUERY 77 — CHECK UNIT PRICE VALUES
   ============================================================ */

SELECT
    UPPER(OrderStatus) AS OrderStatus,
    COUNT(*) AS RecordCount
FROM stg.Sales_Raw
WHERE TRY_CONVERT(DECIMAL(18,2), UnitPrice) = 0
GROUP BY UPPER(OrderStatus)
ORDER BY RecordCount DESC;


/* ============================================================
   QUERY 78 — CHECK QUANTITY VALUES
   ============================================================ */

SELECT
    UPPER(OrderStatus) AS OrderStatus,
    Quantity,
    COUNT(*) AS RecordCount
FROM stg.Sales_Raw
WHERE TRY_CONVERT(DECIMAL(18,2), UnitPrice) = 0
GROUP BY
    UPPER(OrderStatus),
    Quantity
ORDER BY
    OrderStatus,
    Quantity;


/* ============================================================
   QUERY 79 — CHECK UNIT PRICE VALUES
   ============================================================ */

SELECT
    UPPER(OrderStatus) AS OrderStatus,
    DiscountPercent,
    COUNT(*) AS RecordCount
FROM stg.Sales_Raw
WHERE TRY_CONVERT(DECIMAL(18,2), UnitPrice) = 0
GROUP BY
    UPPER(OrderStatus),
    DiscountPercent
ORDER BY
    OrderStatus,
    DiscountPercent;


/* ============================================================
   QUERY 80 — CHECK STORE REFERENCES
   ============================================================ */

SELECT
    UPPER(SalesChannel) AS SalesChannel,
    COUNT(*) AS InvalidStoreReferenceRows
FROM stg.Sales_Raw s
WHERE UPPER(SalesChannel) = 'PHYSICAL STORE'
  AND (
        StoreID IS NULL
        OR NOT EXISTS (
            SELECT 1
            FROM stg.Stores_Raw st
            WHERE st.StoreID = s.StoreID
        )
      )
GROUP BY UPPER(SalesChannel);


/* ============================================================
   QUERY 81 — CHECK SALES CHANNEL VALUES
   ============================================================ */

SELECT COUNT(*) AS MissingStoreID
FROM stg.Sales_Raw
WHERE UPPER(SalesChannel) = 'PHYSICAL STORE'
  AND StoreID IS NULL;


/* ============================================================
   QUERY 82 — CHECK STORE REFERENCES
   ============================================================ */

SELECT
    s.StoreID,
    COUNT(*) AS RecordCount
FROM stg.Sales_Raw s
WHERE UPPER(s.SalesChannel) = 'PHYSICAL STORE'
  AND s.StoreID IS NOT NULL
  AND NOT EXISTS (
      SELECT 1
      FROM stg.Stores_Raw st
      WHERE st.StoreID = s.StoreID
  )
GROUP BY s.StoreID
ORDER BY RecordCount DESC;


/* ============================================================
   QUERY 83 — CHECK SALES CHANNEL VALUES
   ============================================================ */

SELECT
    CASE
        WHEN StoreID IS NULL THEN 'NULL StoreID'
        ELSE 'StoreID Present'
    END AS StoreStatus,
    COUNT(*) AS RecordCount
FROM stg.Sales_Raw
WHERE UPPER(SalesChannel) = 'ONLINE'
GROUP BY
    CASE
        WHEN StoreID IS NULL THEN 'NULL StoreID'
        ELSE 'StoreID Present'
    END;


/* ============================================================
   QUERY 84 — CHECK STORE REFERENCES
   ============================================================ */

SELECT COUNT(*) AS InvalidOrMissingStoreID
FROM stg.Sales_Raw s
WHERE s.StoreID IS NULL
   OR NOT EXISTS (
       SELECT 1
       FROM stg.Stores_Raw st
       WHERE st.StoreID = s.StoreID
   );


/* ============================================================
   QUERY 85 — CHECK ORDER DATE VALUES
   ============================================================ */

SELECT COUNT(*) AS UnparseableOrderDates
FROM stg.Sales_Raw
WHERE OrderDate IS NOT NULL
  AND COALESCE(
        TRY_CONVERT(date, OrderDate, 23),
        TRY_CONVERT(date, OrderDate, 103)
      ) IS NULL;


/* ============================================================
   QUERY 86 — CHECK ORDER DATE VALUES
   ============================================================ */

SELECT COUNT(*) AS MissingOrderDate
FROM stg.Sales_Raw
WHERE OrderDate IS NULL;


/* ============================================================
   QUERY 87 — CHECK UNIT PRICE VALUES
   ============================================================ */

SELECT
    UPPER(OrderStatus) AS OrderStatus,
    COUNT(*) AS MissingUnitPrice
FROM stg.Sales_Raw
WHERE UnitPrice IS NULL
GROUP BY UPPER(OrderStatus)
ORDER BY MissingUnitPrice DESC;


/* ============================================================
   QUERY 88 — CHECK QUANTITY VALUES
   ============================================================ */

SELECT
    CASE
        WHEN Quantity IS NULL
             OR TRY_CONVERT(INT, Quantity) <= 0
            THEN 'Invalid Quantity'
        ELSE 'Valid Quantity'
    END AS QuantityStatus,
    CASE
        WHEN DiscountPercent IS NULL
             OR TRY_CONVERT(DECIMAL(5,2), DiscountPercent)
                NOT IN (0,5,10,15,20,25)
            THEN 'Invalid Discount'
        ELSE 'Valid Discount'
    END AS DiscountStatus,
    COUNT(*) AS RecordCount
FROM stg.Sales_Raw
WHERE UPPER(OrderStatus) = 'COMPLETED'
  AND UnitPrice IS NULL
GROUP BY
    CASE
        WHEN Quantity IS NULL
             OR TRY_CONVERT(INT, Quantity) <= 0
            THEN 'Invalid Quantity'
        ELSE 'Valid Quantity'
    END,
    CASE
        WHEN DiscountPercent IS NULL
             OR TRY_CONVERT(DECIMAL(5,2), DiscountPercent)
                NOT IN (0,5,10,15,20,25)
            THEN 'Invalid Discount'
        ELSE 'Valid Discount'
    END
ORDER BY RecordCount DESC;


/* ============================================================
   QUERY 89 — CHECK QUANTITY VALUES
   ============================================================ */

SELECT
    TransactionID,
    CustomerID,
    ProductID,
    StoreID,
    EmployeeID,
    OrderDate,
    Quantity,
    UnitPrice,
    DiscountPercent,
    SalesChannel,
    PaymentMethod,
    OrderStatus
FROM stg.Sales_Raw
WHERE UPPER(OrderStatus) = 'COMPLETED'
  AND UnitPrice IS NULL
  AND (
        Quantity IS NULL
        OR TRY_CONVERT(INT, Quantity) <= 0
      );


/* ============================================================
   QUERY 90 — CHECK QUANTITY VALUES
   ============================================================ */

SELECT
    CASE
        WHEN Quantity IS NULL
             OR TRY_CONVERT(INT, Quantity) <= 0
            THEN 'Invalid Quantity'
        ELSE 'Valid Quantity'
    END AS QuantityStatus,
    COUNT(*) AS RecordCount
FROM stg.Sales_Raw
WHERE UPPER(OrderStatus) = 'CANCELLED'
  AND UnitPrice IS NULL
GROUP BY
    CASE
        WHEN Quantity IS NULL
             OR TRY_CONVERT(INT, Quantity) <= 0
            THEN 'Invalid Quantity'
        ELSE 'Valid Quantity'
    END;


/* ============================================================
   QUERY 91 — CHECK QUANTITY VALUES
   ============================================================ */

SELECT
    CASE
        WHEN Quantity IS NULL
             OR TRY_CONVERT(INT, Quantity) <= 0
            THEN 'Invalid Quantity'
        ELSE 'Valid Quantity'
    END AS QuantityStatus,
    COUNT(*) AS RecordCount
FROM stg.Sales_Raw
WHERE UPPER(OrderStatus) = 'RETURNED'
  AND UnitPrice IS NULL
GROUP BY
    CASE
        WHEN Quantity IS NULL
             OR TRY_CONVERT(INT, Quantity) <= 0
            THEN 'Invalid Quantity'
        ELSE 'Valid Quantity'
    END;


/* ============================================================
   QUERY 92 — CHECK UNIT PRICE VALUES
   ============================================================ */

SELECT
    CASE
        WHEN DiscountPercent IS NULL
             OR TRY_CONVERT(DECIMAL(5,2), DiscountPercent)
                NOT IN (0,5,10,15,20,25)
            THEN 'Invalid Discount'
        ELSE 'Valid Discount'
    END AS DiscountStatus,
    COUNT(*) AS RecordCount
FROM stg.Sales_Raw
WHERE UnitPrice IS NULL
GROUP BY
    CASE
        WHEN DiscountPercent IS NULL
             OR TRY_CONVERT(DECIMAL(5,2), DiscountPercent)
                NOT IN (0,5,10,15,20,25)
            THEN 'Invalid Discount'
        ELSE 'Valid Discount'
    END;


/* ============================================================
   QUERY 93 — CHECK PAYMENT METHOD VALUES
   ============================================================ */

SELECT
    UPPER(SalesChannel) AS SalesChannel,
    PaymentMethod,
    COUNT(*) AS RecordCount
FROM stg.Sales_Raw
GROUP BY
    UPPER(SalesChannel),
    PaymentMethod
ORDER BY
    SalesChannel,
    RecordCount DESC;


/* ============================================================
   QUERY 94 — CHECK ORDER STATUS VALUES
   ============================================================ */

SELECT
    UPPER(SalesChannel) AS SalesChannel,
    UPPER(OrderStatus) AS OrderStatus,
    COUNT(*) AS RecordCount
FROM stg.Sales_Raw
GROUP BY
    UPPER(SalesChannel),
    UPPER(OrderStatus)
ORDER BY
    SalesChannel,
    OrderStatus;


/* ============================================================
   QUERY 95 — CHECK ORDER STATUS VALUES
   ============================================================ */

SELECT
    UPPER(OrderStatus) AS OrderStatus,
    DiscountPercent,
    COUNT(*) AS RecordCount
FROM stg.Sales_Raw
GROUP BY
    UPPER(OrderStatus),
    DiscountPercent
ORDER BY
    OrderStatus,
    DiscountPercent;


/* ============================================================
   QUERY 96 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT
    DiscountPercent,
    COUNT(*) AS RecordCount
FROM stg.Sales_Raw
WHERE DiscountPercent IS NOT NULL
  AND TRY_CONVERT(DECIMAL(5,2), DiscountPercent) IS NULL
GROUP BY DiscountPercent
ORDER BY RecordCount DESC;


/* ============================================================
   QUERY 97 — CHECK QUANTITY VALUES
   ============================================================ */

SELECT
    Quantity,
    COUNT(*) AS RecordCount
FROM stg.Sales_Raw
WHERE Quantity IS NOT NULL
  AND TRY_CONVERT(INT, Quantity) IS NULL
GROUP BY Quantity
ORDER BY RecordCount DESC;


/* ============================================================
   QUERY 98 — CHECK UNIT PRICE VALUES
   ============================================================ */

SELECT
    UnitPrice,
    COUNT(*) AS RecordCount
FROM stg.Sales_Raw
WHERE UnitPrice IS NOT NULL
  AND TRY_CONVERT(DECIMAL(18,4), UnitPrice) IS NOT NULL
  AND TRY_CONVERT(DECIMAL(18,4), UnitPrice)
      <> TRY_CONVERT(DECIMAL(18,2), UnitPrice)
GROUP BY UnitPrice
ORDER BY RecordCount DESC;


/* ============================================================
   QUERY 99 — CHECK QUANTITY VALUES
   ============================================================ */

SELECT
    Quantity,
    COUNT(*) AS RecordCount
FROM stg.Sales_Raw
WHERE Quantity IS NOT NULL
  AND TRY_CONVERT(DECIMAL(18,4), Quantity) IS NOT NULL
  AND TRY_CONVERT(DECIMAL(18,4), Quantity)
      <> TRY_CONVERT(INT, Quantity)
GROUP BY Quantity
ORDER BY RecordCount DESC;


/* ============================================================
   QUERY 100 — CHECK ORDER STATUS VALUES
   ============================================================ */

SELECT COUNT(*) AS BlankOrderStatus
FROM stg.Sales_Raw
WHERE OrderStatus IS NOT NULL
  AND LTRIM(RTRIM(OrderStatus)) = '';


/* ============================================================
   QUERY 101 — CHECK SALES CHANNEL VALUES
   ============================================================ */

SELECT COUNT(*) AS BlankSalesChannel
FROM stg.Sales_Raw
WHERE SalesChannel IS NOT NULL
  AND LTRIM(RTRIM(SalesChannel)) = '';


/* ============================================================
   QUERY 102 — CHECK PAYMENT METHOD VALUES
   ============================================================ */

SELECT COUNT(*) AS BlankPaymentMethod
FROM stg.Sales_Raw
WHERE PaymentMethod IS NOT NULL
  AND LTRIM(RTRIM(PaymentMethod)) = '';


/* ============================================================
   QUERY 103 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT COUNT(*) AS BlankCustomerID
FROM stg.Sales_Raw
WHERE CustomerID IS NOT NULL
  AND LTRIM(RTRIM(CustomerID)) = '';


/* ============================================================
   QUERY 104 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT COUNT(*) AS BlankProductID
FROM stg.Sales_Raw
WHERE ProductID IS NOT NULL
  AND LTRIM(RTRIM(ProductID)) = '';


/* ============================================================
   QUERY 105 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT COUNT(*) AS BlankStoreID
FROM stg.Sales_Raw
WHERE StoreID IS NOT NULL
  AND LTRIM(RTRIM(StoreID)) = '';


/* ============================================================
   QUERY 106 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT COUNT(*) AS BlankEmployeeID
FROM stg.Sales_Raw
WHERE EmployeeID IS NOT NULL
  AND LTRIM(RTRIM(EmployeeID)) = '';


/* ============================================================
   QUERY 107 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT COUNT(*) AS BlankTransactionID
FROM stg.Sales_Raw
WHERE TransactionID IS NOT NULL
  AND LTRIM(RTRIM(TransactionID)) = '';


/* ============================================================
   QUERY 108 — CHECK FOR DUPLICATE TRANSACTION IDS
   ============================================================ */

SELECT
    TransactionID,
    COUNT(*) AS RecordCount
FROM stg.Sales_Raw
WHERE TransactionID <> LTRIM(RTRIM(TransactionID))
GROUP BY TransactionID
ORDER BY RecordCount DESC;


/* ============================================================
   QUERY 109 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT
    CustomerID,
    COUNT(*) AS RecordCount
FROM stg.Sales_Raw
WHERE CustomerID <> LTRIM(RTRIM(CustomerID))
GROUP BY CustomerID
ORDER BY RecordCount DESC;


/* ============================================================
   QUERY 110 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT
    ProductID,
    COUNT(*) AS RecordCount
FROM stg.Sales_Raw
WHERE ProductID <> LTRIM(RTRIM(ProductID))
GROUP BY ProductID
ORDER BY RecordCount DESC;


/* ============================================================
   QUERY 111 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT
    StoreID,
    COUNT(*) AS RecordCount
FROM stg.Sales_Raw
WHERE StoreID <> LTRIM(RTRIM(StoreID))
GROUP BY StoreID
ORDER BY RecordCount DESC;


/* ============================================================
   QUERY 112 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT
    EmployeeID,
    COUNT(*) AS RecordCount
FROM stg.Sales_Raw
WHERE EmployeeID <> LTRIM(RTRIM(EmployeeID))
GROUP BY EmployeeID
ORDER BY RecordCount DESC;


/* ============================================================
   QUERY 113 — CHECK CUSTOMER REFERENCES
   ============================================================ */

SELECT
    CustomerID,
    COUNT(*) AS RecordCount
FROM stg.Customers_Raw
WHERE CustomerID IS NOT NULL
GROUP BY CustomerID
HAVING COUNT(*) > 1
ORDER BY RecordCount DESC;


/* ============================================================
   QUERY 114 — CHECK CUSTOMER REFERENCES
   ============================================================ */

SELECT *
FROM stg.Customers_Raw
WHERE CustomerID = 'CUST14073';


/* ============================================================
   QUERY 115 — CHECK CUSTOMER REFERENCES
   ============================================================ */

SELECT
    CustomerID,
    COUNT(DISTINCT CustomerName) AS NameVariants,
    COUNT(DISTINCT Gender) AS GenderVariants,
    COUNT(DISTINCT DateOfBirth) AS DOBVariants,
    COUNT(DISTINCT Phone) AS PhoneVariants,
    COUNT(DISTINCT City) AS CityVariants,
    COUNT(DISTINCT State) AS StateVariants,
    COUNT(DISTINCT Region) AS RegionVariants,
    COUNT(DISTINCT SignupDate) AS SignupDateVariants,
    COUNT(DISTINCT CustomerSegment) AS SegmentVariants
FROM stg.Customers_Raw
WHERE CustomerID IS NOT NULL
GROUP BY CustomerID
HAVING COUNT(*) > 1
ORDER BY CustomerID;


/* ============================================================
   QUERY 116 — CHECK CUSTOMER REFERENCES
   ============================================================ */

SELECT
    CustomerID,
    COUNT(DISTINCT LOWER(LTRIM(RTRIM(Email)))) AS EmailVariants
FROM stg.Customers_Raw
WHERE CustomerID IS NOT NULL
GROUP BY CustomerID
HAVING COUNT(*) > 1
ORDER BY CustomerID;


/* ============================================================
   QUERY 117 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT
    COLUMN_NAME,
    DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'stg'
  AND TABLE_NAME = 'Customers_Raw'
ORDER BY ORDINAL_POSITION;


/* ============================================================
   QUERY 118 — CHECK CUSTOMER REFERENCES
   ============================================================ */

SELECT
    CustomerID,
    COUNT(*) AS DuplicateRows,
    COUNT(DISTINCT COALESCE(CustomerName, '<NULL>')) AS NameVariants,
    COUNT(DISTINCT COALESCE(Gender, '<NULL>')) AS GenderVariants,
    COUNT(DISTINCT COALESCE(DateOfBirth, '<NULL>')) AS DOBVariants,
    COUNT(DISTINCT COALESCE(LOWER(LTRIM(RTRIM(Email))), '<NULL>')) AS EmailVariants,
    COUNT(DISTINCT COALESCE(Phone, '<NULL>')) AS PhoneVariants,
    COUNT(DISTINCT COALESCE(City, '<NULL>')) AS CityVariants,
    COUNT(DISTINCT COALESCE(State, '<NULL>')) AS StateVariants,
    COUNT(DISTINCT COALESCE(Region, '<NULL>')) AS RegionVariants,
    COUNT(DISTINCT COALESCE(SignupDate, '<NULL>')) AS SignupDateVariants,
    COUNT(DISTINCT COALESCE(CustomerSegment, '<NULL>')) AS SegmentVariants
FROM stg.Customers_Raw
WHERE CustomerID IS NOT NULL
GROUP BY CustomerID
HAVING COUNT(*) > 1
ORDER BY CustomerID;


/* ============================================================
   QUERY 119 — CHECK PRODUCT REFERENCES
   ============================================================ */

SELECT
    ProductID,
    COUNT(*) AS DuplicateRows
FROM stg.Products_Raw
WHERE ProductID IS NOT NULL
GROUP BY ProductID
HAVING COUNT(*) > 1
ORDER BY DuplicateRows DESC;


/* ============================================================
   QUERY 120 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT
    COLUMN_NAME,
    DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'stg'
  AND TABLE_NAME = 'Products_Raw'
ORDER BY ORDINAL_POSITION;


/* ============================================================
   QUERY 121 — CHECK STORE REFERENCES
   ============================================================ */

SELECT
    StoreID,
    COUNT(*) AS DuplicateRows
FROM stg.Stores_Raw
WHERE StoreID IS NOT NULL
GROUP BY StoreID
HAVING COUNT(*) > 1
ORDER BY DuplicateRows DESC;


/* ============================================================
   QUERY 122 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT
    COLUMN_NAME,
    DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'stg'
  AND TABLE_NAME = 'Stores_Raw'
ORDER BY ORDINAL_POSITION;


/* ============================================================
   QUERY 123 — CHECK EMPLOYEE REFERENCES
   ============================================================ */

SELECT
    EmployeeID,
    COUNT(*) AS DuplicateRows
FROM stg.Employees_Raw
WHERE EmployeeID IS NOT NULL
GROUP BY EmployeeID
HAVING COUNT(*) > 1
ORDER BY DuplicateRows DESC;


/* ============================================================
   QUERY 124 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT
    COLUMN_NAME,
    DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'stg'
  AND TABLE_NAME = 'Employees_Raw'
ORDER BY ORDINAL_POSITION;


/* ============================================================
   QUERY 125 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT COUNT(*) AS MissingEmployeeStoreID
FROM stg.Employees_Raw
WHERE StoreID IS NULL;


/* ============================================================
   QUERY 126 — CHECK STORE REFERENCES
   ============================================================ */

SELECT COUNT(*) AS InvalidEmployeeStoreID
FROM stg.Employees_Raw e
WHERE e.StoreID IS NOT NULL
  AND NOT EXISTS
  (
      SELECT 1
      FROM stg.Stores_Raw s
      WHERE s.StoreID = e.StoreID
  );


/* ============================================================
   QUERY 127 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT COUNT(*) AS MissingManagerEmployeeID
FROM stg.Stores_Raw
WHERE ManagerEmployeeID IS NULL;


/* ============================================================
   QUERY 128 — CHECK EMPLOYEE REFERENCES
   ============================================================ */

SELECT COUNT(*) AS InvalidManagerEmployeeID
FROM stg.Stores_Raw s
WHERE s.ManagerEmployeeID IS NOT NULL
  AND NOT EXISTS
  (
      SELECT 1
      FROM stg.Employees_Raw e
      WHERE e.EmployeeID = s.ManagerEmployeeID
  );


/* ============================================================
   QUERY 129 — CHECK UNIT PRICE VALUES
   ============================================================ */

SELECT COUNT(*) AS ProductsBelowCost
FROM stg.Products_Raw
WHERE TRY_CONVERT(DECIMAL(18,2), UnitPrice)
      < TRY_CONVERT(DECIMAL(18,2), UnitCost);


/* ============================================================
   QUERY 130 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT COUNT(*) AS MissingUnitCost
FROM stg.Products_Raw
WHERE UnitCost IS NULL;


/* ============================================================
   QUERY 131 — CHECK UNIT PRICE VALUES
   ============================================================ */

SELECT COUNT(*) AS MissingProductUnitPrice
FROM stg.Products_Raw
WHERE UnitPrice IS NULL;


/* ============================================================
   QUERY 132 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT
    UnitCost,
    COUNT(*) AS RecordCount
FROM stg.Products_Raw
WHERE UnitCost IS NOT NULL
  AND TRY_CONVERT(DECIMAL(18,2), UnitCost) IS NULL
GROUP BY UnitCost
ORDER BY RecordCount DESC;


/* ============================================================
   QUERY 133 — CHECK UNIT PRICE VALUES
   ============================================================ */

SELECT
    UnitPrice,
    COUNT(*) AS RecordCount
FROM stg.Products_Raw
WHERE UnitPrice IS NOT NULL
  AND TRY_CONVERT(DECIMAL(18,2), UnitPrice) IS NULL
GROUP BY UnitPrice
ORDER BY RecordCount DESC;


/* ============================================================
   QUERY 134 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT
    UnitCost,
    COUNT(*) AS RecordCount
FROM stg.Products_Raw
WHERE UnitCost IS NOT NULL
  AND TRY_CONVERT(DECIMAL(18,4), UnitCost) IS NOT NULL
  AND TRY_CONVERT(DECIMAL(18,4), UnitCost)
      <> TRY_CONVERT(DECIMAL(18,2), UnitCost)
GROUP BY UnitCost
ORDER BY RecordCount DESC;


/* ============================================================
   QUERY 135 — CHECK UNIT PRICE VALUES
   ============================================================ */

SELECT
    UnitPrice,
    COUNT(*) AS RecordCount
FROM stg.Products_Raw
WHERE UnitPrice IS NOT NULL
  AND TRY_CONVERT(DECIMAL(18,4), UnitPrice) IS NOT NULL
  AND TRY_CONVERT(DECIMAL(18,4), UnitPrice)
      <> TRY_CONVERT(DECIMAL(18,2), UnitPrice)
GROUP BY UnitPrice
ORDER BY RecordCount DESC;


/* ============================================================
   QUERY 136 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT
    ProductStatus,
    COUNT(*) AS RecordCount
FROM stg.Products_Raw
GROUP BY ProductStatus
ORDER BY RecordCount DESC;


/* ============================================================
   QUERY 137 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT COUNT(*) AS MissingProductStatus
FROM stg.Products_Raw
WHERE ProductStatus IS NULL;


/* ============================================================
   QUERY 138 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT COUNT(*) AS BlankProductStatus
FROM stg.Products_Raw
WHERE ProductStatus IS NOT NULL
  AND LTRIM(RTRIM(ProductStatus)) = '';


/* ============================================================
   QUERY 139 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT
    ProductStatus,
    COUNT(*) AS RecordCount
FROM stg.Products_Raw
GROUP BY ProductStatus
ORDER BY RecordCount DESC;


/* ============================================================
   QUERY 140 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT
    ProductStatus COLLATE Latin1_General_100_BIN2 AS ProductStatus,
    COUNT(*) AS RecordCount
FROM stg.Products_Raw
GROUP BY
    ProductStatus COLLATE Latin1_General_100_BIN2
ORDER BY RecordCount DESC;


/* ============================================================
   QUERY 141 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT
    MIN(TRY_CONVERT(date, LaunchDate, 23)) AS MinLaunchDate,
    MAX(TRY_CONVERT(date, LaunchDate, 23)) AS MaxLaunchDate
FROM stg.Products_Raw;


/* ============================================================
   QUERY 142 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT COUNT(*) AS UnparseableLaunchDates
FROM stg.Products_Raw
WHERE LaunchDate IS NOT NULL
  AND TRY_CONVERT(date, LaunchDate, 23) IS NULL;


/* ============================================================
   QUERY 143 — CHECK UNIT PRICE VALUES
   ============================================================ */

SELECT
    ProductStatus,
    COUNT(*) AS ZeroPriceProducts
FROM stg.Products_Raw
WHERE TRY_CONVERT(DECIMAL(18,2), UnitPrice) = 0
GROUP BY ProductStatus
ORDER BY ProductStatus;


/* ============================================================
   QUERY 144 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT
    ProductStatus,
    COUNT(*) AS MissingUnitCost
FROM stg.Products_Raw
WHERE UnitCost IS NULL
GROUP BY ProductStatus
ORDER BY ProductStatus;


/* ============================================================
   QUERY 145 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT COUNT(*) AS MissingCategory
FROM stg.Products_Raw
WHERE Category IS NULL;


/* ============================================================
   QUERY 146 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT COUNT(*) AS BlankCategory
FROM stg.Products_Raw
WHERE Category IS NOT NULL
  AND LTRIM(RTRIM(Category)) = '';


/* ============================================================
   QUERY 147 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT
    Category COLLATE Latin1_General_100_BIN2 AS Category,
    COUNT(*) AS RecordCount
FROM stg.Products_Raw
GROUP BY
    Category COLLATE Latin1_General_100_BIN2
ORDER BY RecordCount DESC;


/* ============================================================
   QUERY 148 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT COUNT(*) AS MissingSubCategory
FROM stg.Products_Raw
WHERE SubCategory IS NULL;


/* ============================================================
   QUERY 149 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT COUNT(*) AS BlankSubCategory
FROM stg.Products_Raw
WHERE SubCategory IS NOT NULL
  AND LTRIM(RTRIM(SubCategory)) = '';


/* ============================================================
   QUERY 150 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT
    SubCategory COLLATE Latin1_General_100_BIN2 AS SubCategory,
    COUNT(*) AS RecordCount
FROM stg.Products_Raw
GROUP BY
    SubCategory COLLATE Latin1_General_100_BIN2
ORDER BY RecordCount DESC;


/* ============================================================
   QUERY 151 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT COUNT(*) AS MissingBrand
FROM stg.Products_Raw
WHERE Brand IS NULL;


/* ============================================================
   QUERY 152 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT COUNT(*) AS BlankBrand
FROM stg.Products_Raw
WHERE Brand IS NOT NULL
  AND LTRIM(RTRIM(Brand)) = '';


/* ============================================================
   QUERY 153 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT
    Brand COLLATE Latin1_General_100_BIN2 AS Brand,
    COUNT(*) AS RecordCount
FROM stg.Products_Raw
GROUP BY
    Brand COLLATE Latin1_General_100_BIN2
ORDER BY RecordCount DESC;


/* ============================================================
   QUERY 154 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT COUNT(*) AS MissingSupplier
FROM stg.Products_Raw
WHERE Supplier IS NULL;


/* ============================================================
   QUERY 155 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT COUNT(*) AS BlankSupplier
FROM stg.Products_Raw
WHERE Supplier IS NOT NULL
  AND LTRIM(RTRIM(Supplier)) = '';


/* ============================================================
   QUERY 156 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT
    Supplier COLLATE Latin1_General_100_BIN2 AS Supplier,
    COUNT(*) AS RecordCount
FROM stg.Products_Raw
WHERE Supplier IS NOT NULL
GROUP BY
    Supplier COLLATE Latin1_General_100_BIN2
ORDER BY RecordCount DESC;


/* ============================================================
   QUERY 157 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT
    Category,
    SubCategory,
    COUNT(*) AS RecordCount
FROM stg.Products_Raw
GROUP BY
    Category,
    SubCategory
ORDER BY
    Category,
    SubCategory;


/* ============================================================
   QUERY 158 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT
    SubCategory,
    COUNT(DISTINCT Category) AS CategoryCount
FROM stg.Products_Raw
WHERE SubCategory IS NOT NULL
GROUP BY SubCategory
HAVING COUNT(DISTINCT Category) > 1
ORDER BY CategoryCount DESC, SubCategory;


/* ============================================================
   QUERY 159 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT
    StoreStatus,
    COUNT(*) AS RecordCount
FROM stg.Stores_Raw
GROUP BY StoreStatus
ORDER BY RecordCount DESC;


/* ============================================================
   QUERY 160 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT COUNT(*) AS MissingStoreStatus
FROM stg.Stores_Raw
WHERE StoreStatus IS NULL;


/* ============================================================
   QUERY 161 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT COUNT(*) AS BlankStoreStatus
FROM stg.Stores_Raw
WHERE StoreStatus IS NOT NULL
  AND LTRIM(RTRIM(StoreStatus)) = '';


/* ============================================================
   QUERY 162 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT
    StoreStatus COLLATE Latin1_General_100_BIN2 AS StoreStatus,
    COUNT(*) AS RecordCount
FROM stg.Stores_Raw
GROUP BY
    StoreStatus COLLATE Latin1_General_100_BIN2
ORDER BY RecordCount DESC;


/* ============================================================
   QUERY 163 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT
    StoreType,
    COUNT(*) AS RecordCount
FROM stg.Stores_Raw
GROUP BY StoreType
ORDER BY RecordCount DESC;


/* ============================================================
   QUERY 164 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT COUNT(*) AS MissingStoreType
FROM stg.Stores_Raw
WHERE StoreType IS NULL;


/* ============================================================
   QUERY 165 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT COUNT(*) AS BlankStoreType
FROM stg.Stores_Raw
WHERE StoreType IS NOT NULL
  AND LTRIM(RTRIM(StoreType)) = '';


/* ============================================================
   QUERY 166 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT
    StoreType  COLLATE Latin1_General_100_BIN2 AS StoreType,
    COUNT(*) AS RecordCount
FROM stg.Stores_Raw
GROUP BY
    StoreType COLLATE Latin1_General_100_BIN2
ORDER BY RecordCount DESC;


/* ============================================================
   QUERY 167 — CHECK SALES CHANNEL VALUES
   ============================================================ */

SELECT
    SalesChannel,
    COUNT(*) AS RecordCount
FROM stg.Stores_Raw
GROUP BY SalesChannel
ORDER BY RecordCount DESC;


/* ============================================================
   QUERY 168 — CHECK SALES CHANNEL VALUES
   ============================================================ */

SELECT COUNT(*) AS MissingSalesChannel
FROM stg.Stores_Raw
WHERE SalesChannel  IS NULL;


/* ============================================================
   QUERY 169 — CHECK SALES CHANNEL VALUES
   ============================================================ */

SELECT COUNT(*) AS BlankSalesChannels
FROM stg.Stores_Raw
WHERE SalesChannel  IS NOT NULL
  AND LTRIM(RTRIM(SalesChannel )) = '';


/* ============================================================
   QUERY 170 — CHECK SALES CHANNEL VALUES
   ============================================================ */

SELECT
    SalesChannel   COLLATE Latin1_General_100_BIN2 AS SalesChannel,
    COUNT(*) AS RecordCount
FROM stg.Stores_Raw
GROUP BY
    SalesChannel  COLLATE Latin1_General_100_BIN2
ORDER BY RecordCount DESC;


/* ============================================================
   QUERY 171 — CHECK STORE REFERENCES
   ============================================================ */

SELECT COUNT(*) AS ManagerStoreMismatch
FROM stg.Stores_Raw s
INNER JOIN stg.Employees_Raw e
    ON s.ManagerEmployeeID = e.EmployeeID
WHERE s.StoreID <> e.StoreID;


/* ============================================================
   QUERY 172 — CHECK STORE REFERENCES
   ============================================================ */

SELECT
    s.StoreID,
    s.ManagerEmployeeID,
    e.StoreID AS EmployeeStoreID
FROM stg.Stores_Raw s
INNER JOIN stg.Employees_Raw e
    ON s.ManagerEmployeeID = e.EmployeeID
WHERE s.StoreID <> e.StoreID
ORDER BY s.StoreID;


/* ============================================================
   QUERY 173 — CHECK STORE REFERENCES
   ============================================================ */

SELECT COUNT(*) AS MismatchesWithDuplicateEmployeeID
FROM stg.Stores_Raw s
INNER JOIN stg.Employees_Raw e
    ON s.ManagerEmployeeID = e.EmployeeID
WHERE s.StoreID <> e.StoreID
  AND e.EmployeeID IN
  (
      SELECT EmployeeID
      FROM stg.Employees_Raw
      WHERE EmployeeID IS NOT NULL
      GROUP BY EmployeeID
      HAVING COUNT(*) > 1
  );


/* ============================================================
   QUERY 174 — CHECK STORE REFERENCES
   ============================================================ */

SELECT
    s.StoreID,
    s.ManagerEmployeeID,
    e.StoreID AS EmployeeStoreID
FROM stg.Stores_Raw s
INNER JOIN stg.Employees_Raw e
    ON s.ManagerEmployeeID = e.EmployeeID
WHERE s.StoreID <> e.StoreID
  AND e.EmployeeID IN
  (
      SELECT EmployeeID
      FROM stg.Employees_Raw
      WHERE EmployeeID IS NOT NULL
      GROUP BY EmployeeID
      HAVING COUNT(*) > 1
  )
ORDER BY s.StoreID, s.ManagerEmployeeID;


/* ============================================================
   QUERY 175 — CHECK EMPLOYEE REFERENCES
   ============================================================ */

SELECT *
FROM stg.Employees_Raw
WHERE EmployeeID = 'EMP0300';


/* ============================================================
   QUERY 176 — CHECK EMPLOYEE REFERENCES
   ============================================================ */

SELECT
    EmployeeID,
    COUNT(*) AS DuplicateRows,
    COUNT(DISTINCT COALESCE(StoreID, '<NULL>')) AS StoreVariants
FROM stg.Employees_Raw
WHERE EmployeeID IS NOT NULL
GROUP BY EmployeeID
HAVING COUNT(*) > 1
   AND COUNT(DISTINCT COALESCE(StoreID, '<NULL>')) > 1
ORDER BY EmployeeID;


/* ============================================================
   QUERY 177 — CHECK EMPLOYEE REFERENCES
   ============================================================ */

SELECT
    EmployeeID,
    StoreID,
    COUNT(*) AS RecordCount
FROM stg.Employees_Raw
WHERE EmployeeID IS NOT NULL
GROUP BY EmployeeID, StoreID
HAVING EmployeeID IN
(
    SELECT EmployeeID
    FROM stg.Employees_Raw
    GROUP BY EmployeeID
    HAVING COUNT(*) > 1
)
ORDER BY EmployeeID, StoreID;


/* ============================================================
   QUERY 178 — CHECK EMPLOYEE REFERENCES
   ============================================================ */

SELECT
    EmployeeID,
    StoreID,
    COUNT(*) AS RecordCount
FROM stg.Employees_Raw
WHERE EmployeeID = 'EMP0300'
GROUP BY EmployeeID, StoreID
ORDER BY StoreID;


/* ============================================================
   QUERY 179 — CHECK STORE REFERENCES
   ============================================================ */

SELECT
    s.StoreID,
    COUNT(*) AS StoreRows
FROM stg.Stores_Raw s
WHERE s.StoreID IN
(
    SELECT StoreID
    FROM stg.Stores_Raw
    GROUP BY StoreID
    HAVING COUNT(*) > 1
)
GROUP BY s.StoreID;


/* ============================================================
   QUERY 180 — CHECK STORE REFERENCES
   ============================================================ */

SELECT
    COUNT(DISTINCT s.StoreID) AS AffectedStores
FROM stg.Stores_Raw s
INNER JOIN stg.Employees_Raw e
    ON s.ManagerEmployeeID = e.EmployeeID
WHERE s.StoreID <> e.StoreID;


/* ============================================================
   QUERY 181 — CHECK SALES CHANNEL VALUES
   ============================================================ */

SELECT
    SalesChannel COLLATE Latin1_General_100_BIN2 AS SalesChannel,
    COUNT(*) AS RecordCount
FROM stg.Stores_Raw
GROUP BY
    SalesChannel COLLATE Latin1_General_100_BIN2
ORDER BY RecordCount DESC;


/* ============================================================
   QUERY 182 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT COUNT(*) AS MissingStoreName
FROM stg.Stores_Raw
WHERE StoreName IS NULL;


/* ============================================================
   QUERY 183 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT COUNT(*) AS BlankStoreName
FROM stg.Stores_Raw
WHERE StoreName   IS NOT NULL
  AND LTRIM(RTRIM(StoreName  )) = '';


/* ============================================================
   QUERY 184 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT
    StoreName    COLLATE Latin1_General_100_BIN2 AS StoreName,
    COUNT(*) AS RecordCount
FROM stg.Stores_Raw
GROUP BY
    StoreName   COLLATE Latin1_General_100_BIN2
ORDER BY RecordCount DESC;


/* ============================================================
   QUERY 185 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT COUNT(*) AS MissingCity
FROM stg.Stores_Raw
WHERE City IS NULL;


/* ============================================================
   QUERY 186 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT COUNT(*) AS Blankcity
FROM stg.Stores_Raw
WHERE City    IS NOT NULL
  AND LTRIM(RTRIM(City   )) = '';


/* ============================================================
   QUERY 187 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT
    City     COLLATE Latin1_General_100_BIN2 AS City,
    COUNT(*) AS RecordCount
FROM stg.Stores_Raw
GROUP BY
    City    COLLATE Latin1_General_100_BIN2
ORDER BY RecordCount DESC;


/* ============================================================
   QUERY 188 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT COUNT(*) AS MissingState
FROM stg.Stores_Raw
WHERE State IS NULL;


/* ============================================================
   QUERY 189 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

select count(*) as BlankState
from stg.Stores_Raw 
where State is not null
and LTRIM(RTRIM(state))='';


/* ============================================================
   QUERY 190 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

select state collate Latin1_general_100_BIN2 as state,
count(*) as recordcount
from stg.stores_raw 
group by state collate Latin1_general_100_BIN2
order by recordcount;


/* ============================================================
   QUERY 191 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT
    Region,
    COUNT(*) AS RecordCount
FROM stg.Stores_Raw
GROUP BY Region
ORDER BY RecordCount DESC;


/* ============================================================
   QUERY 192 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

select count(*) as missingRegion
from stg.Stores_Raw 
where Region is null;


/* ============================================================
   QUERY 193 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

select count(*) as blankregion 
from stg.Stores_Raw where region is not null
and LTRIM(RTRIM(Region))='';


/* ============================================================
   QUERY 194 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

select region collate Latin1_general_100_BIN2 as region,
count(*) as recordcount
from stg.Stores_Raw 
group by region collate Latin1_general_100_BIN2
order by recordcount;


/* ============================================================
   QUERY 195 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT
    State,
    COUNT(DISTINCT Region COLLATE Latin1_General_100_BIN2) AS RegionCount
FROM stg.Stores_Raw
WHERE State IS NOT NULL
  AND Region IS NOT NULL
GROUP BY State
HAVING COUNT(DISTINCT Region COLLATE Latin1_General_100_BIN2) > 1
ORDER BY State;


/* ============================================================
   QUERY 196 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT
    State,
    COUNT(
        DISTINCT UPPER(LTRIM(RTRIM(Region)))
    ) AS RegionCount
FROM stg.Stores_Raw
WHERE State IS NOT NULL
  AND Region IS NOT NULL
GROUP BY State
HAVING COUNT(
        DISTINCT UPPER(LTRIM(RTRIM(Region)))
       ) > 1
ORDER BY State;


/* ============================================================
   QUERY 197 — CHECK STORE REFERENCES
   ============================================================ */

SELECT
    StoreID,
    COUNT(*) AS RecordCount
FROM stg.Stores_Raw
WHERE StoreID IS NOT NULL
  AND StoreID NOT LIKE 'STORE[0-9][0-9][0-9]'
GROUP BY StoreID
ORDER BY RecordCount DESC;


/* ============================================================
   QUERY 198 — CHECK EMPLOYEE REFERENCES
   ============================================================ */

SELECT
    EmployeeID,
    COUNT(*) AS RecordCount
FROM stg.Employees_Raw
WHERE EmployeeID IS NOT NULL
  AND EmployeeID NOT LIKE 'EMP[0-9][0-9][0-9][0-9]'
GROUP BY EmployeeID
ORDER BY RecordCount DESC;


/* ============================================================
   QUERY 199 — CHECK CUSTOMER REFERENCES
   ============================================================ */

SELECT
    CustomerID,
    COUNT(*) AS RecordCount
FROM stg.Customers_Raw
WHERE CustomerID IS NOT NULL
  AND CustomerID NOT LIKE 'CUST[0-9][0-9][0-9][0-9][0-9]'
GROUP BY CustomerID
ORDER BY RecordCount DESC;


/* ============================================================
   QUERY 200 — CHECK PRODUCT REFERENCES
   ============================================================ */

SELECT
    ProductID,
    COUNT(*) AS RecordCount
FROM stg.Products_Raw
WHERE ProductID IS NOT NULL
  AND ProductID NOT LIKE 'PROD[0-9][0-9][0-9][0-9][0-9]'
GROUP BY ProductID
ORDER BY RecordCount DESC;


/* ============================================================
   QUERY 201 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT
    Gender,
    COUNT(*) AS RecordCount
FROM stg.Customers_Raw
GROUP BY Gender
ORDER BY RecordCount DESC;


/* ============================================================
   QUERY 202 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

select count(*) as missingGender
from stg.Customers_Raw 
where Gender is null;


/* ============================================================
   QUERY 203 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT COUNT(*) AS BlankGender
FROM stg.Customers_Raw
WHERE Gender IS NOT NULL
  AND LTRIM(RTRIM(Gender)) = '';


/* ============================================================
   QUERY 204 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

select gender collate Latin1_general_100_BIN2 as gender,
count(*) as recordcount
from stg.Customers_Raw 
group by  gender collate Latin1_general_100_BIN2
order by recordcount;


/* ============================================================
   QUERY 205 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT COUNT(*) AS MissingDateOfBirth
FROM stg.Customers_Raw
WHERE DateOfBirth IS NULL;


/* ============================================================
   QUERY 206 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT COUNT(*) AS BlankDateOfBirth
FROM stg.Customers_Raw
WHERE DateOfBirth IS NOT NULL
  AND LTRIM(RTRIM(DateOfBirth)) = '';


/* ============================================================
   QUERY 207 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT COUNT(*) AS UnparseableDateOfBirth
FROM stg.Customers_Raw
WHERE DateOfBirth IS NOT NULL
  AND TRY_CONVERT(date, DateOfBirth, 23) IS NULL;


/* ============================================================
   QUERY 208 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT COUNT(*) AS FutureDateOfBirth
FROM stg.Customers_Raw
WHERE TRY_CONVERT(date, DateOfBirth, 23) > CAST(GETDATE() AS date);


/* ============================================================
   QUERY 209 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT COUNT(*) AS MissingEmail
FROM stg.Customers_Raw
WHERE Email IS NULL;


/* ============================================================
   QUERY 210 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT COUNT(*) AS BlankEmail
FROM stg.Customers_Raw
WHERE Email IS NOT NULL
  AND LTRIM(RTRIM(Email)) = '';


/* ============================================================
   QUERY 211 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT COUNT(*) AS InvalidEmailFormat
FROM stg.Customers_Raw
WHERE Email IS NOT NULL
  AND (
        Email NOT LIKE '%@%'
        OR Email LIKE '%@%@%'
        OR Email LIKE '@%'
        OR Email LIKE '%@'
        OR Email LIKE '% %'
      );


/* ============================================================
   QUERY 212 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT
    Email,
    COUNT(*) AS RecordCount
FROM stg.Customers_Raw
WHERE Email IS NOT NULL
  AND (
        Email NOT LIKE '%@%'
        OR Email LIKE '%@%@%'
        OR Email LIKE '@%'
        OR Email LIKE '%@'
        OR Email LIKE '% %'
      )
GROUP BY Email
ORDER BY RecordCount DESC;


/* ============================================================
   QUERY 213 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT
    Email
FROM stg.Customers_Raw
WHERE Email IS NOT NULL
  AND Email LIKE '%@%'
  AND (
        Email LIKE '%@%@%'
        OR Email LIKE '@%'
        OR Email LIKE '%@'
        OR Email LIKE '% %'
      );


/* ============================================================
   QUERY 214 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT COUNT(*) AS MissingPhone
FROM stg.Customers_Raw
WHERE Phone IS NULL;


/* ============================================================
   QUERY 215 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT COUNT(*) AS BlankPhone
FROM stg.Customers_Raw
WHERE Phone IS NOT NULL
  AND LTRIM(RTRIM(Phone)) = '';


/* ============================================================
   QUERY 216 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT COUNT(*) AS InvalidPhoneFormat
FROM stg.Customers_Raw
WHERE Phone IS NOT NULL
  AND (
        LEN(LTRIM(RTRIM(Phone))) <> 10
        OR LTRIM(RTRIM(Phone)) LIKE '%[^0-9]%'
      );


/* ============================================================
   QUERY 217 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT
    City,
    COUNT(*) AS RecordCount
FROM stg.Customers_Raw
GROUP BY City
ORDER BY RecordCount DESC;


/* ============================================================
   QUERY 218 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT COUNT(*) AS MissingCity
FROM stg.Customers_Raw
WHERE City IS NULL;


/* ============================================================
   QUERY 219 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT COUNT(*) AS BlankCity
FROM stg.Customers_Raw
WHERE City IS NOT NULL
  AND LTRIM(RTRIM(City)) = '';


/* ============================================================
   QUERY 220 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT
    City COLLATE Latin1_General_100_BIN2 AS City,
    COUNT(*) AS RecordCount
FROM stg.Customers_Raw
GROUP BY
    City COLLATE Latin1_General_100_BIN2
ORDER BY RecordCount DESC;


/* ============================================================
   QUERY 221 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT
    State,
    COUNT(*) AS RecordCount
FROM stg.Customers_Raw
GROUP BY State
ORDER BY RecordCount DESC;


/* ============================================================
   QUERY 222 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT COUNT(*) AS MissingState
FROM stg.Customers_Raw
WHERE State IS NULL;


/* ============================================================
   QUERY 223 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT COUNT(*) AS BlankState
FROM stg.Customers_Raw
WHERE State  IS NOT NULL
  AND LTRIM(RTRIM(State )) = '';


/* ============================================================
   QUERY 224 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT
    State  COLLATE Latin1_General_100_BIN2 AS State,
    COUNT(*) AS RecordCount
FROM stg.Customers_Raw
GROUP BY
    State COLLATE Latin1_General_100_BIN2
ORDER BY RecordCount DESC;


/* ============================================================
   QUERY 225 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT
    State,
    COUNT(DISTINCT UPPER(LTRIM(RTRIM(Region)))) AS RegionCount
FROM stg.Customers_Raw
WHERE State IS NOT NULL
  AND Region IS NOT NULL
GROUP BY State
HAVING COUNT(DISTINCT UPPER(LTRIM(RTRIM(Region)))) > 1
ORDER BY State;


/* ============================================================
   QUERY 226 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT
    Region,
    COUNT(*) AS RecordCount
FROM stg.Customers_Raw
GROUP BY Region
ORDER BY RecordCount DESC;


/* ============================================================
   QUERY 227 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT COUNT(*) AS MissingRegion
FROM stg.Customers_Raw
WHERE Region IS NULL;


/* ============================================================
   QUERY 228 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT COUNT(*) AS BlankRegion
FROM stg.Customers_Raw
WHERE Region  IS NOT NULL
  AND LTRIM(RTRIM(Region )) = '';


/* ============================================================
   QUERY 229 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT
    Region  COLLATE Latin1_General_100_BIN2 AS Region,
    COUNT(*) AS RecordCount
FROM stg.Customers_Raw
GROUP BY
    Region COLLATE Latin1_General_100_BIN2
ORDER BY RecordCount DESC;


/* ============================================================
   QUERY 230 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT
    Region,
    COUNT(*) AS RecordCount
FROM stg.Customers_Raw
WHERE Region IS NOT NULL
  AND UPPER(LTRIM(RTRIM(Region))) NOT IN
      ('NORTH', 'SOUTH', 'EAST', 'WEST')
GROUP BY Region
ORDER BY RecordCount DESC;


/* ============================================================
   QUERY 231 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT
    CustomerSegment,
    COUNT(*) AS RecordCount
FROM stg.Customers_Raw
GROUP BY CustomerSegment
ORDER BY RecordCount DESC;


/* ============================================================
   QUERY 232 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT COUNT(*) AS BlankCustomerSegment
FROM stg.Customers_Raw
WHERE CustomerSegment IS NOT NULL
  AND LTRIM(RTRIM(CustomerSegment)) = '';


/* ============================================================
   QUERY 233 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT
    CustomerSegment COLLATE Latin1_General_100_BIN2 AS CustomerSegment,
    COUNT(*) AS RecordCount
FROM stg.Customers_Raw
GROUP BY
    CustomerSegment COLLATE Latin1_General_100_BIN2
ORDER BY RecordCount DESC;


/* ============================================================
   QUERY 234 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT
    CustomerSegment,
    COUNT(*) AS RecordCount
FROM stg.Customers_Raw
WHERE CustomerSegment IS NOT NULL
  AND UPPER(LTRIM(RTRIM(CustomerSegment))) NOT IN
      ('CONSUMER', 'CORPORATE', 'SMALL BUSINESS', 'PREMIUM')
GROUP BY CustomerSegment
ORDER BY RecordCount DESC;


/* ============================================================
   QUERY 235 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT
    LEFT(LTRIM(RTRIM(SignupDate)), 10) AS SignupDateSample,
    COUNT(*) AS RecordCount
FROM stg.Customers_Raw
WHERE SignupDate IS NOT NULL
GROUP BY LEFT(LTRIM(RTRIM(SignupDate)), 10)
ORDER BY RecordCount DESC;


/* ============================================================
   QUERY 236 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT COUNT(*) AS MissingSignupDate
FROM stg.Customers_Raw
WHERE SignupDate IS NULL;


/* ============================================================
   QUERY 237 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT COUNT(*) AS BlankSignupDate
FROM stg.Customers_Raw
WHERE SignupDate IS NOT NULL
  AND LTRIM(RTRIM(SignupDate)) = '';


/* ============================================================
   QUERY 238 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT COUNT(*) AS UnparseableSignupDate
FROM stg.Customers_Raw
WHERE SignupDate IS NOT NULL
  AND TRY_CONVERT(date, SignupDate, 23) IS NULL;


/* ============================================================
   QUERY 239 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT COUNT(*) AS FutureSignupDate
FROM stg.Customers_Raw
WHERE TRY_CONVERT(date, SignupDate, 23) > CAST(GETDATE() AS date);


/* ============================================================
   QUERY 240 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT COUNT(*) AS MissingCustomerName
FROM stg.Customers_Raw
WHERE CustomerName IS NULL;


/* ============================================================
   QUERY 241 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT COUNT(*) AS BlankCustomerName
FROM stg.Customers_Raw
WHERE CustomerName IS NOT NULL
  AND LTRIM(RTRIM(CustomerName)) = '';


/* ============================================================
   QUERY 242 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT
    CustomerName COLLATE Latin1_General_100_BIN2 AS CustomerName,
    COUNT(*) AS RecordCount
FROM stg.Customers_Raw
GROUP BY
    CustomerName COLLATE Latin1_General_100_BIN2
ORDER BY RecordCount DESC;


/* ============================================================
   QUERY 243 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT
    UPPER(LTRIM(RTRIM(CustomerName))) AS NormalizedName,
    COUNT(DISTINCT CustomerName COLLATE Latin1_General_100_BIN2) AS NameVariants,
    COUNT(*) AS RecordCount
FROM stg.Customers_Raw
WHERE CustomerName IS NOT NULL
GROUP BY UPPER(LTRIM(RTRIM(CustomerName)))
HAVING COUNT(DISTINCT CustomerName COLLATE Latin1_General_100_BIN2) > 1
ORDER BY NameVariants DESC, RecordCount DESC;


/* ============================================================
   QUERY 244 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT
    COUNT(*) AS AffectedCustomerNameRows
FROM stg.Customers_Raw c
WHERE c.CustomerName IS NOT NULL
  AND EXISTS
  (
      SELECT 1
      FROM stg.Customers_Raw x
      WHERE UPPER(LTRIM(RTRIM(x.CustomerName)))
            = UPPER(LTRIM(RTRIM(c.CustomerName)))
      GROUP BY UPPER(LTRIM(RTRIM(x.CustomerName)))
      HAVING COUNT(DISTINCT x.CustomerName COLLATE Latin1_General_100_BIN2) > 1
  );


/* ============================================================
   QUERY 245 — CHECK CUSTOMER REFERENCES
   ============================================================ */

SELECT
    Email,
    COUNT(DISTINCT CustomerID) AS CustomerCount,
    COUNT(*) AS RecordCount
FROM stg.Customers_Raw
WHERE Email IS NOT NULL
GROUP BY Email
HAVING COUNT(DISTINCT CustomerID) > 1
ORDER BY CustomerCount DESC, RecordCount DESC;


/* ============================================================
   QUERY 246 — CHECK CUSTOMER REFERENCES
   ============================================================ */

SELECT
    Phone,
    COUNT(DISTINCT CustomerID) AS CustomerCount,
    COUNT(*) AS RecordCount
FROM stg.Customers_Raw
WHERE Phone IS NOT NULL
GROUP BY Phone
HAVING COUNT(DISTINCT CustomerID) > 1
ORDER BY CustomerCount DESC, RecordCount DESC;


/* ============================================================
   QUERY 247 — CHECK CUSTOMER REFERENCES
   ============================================================ */

SELECT
    CustomerID,
    COUNT(*) AS DuplicateRows,
    COUNT(DISTINCT CustomerName COLLATE Latin1_General_100_BIN2) AS NameVariants,
    COUNT(DISTINCT Gender COLLATE Latin1_General_100_BIN2) AS GenderVariants,
    COUNT(DISTINCT DateOfBirth) AS DOBVariants,
    COUNT(DISTINCT Email COLLATE Latin1_General_100_BIN2) AS EmailVariants,
    COUNT(DISTINCT Phone COLLATE Latin1_General_100_BIN2) AS PhoneVariants,
    COUNT(DISTINCT City COLLATE Latin1_General_100_BIN2) AS CityVariants,
    COUNT(DISTINCT State COLLATE Latin1_General_100_BIN2) AS StateVariants,
    COUNT(DISTINCT Region COLLATE Latin1_General_100_BIN2) AS RegionVariants,
    COUNT(DISTINCT SignupDate) AS SignupDateVariants,
    COUNT(DISTINCT CustomerSegment COLLATE Latin1_General_100_BIN2) AS SegmentVariants
FROM stg.Customers_Raw
WHERE CustomerID IS NOT NULL
GROUP BY CustomerID
HAVING COUNT(*) > 1
ORDER BY CustomerID;


/* ============================================================
   QUERY 248 — CHECK CUSTOMER REFERENCES
   ============================================================ */

SELECT COUNT(*) AS ConflictingDuplicateGroups
FROM
(
    SELECT
        CustomerID,
        COUNT(*) AS DuplicateRows,
        COUNT(DISTINCT Gender COLLATE Latin1_General_100_BIN2) AS GenderVariants,
        COUNT(DISTINCT DateOfBirth) AS DOBVariants,
        COUNT(DISTINCT Phone COLLATE Latin1_General_100_BIN2) AS PhoneVariants,
        COUNT(DISTINCT City COLLATE Latin1_General_100_BIN2) AS CityVariants,
        COUNT(DISTINCT State COLLATE Latin1_General_100_BIN2) AS StateVariants,
        COUNT(DISTINCT Region COLLATE Latin1_General_100_BIN2) AS RegionVariants,
        COUNT(DISTINCT SignupDate) AS SignupDateVariants,
        COUNT(DISTINCT CustomerSegment COLLATE Latin1_General_100_BIN2) AS SegmentVariants
    FROM stg.Customers_Raw
    WHERE CustomerID IS NOT NULL
    GROUP BY CustomerID
    HAVING COUNT(*) > 1
) d
WHERE GenderVariants > 1
   OR DOBVariants > 1
   OR PhoneVariants > 1
   OR CityVariants > 1
   OR StateVariants > 1
   OR RegionVariants > 1
   OR SignupDateVariants > 1
   OR SegmentVariants > 1;


/* ============================================================
   QUERY 249 — CHECK CUSTOMER REFERENCES
   ============================================================ */

SELECT COUNT(*) AS NameEmailDuplicateGroups
FROM
(
    SELECT
        CustomerID,
        COUNT(*) AS DuplicateRows,
        COUNT(DISTINCT CustomerName COLLATE Latin1_General_100_BIN2) AS NameVariants,
        COUNT(DISTINCT Email COLLATE Latin1_General_100_BIN2) AS EmailVariants
    FROM stg.Customers_Raw
    WHERE CustomerID IS NOT NULL
    GROUP BY CustomerID
    HAVING COUNT(*) > 1
) d
WHERE NameVariants > 1
   OR EmailVariants > 1;


/* ============================================================
   QUERY 250 — CHECK CUSTOMER REFERENCES
   ============================================================ */

SELECT TOP 20
    CustomerID,
    CustomerName,
    Email
FROM stg.Customers_Raw
WHERE CustomerID IN
(
    SELECT TOP 10 CustomerID
    FROM stg.Customers_Raw
    GROUP BY CustomerID
    HAVING COUNT(*) > 1
    ORDER BY CustomerID
)
ORDER BY CustomerID;


/* ============================================================
   QUERY 251 — CHECK CUSTOMER REFERENCES
   ============================================================ */

SELECT COUNT(*) AS ConflictingAfterNormalization
FROM
(
    SELECT
        CustomerID,

        COUNT(DISTINCT
            UPPER(LTRIM(RTRIM(CustomerName)))
        ) AS NormalizedNameVariants,

        COUNT(DISTINCT
            UPPER(LTRIM(RTRIM(Email)))
        ) AS NormalizedEmailVariants

    FROM stg.Customers_Raw
    WHERE CustomerID IS NOT NULL
    GROUP BY CustomerID
    HAVING COUNT(*) > 1
) d
WHERE NormalizedNameVariants > 1
   OR NormalizedEmailVariants > 1;


/* ============================================================
   QUERY 252 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT
    City,
    COUNT(DISTINCT State) AS StateCount
FROM stg.Customers_Raw
WHERE City IS NOT NULL
  AND State IS NOT NULL
GROUP BY City
HAVING COUNT(DISTINCT State) > 1
ORDER BY City;


/* ============================================================
   QUERY 253 — CHECK PRODUCT REFERENCES
   ============================================================ */

SELECT COUNT(*) AS MissingProductID
FROM stg.Products_Raw
WHERE ProductID IS NULL;


/* ============================================================
   QUERY 254 — CHECK PRODUCT REFERENCES
   ============================================================ */

SELECT COUNT(*) AS BlankProductID
FROM stg.Products_Raw
WHERE ProductID IS NOT NULL
  AND LTRIM(RTRIM(ProductID)) = '';


/* ============================================================
   QUERY 255 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT COUNT(*) AS MissingProductName
FROM stg.Products_Raw
WHERE ProductName IS NULL;


/* ============================================================
   QUERY 256 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT COUNT(*) AS BlankProductName
FROM stg.Products_Raw
WHERE ProductName IS NOT NULL
  AND LTRIM(RTRIM(ProductName)) = '';


/* ============================================================
   QUERY 257 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT
    UPPER(LTRIM(RTRIM(ProductName))) AS NormalizedProductName,
    COUNT(DISTINCT ProductName COLLATE Latin1_General_100_BIN2) AS NameVariants,
    COUNT(*) AS RecordCount
FROM stg.Products_Raw
WHERE ProductName IS NOT NULL
GROUP BY UPPER(LTRIM(RTRIM(ProductName)))
HAVING COUNT(DISTINCT ProductName COLLATE Latin1_General_100_BIN2) > 1
ORDER BY NameVariants DESC, RecordCount DESC;


/* ============================================================
   QUERY 258 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT
    COUNT(*) AS AffectedProductNameRows
FROM stg.Products_Raw p
WHERE p.ProductName IS NOT NULL
  AND EXISTS
  (
      SELECT 1
      FROM stg.Products_Raw x
      WHERE UPPER(LTRIM(RTRIM(x.ProductName)))
            = UPPER(LTRIM(RTRIM(p.ProductName)))
      GROUP BY UPPER(LTRIM(RTRIM(x.ProductName)))
      HAVING COUNT(
          DISTINCT x.ProductName COLLATE Latin1_General_100_BIN2
      ) > 1
  );


/* ============================================================
   QUERY 259 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT COUNT(*) AS MissingCategory
FROM stg.Products_Raw
WHERE Category IS NULL;


/* ============================================================
   QUERY 260 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT
    Category,
    COUNT(*) AS RecordCount
FROM stg.Products_Raw
WHERE Category IS NOT NULL
  AND UPPER(LTRIM(RTRIM(Category))) NOT IN
      (
          'ELECTRONICS',
          'FURNITURE',
          'HOME APPLIANCES',
          'MOBILE & ACCESSORIES',
          'OFFICE EQUIPMENT'
      )
GROUP BY Category
ORDER BY RecordCount DESC;


/* ============================================================
   QUERY 261 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT
    SubCategory,
    COUNT(
        DISTINCT UPPER(LTRIM(RTRIM(Category)))
    ) AS CategoryCount
FROM stg.Products_Raw
WHERE SubCategory IS NOT NULL
  AND Category IS NOT NULL
GROUP BY SubCategory
HAVING COUNT(
        DISTINCT UPPER(LTRIM(RTRIM(Category)))
       ) > 1
ORDER BY SubCategory;


/* ============================================================
   QUERY 262 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT COUNT(*) AS MissingSubCategory
FROM stg.Products_Raw
WHERE SubCategory IS NULL;


/* ============================================================
   QUERY 263 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT COUNT(*) AS BlankSubCategory
FROM stg.Products_Raw
WHERE SubCategory IS NOT NULL
  AND LTRIM(RTRIM(SubCategory)) = '';


/* ============================================================
   QUERY 264 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT
    UPPER(LTRIM(RTRIM(SubCategory))) AS NormalizedSubCategory,
    COUNT(DISTINCT SubCategory COLLATE Latin1_General_100_BIN2) AS SubCategoryVariants,
    COUNT(*) AS RecordCount
FROM stg.Products_Raw
WHERE SubCategory IS NOT NULL
GROUP BY UPPER(LTRIM(RTRIM(SubCategory)))
HAVING COUNT(DISTINCT SubCategory COLLATE Latin1_General_100_BIN2) > 1
ORDER BY SubCategoryVariants DESC, RecordCount DESC;


/* ============================================================
   QUERY 265 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT COUNT(*) AS MissingBrand
FROM stg.Products_Raw
WHERE Brand IS NULL;


/* ============================================================
   QUERY 266 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT COUNT(*) AS BlankBrand
FROM stg.Products_Raw
WHERE Brand IS NOT NULL
  AND LTRIM(RTRIM(Brand)) = '';


/* ============================================================
   QUERY 267 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT
    UPPER(LTRIM(RTRIM(Brand))) AS NormalizedBrand,
    COUNT(DISTINCT Brand COLLATE Latin1_General_100_BIN2) AS BrandVariants,
    COUNT(*) AS RecordCount
FROM stg.Products_Raw
WHERE Brand IS NOT NULL
GROUP BY UPPER(LTRIM(RTRIM(Brand)))
HAVING COUNT(DISTINCT Brand COLLATE Latin1_General_100_BIN2) > 1
ORDER BY BrandVariants DESC, RecordCount DESC;


/* ============================================================
   QUERY 268 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT COUNT(*) AS BlankSupplier
FROM stg.Products_Raw
WHERE Supplier IS NOT NULL
  AND LTRIM(RTRIM(Supplier)) = '';


/* ============================================================
   QUERY 269 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT
    UPPER(LTRIM(RTRIM(Supplier))) AS NormalizedSupplier,
    COUNT(DISTINCT Supplier COLLATE Latin1_General_100_BIN2) AS SupplierVariants,
    COUNT(*) AS RecordCount
FROM stg.Products_Raw
WHERE Supplier IS NOT NULL
GROUP BY UPPER(LTRIM(RTRIM(Supplier)))
HAVING COUNT(DISTINCT Supplier COLLATE Latin1_General_100_BIN2) > 1
ORDER BY SupplierVariants DESC, RecordCount DESC;


/* ============================================================
   QUERY 270 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT COUNT(*) AS NegativeUnitCost
FROM stg.Products_Raw
WHERE UnitCost < 0;


/* ============================================================
   QUERY 271 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT COUNT(*) AS ZeroUnitCost
FROM stg.Products_Raw
WHERE UnitCost = 0;


/* ============================================================
   QUERY 272 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT
    COLUMN_NAME,
    DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'stg'
  AND TABLE_NAME = 'Products_Raw'
ORDER BY ORDINAL_POSITION;


/* ============================================================
   QUERY 273 — CHECK UNIT PRICE VALUES
   ============================================================ */

SELECT COUNT(*) AS MissingUnitPrice
FROM stg.Products_Raw
WHERE UnitPrice IS NULL;


/* ============================================================
   QUERY 274 — CHECK UNIT PRICE VALUES
   ============================================================ */

SELECT COUNT(*) AS BlankUnitPrice
FROM stg.Products_Raw
WHERE UnitPrice IS NOT NULL
  AND LTRIM(RTRIM(UnitPrice)) = '';


/* ============================================================
   QUERY 275 — CHECK UNIT PRICE VALUES
   ============================================================ */

SELECT COUNT(*) AS NonNumericUnitPrice
FROM stg.Products_Raw
WHERE UnitPrice IS NOT NULL
  AND LTRIM(RTRIM(UnitPrice)) <> ''
  AND TRY_CONVERT(DECIMAL(18,2), UnitPrice) IS NULL;


/* ============================================================
   QUERY 276 — CHECK UNIT PRICE VALUES
   ============================================================ */

SELECT COUNT(*) AS NonPositiveUnitPrice
FROM stg.Products_Raw
WHERE TRY_CONVERT(DECIMAL(18,2), UnitPrice) <= 0;


/* ============================================================
   QUERY 277 — CHECK UNIT PRICE VALUES
   ============================================================ */

SELECT COUNT(*) AS InvalidCostPriceRelationship
FROM stg.Products_Raw
WHERE TRY_CONVERT(DECIMAL(18,2), UnitCost) IS NOT NULL
  AND TRY_CONVERT(DECIMAL(18,2), UnitPrice) IS NOT NULL
  AND TRY_CONVERT(DECIMAL(18,2), UnitPrice)
      <= TRY_CONVERT(DECIMAL(18,2), UnitCost);


/* ============================================================
   QUERY 278 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT COUNT(*) AS MissingLaunchDate
FROM stg.Products_Raw
WHERE LaunchDate IS NULL;


/* ============================================================
   QUERY 279 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT COUNT(*) AS BlankLaunchDate
FROM stg.Products_Raw
WHERE LaunchDate IS NOT NULL
  AND LTRIM(RTRIM(LaunchDate)) = '';


/* ============================================================
   QUERY 280 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT COUNT(*) AS UnparseableLaunchDate
FROM stg.Products_Raw
WHERE LaunchDate IS NOT NULL
  AND TRY_CONVERT(date, LaunchDate, 23) IS NULL;


/* ============================================================
   QUERY 281 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT COUNT(*) AS FutureLaunchDate
FROM stg.Products_Raw
WHERE TRY_CONVERT(date, LaunchDate, 23)
      > CAST(GETDATE() AS date);


/* ============================================================
   QUERY 282 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT
    ProductStatus,
    COUNT(*) AS RecordCount
FROM stg.Products_Raw
GROUP BY ProductStatus
ORDER BY RecordCount DESC;


/* ============================================================
   QUERY 283 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT COUNT(*) AS MissingProductStatus
FROM stg.Products_Raw
WHERE ProductStatus IS NULL;


/* ============================================================
   QUERY 284 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT COUNT(*) AS BlankProductStatus
FROM stg.Products_Raw
WHERE ProductStatus IS NOT NULL
  AND LTRIM(RTRIM(ProductStatus)) = '';


/* ============================================================
   QUERY 285 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT
    ProductStatus COLLATE Latin1_General_100_BIN2 AS ProductStatus,
    COUNT(*) AS RecordCount
FROM stg.Products_Raw
GROUP BY ProductStatus COLLATE Latin1_General_100_BIN2
ORDER BY RecordCount DESC;


/* ============================================================
   QUERY 286 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT
    ProductStatus,
    COUNT(*) AS RecordCount
FROM stg.Products_Raw
WHERE ProductStatus IS NOT NULL
  AND UPPER(LTRIM(RTRIM(ProductStatus))) NOT IN
      ('ACTIVE', 'DISCONTINUED')
GROUP BY ProductStatus
ORDER BY RecordCount DESC;


/* ============================================================
   QUERY 287 — CHECK PRODUCT REFERENCES
   ============================================================ */

SELECT
    ProductID,
    COUNT(*) AS DuplicateRows,
    COUNT(DISTINCT ProductName COLLATE Latin1_General_100_BIN2) AS NameVariants,
    COUNT(DISTINCT Category COLLATE Latin1_General_100_BIN2) AS CategoryVariants,
    COUNT(DISTINCT SubCategory COLLATE Latin1_General_100_BIN2) AS SubCategoryVariants,
    COUNT(DISTINCT Brand COLLATE Latin1_General_100_BIN2) AS BrandVariants,
    COUNT(DISTINCT UnitCost COLLATE Latin1_General_100_BIN2) AS UnitCostVariants,
    COUNT(DISTINCT UnitPrice COLLATE Latin1_General_100_BIN2) AS UnitPriceVariants,
    COUNT(DISTINCT Supplier COLLATE Latin1_General_100_BIN2) AS SupplierVariants,
    COUNT(DISTINCT LaunchDate COLLATE Latin1_General_100_BIN2) AS LaunchDateVariants,
    COUNT(DISTINCT ProductStatus COLLATE Latin1_General_100_BIN2) AS StatusVariants
FROM stg.Products_Raw
WHERE ProductID IS NOT NULL
GROUP BY ProductID
HAVING COUNT(*) > 1
ORDER BY ProductID;


/* ============================================================
   QUERY 288 — CHECK PRODUCT REFERENCES
   ============================================================ */

SELECT COUNT(*) AS ConflictingProductGroups
FROM
(
    SELECT
        ProductID,
        COUNT(*) AS DuplicateRows,
        COUNT(DISTINCT Category COLLATE Latin1_General_100_BIN2) AS CategoryVariants,
        COUNT(DISTINCT SubCategory COLLATE Latin1_General_100_BIN2) AS SubCategoryVariants,
        COUNT(DISTINCT Brand COLLATE Latin1_General_100_BIN2) AS BrandVariants,
        COUNT(DISTINCT UnitCost COLLATE Latin1_General_100_BIN2) AS UnitCostVariants,
        COUNT(DISTINCT UnitPrice COLLATE Latin1_General_100_BIN2) AS UnitPriceVariants,
        COUNT(DISTINCT Supplier COLLATE Latin1_General_100_BIN2) AS SupplierVariants,
        COUNT(DISTINCT LaunchDate COLLATE Latin1_General_100_BIN2) AS LaunchDateVariants,
        COUNT(DISTINCT ProductStatus COLLATE Latin1_General_100_BIN2) AS StatusVariants
    FROM stg.Products_Raw
    WHERE ProductID IS NOT NULL
    GROUP BY ProductID
    HAVING COUNT(*) > 1
) p
WHERE CategoryVariants > 1
   OR SubCategoryVariants > 1
   OR BrandVariants > 1
   OR UnitCostVariants > 1
   OR UnitPriceVariants > 1
   OR SupplierVariants > 1
   OR LaunchDateVariants > 1
   OR StatusVariants > 1;


/* ============================================================
   QUERY 289 — CHECK PRODUCT REFERENCES
   ============================================================ */

SELECT COUNT(*) AS ConflictingNamesAfterNormalization
FROM
(
    SELECT
        ProductID,
        COUNT(DISTINCT
            UPPER(LTRIM(RTRIM(ProductName)))
        ) AS NormalizedNameVariants
    FROM stg.Products_Raw
    WHERE ProductID IS NOT NULL
    GROUP BY ProductID
    HAVING COUNT(*) > 1
) p
WHERE NormalizedNameVariants > 1;


/* ============================================================
   QUERY 290 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'stg'
ORDER BY TABLE_NAME;


/* ============================================================
   QUERY 291 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT
    COLUMN_NAME,
    DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'stg'
  AND TABLE_NAME = 'Employees_Raw'
ORDER BY ORDINAL_POSITION;


/* ============================================================
   QUERY 292 — CHECK EMPLOYEE REFERENCES
   ============================================================ */

SELECT COUNT(*) AS MissingEmployeeID
FROM stg.Employees_Raw
WHERE EmployeeID IS NULL;


/* ============================================================
   QUERY 293 — CHECK EMPLOYEE REFERENCES
   ============================================================ */

SELECT COUNT(*) AS BlankEmployeeID
FROM stg.Employees_Raw
WHERE EmployeeID IS NOT NULL
  AND LTRIM(RTRIM(EmployeeID)) = '';


/* ============================================================
   QUERY 294 — CHECK EMPLOYEE REFERENCES
   ============================================================ */

SELECT
    EmployeeID,
    COUNT(*) AS RecordCount
FROM stg.Employees_Raw
GROUP BY EmployeeID
HAVING COUNT(*) > 1
ORDER BY RecordCount DESC, EmployeeID;


/* ============================================================
   QUERY 295 — CHECK EMPLOYEE REFERENCES
   ============================================================ */

SELECT
    EmployeeID,
    COUNT(*) AS DuplicateRows,
    COUNT(DISTINCT EmployeeName COLLATE Latin1_General_100_BIN2) AS NameVariants,
    COUNT(DISTINCT Gender COLLATE Latin1_General_100_BIN2) AS GenderVariants,
    COUNT(DISTINCT JobTitle COLLATE Latin1_General_100_BIN2) AS JobTitleVariants,
    COUNT(DISTINCT Department COLLATE Latin1_General_100_BIN2) AS DepartmentVariants,
    COUNT(DISTINCT StoreID COLLATE Latin1_General_100_BIN2) AS StoreVariants,
    COUNT(DISTINCT Region COLLATE Latin1_General_100_BIN2) AS RegionVariants,
    COUNT(DISTINCT HireDate COLLATE Latin1_General_100_BIN2) AS HireDateVariants,
    COUNT(DISTINCT EmploymentStatus COLLATE Latin1_General_100_BIN2) AS StatusVariants
FROM stg.Employees_Raw
WHERE EmployeeID IS NOT NULL
GROUP BY EmployeeID
HAVING COUNT(*) > 1
ORDER BY EmployeeID;


/* ============================================================
   QUERY 296 — CHECK EMPLOYEE REFERENCES
   ============================================================ */

SELECT COUNT(*) AS ConflictingNamesAfterNormalization
FROM
(
    SELECT
        EmployeeID,
        COUNT(DISTINCT
            UPPER(LTRIM(RTRIM(EmployeeName)))
        ) AS NormalizedNameVariants
    FROM stg.Employees_Raw
    WHERE EmployeeID IS NOT NULL
    GROUP BY EmployeeID
    HAVING COUNT(*) > 1
) e
WHERE NormalizedNameVariants > 1;


/* ============================================================
   QUERY 297 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT
    UPPER(LTRIM(RTRIM(EmployeeName))) AS NormalizedEmployeeName,
    COUNT(DISTINCT EmployeeName COLLATE Latin1_General_100_BIN2) AS NameVariants,
    COUNT(*) AS RecordCount
FROM stg.Employees_Raw
WHERE EmployeeName IS NOT NULL
GROUP BY UPPER(LTRIM(RTRIM(EmployeeName)))
HAVING COUNT(DISTINCT EmployeeName COLLATE Latin1_General_100_BIN2) > 1
ORDER BY NameVariants DESC, RecordCount DESC;


/* ============================================================
   QUERY 298 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT COUNT(*) AS AffectedEmployeeNameRows
FROM stg.Employees_Raw e
WHERE e.EmployeeName IS NOT NULL
  AND EXISTS
  (
      SELECT 1
      FROM stg.Employees_Raw x
      WHERE UPPER(LTRIM(RTRIM(x.EmployeeName)))
            = UPPER(LTRIM(RTRIM(e.EmployeeName)))
      GROUP BY UPPER(LTRIM(RTRIM(x.EmployeeName)))
      HAVING COUNT(
          DISTINCT x.EmployeeName COLLATE Latin1_General_100_BIN2
      ) > 1
  );


/* ============================================================
   QUERY 299 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT COUNT(*) AS MissingEmployeeName
FROM stg.Employees_Raw
WHERE EmployeeName IS NULL;


/* ============================================================
   QUERY 300 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT COUNT(*) AS BlankEmployeeName
FROM stg.Employees_Raw
WHERE EmployeeName IS NOT NULL
  AND LTRIM(RTRIM(EmployeeName)) = '';


/* ============================================================
   QUERY 301 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT
    Gender,
    COUNT(*) AS RecordCount
FROM stg.Employees_Raw
GROUP BY Gender
ORDER BY RecordCount DESC;


/* ============================================================
   QUERY 302 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT COUNT(*) AS MissingGender
FROM stg.Employees_Raw
WHERE Gender IS NULL;


/* ============================================================
   QUERY 303 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT COUNT(*) AS BlankGender
FROM stg.Employees_Raw
WHERE Gender IS NOT NULL
  AND LTRIM(RTRIM(Gender)) = '';


/* ============================================================
   QUERY 304 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT
    Gender COLLATE Latin1_General_100_BIN2 AS Gender,
    COUNT(*) AS RecordCount
FROM stg.Employees_Raw
GROUP BY Gender COLLATE Latin1_General_100_BIN2
ORDER BY RecordCount DESC;


/* ============================================================
   QUERY 305 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT
    Gender,
    COUNT(*) AS RecordCount
FROM stg.Employees_Raw
WHERE Gender IS NOT NULL
  AND UPPER(LTRIM(RTRIM(Gender))) NOT IN
      ('MALE', 'FEMALE', 'OTHER')
GROUP BY Gender
ORDER BY RecordCount DESC;


/* ============================================================
   QUERY 306 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT
    JobTitle,
    COUNT(*) AS RecordCount
FROM stg.Employees_Raw
GROUP BY JobTitle
ORDER BY RecordCount DESC;


/* ============================================================
   QUERY 307 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT COUNT(*) AS MissingJobTitle
FROM stg.Employees_Raw
WHERE JobTitle IS NULL;


/* ============================================================
   QUERY 308 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT COUNT(*) AS BlankJobTitle
FROM stg.Employees_Raw
WHERE JobTitle IS NOT NULL
  AND LTRIM(RTRIM(JobTitle)) = '';


/* ============================================================
   QUERY 309 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT
    UPPER(LTRIM(RTRIM(JobTitle))) AS NormalizedJobTitle,
    COUNT(DISTINCT JobTitle COLLATE Latin1_General_100_BIN2) AS JobTitleVariants,
    COUNT(*) AS RecordCount
FROM stg.Employees_Raw
WHERE JobTitle IS NOT NULL
GROUP BY UPPER(LTRIM(RTRIM(JobTitle)))
HAVING COUNT(DISTINCT JobTitle COLLATE Latin1_General_100_BIN2) > 1
ORDER BY JobTitleVariants DESC, RecordCount DESC;


/* ============================================================
   QUERY 310 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT
    Department,
    COUNT(*) AS RecordCount
FROM stg.Employees_Raw
GROUP BY Department
ORDER BY RecordCount DESC;


/* ============================================================
   QUERY 311 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT COUNT(*) AS MissingDepartment
FROM stg.Employees_Raw
WHERE Department IS NULL;


/* ============================================================
   QUERY 312 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT COUNT(*) AS BlankDepartment
FROM stg.Employees_Raw
WHERE Department IS NOT NULL
  AND LTRIM(RTRIM(Department)) = '';


/* ============================================================
   QUERY 313 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT
    UPPER(LTRIM(RTRIM(Department))) AS NormalizedDepartment,
    COUNT(DISTINCT Department COLLATE Latin1_General_100_BIN2) AS DepartmentVariants,
    COUNT(*) AS RecordCount
FROM stg.Employees_Raw
WHERE Department IS NOT NULL
GROUP BY UPPER(LTRIM(RTRIM(Department)))
HAVING COUNT(DISTINCT Department COLLATE Latin1_General_100_BIN2) > 1
ORDER BY DepartmentVariants DESC, RecordCount DESC;


/* ============================================================
   QUERY 314 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT
    Department,
    COUNT(*) AS RecordCount
FROM stg.Employees_Raw
WHERE Department IS NOT NULL
  AND UPPER(LTRIM(RTRIM(Department))) NOT IN
      ('SALES', 'OPERATIONS', 'CUSTOMER SERVICE')
GROUP BY Department
ORDER BY RecordCount DESC;


/* ============================================================
   QUERY 315 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT COUNT(*) AS MissingStoreID
FROM stg.Employees_Raw
WHERE StoreID IS NULL;


/* ============================================================
   QUERY 316 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT COUNT(*) AS BlankStoreID
FROM stg.Employees_Raw
WHERE StoreID IS NOT NULL
  AND LTRIM(RTRIM(StoreID)) = '';


/* ============================================================
   QUERY 317 — CHECK STORE REFERENCES
   ============================================================ */

SELECT COUNT(*) AS InvalidStoreID
FROM stg.Employees_Raw e
WHERE e.StoreID IS NOT NULL
  AND NOT EXISTS
  (
      SELECT 1
      FROM stg.Stores_Raw s
      WHERE s.StoreID = e.StoreID
  );


/* ============================================================
   QUERY 318 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT
    Region,
    COUNT(*) AS RecordCount
FROM stg.Employees_Raw
GROUP BY Region
ORDER BY RecordCount DESC;


/* ============================================================
   QUERY 319 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT COUNT(*) AS MissingRegion
FROM stg.Employees_Raw
WHERE Region IS NULL;


/* ============================================================
   QUERY 320 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT COUNT(*) AS BlankRegion
FROM stg.Employees_Raw
WHERE Region IS NOT NULL
  AND LTRIM(RTRIM(Region)) = '';


/* ============================================================
   QUERY 321 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT
    Region COLLATE Latin1_General_100_BIN2 AS Region,
    COUNT(*) AS RecordCount
FROM stg.Employees_Raw
GROUP BY Region COLLATE Latin1_General_100_BIN2
ORDER BY RecordCount DESC;


/* ============================================================
   QUERY 322 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT COUNT(*) AS AffectedEmployeeRegionRows
FROM stg.Employees_Raw e
WHERE e.Region IS NOT NULL
  AND EXISTS
  (
      SELECT 1
      FROM stg.Employees_Raw x
      WHERE UPPER(LTRIM(RTRIM(x.Region)))
            = UPPER(LTRIM(RTRIM(e.Region)))
      GROUP BY UPPER(LTRIM(RTRIM(x.Region)))
      HAVING COUNT(
          DISTINCT x.Region COLLATE Latin1_General_100_BIN2
      ) > 1
  );


/* ============================================================
   QUERY 323 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT
    Region,
    COUNT(*) AS RecordCount
FROM stg.Employees_Raw
WHERE Region IS NOT NULL
  AND UPPER(LTRIM(RTRIM(Region))) NOT IN
      ('NORTH', 'SOUTH', 'EAST', 'WEST')
GROUP BY Region
ORDER BY RecordCount DESC;


/* ============================================================
   QUERY 324 — CHECK STORE REFERENCES
   ============================================================ */

SELECT COUNT(*) AS RegionStoreConflicts
FROM stg.Employees_Raw e
INNER JOIN stg.Stores_Raw s
    ON e.StoreID = s.StoreID
WHERE e.StoreID IS NOT NULL
  AND UPPER(LTRIM(RTRIM(e.Region)))
      <> UPPER(LTRIM(RTRIM(s.Region)));


/* ============================================================
   QUERY 325 — CHECK STORE REFERENCES
   ============================================================ */

SELECT
    e.StoreID,
    s.Region AS StoreRegion,
    e.Region AS EmployeeRegion,
    COUNT(*) AS EmployeeCount
FROM stg.Employees_Raw e
INNER JOIN stg.Stores_Raw s
    ON e.StoreID = s.StoreID
WHERE e.StoreID IS NOT NULL
  AND UPPER(LTRIM(RTRIM(e.Region)))
      <> UPPER(LTRIM(RTRIM(s.Region)))
GROUP BY
    e.StoreID,
    s.Region,
    e.Region
ORDER BY EmployeeCount DESC, e.StoreID;


/* ============================================================
   QUERY 326 — CHECK EMPLOYEE REFERENCES
   ============================================================ */

SELECT
    EmployeeID,
    COUNT(DISTINCT StoreID) AS StoreCount
FROM stg.Employees_Raw
WHERE StoreID IS NOT NULL
GROUP BY EmployeeID
HAVING COUNT(DISTINCT StoreID) > 1
ORDER BY StoreCount DESC, EmployeeID;


/* ============================================================
   QUERY 327 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT COUNT(*) AS MissingHireDate
FROM stg.Employees_Raw
WHERE HireDate IS NULL;


/* ============================================================
   QUERY 328 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT COUNT(*) AS BlankHireDate
FROM stg.Employees_Raw
WHERE HireDate IS NOT NULL
  AND LTRIM(RTRIM(HireDate)) = '';


/* ============================================================
   QUERY 329 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT COUNT(*) AS UnparseableHireDate
FROM stg.Employees_Raw
WHERE HireDate IS NOT NULL
  AND TRY_CONVERT(date, HireDate, 23) IS NULL;


/* ============================================================
   QUERY 330 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT COUNT(*) AS FutureHireDate
FROM stg.Employees_Raw
WHERE TRY_CONVERT(date, HireDate, 23)
      > CAST(GETDATE() AS date);


/* ============================================================
   QUERY 331 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT
    EmploymentStatus,
    COUNT(*) AS RecordCount
FROM stg.Employees_Raw
GROUP BY EmploymentStatus
ORDER BY RecordCount DESC;


/* ============================================================
   QUERY 332 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT COUNT(*) AS MissingEmploymentStatus
FROM stg.Employees_Raw
WHERE EmploymentStatus IS NULL;


/* ============================================================
   QUERY 333 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT COUNT(*) AS BlankEmploymentStatus
FROM stg.Employees_Raw
WHERE EmploymentStatus IS NOT NULL
  AND LTRIM(RTRIM(EmploymentStatus)) = '';


/* ============================================================
   QUERY 334 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT
    EmploymentStatus COLLATE Latin1_General_100_BIN2 AS EmploymentStatus,
    COUNT(*) AS RecordCount
FROM stg.Employees_Raw
GROUP BY EmploymentStatus COLLATE Latin1_General_100_BIN2
ORDER BY RecordCount DESC;


/* ============================================================
   QUERY 335 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT
    EmploymentStatus,
    COUNT(*) AS RecordCount
FROM stg.Employees_Raw
WHERE EmploymentStatus IS NOT NULL
  AND UPPER(LTRIM(RTRIM(EmploymentStatus))) NOT IN
      ('ACTIVE', 'ON LEAVE', 'INACTIVE')
GROUP BY EmploymentStatus
ORDER BY RecordCount DESC;


/* ============================================================
   QUERY 336 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT
    COLUMN_NAME,
    DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'stg'
  AND TABLE_NAME = 'Stores_Raw'
ORDER BY ORDINAL_POSITION;


/* ============================================================
   QUERY 337 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT
    StoreType,
    COUNT(*) AS RecordCount
FROM stg.Stores_Raw
GROUP BY StoreType
ORDER BY RecordCount DESC;


/* ============================================================
   QUERY 338 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT COUNT(*) AS MissingStoreType
FROM stg.Stores_Raw
WHERE StoreType IS NULL;


/* ============================================================
   QUERY 339 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT COUNT(*) AS BlankStoreType
FROM stg.Stores_Raw
WHERE StoreType IS NOT NULL
  AND LTRIM(RTRIM(StoreType)) = '';


/* ============================================================
   QUERY 340 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT
    StoreType COLLATE Latin1_General_100_BIN2 AS StoreType,
    COUNT(*) AS RecordCount
FROM stg.Stores_Raw
GROUP BY StoreType COLLATE Latin1_General_100_BIN2
ORDER BY RecordCount DESC;


/* ============================================================
   QUERY 341 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT COUNT(*) AS AffectedStoreTypeRows
FROM stg.Stores_Raw s
WHERE s.StoreType IS NOT NULL
  AND EXISTS
  (
      SELECT 1
      FROM stg.Stores_Raw x
      WHERE UPPER(LTRIM(RTRIM(x.StoreType)))
            = UPPER(LTRIM(RTRIM(s.StoreType)))
      GROUP BY UPPER(LTRIM(RTRIM(x.StoreType)))
      HAVING COUNT(
          DISTINCT x.StoreType COLLATE Latin1_General_100_BIN2
      ) > 1
  );


/* ============================================================
   QUERY 342 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT
    StoreType,
    COUNT(*) AS RecordCount
FROM stg.Stores_Raw
WHERE StoreType IS NOT NULL
  AND UPPER(LTRIM(RTRIM(StoreType))) NOT IN
      ('STANDARD', 'FLAGSHIP', 'EXPRESS', 'OUTLET')
GROUP BY StoreType
ORDER BY RecordCount DESC;


/* ============================================================
   QUERY 343 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT
    StoreStatus,
    COUNT(*) AS RecordCount
FROM stg.Stores_Raw
GROUP BY StoreStatus
ORDER BY RecordCount DESC;


/* ============================================================
   QUERY 344 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT COUNT(*) AS MissingStoreStatus
FROM stg.Stores_Raw
WHERE StoreStatus IS NULL;


/* ============================================================
   QUERY 345 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT COUNT(*) AS BlankStoreStatus
FROM stg.Stores_Raw
WHERE StoreStatus IS NOT NULL
  AND LTRIM(RTRIM(StoreStatus)) = '';


/* ============================================================
   QUERY 346 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT
    StoreStatus COLLATE Latin1_General_100_BIN2 AS StoreStatus,
    COUNT(*) AS RecordCount
FROM stg.Stores_Raw
GROUP BY StoreStatus COLLATE Latin1_General_100_BIN2
ORDER BY RecordCount DESC;


/* ============================================================
   QUERY 347 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT
    StoreStatus,
    COUNT(*) AS RecordCount
FROM stg.Stores_Raw
WHERE StoreStatus IS NOT NULL
  AND UPPER(LTRIM(RTRIM(StoreStatus))) NOT IN
      ('ACTIVE', 'TEMPORARILY CLOSED')
GROUP BY StoreStatus
ORDER BY RecordCount DESC;


/* ============================================================
   QUERY 348 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT COUNT(*) AS MissingManagerEmployeeID
FROM stg.Stores_Raw
WHERE ManagerEmployeeID IS NULL;


/* ============================================================
   QUERY 349 — CHECK EMPLOYEE REFERENCES
   ============================================================ */

SELECT COUNT(*) AS InvalidManagerEmployeeID
FROM stg.Stores_Raw s
WHERE s.ManagerEmployeeID IS NOT NULL
  AND NOT EXISTS
  (
      SELECT 1
      FROM stg.Employees_Raw e
      WHERE e.EmployeeID = s.ManagerEmployeeID
  );


/* ============================================================
   QUERY 350 — CHECK EMPLOYEE REFERENCES
   ============================================================ */

SELECT
    e.JobTitle,
    COUNT(*) AS StoreCount
FROM stg.Stores_Raw s
INNER JOIN stg.Employees_Raw e
    ON s.ManagerEmployeeID = e.EmployeeID
GROUP BY e.JobTitle
ORDER BY StoreCount DESC;


/* ============================================================
   QUERY 351 — CHECK SALES CHANNEL VALUES
   ============================================================ */

SELECT
    SalesChannel,
    COUNT(*) AS RecordCount
FROM stg.Stores_Raw
GROUP BY SalesChannel
ORDER BY RecordCount DESC;


/* ============================================================
   QUERY 352 — CHECK SALES CHANNEL VALUES
   ============================================================ */

SELECT COUNT(*) AS MissingSalesChannel
FROM stg.Stores_Raw
WHERE SalesChannel IS NULL;


/* ============================================================
   QUERY 353 — CHECK SALES CHANNEL VALUES
   ============================================================ */

SELECT
    SalesChannel COLLATE Latin1_General_100_BIN2 AS SalesChannel,
    COUNT(*) AS RecordCount
FROM stg.Stores_Raw
GROUP BY SalesChannel COLLATE Latin1_General_100_BIN2
ORDER BY RecordCount DESC;


/* ============================================================
   QUERY 354 — CHECK SALES CHANNEL VALUES
   ============================================================ */

SELECT
    SalesChannel,
    COUNT(*) AS RecordCount
FROM stg.Stores_Raw
WHERE SalesChannel IS NOT NULL
  AND UPPER(LTRIM(RTRIM(SalesChannel))) NOT IN
      ('OMNICHANNEL', 'PHYSICAL STORE')
GROUP BY SalesChannel
ORDER BY RecordCount DESC;


/* ============================================================
   QUERY 355 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT COUNT(*) AS BlankManagerEmployeeID
FROM stg.Stores_Raw
WHERE ManagerEmployeeID IS NOT NULL
  AND LTRIM(RTRIM(ManagerEmployeeID)) = '';


/* ============================================================
   QUERY 356 — CHECK STORE REFERENCES
   ============================================================ */

SELECT COUNT(*) AS MissingStoreID
FROM stg.Stores_Raw
WHERE StoreID IS NULL;


/* ============================================================
   QUERY 357 — CHECK STORE REFERENCES
   ============================================================ */

SELECT COUNT(*) AS BlankStoreID
FROM stg.Stores_Raw
WHERE StoreID IS NOT NULL
  AND LTRIM(RTRIM(StoreID)) = '';


/* ============================================================
   QUERY 358 — CHECK STORE REFERENCES
   ============================================================ */

SELECT
    StoreID,
    COUNT(*) AS RecordCount
FROM stg.Stores_Raw
GROUP BY StoreID
HAVING COUNT(*) > 1
ORDER BY RecordCount DESC, StoreID;


/* ============================================================
   QUERY 359 — CHECK STORE REFERENCES
   ============================================================ */

SELECT
    StoreID,
    COUNT(*) AS DuplicateRows,
    COUNT(DISTINCT StoreName COLLATE Latin1_General_100_BIN2) AS NameVariants,
    COUNT(DISTINCT StoreType COLLATE Latin1_General_100_BIN2) AS StoreTypeVariants,
    COUNT(DISTINCT City COLLATE Latin1_General_100_BIN2) AS CityVariants,
    COUNT(DISTINCT State COLLATE Latin1_General_100_BIN2) AS StateVariants,
    COUNT(DISTINCT Region COLLATE Latin1_General_100_BIN2) AS RegionVariants,
    COUNT(DISTINCT SalesChannel COLLATE Latin1_General_100_BIN2) AS SalesChannelVariants,
    COUNT(DISTINCT ManagerEmployeeID COLLATE Latin1_General_100_BIN2) AS ManagerVariants,
    COUNT(DISTINCT StoreStatus COLLATE Latin1_General_100_BIN2) AS StatusVariants
FROM stg.Stores_Raw
GROUP BY StoreID
HAVING COUNT(*) > 1
ORDER BY StoreID;


/* ============================================================
   QUERY 360 — CHECK STORE REFERENCES
   ============================================================ */

SELECT COUNT(*) AS ConflictingStoreNamesAfterNormalization
FROM
(
    SELECT
        StoreID,
        COUNT(DISTINCT
            UPPER(LTRIM(RTRIM(StoreName)))
        ) AS NormalizedNameVariants
    FROM stg.Stores_Raw
    WHERE StoreID IS NOT NULL
    GROUP BY StoreID
    HAVING COUNT(*) > 1
) s
WHERE NormalizedNameVariants > 1;


/* ============================================================
   QUERY 361 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT
    UPPER(LTRIM(RTRIM(StoreName))) AS NormalizedStoreName,
    COUNT(DISTINCT StoreName COLLATE Latin1_General_100_BIN2) AS NameVariants,
    COUNT(*) AS RecordCount
FROM stg.Stores_Raw
WHERE StoreName IS NOT NULL
GROUP BY UPPER(LTRIM(RTRIM(StoreName)))
HAVING COUNT(DISTINCT StoreName COLLATE Latin1_General_100_BIN2) > 1
ORDER BY NameVariants DESC, RecordCount DESC;


/* ============================================================
   QUERY 362 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT COUNT(*) AS AffectedStoreNameRows
FROM stg.Stores_Raw s
WHERE s.StoreName IS NOT NULL
  AND EXISTS
  (
      SELECT 1
      FROM stg.Stores_Raw x
      WHERE UPPER(LTRIM(RTRIM(x.StoreName)))
            = UPPER(LTRIM(RTRIM(s.StoreName)))
      GROUP BY UPPER(LTRIM(RTRIM(x.StoreName)))
      HAVING COUNT(
          DISTINCT x.StoreName COLLATE Latin1_General_100_BIN2
      ) > 1
  );


/* ============================================================
   QUERY 363 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT
    UPPER(LTRIM(RTRIM(City))) AS NormalizedCity,
    COUNT(DISTINCT City COLLATE Latin1_General_100_BIN2) AS CityVariants,
    COUNT(*) AS RecordCount
FROM stg.Stores_Raw
WHERE City IS NOT NULL
GROUP BY UPPER(LTRIM(RTRIM(City)))
HAVING COUNT(DISTINCT City COLLATE Latin1_General_100_BIN2) > 1
ORDER BY CityVariants DESC, RecordCount DESC;


/* ============================================================
   QUERY 364 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT
    UPPER(LTRIM(RTRIM(State))) AS NormalizedState,
    COUNT(DISTINCT State COLLATE Latin1_General_100_BIN2) AS StateVariants,
    COUNT(*) AS RecordCount
FROM stg.Stores_Raw
WHERE State IS NOT NULL
GROUP BY UPPER(LTRIM(RTRIM(State)))
HAVING COUNT(DISTINCT State COLLATE Latin1_General_100_BIN2) > 1
ORDER BY StateVariants DESC, RecordCount DESC;


/* ============================================================
   QUERY 365 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT
    State,
    COUNT(*) AS RecordCount
FROM stg.Stores_Raw
GROUP BY State
ORDER BY RecordCount DESC;


/* ============================================================
   QUERY 366 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT
    UPPER(LTRIM(RTRIM(City))) AS NormalizedCity,
    COUNT(DISTINCT State COLLATE Latin1_General_100_BIN2) AS StateCount
FROM stg.Stores_Raw
WHERE City IS NOT NULL
  AND State IS NOT NULL
GROUP BY UPPER(LTRIM(RTRIM(City)))
HAVING COUNT(DISTINCT State COLLATE Latin1_General_100_BIN2) > 1
ORDER BY StateCount DESC, NormalizedCity;


/* ============================================================
   QUERY 367 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT
    Region COLLATE Latin1_General_100_BIN2 AS Region,
    COUNT(*) AS RecordCount
FROM stg.Stores_Raw
GROUP BY Region COLLATE Latin1_General_100_BIN2
ORDER BY RecordCount DESC;


/* ============================================================
   QUERY 368 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT COUNT(*) AS AffectedStoreRegionRows
FROM stg.Stores_Raw s
WHERE s.Region IS NOT NULL
  AND EXISTS
  (
      SELECT 1
      FROM stg.Stores_Raw x
      WHERE UPPER(LTRIM(RTRIM(x.Region)))
            = UPPER(LTRIM(RTRIM(s.Region)))
      GROUP BY UPPER(LTRIM(RTRIM(x.Region)))
      HAVING COUNT(
          DISTINCT x.Region COLLATE Latin1_General_100_BIN2
      ) > 1
  );


/* ============================================================
   QUERY 369 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT
    Region,
    COUNT(*) AS RecordCount
FROM stg.Stores_Raw
WHERE Region IS NOT NULL
  AND UPPER(LTRIM(RTRIM(Region))) NOT IN
      ('NORTH', 'SOUTH', 'EAST', 'WEST')
GROUP BY Region
ORDER BY RecordCount DESC;


/* ============================================================
   QUERY 370 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT
    UPPER(LTRIM(RTRIM(State))) AS NormalizedState,
    COUNT(DISTINCT UPPER(LTRIM(RTRIM(Region)))) AS RegionCount
FROM stg.Stores_Raw
WHERE State IS NOT NULL
  AND Region IS NOT NULL
GROUP BY UPPER(LTRIM(RTRIM(State)))
HAVING COUNT(DISTINCT UPPER(LTRIM(RTRIM(Region)))) > 1
ORDER BY RegionCount DESC, NormalizedState;


/* ============================================================
   QUERY 371 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT
    COLUMN_NAME,
    DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'stg'
  AND TABLE_NAME = 'Sales_Raw'
ORDER BY ORDINAL_POSITION;


/* ============================================================
   QUERY 372 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT COUNT(*) AS MissingOrderID
FROM stg.Sales_Raw
WHERE OrderID IS NULL;


/* ============================================================
   QUERY 373 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT COUNT(*) AS BlankOrderID
FROM stg.Sales_Raw
WHERE OrderID IS NOT NULL
  AND LTRIM(RTRIM(OrderID)) = '';


/* ============================================================
   QUERY 374 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT COUNT(*) AS MissingOrderLineNumber
FROM stg.Sales_Raw
WHERE OrderLineNumber IS NULL;


/* ============================================================
   QUERY 375 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT COUNT(*) AS BlankOrderLineNumber
FROM stg.Sales_Raw
WHERE OrderLineNumber IS NOT NULL
  AND LTRIM(RTRIM(OrderLineNumber)) = '';


/* ============================================================
   QUERY 376 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT COUNT(*) AS NonNumericOrderLineNumber
FROM stg.Sales_Raw
WHERE OrderLineNumber IS NOT NULL
  AND TRY_CONVERT(INT, OrderLineNumber) IS NULL;


/* ============================================================
   QUERY 377 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT COUNT(*) AS NonPositiveOrderLineNumber
FROM stg.Sales_Raw
WHERE TRY_CONVERT(INT, OrderLineNumber) <= 0;


/* ============================================================
   QUERY 378 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT
    OrderID,
    OrderLineNumber,
    COUNT(*) AS RecordCount
FROM stg.Sales_Raw
GROUP BY
    OrderID,
    OrderLineNumber
HAVING COUNT(*) > 1
ORDER BY RecordCount DESC, OrderID, OrderLineNumber;


/* ============================================================
   QUERY 379 — CHECK QUANTITY VALUES
   ============================================================ */

SELECT
    OrderID,
    OrderLineNumber,
    COUNT(*) AS DuplicateRows,
    COUNT(DISTINCT TransactionID) AS TransactionVariants,
    COUNT(DISTINCT CustomerID) AS CustomerVariants,
    COUNT(DISTINCT ProductID) AS ProductVariants,
    COUNT(DISTINCT StoreID) AS StoreVariants,
    COUNT(DISTINCT EmployeeID) AS EmployeeVariants,
    COUNT(DISTINCT Quantity) AS QuantityVariants,
    COUNT(DISTINCT UnitPrice) AS UnitPriceVariants,
    COUNT(DISTINCT DiscountPercent) AS DiscountVariants,
    COUNT(DISTINCT TaxPercent) AS TaxVariants,
    COUNT(DISTINCT PaymentMethod) AS PaymentVariants,
    COUNT(DISTINCT SalesChannel) AS SalesChannelVariants,
    COUNT(DISTINCT OrderStatus) AS StatusVariants
FROM stg.Sales_Raw
GROUP BY
    OrderID,
    OrderLineNumber
HAVING COUNT(*) > 1
ORDER BY OrderID, OrderLineNumber;


/* ============================================================
   QUERY 380 — CHECK QUANTITY VALUES
   ============================================================ */

SELECT COUNT(*) AS ExactDuplicateGroups
FROM
(
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
    FROM stg.Sales_Raw
    GROUP BY
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
    HAVING COUNT(*) > 1
) d;


/* ============================================================
   QUERY 381 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT
    TaxPercent,
    COUNT(*) AS RecordCount
FROM stg.Sales_Raw
GROUP BY TaxPercent
ORDER BY RecordCount DESC;


/* ============================================================
   QUERY 382 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT COUNT(*) AS MissingTaxPercent
FROM stg.Sales_Raw
WHERE TaxPercent IS NULL;


/* ============================================================
   QUERY 383 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT COUNT(*) AS BlankTaxPercent
FROM stg.Sales_Raw
WHERE TaxPercent IS NOT NULL
  AND LTRIM(RTRIM(TaxPercent)) = '';


/* ============================================================
   QUERY 384 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT COUNT(*) AS NonNumericTaxPercent
FROM stg.Sales_Raw
WHERE TaxPercent IS NOT NULL
  AND TRY_CONVERT(DECIMAL(5,2), TaxPercent) IS NULL;


/* ============================================================
   QUERY 385 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT
    TRY_CONVERT(DECIMAL(5,2), TaxPercent) AS TaxPercent,
    COUNT(*) AS RecordCount
FROM stg.Sales_Raw
GROUP BY TRY_CONVERT(DECIMAL(5,2), TaxPercent)
ORDER BY TaxPercent;


/* ============================================================
   QUERY 386 — CHECK ORDER DATE VALUES
   ============================================================ */

SELECT
    COUNT(*) AS TotalRows,
    SUM(CASE
        WHEN TRY_CONVERT(date, OrderDate, 23) IS NOT NULL
          OR TRY_CONVERT(date, OrderDate, 103) IS NOT NULL
        THEN 1 ELSE 0
    END) AS ParseableRows,
    SUM(CASE
        WHEN TRY_CONVERT(date, OrderDate, 23) IS NULL
         AND TRY_CONVERT(date, OrderDate, 103) IS NULL
        THEN 1 ELSE 0
    END) AS UnparseableRows
FROM stg.Sales_Raw;


/* ============================================================
   QUERY 387 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT COUNT(*) AS MissingCustomerID
FROM stg.Sales_Raw
WHERE CustomerID IS NULL;


/* ============================================================
   QUERY 388 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT COUNT(*) AS BlankCustomerID
FROM stg.Sales_Raw
WHERE CustomerID IS NOT NULL
  AND LTRIM(RTRIM(CustomerID)) = '';


/* ============================================================
   QUERY 389 — CHECK CUSTOMER REFERENCES
   ============================================================ */

SELECT COUNT(*) AS InvalidCustomerID
FROM stg.Sales_Raw s
WHERE s.CustomerID IS NOT NULL
  AND NOT EXISTS
  (
      SELECT 1
      FROM stg.Customers_Raw c
      WHERE c.CustomerID = s.CustomerID
  );


/* ============================================================
   QUERY 390 — CHECK CUSTOMER REFERENCES
   ============================================================ */

SELECT
    s.CustomerID,
    COUNT(*) AS SalesRecordCount
FROM stg.Sales_Raw s
WHERE s.CustomerID IS NOT NULL
  AND NOT EXISTS
  (
      SELECT 1
      FROM stg.Customers_Raw c
      WHERE c.CustomerID = s.CustomerID
  )
GROUP BY s.CustomerID
ORDER BY SalesRecordCount DESC, s.CustomerID;


/* ============================================================
   QUERY 391 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT COUNT(*) AS MissingProductID
FROM stg.Sales_Raw
WHERE ProductID IS NULL;


/* ============================================================
   QUERY 392 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT COUNT(*) AS BlankProductID
FROM stg.Sales_Raw
WHERE ProductID IS NOT NULL
  AND LTRIM(RTRIM(ProductID)) = '';


/* ============================================================
   QUERY 393 — CHECK PRODUCT REFERENCES
   ============================================================ */

SELECT COUNT(*) AS InvalidProductID
FROM stg.Sales_Raw s
WHERE s.ProductID IS NOT NULL
  AND NOT EXISTS
  (
      SELECT 1
      FROM stg.Products_Raw p
      WHERE p.ProductID = s.ProductID
  );


/* ============================================================
   QUERY 394 — CHECK PRODUCT REFERENCES
   ============================================================ */

SELECT
    s.ProductID,
    COUNT(*) AS SalesRecordCount
FROM stg.Sales_Raw s
WHERE s.ProductID IS NOT NULL
  AND NOT EXISTS
  (
      SELECT 1
      FROM stg.Products_Raw p
      WHERE p.ProductID = s.ProductID
  )
GROUP BY s.ProductID
ORDER BY SalesRecordCount DESC, s.ProductID;


/* ============================================================
   QUERY 395 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT COUNT(*) AS MissingTransactionID
FROM stg.Sales_Raw
WHERE TransactionID IS NULL;


/* ============================================================
   QUERY 396 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT COUNT(*) AS MissingTransactionID
FROM stg.Sales_Raw
WHERE TransactionID IS NULL;


/* ============================================================
   QUERY 397 — PROFILE SOURCE DATA QUALITY
   ============================================================ */

SELECT COUNT(*) AS BlankTransactionID
FROM stg.Sales_Raw
WHERE TransactionID IS NOT NULL
  AND LTRIM(RTRIM(TransactionID)) = '';


/* ============================================================
   QUERY 398 — CHECK FOR DUPLICATE TRANSACTION IDS
   ============================================================ */

SELECT
    TransactionID,
    COUNT(*) AS RecordCount
FROM stg.Sales_Raw
GROUP BY TransactionID
HAVING COUNT(*) > 1
ORDER BY RecordCount DESC, TransactionID;


/* ============================================================
   QUERY 399 — CHECK FOR DUPLICATE TRANSACTION IDS
   ============================================================ */

SELECT
    TransactionID,
    COUNT(*) AS DuplicateRows,
    COUNT(DISTINCT OrderID) AS OrderVariants,
    COUNT(DISTINCT OrderLineNumber) AS LineVariants,
    COUNT(DISTINCT OrderDate) AS DateVariants,
    COUNT(DISTINCT CustomerID) AS CustomerVariants,
    COUNT(DISTINCT ProductID) AS ProductVariants,
    COUNT(DISTINCT StoreID) AS StoreVariants,
    COUNT(DISTINCT EmployeeID) AS EmployeeVariants,
    COUNT(DISTINCT Quantity) AS QuantityVariants,
    COUNT(DISTINCT UnitPrice) AS UnitPriceVariants,
    COUNT(DISTINCT DiscountPercent) AS DiscountVariants,
    COUNT(DISTINCT TaxPercent) AS TaxVariants,
    COUNT(DISTINCT PaymentMethod) AS PaymentVariants,
    COUNT(DISTINCT SalesChannel) AS SalesChannelVariants,
    COUNT(DISTINCT OrderStatus) AS StatusVariants
FROM stg.Sales_Raw
GROUP BY TransactionID
HAVING COUNT(*) > 1
ORDER BY TransactionID;


/* ============================================================
   QUERY 400 — CHECK QUANTITY VALUES
   ============================================================ */

SELECT COUNT(*) AS ExactDuplicateTransactionGroups
FROM
(
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
    FROM stg.Sales_Raw
    GROUP BY
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
    HAVING COUNT(*) > 1
) d;


/* ============================================================
   QUERY 401 — CHECK FOR DUPLICATE TRANSACTION IDS
   ============================================================ */

SELECT
    COUNT(*) AS DuplicateTransactionGroups,
    COUNT(DISTINCT TransactionID) AS DuplicateTransactionIDs,
    COUNT(DISTINCT OrderID + '|' + OrderLineNumber) AS DuplicateOrderLines
FROM stg.Sales_Raw
WHERE TransactionID IN
(
    SELECT TransactionID
    FROM stg.Sales_Raw
    GROUP BY TransactionID
    HAVING COUNT(*) > 1
);


/* ============================================================
   QUERY 402 — CHECK FOR DUPLICATE TRANSACTION IDS
   ============================================================ */

SELECT COUNT(*) AS TransactionDuplicatesNotMatchingOrderLineDuplicates
FROM
(
    SELECT DISTINCT
        TransactionID,
        OrderID,
        OrderLineNumber
    FROM stg.Sales_Raw
    WHERE TransactionID IN
    (
        SELECT TransactionID
        FROM stg.Sales_Raw
        GROUP BY TransactionID
        HAVING COUNT(*) > 1
    )
) d
WHERE NOT EXISTS
(
    SELECT 1
    FROM stg.Sales_Raw s
    GROUP BY s.OrderID, s.OrderLineNumber
    HAVING COUNT(*) > 1
       AND s.OrderID = d.OrderID
       AND s.OrderLineNumber = d.OrderLineNumber
);


/* ============================================================
   QUERY 403 — CHECK ORDER DATE VALUES
   ============================================================ */

SELECT
    SUM(CASE
        WHEN TRY_CONVERT(date, OrderDate, 23) IS NOT NULL
        THEN 1 ELSE 0
    END) AS ISO_YYYYMMDD_Rows,

    SUM(CASE
        WHEN TRY_CONVERT(date, OrderDate, 23) IS NULL
         AND TRY_CONVERT(date, OrderDate, 103) IS NOT NULL
        THEN 1 ELSE 0
    END) AS DMY_DDMMYYYY_Rows
FROM stg.Sales_Raw;

