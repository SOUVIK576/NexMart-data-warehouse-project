USE NexMartDW;
GO

/* ============================================================
   GOLD TESTS
   Purpose:
   Independent regression checks for the final Gold layer.
   ============================================================ */

/* ------------------------------------------------------------
   1. Gold dimension row counts
   ------------------------------------------------------------ */

SELECT
    'DimCustomer' AS TableName,
    COUNT(*) AS ActualRowCount,
    15001 AS ExpectedRowCount,
    CASE WHEN COUNT(*) = 15001 THEN 'PASS' ELSE 'FAIL' END AS TestResult
FROM gld.DimCustomer

UNION ALL

SELECT
    'DimProduct',
    COUNT(*),
    501,
    CASE WHEN COUNT(*) = 501 THEN 'PASS' ELSE 'FAIL' END
FROM gld.DimProduct

UNION ALL

SELECT
    'DimStore',
    COUNT(*),
    51,
    CASE WHEN COUNT(*) = 51 THEN 'PASS' ELSE 'FAIL' END
FROM gld.DimStore

UNION ALL

SELECT
    'DimEmployee',
    COUNT(*),
    301,
    CASE WHEN COUNT(*) = 301 THEN 'PASS' ELSE 'FAIL' END
FROM gld.DimEmployee

UNION ALL

SELECT
    'DimDate',
    COUNT(*),
    1277,
    CASE WHEN COUNT(*) = 1277 THEN 'PASS' ELSE 'FAIL' END
FROM gld.DimDate

UNION ALL

SELECT
    'FactSales',
    COUNT(*),
    420006,
    CASE WHEN COUNT(*) = 420006 THEN 'PASS' ELSE 'FAIL' END
FROM gld.FactSales;
GO

/* ------------------------------------------------------------
   2. Unknown dimension members
   ------------------------------------------------------------ */

SELECT
    'DimCustomer' AS TableName,
    CustomerKey,
    CustomerID,
    CustomerName
FROM gld.DimCustomer
WHERE CustomerKey = 0

UNION ALL

SELECT
    'DimProduct',
    ProductKey,
    ProductID,
    ProductName
FROM gld.DimProduct
WHERE ProductKey = 0

UNION ALL

SELECT
    'DimStore',
    StoreKey,
    StoreID,
    StoreName
FROM gld.DimStore
WHERE StoreKey = 0

UNION ALL

SELECT
    'DimEmployee',
    EmployeeKey,
    EmployeeID,
    EmployeeName
FROM gld.DimEmployee
WHERE EmployeeKey = 0;
GO

/* ------------------------------------------------------------
   3. Business-key uniqueness in dimensions
   Unknown members are excluded.
   ------------------------------------------------------------ */

SELECT
    'DimCustomer' AS TableName,
    COUNT(*) AS TotalRealMembers,
    COUNT(DISTINCT CustomerID) AS DistinctBusinessKeys,
    CASE
        WHEN COUNT(*) = COUNT(DISTINCT CustomerID)
        THEN 'PASS'
        ELSE 'FAIL'
    END AS TestResult
FROM gld.DimCustomer
WHERE CustomerKey <> 0

UNION ALL

SELECT
    'DimProduct',
    COUNT(*),
    COUNT(DISTINCT ProductID),
    CASE
        WHEN COUNT(*) = COUNT(DISTINCT ProductID)
        THEN 'PASS'
        ELSE 'FAIL'
    END
FROM gld.DimProduct
WHERE ProductKey <> 0

UNION ALL

SELECT
    'DimStore',
    COUNT(*),
    COUNT(DISTINCT StoreID),
    CASE
        WHEN COUNT(*) = COUNT(DISTINCT StoreID)
        THEN 'PASS'
        ELSE 'FAIL'
    END
FROM gld.DimStore
WHERE StoreKey <> 0

UNION ALL

SELECT
    'DimEmployee',
    COUNT(*),
    COUNT(DISTINCT EmployeeID),
    CASE
        WHEN COUNT(*) = COUNT(DISTINCT EmployeeID)
        THEN 'PASS'
        ELSE 'FAIL'
    END
FROM gld.DimEmployee
WHERE EmployeeKey <> 0;
GO

/* ------------------------------------------------------------
   4. DimDate completeness and uniqueness
   ------------------------------------------------------------ */

SELECT
    COUNT(*) AS TotalDates,
    COUNT(DISTINCT FullDate) AS DistinctDates,
    MIN(FullDate) AS EarliestDate,
    MAX(FullDate) AS LatestDate,
    CASE
        WHEN COUNT(*) = 1277
         AND COUNT(DISTINCT FullDate) = 1277
         AND MIN(FullDate) = '2023-01-01'
         AND MAX(FullDate) = '2026-06-30'
        THEN 'PASS'
        ELSE 'FAIL'
    END AS TestResult
FROM gld.DimDate;
GO

/* ------------------------------------------------------------
   5. DimDate gap check
   Expected result: zero missing dates.
   ------------------------------------------------------------ */

SELECT
    COUNT(*) AS MissingDateCount,
    CASE
        WHEN COUNT(*) = 0 THEN 'PASS'
        ELSE 'FAIL'
    END AS TestResult
FROM
(
    SELECT
        DATEADD(DAY, 1, d1.FullDate) AS MissingDate
    FROM gld.DimDate d1
    LEFT JOIN gld.DimDate d2
        ON d2.FullDate = DATEADD(DAY, 1, d1.FullDate)
    WHERE d1.FullDate < '2026-06-30'
      AND d2.FullDate IS NULL
) x;
GO

/* ------------------------------------------------------------
   6. FactSales TransactionID uniqueness
   ------------------------------------------------------------ */

SELECT
    COUNT(*) AS TotalFactRows,
    COUNT(DISTINCT TransactionID) AS DistinctTransactions,
    COUNT(*) - COUNT(DISTINCT TransactionID) AS DuplicateTransactionCount,
    CASE
        WHEN COUNT(*) = COUNT(DISTINCT TransactionID)
        THEN 'PASS'
        ELSE 'FAIL'
    END AS TestResult
FROM gld.FactSales;
GO

/* ------------------------------------------------------------
   7. FactSales reconciliation with Sales Silver
   ------------------------------------------------------------ */

SELECT
    (SELECT COUNT(*) FROM dbo.Sales_Silver) AS SilverSalesRows,
    (SELECT COUNT(*) FROM gld.FactSales) AS GoldFactRows,
    (SELECT COUNT(*) FROM dbo.Sales_Silver)
      - (SELECT COUNT(*) FROM gld.FactSales) AS RowDifference,
    CASE
        WHEN
            (SELECT COUNT(*) FROM dbo.Sales_Silver)
            =
            (SELECT COUNT(*) FROM gld.FactSales)
        THEN 'PASS'
        ELSE 'FAIL'
    END AS TestResult;
GO

/* ------------------------------------------------------------
   8. Required FactSales dimension keys must not be NULL
   ------------------------------------------------------------ */

SELECT
    COUNT(*) AS TotalFactRows,
    SUM(CASE WHEN DateKey IS NULL THEN 1 ELSE 0 END) AS NullDateKeys,
    SUM(CASE WHEN CustomerKey IS NULL THEN 1 ELSE 0 END) AS NullCustomerKeys,
    SUM(CASE WHEN ProductKey IS NULL THEN 1 ELSE 0 END) AS NullProductKeys,
    SUM(CASE WHEN StoreKey IS NULL THEN 1 ELSE 0 END) AS NullStoreKeys,
    SUM(CASE WHEN EmployeeKey IS NULL THEN 1 ELSE 0 END) AS NullEmployeeKeys,
    CASE
        WHEN SUM(CASE WHEN DateKey IS NULL THEN 1 ELSE 0 END) = 0
         AND SUM(CASE WHEN CustomerKey IS NULL THEN 1 ELSE 0 END) = 0
         AND SUM(CASE WHEN ProductKey IS NULL THEN 1 ELSE 0 END) = 0
         AND SUM(CASE WHEN StoreKey IS NULL THEN 1 ELSE 0 END) = 0
         AND SUM(CASE WHEN EmployeeKey IS NULL THEN 1 ELSE 0 END) = 0
        THEN 'PASS'
        ELSE 'FAIL'
    END AS TestResult
FROM gld.FactSales;
GO

/* ------------------------------------------------------------
   9. FactSales -> dimension referential integrity
   Expected invalid references: 0
   ------------------------------------------------------------ */

SELECT
    'Customer' AS DimensionName,
    COUNT(*) AS InvalidReferences
FROM gld.FactSales f
LEFT JOIN gld.DimCustomer d
    ON f.CustomerKey = d.CustomerKey
WHERE f.CustomerKey <> 0
  AND d.CustomerKey IS NULL

UNION ALL

SELECT
    'Product',
    COUNT(*)
FROM gld.FactSales f
LEFT JOIN gld.DimProduct d
    ON f.ProductKey = d.ProductKey
WHERE f.ProductKey <> 0
  AND d.ProductKey IS NULL

UNION ALL

SELECT
    'Store',
    COUNT(*)
FROM gld.FactSales f
LEFT JOIN gld.DimStore d
    ON f.StoreKey = d.StoreKey
WHERE f.StoreKey <> 0
  AND d.StoreKey IS NULL

UNION ALL

SELECT
    'Employee',
    COUNT(*)
FROM gld.FactSales f
LEFT JOIN gld.DimEmployee d
    ON f.EmployeeKey = d.EmployeeKey
WHERE f.EmployeeKey <> 0
  AND d.EmployeeKey IS NULL

UNION ALL

SELECT
    'Date',
    COUNT(*)
FROM gld.FactSales f
LEFT JOIN gld.DimDate d
    ON f.DateKey = d.DateKey
WHERE f.DateKey <> 0
  AND d.DateKey IS NULL;
GO

/* ------------------------------------------------------------
   10. Expected Unknown-member mappings
   These values are based on the completed Project 1 load.
   ------------------------------------------------------------ */

SELECT
    COUNT(*) AS TotalFactRows,
    SUM(CASE WHEN CustomerKey = 0 THEN 1 ELSE 0 END)
        AS UnknownCustomerRows,
    SUM(CASE WHEN ProductKey = 0 THEN 1 ELSE 0 END)
        AS UnknownProductRows,
    SUM(CASE WHEN StoreKey = 0 THEN 1 ELSE 0 END)
        AS UnknownStoreRows,
    SUM(CASE WHEN EmployeeKey = 0 THEN 1 ELSE 0 END)
        AS UnknownEmployeeRows,
    SUM(CASE WHEN DateKey = 0 THEN 1 ELSE 0 END)
        AS UnknownDateRows
FROM gld.FactSales;
GO

/* ------------------------------------------------------------
   11. FactSales TransactionID completeness
   ------------------------------------------------------------ */

SELECT
    COUNT(*) AS MissingTransactionIDCount,
    CASE
        WHEN COUNT(*) = 0 THEN 'PASS'
        ELSE 'FAIL'
    END AS TestResult
FROM gld.FactSales
WHERE TransactionID IS NULL
   OR LTRIM(RTRIM(TransactionID)) = '';
GO

/* ------------------------------------------------------------
   12. Verify required Gold foreign keys exist
   ------------------------------------------------------------ */

SELECT
    fk.name AS ForeignKeyName,
    OBJECT_SCHEMA_NAME(fk.parent_object_id) AS ParentSchema,
    OBJECT_NAME(fk.parent_object_id) AS ParentTable,
    OBJECT_SCHEMA_NAME(fk.referenced_object_id) AS ReferencedSchema,
    OBJECT_NAME(fk.referenced_object_id) AS ReferencedTable
FROM sys.foreign_keys fk
WHERE fk.parent_object_id = OBJECT_ID('gld.FactSales')
ORDER BY fk.name;
GO
