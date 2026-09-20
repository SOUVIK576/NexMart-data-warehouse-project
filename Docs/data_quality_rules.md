# NexMart Retail — Data Quality Rules

## 1. Purpose

This document defines the data quality rules used during Project 1 of the NexMart Retail Enterprise Data Warehouse.

The rules are based on the actual profiling findings and transformation decisions documented for the project.

The purpose is to make the Silver and Gold layers:

- Consistent
- Reliable
- Traceable
- Structurally valid
- Suitable for analytics
- Protected against known source-data issues

The rules are grouped into:

1. Completeness
2. Uniqueness
3. Validity
4. Consistency
5. Referential integrity
6. Data type and format quality
7. Business-rule quality
8. Transformation rules
9. Gold-layer integrity rules

---

# 2. Data Quality Principles

The following principles apply throughout the project.

### Rule 2.1 — Bronze data must remain immutable

Raw source data in the `stg` schema must not be directly modified.

All cleaning, standardization, deduplication, and type conversion must happen in the Silver layer.

### Rule 2.2 — Do not invent source values

If the correct value cannot be determined from the available source data, preserve the NULL or invalid source condition and classify it where appropriate.

### Rule 2.3 — Investigate duplicates before deletion

A duplicate business key must be profiled before records are removed.

Duplicates may be removed only when the evidence indicates that the records represent repeated versions of the same business entity or transaction.

### Rule 2.4 — Preserve transactional records when possible

A transaction with an unresolved dimension reference should not automatically be deleted.

The Gold layer should preserve the fact and use an Unknown dimension member where appropriate.

### Rule 2.5 — Business assumptions must be documented

A rule based on business interpretation rather than direct source evidence must be explicitly identified as a business assumption.

---

# 3. Quality Dimensions

## 3.1 Completeness

Checks whether required information is present.

Examples:

- Missing CustomerID
- Missing ProductID
- Missing StoreID
- Missing EmployeeID
- Missing UnitCost
- Missing Supplier
- Missing CustomerSegment

## 3.2 Uniqueness

Checks whether business keys contain unintended duplicates.

Examples:

- CustomerID
- ProductID
- StoreID
- EmployeeID
- TransactionID

## 3.3 Validity

Checks whether values conform to the expected domain or format.

Examples:

- Invalid dates
- Invalid numeric values
- Invalid categorical values
- Invalid quantities
- Invalid foreign keys

## 3.4 Consistency

Checks whether related values agree across records and tables.

Examples:

- Store → Manager Employee
- Sales → Customer
- Sales → Product
- Sales → Store
- Sales → Employee
- City → State
- State → Region

## 3.5 Referential Integrity

Checks whether a foreign-key-like business key exists in the referenced master table.

Examples:

- Sales.CustomerID → Customers.CustomerID
- Sales.ProductID → Products.ProductID
- Sales.StoreID → Stores.StoreID
- Sales.EmployeeID → Employees.EmployeeID
- Stores.ManagerEmployeeID → Employees.EmployeeID
- Employees.StoreID → Stores.StoreID

---

# 4. Customer Data Quality Rules

## DQ-CUST-001 — CustomerID completeness

**Rule:**

CustomerID must not be NULL or blank.

**Expected result:**

- Missing CustomerID = 0

**Actual Project 1 result:**

- Missing CustomerID = 0

---

## DQ-CUST-002 — CustomerID uniqueness

**Rule:**

Each CustomerID must identify one customer in the final Silver layer.

**Expected result:**

- Duplicate CustomerID = 0

**Actual Project 1 result:**

- 150 duplicate groups were found in the source.
- After deduplication: 15,000 unique CustomerIDs.

---

## DQ-CUST-003 — CustomerName standardization

**Rule:**

CustomerName should be trimmed and standardized to uppercase in Silver.

**Transformation:**

```sql
UPDATE dbo.Customers_Silver
SET CustomerName = UPPER(LTRIM(RTRIM(CustomerName)));
```

---

## DQ-CUST-004 — Gender domain

**Rule:**

Gender must be one of the observed valid values:

- Female
- Male
- Other

NULL is allowed when the source value is missing.

**Project 1 result:**

- Female: 5,007
- Male: 4,880
- Other: 4,954
- Missing: 159

---

## DQ-CUST-005 — Missing Gender classification

**Rule:**

A missing Gender value must not be replaced with an inferred value.

It must be classified as:

```text
Missing Gender
```

through `GenderQualityStatus`.

---

## DQ-CUST-006 — DateOfBirth validity

**Rule:**

DateOfBirth must be convertible to DATE.

**Checks:**

- NULL
- Blank
- Invalid date
- Future date

**Project 1 result:**

- Invalid conversion = 0
- Future DOB = 0
- All 15,000 records converted successfully.

---

## DQ-CUST-007 — Email completeness

**Rule:**

Email may be NULL, but a non-NULL email should contain `@`.

**Project 1 source findings:**

- NULL: 243
- Missing `@`: 128

The 128 structurally incomplete values were deterministically repaired using the existing CustomerName and CustomerID pattern.

Final result:

- Remaining emails without `@` = 0

---

## DQ-CUST-008 — Email standardization

**Rule:**

Email values should be trimmed and converted to lowercase.

```sql
UPDATE dbo.Customers_Silver
SET Email = LOWER(LTRIM(RTRIM(Email)));
```

---

## DQ-CUST-009 — Customer email uniqueness

**Rule:**

Non-NULL email values should not be duplicated.

**Project 1 result:**

- Duplicate non-NULL emails = 0

---

## DQ-CUST-010 — Phone format

**Rule:**

A populated customer phone number must:

- Be numeric
- Contain 10 digits

NULL is allowed.

**Project 1 result:**

- Present: 14,814
- Missing: 186
- Non-numeric: 0
- Invalid length: 0

---

## DQ-CUST-011 — City completeness

**Rule:**

Customer City should be populated.

**Project 1 result:**

- Present: 15,000
- Missing: 0

---

## DQ-CUST-012 — State completeness

**Rule:**

Customer State should be populated.

**Project 1 result:**

- Present: 15,000
- Missing: 0

---

## DQ-CUST-013 — Region completeness

**Rule:**

Customer Region should be populated.

**Project 1 result:**

- Present: 15,000
- Missing: 0

---

## DQ-CUST-014 — CustomerSegment domain

**Rule:**

Non-NULL CustomerSegment values must belong to the observed valid domain:

- Premium
- Consumer
- Small Business
- Corporate

NULL is allowed and must be classified.

**Project 1 result:**

- Missing: 186
- Valid: 14,814
- Unexpected non-NULL values: 0

---

# 5. Product Data Quality Rules

## DQ-PROD-001 — ProductID completeness

**Rule:**

ProductID must not be NULL or blank.

**Project 1 result:**

- Missing ProductID = 0

---

## DQ-PROD-002 — ProductID uniqueness

**Rule:**

ProductID must be unique in Products Silver.

**Project 1 result:**

- Source duplicate groups: 15
- Final duplicate ProductIDs: 0
- Final products: 500

---

## DQ-PROD-003 — ProductName standardization

**Rule:**

ProductName should be trimmed and standardized to uppercase.

```sql
UPPER(LTRIM(RTRIM(ProductName)))
```

---

## DQ-PROD-004 — Category completeness

**Rule:**

Category must be populated.

**Project 1 result:**

- Missing Category = 0

Observed categories:

- Electronics
- Furniture
- Home Appliances
- Mobile & Accessories
- Office Equipment

---

## DQ-PROD-005 — SubCategory completeness

**Rule:**

SubCategory must be populated.

**Project 1 result:**

- Missing SubCategory = 0

---

## DQ-PROD-006 — Brand completeness

**Rule:**

Brand must be populated.

**Project 1 result:**

- Missing Brand = 0

---

## DQ-PROD-007 — UnitCost numeric validity

**Rule:**

UnitCost must be convertible to DECIMAL(18,2).

**Project 1 result:**

- Invalid conversion = 0
- Positive = 494
- Missing = 6
- Zero = 0
- Negative = 0

---

## DQ-PROD-008 — Missing UnitCost classification

**Rule:**

A missing UnitCost must be preserved rather than guessed.

`UnitCostQualityStatus` must classify it as:

```text
Missing UnitCost
```

Final:

- Valid UnitCost: 494
- Missing UnitCost: 6

---

## DQ-PROD-009 — UnitPrice numeric validity

**Rule:**

UnitPrice must be convertible to DECIMAL(18,2).

**Project 1 result:**

- Invalid conversion = 0
- Positive = 500

---

## DQ-PROD-010 — Supplier completeness

**Rule:**

Supplier may be NULL, but blank Supplier values are not expected.

**Project 1 result:**

- NULL: 8
- Blank: 0

Missing Supplier values must be classified through `SupplierQualityStatus`.

---

## DQ-PROD-011 — ProductStatus domain

**Rule:**

ProductStatus must represent the observed valid states:

- Active
- Discontinued

**Project 1 result:**

- Active: 448
- Discontinued: 52

---

## DQ-PROD-012 — LaunchDate validity

**Rule:**

LaunchDate must be convertible to DATE.

**Project 1 result:**

- Invalid dates: 0
- Missing/blank: 0
- Earliest: 2022-01-02
- Latest: 2026-02-09

Final Silver LaunchDate data type:

```text
DATE
```

---

# 6. Store Data Quality Rules

## DQ-STORE-001 — StoreID completeness

**Rule:**

StoreID must not be NULL or blank.

**Project 1 result:**

- Missing StoreID = 0

---

## DQ-STORE-002 — StoreID uniqueness

**Rule:**

StoreID must uniquely identify one store in Stores Silver.

**Project 1 source findings:**

- STORE017 duplicated
- STORE045 duplicated
- 4 physical rows affected

After deduplication:

- 50 stores
- 50 distinct StoreIDs

---

## DQ-STORE-003 — StoreName standardization

**Rule:**

StoreName must be trimmed and standardized to uppercase.

```sql
UPPER(LTRIM(RTRIM(StoreName)))
```

---

## DQ-STORE-004 — StoreType standardization

**Rule:**

StoreType values must use consistent capitalization.

Observed valid domain:

- Standard
- Flagship
- Express
- Outlet

Final distribution:

- Express: 10
- Flagship: 16
- Outlet: 6
- Standard: 18

---

## DQ-STORE-005 — StoreStatus validity

**Rule:**

StoreStatus must use the observed valid states:

- Active
- Temporarily Closed

Final distribution:

- Active: 38
- Temporarily Closed: 12

---

## DQ-STORE-006 — ManagerEmployeeID referential integrity

**Rule:**

Every non-NULL ManagerEmployeeID should exist in Employees Silver.

**Project 1 result:**

- Invalid ManagerEmployeeID = 0

---

## DQ-STORE-007 — Store geography consistency

**Rule:**

A City should not map to conflicting States within the available store data.

**Project 1 result:**

- City → State conflicts = 0

---

## DQ-STORE-008 — Region consistency

**Rule:**

A State should not map to conflicting Regions within the available store data.

**Project 1 result:**

- State → Region conflicts = 0

---

## DQ-STORE-009 — Region standardization

**Rule:**

Region capitalization variants must be standardized.

Observed variants included:

- North / NORTH
- South / SOUTH
- East / EAST
- West

Final:

- East: 12
- North: 12
- South: 14
- West: 12

---

## DQ-STORE-010 — SalesChannel validity

**Rule:**

Store SalesChannel must use:

- Omnichannel
- Physical Store

Project 1 result:

- Omnichannel: 27
- Physical Store: 23
- Invalid/missing: 0

---

# 7. Employee Data Quality Rules

## DQ-EMP-001 — EmployeeID completeness

**Rule:**

EmployeeID must not be NULL or blank.

**Project 1 result:**

- Missing EmployeeID = 0

---

## DQ-EMP-002 — EmployeeID uniqueness

**Rule:**

EmployeeID must be unique in Employees Silver.

Source duplicate groups:

- 10

Final:

- Total employees: 300
- Distinct EmployeeIDs: 300
- Duplicate EmployeeIDs: 0

---

## DQ-EMP-003 — Gender validity

**Rule:**

Gender must use the observed values:

- Female
- Male
- Other

Final:

- Female: 90
- Male: 102
- Other: 108

---

## DQ-EMP-004 — HireDate validity

**Rule:**

HireDate must be convertible to DATE and must not be a future date.

Project 1:

- Missing: 0
- Blank: 0
- Unparseable: 0
- Future: 0

---

## DQ-EMP-005 — EmploymentStatus validity

**Rule:**

EmploymentStatus must use:

- Active
- Inactive
- On Leave

Final:

- Active: 280
- Inactive: 7
- On Leave: 13

---

## DQ-EMP-006 — Employee → Store integrity

**Rule:**

A populated Employee.StoreID should exist in Stores Silver.

Project 1 exception:

- EMP0058 has StoreID = NULL

The source also contained NULL.

The StoreID must not be guessed.

`StoreQualityStatus` is used to classify the condition.

---

## DQ-EMP-007 — Sales → Employee integrity

**Rule:**

A populated Sales.EmployeeID should normally exist in Employees Silver.

Project 1 exception:

- EMP9999
- 75 sales transactions
- Employee does not exist in Employees_Raw

These transactions are retained and mapped to the Gold Unknown Employee.

---

# 8. Sales Data Quality Rules

## DQ-SALES-001 — TransactionID completeness

**Rule:**

TransactionID must not be NULL or blank.

Project 1:

- Missing: 0

---

## DQ-SALES-002 — TransactionID uniqueness

**Rule:**

TransactionID must be unique in Sales Silver.

Source:

- 420,306 rows
- 300 duplicate groups
- 600 physical duplicate rows

Final:

- 420,006 rows
- 420,006 distinct TransactionIDs
- 0 duplicates

---

## DQ-SALES-003 — Duplicate transaction handling

**Rule:**

Exact duplicate transaction loads should be reduced to one physical record per TransactionID.

The duplicate records were investigated before deletion.

---

## DQ-SALES-004 — OrderID completeness

**Rule:**

OrderID must not be NULL or blank.

Project 1:

- Missing/blank = 0

---

## DQ-SALES-005 — OrderLineNumber validity

**Rule:**

OrderLineNumber must:

- Be numeric
- Be greater than zero

Project 1:

- Non-numeric = 0
- Non-positive = 0

Final data type:

```text
INT NOT NULL
```

---

## DQ-SALES-006 — OrderDate validity

**Rule:**

OrderDate must be convertible to DATE.

Supported source formats were evaluated using `TRY_CONVERT`.

Project 1:

- Invalid dates = 0
- Earliest = 2023-01-01
- Latest = 2026-06-30

---

## DQ-SALES-007 — CustomerID referential integrity

**Rule:**

A populated Sales.CustomerID should exist in Customers Silver.

Project 1:

- Valid: 419,336
- Invalid: 250
- Missing: 420

All 420,006 rows receive a `CustomerQualityStatus`.

---

## DQ-SALES-008 — ProductID referential integrity

**Rule:**

A populated Sales.ProductID should exist in Products Silver.

Project 1:

- Valid: 419,856
- Invalid: 150
- Missing: 0

---

## DQ-SALES-009 — StoreID referential integrity

**Rule:**

A populated Sales.StoreID should exist in Stores Silver.

Project 1:

- Valid: 419,931
- Invalid: 75
- Missing: 0

---

## DQ-SALES-010 — EmployeeID referential integrity

**Rule:**

A populated Sales.EmployeeID should exist in Employees Silver.

Project 1:

- Valid: 419,595
- Invalid: 75
- Missing: 336

---

## DQ-SALES-011 — Quantity validity

**Rule:**

For this project, Quantity is assumed to represent the number of units associated with the sales order line.

For Completed, Cancelled, and Returned transactions, Quantity is expected to be greater than zero.

This is explicitly a business assumption.

Raw findings:

- NULL: 512
- Zero: 94
- Negative: 76
- Total raw invalid: 683

Final quality classification:

- Valid: 418,866
- Invalid: 1,140
- Not Evaluated: 0

Invalid values are preserved because replacement values cannot be reliably determined.

---

## DQ-SALES-012 — UnitPrice numeric validity

**Rule:**

UnitPrice must be numeric and convertible to DECIMAL(18,2).

Project 1:

- Positive: 419,276
- NULL: 630
- Zero: 100
- Negative: 0
- Non-numeric: 0

NULL and zero are preserved.

---

## DQ-SALES-013 — DiscountPercent validity

**Rule:**

DiscountPercent must be numeric.

Observed valid values:

- 0
- 5
- 10
- 15
- 20
- 25

Non-numeric values:

- 0

---

## DQ-SALES-014 — TaxPercent validity

**Rule:**

TaxPercent must be numeric.

Observed values:

- 5
- 12
- 18

Non-numeric values:

- 0

---

## DQ-SALES-015 — PaymentMethod validity

**Rule:**

PaymentMethod must belong to the observed domain:

- UPI
- Credit Card
- Debit Card
- EMI
- Net Banking
- Cash

Project 1:

- Missing/unexpected values = 0

---

## DQ-SALES-016 — SalesChannel validity

**Rule:**

SalesChannel must be:

- Online
- Physical Store

Project 1:

- Missing/blank/unexpected = 0

---

## DQ-SALES-017 — OrderStatus standardization

**Rule:**

OrderStatus capitalization must be standardized.

Final domain:

- Completed
- Cancelled
- Returned

Final counts:

- Completed: 252,268
- Cancelled: 83,979
- Returned: 83,759

---

# 9. Cross-Table Business Rules

## DQ-REL-001 — Sales → Customers

A valid Sales.CustomerID should exist in Customers Silver.

Known exceptions:

- 250 invalid non-NULL references
- 420 missing references

These are retained and mapped to Unknown Customer in Gold.

---

## DQ-REL-002 — Sales → Products

Known exception:

- 150 invalid ProductID references

These are retained and mapped to Unknown Product.

---

## DQ-REL-003 — Sales → Stores

Known exception:

- 75 invalid StoreID references

These are retained and mapped to Unknown Store.

---

## DQ-REL-004 — Sales → Employees

Known exceptions:

- 75 invalid EmployeeID references
- 336 missing EmployeeID values

These are retained and mapped to Unknown Employee.

---

## DQ-REL-005 — Stores → Employees

Every populated Store.ManagerEmployeeID should exist in Employees Silver.

Project 1:

- Invalid references = 0

---

## DQ-REL-006 — Employees → Stores

Every populated Employee.StoreID should exist in Stores Silver.

Project 1:

- Invalid non-NULL references = 0
- One missing StoreID: EMP0058

The missing value is preserved.

---

## DQ-REL-007 — SalesChannel vs Store SalesChannel

The following combinations were observed:

| SalesChannel | Store SalesChannel | Rows |
|---|---|---:|
| Online | Omnichannel | 85,727 |
| Online | Physical Store | 73,556 |
| Physical Store | Omnichannel | 140,449 |
| Physical Store | Physical Store | 120,199 |

The Online + Physical Store combination is treated as a business clarification rather than automatically classified as invalid.

---

# 10. Silver Quality Status Rules

Quality-status columns are used to ensure that unresolved source conditions are explicitly classified.

## Sales

Required status columns:

- CustomerQualityStatus
- ProductQualityStatus
- StoreQualityStatus
- EmployeeQualityStatus
- QuantityQualityStatus
- UnitPriceQualityStatus

Rule:

> Every Sales Silver row must receive a classification for each applicable quality-status field.

Validation:

- Total Sales rows: 420,006
- Missing quality classifications: 0

## Products

Required status columns:

- UnitCostQualityStatus
- SupplierQualityStatus

Validation:

- Total Products: 500
- Missing classifications: 0

## Employees

Required status column:

- StoreQualityStatus

Validation:

- Total Employees: 300
- Missing classifications: 0

## Customers

Required status columns:

- GenderQualityStatus
- EmailQualityStatus
- PhoneQualityStatus
- CustomerSegmentQualityStatus

Validation:

- Total Customers: 15,000
- Missing classifications: 0

## Stores

Required quality validation covers:

- StoreID
- StoreType
- StoreStatus
- Region

Validation:

- Total Stores: 50
- Missing classifications: 0

---

# 11. Gold Data Quality Rules

## DQ-GOLD-001 — Unknown dimension members

Each dimension must contain an Unknown member with surrogate key `0`.

Required Unknown members:

- CustomerKey = 0
- ProductKey = 0
- StoreKey = 0
- EmployeeKey = 0

---

## DQ-GOLD-002 — Dimension business-key uniqueness

Real dimension records must contain unique business keys.

Final results:

| Dimension | Real Rows | Distinct Business Keys |
|---|---:|---:|
| DimCustomer | 15,000 | 15,000 |
| DimProduct | 500 | 500 |
| DimStore | 50 | 50 |
| DimEmployee | 300 | 300 |

---

## DQ-GOLD-003 — DimDate completeness

DimDate must contain every date between the minimum and maximum sales dates.

Project 1:

- Earliest: 2023-01-01
- Latest: 2026-06-30
- Rows: 1,277
- Gaps: 0

---

## DQ-GOLD-004 — FactSales row reconciliation

FactSales row count must equal the final Sales Silver row count.

Project 1:

- Sales Silver: 420,006
- FactSales: 420,006

Difference:

- 0

---

## DQ-GOLD-005 — FactSales TransactionID uniqueness

TransactionID must be unique in FactSales.

Project 1:

- FactSales rows: 420,006
- Distinct TransactionIDs: 420,006
- Duplicates: 0

---

## DQ-GOLD-006 — Fact dimension keys cannot be NULL

Required FactSales dimension keys:

- DateKey
- CustomerKey
- ProductKey
- StoreKey
- EmployeeKey

Expected:

- NULL = 0

Project 1:

- DateKey NULL = 0
- CustomerKey NULL = 0
- ProductKey NULL = 0
- StoreKey NULL = 0
- EmployeeKey NULL = 0

---

## DQ-GOLD-007 — Fact foreign-key integrity

FactSales dimension keys must reference existing dimension rows.

Foreign keys exist for:

- FactSales → DimCustomer
- FactSales → DimProduct
- FactSales → DimStore
- FactSales → DimEmployee
- FactSales → DimDate

Final invalid foreign-key references:

- 0

---

## DQ-GOLD-008 — Unknown mapping preservation

Unresolved Silver references must map to the appropriate Unknown dimension member rather than producing NULL foreign keys.

Project 1 Unknown mappings:

| Dimension | Unknown Fact Rows |
|---|---:|
| Customer | 670 |
| Product | 150 |
| Store | 75 |
| Employee | 411 |
| Date | 0 |

---

# 12. Quality Rule Severity

The project uses the following practical severity interpretation.

### Critical

A condition that can break the warehouse structure or prevent reliable joins.

Examples:

- Missing primary/business key
- Duplicate transaction key after Silver processing
- Broken Gold foreign-key integrity
- NULL required Gold dimension key

### High

A condition that can materially affect analysis.

Examples:

- Invalid CustomerID
- Invalid ProductID
- Invalid StoreID
- Invalid EmployeeID
- Invalid transaction date

### Medium

A condition that affects data quality but can be retained and classified.

Examples:

- Missing UnitCost
- Missing Supplier
- Missing CustomerSegment
- Missing Gender
- Missing Phone
- Invalid Quantity

### Low / Informational

A condition requiring business clarification rather than automatic correction.

Examples:

- Online sales associated with Physical Store classifications
- Store manager job title not matching an expected managerial title
- Temporarily Closed stores with historical sales when no closure date exists

These severity interpretations are operational guidance for this project, not external industry standards.

---

# 13. Data Quality Control Summary

| Area | Rule | Final Result |
|---|---|---|
| CustomerID uniqueness | Must be unique | Pass |
| ProductID uniqueness | Must be unique | Pass |
| StoreID uniqueness | Must be unique | Pass |
| EmployeeID uniqueness | Must be unique | Pass |
| TransactionID uniqueness | Must be unique | Pass |
| Customer email uniqueness | Non-NULL emails unique | Pass |
| Date conversion | Invalid dates = 0 where required | Pass |
| Product numeric conversion | Invalid UnitCost/UnitPrice conversions = 0 | Pass |
| Sales OrderDate conversion | Invalid dates = 0 | Pass |
| Sales → Customer | Exceptions classified | Pass |
| Sales → Product | Exceptions classified | Pass |
| Sales → Store | Exceptions classified | Pass |
| Sales → Employee | Exceptions classified | Pass |
| Store → Employee | Invalid references = 0 | Pass |
| Gold foreign keys | Invalid references = 0 | Pass |
| Gold fact key NULLs | NULL = 0 | Pass |
| Silver row reconciliation | Counts documented | Pass |
| Gold fact reconciliation | 420,006 = 420,006 | Pass |

---

# 14. Known Exceptions That Remain

The following conditions are intentionally retained because the correct replacement value cannot be established from the current source data:

### Customers

- 159 missing Gender values
- 243 missing Email values
- 186 missing Phone values
- 186 missing CustomerSegment values

### Products

- 6 missing UnitCost values
- 8 missing Supplier values

### Employees

- EMP0058 has missing StoreID

### Sales

- 420 missing CustomerID values
- 250 invalid CustomerID references
- 150 invalid ProductID references
- 75 invalid StoreID references
- 336 missing EmployeeID values
- 75 invalid EmployeeID references
- 1,140 invalid Quantity classifications
- 630 missing UnitPrice values
- 100 zero UnitPrice values

These exceptions are not hidden. They are represented through Silver quality-status fields and/or Gold Unknown members where applicable.

---

# 15. Final Data Quality Philosophy

The Project 1 implementation follows a controlled data-quality approach:

```text
Profile
   ↓
Identify Issue
   ↓
Investigate Evidence
   ↓
Determine Whether a Reliable Rule Exists
   ↓
 ┌───────────────────────┐
 │ Reliable correction?  │
 └───────────┬───────────┘
             |
       Yes   |   No
        ↓    |    ↓
    Correct  |  Preserve
             |  + Classify
             ↓
        Silver Layer
             ↓
     Gold Unknown Member
       when reference
       cannot be resolved
```

The objective is not to make every source value appear clean.

The objective is to make the transformation:

- Explainable
- Repeatable
- Controlled
- Traceable
- Safe for downstream analytics

This principle is especially important for enterprise data warehouse development because changing an unknown source value without evidence can introduce a new data error rather than remove one.
