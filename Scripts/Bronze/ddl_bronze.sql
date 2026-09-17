-- NexMart Enterprise Data Warehouse
-- Bronze Layer: Database, schema, and raw staging table definitions


Use master;
GO

CREATE DATABASE NexMartDW;
GO

USE NexMartDW;
GO

CREATE SCHEMA stg;
GO

CREATE TABLE stg.Customers_Raw
(
    CustomerID          VARCHAR(20),
    CustomerName        VARCHAR(150),
    Gender              VARCHAR(20),
    DateOfBirth         VARCHAR(30),
    Email               VARCHAR(150),
    Phone               VARCHAR(30),
    City                VARCHAR(100),
    State               VARCHAR(100),
    Region              VARCHAR(50),
    SignupDate          VARCHAR(30),
    CustomerSegment     VARCHAR(50)
);
GO

USE NexMartDW;
GO

DROP TABLE dbo.NexMart_Customers_Raw;
GO

CREATE TABLE stg.Products_Raw
(
    ProductID        VARCHAR(20),
    ProductName      VARCHAR(200),
    Category         VARCHAR(100),
    SubCategory      VARCHAR(100),
    Brand            VARCHAR(100),
    UnitCost         VARCHAR(30),
    UnitPrice        VARCHAR(30),
    Supplier         VARCHAR(150),
    LaunchDate       VARCHAR(30),
    ProductStatus    VARCHAR(30)
);
GO

DROP TABLE stg.NexMart_Products_Raw;
GO

CREATE TABLE stg.Stores_Raw
(
    StoreID              VARCHAR(20),
    StoreName            VARCHAR(150),
    StoreType            VARCHAR(50),
    City                 VARCHAR(100),
    State                VARCHAR(100),
    Region               VARCHAR(50),
    SalesChannel         VARCHAR(50),
    ManagerEmployeeID    VARCHAR(20),
    StoreStatus          VARCHAR(50)
);
GO

DROP TABLE stg.NexMart_Stores_Raw;
GO

CREATE TABLE stg.Employees_Raw
(
    EmployeeID       VARCHAR(20),
    EmployeeName     VARCHAR(150),
    Gender           VARCHAR(20),
    JobTitle         VARCHAR(100),
    Department       VARCHAR(100),
    StoreID          VARCHAR(20),
    Region           VARCHAR(50),
    HireDate         VARCHAR(30),
    EmploymentStatus VARCHAR(50)
);
GO

DROP TABLE stg.NexMart_Employees_Raw;
GO

CREATE TABLE stg.Sales_Raw
(
    TransactionID      VARCHAR(30),
    OrderID            VARCHAR(30),
    OrderLineNumber    VARCHAR(10),
    OrderDate          VARCHAR(30),
    CustomerID         VARCHAR(20),
    ProductID          VARCHAR(20),
    StoreID            VARCHAR(20),
    EmployeeID         VARCHAR(20),
    Quantity           VARCHAR(20),
    UnitPrice          VARCHAR(30),
    DiscountPercent    VARCHAR(20),
    TaxPercent         VARCHAR(20),
    PaymentMethod      VARCHAR(50),
    SalesChannel       VARCHAR(50),
    OrderStatus        VARCHAR(50)
);
GO

DROP TABLE stg.NexMart_Sales_Raw;
GO
