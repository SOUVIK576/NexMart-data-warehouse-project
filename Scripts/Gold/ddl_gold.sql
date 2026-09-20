USE NexMartDW;
GO

/* ============================================================
   GOLD LAYER DDL
   Source: dbo Silver tables
   Target: gld Gold schema
   ============================================================ */

/* ============================================================
   1. CREATE GOLD SCHEMA
   ============================================================ */

IF NOT EXISTS
(
    SELECT 1
    FROM sys.schemas
    WHERE name = 'gld'
)
BEGIN
    EXEC('CREATE SCHEMA gld');
END;
GO

/* ============================================================
   2. DIM CUSTOMER
   ============================================================ */

CREATE TABLE gld.DimCustomer
(
    CustomerKey INT IDENTITY(1,1) NOT NULL,
    CustomerID VARCHAR(20) NOT NULL,
    CustomerName VARCHAR(150) NULL,
    Gender VARCHAR(20) NULL,
    DateOfBirth DATE NULL,
    Email VARCHAR(150) NULL,
    Phone VARCHAR(30) NULL,
    City VARCHAR(100) NULL,
    State VARCHAR(100) NULL,
    Region VARCHAR(50) NULL,
    CustomerSegment VARCHAR(50) NULL,
    SignupDate DATE NULL,

    CONSTRAINT PK_DimCustomer
        PRIMARY KEY (CustomerKey),

    CONSTRAINT UQ_DimCustomer_CustomerID
        UNIQUE (CustomerID)
);
GO

/* ============================================================
   3. DIM PRODUCT
   ============================================================ */

CREATE TABLE gld.DimProduct
(
    ProductKey INT IDENTITY(1,1) NOT NULL,
    ProductID VARCHAR(20) NOT NULL,
    ProductName VARCHAR(200) NULL,
    Category VARCHAR(100) NULL,
    SubCategory VARCHAR(100) NULL,
    Brand VARCHAR(100) NULL,
    Supplier VARCHAR(150) NULL,
    LaunchDate DATE NULL,
    ProductStatus VARCHAR(30) NULL,
    UnitCost DECIMAL(18,2) NULL,
    UnitPrice DECIMAL(18,2) NULL,

    CONSTRAINT PK_DimProduct
        PRIMARY KEY (ProductKey),

    CONSTRAINT UQ_DimProduct_ProductID
        UNIQUE (ProductID)
);
GO

/* ============================================================
   4. DIM STORE
   ============================================================ */

CREATE TABLE gld.DimStore
(
    StoreKey INT IDENTITY(1,1) NOT NULL,
    StoreID VARCHAR(20) NOT NULL,
    StoreName VARCHAR(150) NULL,
    StoreType VARCHAR(50) NULL,
    City VARCHAR(100) NULL,
    State VARCHAR(100) NULL,
    Region VARCHAR(50) NULL,
    SalesChannel VARCHAR(50) NULL,
    ManagerEmployeeID VARCHAR(20) NULL,
    StoreStatus VARCHAR(50) NULL,

    CONSTRAINT PK_DimStore
        PRIMARY KEY (StoreKey),

    CONSTRAINT UQ_DimStore_StoreID
        UNIQUE (StoreID)
);
GO

/* ============================================================
   5. DIM EMPLOYEE
   ============================================================ */

CREATE TABLE gld.DimEmployee
(
    EmployeeKey INT IDENTITY(1,1) NOT NULL,
    EmployeeID VARCHAR(20) NOT NULL,
    EmployeeName VARCHAR(150) NULL,
    Gender VARCHAR(20) NULL,
    JobTitle VARCHAR(100) NULL,
    Department VARCHAR(100) NULL,
    StoreID VARCHAR(20) NULL,
    Region VARCHAR(50) NULL,
    EmploymentStatus VARCHAR(50) NULL,
    HireDate DATE NULL,

    CONSTRAINT PK_DimEmployee
        PRIMARY KEY (EmployeeKey),

    CONSTRAINT UQ_DimEmployee_EmployeeID
        UNIQUE (EmployeeID)
);
GO

/* ============================================================
   6. DIM DATE
   ============================================================ */

CREATE TABLE gld.DimDate
(
    DateKey INT NOT NULL,
    FullDate DATE NOT NULL,
    [Year] INT NOT NULL,
    [Quarter] INT NOT NULL,
    [Month] INT NOT NULL,
    MonthName VARCHAR(20) NOT NULL,
    MonthNumber INT NOT NULL,
    [Week] INT NOT NULL,
    [Day] INT NOT NULL,
    DayName VARCHAR(20) NOT NULL,

    CONSTRAINT PK_DimDate
        PRIMARY KEY (DateKey),

    CONSTRAINT UQ_DimDate_FullDate
        UNIQUE (FullDate)
);
GO

/* ============================================================
   7. FACT SALES
   ============================================================ */

CREATE TABLE gld.FactSales
(
    SalesKey INT IDENTITY(1,1) NOT NULL,

    TransactionID VARCHAR(30) NOT NULL,
    OrderID VARCHAR(30) NULL,
    OrderLineNumber INT NOT NULL,

    DateKey INT NOT NULL,
    CustomerKey INT NOT NULL,
    ProductKey INT NOT NULL,
    StoreKey INT NOT NULL,
    EmployeeKey INT NOT NULL,

    Quantity INT NULL,
    UnitPrice DECIMAL(18,2) NULL,
    DiscountPercent DECIMAL(5,2) NULL,
    TaxPercent DECIMAL(5,2) NULL,

    PaymentMethod VARCHAR(50) NULL,
    SalesChannel VARCHAR(50) NULL,
    OrderStatus VARCHAR(50) NULL,

    CONSTRAINT PK_FactSales
        PRIMARY KEY (SalesKey),

    CONSTRAINT UQ_FactSales_TransactionID
        UNIQUE (TransactionID)
);
GO
