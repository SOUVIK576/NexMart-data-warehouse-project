USE NexMartDW;
GO

/* ============================================================
   SILVER TESTS
   Purpose:
   Independent regression checks for the final Silver layer.
   Detailed transformation validation remains inside the
   entity-specific Silver scripts.
   ============================================================ */

/* ------------------------------------------------------------
   1. Final Silver row counts
   ------------------------------------------------------------ */

SELECT
    'Customers_Silver' AS TableName,
    COUNT(*) AS ActualRowCount,
    15000 AS ExpectedRowCount,
    CASE WHEN COUNT(*) = 15000 THEN 'PASS' ELSE 'FAIL' END AS TestResult
FROM dbo.Customers_Silver

UNION ALL

SELECT
    'Products_Silver',
    COUNT(*),
    500,
    CASE WHEN COUNT(*) = 500 THEN 'PASS' ELSE 'FAIL' END
FROM dbo.Products_Silver

UNION ALL

SELECT
    'Stores_Silver',
    COUNT(*),
    50,
    CASE WHEN COUNT(*) = 50 THEN 'PASS' ELSE 'FAIL' END
FROM dbo.Stores_Silver

UNION ALL

SELECT
    'Employees_Silver',
    COUNT(*),
    300,
    CASE WHEN COUNT(*) = 300 THEN 'PASS' ELSE 'FAIL' END
FROM dbo.Employees_Silver

UNION ALL

SELECT
    'Sales_Silver',
    COUNT(*),
    420006,
    CASE WHEN COUNT(*) = 420006 THEN 'PASS' ELSE 'FAIL' END
FROM dbo.Sales_Silver;
GO

/* ------------------------------------------------------------
   2. Silver business-key uniqueness
   ------------------------------------------------------------ */

SELECT
    'Customers_Silver' AS TableName,
    COUNT(*) - COUNT(DISTINCT CustomerID) AS DuplicateKeyCount
FROM dbo.Customers_Silver

UNION ALL

SELECT
    'Products_Silver',
    COUNT(*) - COUNT(DISTINCT ProductID)
FROM dbo.Products_Silver

UNION ALL

SELECT
    'Stores_Silver',
    COUNT(*) - COUNT(DISTINCT StoreID)
FROM dbo.Stores_Silver

UNION ALL

SELECT
    'Employees_Silver',
    COUNT(*) - COUNT(DISTINCT EmployeeID)
FROM dbo.Employees_Silver

UNION ALL

SELECT
    'Sales_Silver',
    COUNT(*) - COUNT(DISTINCT TransactionID)
FROM dbo.Sales_Silver;
GO

/* ------------------------------------------------------------
   3. Required Silver business keys must be populated
   ------------------------------------------------------------ */

SELECT
    'Customers_Silver CustomerID' AS TestName,
    COUNT(*) AS FailureCount
FROM dbo.Customers_Silver
WHERE CustomerID IS NULL
   OR LTRIM(RTRIM(CustomerID)) = ''

UNION ALL

SELECT
    'Products_Silver ProductID',
    COUNT(*)
FROM dbo.Products_Silver
WHERE ProductID IS NULL
   OR LTRIM(RTRIM(ProductID)) = ''

UNION ALL

SELECT
    'Stores_Silver StoreID',
    COUNT(*)
FROM dbo.Stores_Silver
WHERE StoreID IS NULL
   OR LTRIM(RTRIM(StoreID)) = ''

UNION ALL

SELECT
    'Employees_Silver EmployeeID',
    COUNT(*)
FROM dbo.Employees_Silver
WHERE EmployeeID IS NULL
   OR LTRIM(RTRIM(EmployeeID)) = ''

UNION ALL

SELECT
    'Sales_Silver TransactionID',
    COUNT(*)
FROM dbo.Sales_Silver
WHERE TransactionID IS NULL
   OR LTRIM(RTRIM(TransactionID)) = '';
GO

/* ------------------------------------------------------------
   4. Quality-status completeness
   Every applicable Silver row must have a quality classification.
   ------------------------------------------------------------ */

SELECT
    'Sales CustomerQualityStatus' AS TestName,
    COUNT(*) AS FailureCount
FROM dbo.Sales_Silver
WHERE CustomerQualityStatus IS NULL

UNION ALL

SELECT
    'Sales ProductQualityStatus',
    COUNT(*)
FROM dbo.Sales_Silver
WHERE ProductQualityStatus IS NULL

UNION ALL

SELECT
    'Sales StoreQualityStatus',
    COUNT(*)
FROM dbo.Sales_Silver
WHERE StoreQualityStatus IS NULL

UNION ALL

SELECT
    'Sales EmployeeQualityStatus',
    COUNT(*)
FROM dbo.Sales_Silver
WHERE EmployeeQualityStatus IS NULL

UNION ALL

SELECT
    'Sales QuantityQualityStatus',
    COUNT(*)
FROM dbo.Sales_Silver
WHERE QuantityQualityStatus IS NULL

UNION ALL

SELECT
    'Sales UnitPriceQualityStatus',
    COUNT(*)
FROM dbo.Sales_Silver
WHERE UnitPriceQualityStatus IS NULL

UNION ALL

SELECT
    'Products UnitCostQualityStatus',
    COUNT(*)
FROM dbo.Products_Silver
WHERE UnitCostQualityStatus IS NULL

UNION ALL

SELECT
    'Products SupplierQualityStatus',
    COUNT(*)
FROM dbo.Products_Silver
WHERE SupplierQualityStatus IS NULL

UNION ALL

SELECT
    'Employees StoreQualityStatus',
    COUNT(*)
FROM dbo.Employees_Silver
WHERE StoreQualityStatus IS NULL

UNION ALL

SELECT
    'Customers GenderQualityStatus',
    COUNT(*)
FROM dbo.Customers_Silver
WHERE GenderQualityStatus IS NULL

UNION ALL

SELECT
    'Customers EmailQualityStatus',
    COUNT(*)
FROM dbo.Customers_Silver
WHERE EmailQualityStatus IS NULL

UNION ALL

SELECT
    'Customers PhoneQualityStatus',
    COUNT(*)
FROM dbo.Customers_Silver
WHERE PhoneQualityStatus IS NULL

UNION ALL

SELECT
    'Customers CustomerSegmentQualityStatus',
    COUNT(*)
FROM dbo.Customers_Silver
WHERE CustomerSegmentQualityStatus IS NULL;
GO

/* ------------------------------------------------------------
   5. Final Sales date range
   ------------------------------------------------------------ */

SELECT
    MIN(OrderDate) AS EarliestOrderDate,
    MAX(OrderDate) AS LatestOrderDate,
    CASE
        WHEN MIN(OrderDate) = '2023-01-01'
         AND MAX(OrderDate) = '2026-06-30'
        THEN 'PASS'
        ELSE 'FAIL'
    END AS TestResult
FROM dbo.Sales_Silver;
GO

/* ------------------------------------------------------------
   6. Key referential-integrity regression checks
   Only invalid non-NULL references are tested here.
   Known missing/invalid Sales references are expected source
   conditions and are handled through quality status + Gold
   Unknown members.
   ------------------------------------------------------------ */

SELECT
    'Sales -> Customers' AS Relationship,
    COUNT(*) AS InvalidReferenceCount
FROM dbo.Sales_Silver s
LEFT JOIN dbo.Customers_Silver c
    ON c.CustomerID = s.CustomerID
WHERE s.CustomerID IS NOT NULL
  AND c.CustomerID IS NULL

UNION ALL

SELECT
    'Sales -> Products',
    COUNT(*)
FROM dbo.Sales_Silver s
LEFT JOIN dbo.Products_Silver p
    ON p.ProductID = s.ProductID
WHERE s.ProductID IS NOT NULL
  AND p.ProductID IS NULL

UNION ALL

SELECT
    'Sales -> Stores',
    COUNT(*)
FROM dbo.Sales_Silver s
LEFT JOIN dbo.Stores_Silver st
    ON st.StoreID = s.StoreID
WHERE s.StoreID IS NOT NULL
  AND st.StoreID IS NULL

UNION ALL

SELECT
    'Sales -> Employees',
    COUNT(*)
FROM dbo.Sales_Silver s
LEFT JOIN dbo.Employees_Silver e
    ON e.EmployeeID = s.EmployeeID
WHERE s.EmployeeID IS NOT NULL
  AND e.EmployeeID IS NULL

UNION ALL

SELECT
    'Stores -> Employees',
    COUNT(*)
FROM dbo.Stores_Silver st
LEFT JOIN dbo.Employees_Silver e
    ON e.EmployeeID = st.ManagerEmployeeID
WHERE st.ManagerEmployeeID IS NOT NULL
  AND e.EmployeeID IS NULL

UNION ALL

SELECT
    'Employees -> Stores',
    COUNT(*)
FROM dbo.Employees_Silver e
LEFT JOIN dbo.Stores_Silver st
    ON st.StoreID = e.StoreID
WHERE e.StoreID IS NOT NULL
  AND st.StoreID IS NULL;
GO
