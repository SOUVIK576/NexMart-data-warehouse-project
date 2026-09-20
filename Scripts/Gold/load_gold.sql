USE NexMartDW;
GO

/* ============================================================
   GOLD LAYER LOAD
   Source: dbo Silver tables
   Target: gld Gold tables
   ============================================================ */

/* ============================================================
   1. INSERT UNKNOWN CUSTOMER
   ============================================================ */

SET IDENTITY_INSERT gld.DimCustomer ON;

INSERT INTO gld.DimCustomer
(
    CustomerKey,
    CustomerID,
    CustomerName
)
VALUES
(
    0,
    'UNKNOWN',
    'Unknown Customer'
);

SET IDENTITY_INSERT gld.DimCustomer OFF;
GO

/* ============================================================
   2. INSERT UNKNOWN PRODUCT
   ============================================================ */

SET IDENTITY_INSERT gld.DimProduct ON;

INSERT INTO gld.DimProduct
(
    ProductKey,
    ProductID,
    ProductName
)
VALUES
(
    0,
    'UNKNOWN',
    'Unknown Product'
);

SET IDENTITY_INSERT gld.DimProduct OFF;
GO

/* ============================================================
   3. INSERT UNKNOWN STORE
   ============================================================ */

SET IDENTITY_INSERT gld.DimStore ON;

INSERT INTO gld.DimStore
(
    StoreKey,
    StoreID,
    StoreName
)
VALUES
(
    0,
    'UNKNOWN',
    'Unknown Store'
);

SET IDENTITY_INSERT gld.DimStore OFF;
GO

/* ============================================================
   4. INSERT UNKNOWN EMPLOYEE
   ============================================================ */

SET IDENTITY_INSERT gld.DimEmployee ON;

INSERT INTO gld.DimEmployee
(
    EmployeeKey,
    EmployeeID,
    EmployeeName
)
VALUES
(
    0,
    'UNKNOWN',
    'Unknown Employee'
);

SET IDENTITY_INSERT gld.DimEmployee OFF;
GO

/* ============================================================
   5. LOAD CUSTOMERS
   ============================================================ */

INSERT INTO gld.DimCustomer
(
    CustomerID,
    CustomerName,
    Gender,
    DateOfBirth,
    Email,
    Phone,
    City,
    State,
    Region,
    CustomerSegment,
    SignupDate
)
SELECT
    CustomerID,
    CustomerName,
    Gender,
    DateOfBirth,
    Email,
    Phone,
    City,
    State,
    Region,
    CustomerSegment,
    SignupDate
FROM dbo.Customers_Silver;
GO

/* ============================================================
   6. LOAD PRODUCTS
   ============================================================ */

INSERT INTO gld.DimProduct
(
    ProductID,
    ProductName,
    Category,
    SubCategory,
    Brand,
    Supplier,
    LaunchDate,
    ProductStatus,
    UnitCost,
    UnitPrice
)
SELECT
    ProductID,
    ProductName,
    Category,
    SubCategory,
    Brand,
    Supplier,
    LaunchDate,
    ProductStatus,
    UnitCost,
    UnitPrice
FROM dbo.Products_Silver;
GO

/* ============================================================
   7. LOAD STORES
   ============================================================ */

INSERT INTO gld.DimStore
(
    StoreID,
    StoreName,
    StoreType,
    City,
    State,
    Region,
    SalesChannel,
    ManagerEmployeeID,
    StoreStatus
)
SELECT
    StoreID,
    StoreName,
    StoreType,
    City,
    State,
    Region,
    SalesChannel,
    ManagerEmployeeID,
    StoreStatus
FROM dbo.Stores_Silver;
GO

/* ============================================================
   8. LOAD EMPLOYEES
   ============================================================ */

INSERT INTO gld.DimEmployee
(
    EmployeeID,
    EmployeeName,
    Gender,
    JobTitle,
    Department,
    StoreID,
    Region,
    EmploymentStatus,
    HireDate
)
SELECT
    EmployeeID,
    EmployeeName,
    Gender,
    JobTitle,
    Department,
    StoreID,
    Region,
    EmploymentStatus,
    HireDate
FROM dbo.Employees_Silver;
GO

/* ============================================================
   9. LOAD DATE DIMENSION
   Sales range:
   2023-01-01 → 2026-06-30
   ============================================================ */

;WITH DateSeries AS
(
    SELECT CAST('2023-01-01' AS DATE) AS FullDate

    UNION ALL

    SELECT DATEADD(DAY, 1, FullDate)
    FROM DateSeries
    WHERE FullDate < '2026-06-30'
)
INSERT INTO gld.DimDate
(
    DateKey,
    FullDate,
    [Year],
    [Quarter],
    [Month],
    MonthName,
    MonthNumber,
    [Week],
    [Day],
    DayName
)
SELECT
    CONVERT(INT, CONVERT(CHAR(8), FullDate, 112)),
    FullDate,
    YEAR(FullDate),
    DATEPART(QUARTER, FullDate),
    MONTH(FullDate),
    DATENAME(MONTH, FullDate),
    MONTH(FullDate),
    DATEPART(ISO_WEEK, FullDate),
    DAY(FullDate),
    DATENAME(WEEKDAY, FullDate)
FROM DateSeries
OPTION (MAXRECURSION 0);
GO

/* ============================================================
   10. LOAD FACT SALES
   ============================================================ */

INSERT INTO gld.FactSales
(
    TransactionID,
    OrderID,
    OrderLineNumber,

    DateKey,
    CustomerKey,
    ProductKey,
    StoreKey,
    EmployeeKey,

    Quantity,
    UnitPrice,
    DiscountPercent,
    TaxPercent,

    PaymentMethod,
    SalesChannel,
    OrderStatus
)
SELECT
    s.TransactionID,
    s.OrderID,
    s.OrderLineNumber,

    d.DateKey,

    COALESCE(c.CustomerKey, 0) AS CustomerKey,
    COALESCE(p.ProductKey, 0) AS ProductKey,
    COALESCE(st.StoreKey, 0) AS StoreKey,
    COALESCE(e.EmployeeKey, 0) AS EmployeeKey,

    s.Quantity,
    s.UnitPrice,
    s.DiscountPercent,
    s.TaxPercent,

    s.PaymentMethod,
    s.SalesChannel,
    s.OrderStatus

FROM dbo.Sales_Silver s

LEFT JOIN gld.DimDate d
    ON d.FullDate = s.OrderDate

LEFT JOIN gld.DimCustomer c
    ON c.CustomerID = s.CustomerID

LEFT JOIN gld.DimProduct p
    ON p.ProductID = s.ProductID

LEFT JOIN gld.DimStore st
    ON st.StoreID = s.StoreID

LEFT JOIN gld.DimEmployee e
    ON e.EmployeeID = s.EmployeeID;
GO

/* ============================================================
   11. CREATE FACT-TO-DIMENSION FOREIGN KEYS
   ============================================================ */

ALTER TABLE gld.FactSales
ADD CONSTRAINT FK_FactSales_DimCustomer
    FOREIGN KEY (CustomerKey)
    REFERENCES gld.DimCustomer(CustomerKey);
GO

ALTER TABLE gld.FactSales
ADD CONSTRAINT FK_FactSales_DimProduct
    FOREIGN KEY (ProductKey)
    REFERENCES gld.DimProduct(ProductKey);
GO

ALTER TABLE gld.FactSales
ADD CONSTRAINT FK_FactSales_DimStore
    FOREIGN KEY (StoreKey)
    REFERENCES gld.DimStore(StoreKey);
GO

ALTER TABLE gld.FactSales
ADD CONSTRAINT FK_FactSales_DimEmployee
    FOREIGN KEY (EmployeeKey)
    REFERENCES gld.DimEmployee(EmployeeKey);
GO

ALTER TABLE gld.FactSales
ADD CONSTRAINT FK_FactSales_DimDate
    FOREIGN KEY (DateKey)
    REFERENCES gld.DimDate(DateKey);
GO
