USE NexMartDW;
GO

/* ============================================================
   BRONZE TESTS
   Purpose:
   Independent regression checks for the raw/staging layer.
   Bronze data must remain raw and structurally intact.
   ============================================================ */

/* ------------------------------------------------------------
   1. Expected Bronze row counts
   Expected source counts:
   Customers = 15,150
   Products  = 515
   Stores    = 52
   Employees = 300
   Sales     = 420,306
   ------------------------------------------------------------ */

SELECT
    'Customers_Raw' AS TableName,
    COUNT(*) AS ActualRowCount,
    15150 AS ExpectedRowCount,
    CASE WHEN COUNT(*) = 15150 THEN 'PASS' ELSE 'FAIL' END AS TestResult
FROM stg.Customers_Raw

UNION ALL

SELECT
    'Products_Raw',
    COUNT(*),
    515,
    CASE WHEN COUNT(*) = 515 THEN 'PASS' ELSE 'FAIL' END
FROM stg.Products_Raw

UNION ALL

SELECT
    'Stores_Raw',
    COUNT(*),
    52,
    CASE WHEN COUNT(*) = 52 THEN 'PASS' ELSE 'FAIL' END
FROM stg.Stores_Raw

UNION ALL

SELECT
    'Employees_Raw',
    COUNT(*),
    300,
    CASE WHEN COUNT(*) = 300 THEN 'PASS' ELSE 'FAIL' END
FROM stg.Employees_Raw

UNION ALL

SELECT
    'Sales_Raw',
    COUNT(*),
    420306,
    CASE WHEN COUNT(*) = 420306 THEN 'PASS' ELSE 'FAIL' END
FROM stg.Sales_Raw;
GO

/* ------------------------------------------------------------
   2. Required raw business keys must exist
   These checks are structural checks only.
   Raw duplicates are allowed and are handled downstream.
   ------------------------------------------------------------ */

SELECT
    'Customers_Raw CustomerID missing' AS TestName,
    COUNT(*) AS FailureCount
FROM stg.Customers_Raw
WHERE CustomerID IS NULL
   OR LTRIM(RTRIM(CustomerID)) = ''

UNION ALL

SELECT
    'Products_Raw ProductID missing',
    COUNT(*)
FROM stg.Products_Raw
WHERE ProductID IS NULL
   OR LTRIM(RTRIM(ProductID)) = ''

UNION ALL

SELECT
    'Stores_Raw StoreID missing',
    COUNT(*)
FROM stg.Stores_Raw
WHERE StoreID IS NULL
   OR LTRIM(RTRIM(StoreID)) = ''

UNION ALL

SELECT
    'Employees_Raw EmployeeID missing',
    COUNT(*)
FROM stg.Employees_Raw
WHERE EmployeeID IS NULL
   OR LTRIM(RTRIM(EmployeeID)) = ''

UNION ALL

SELECT
    'Sales_Raw TransactionID missing',
    COUNT(*)
FROM stg.Sales_Raw
WHERE TransactionID IS NULL
   OR LTRIM(RTRIM(TransactionID)) = '';
GO

/* ------------------------------------------------------------
   3. Bronze tables must exist
   ------------------------------------------------------------ */

SELECT
    RequiredTable,
    CASE
        WHEN EXISTS
        (
            SELECT 1
            FROM sys.tables t
            INNER JOIN sys.schemas s
                ON t.schema_id = s.schema_id
            WHERE s.name = 'stg'
              AND t.name = RequiredTable
        )
        THEN 'PASS'
        ELSE 'FAIL'
    END AS TestResult
FROM
(
    VALUES
        ('Customers_Raw'),
        ('Products_Raw'),
        ('Stores_Raw'),
        ('Employees_Raw'),
        ('Sales_Raw')
) v(RequiredTable);
GO
