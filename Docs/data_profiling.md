# NexMart Retail — Data Profiling Documentation

## 1. Purpose

This document records the data profiling performed during Project 1 of the NexMart Retail Enterprise Data Warehouse.

The profiling was performed to understand:

- Source data structure and quality
- Duplicate records
- Missing values
- Invalid values
- Data type issues
- Standardization requirements
- Referential integrity issues
- Business-rule exceptions
- Silver-layer transformation decisions
- Gold-layer reconciliation and validation

The profiling results documented here reflect the actual findings and decisions made during Project 1.

## 2. Project Architecture

```text
Source CSV Files
       |
       v
Bronze / Staging
stg
       |
       | Profiling + Cleaning + Standardization
       v
Silver
dbo
       |
       | Dimensional Modeling + Surrogate Keys
       v
Gold
gld
       |
       v
Power BI / Analytics
```

### Bronze

The `stg` schema contains the raw source data.

Bronze data is treated as immutable.

Tables:

- `stg.Customers_Raw`
- `stg.Products_Raw`
- `stg.Stores_Raw`
- `stg.Employees_Raw`
- `stg.Sales_Raw`

### Silver

The `dbo` schema contains cleaned and standardized data.

Tables:

- `dbo.Customers_Silver`
- `dbo.Products_Silver`
- `dbo.Stores_Silver`
- `dbo.Employees_Silver`
- `dbo.Sales_Silver`

### Gold

The `gld` schema contains the dimensional model.

Tables:

- `gld.DimDate`
- `gld.DimCustomer`
- `gld.DimProduct`
- `gld.DimStore`
- `gld.DimEmployee`
- `gld.FactSales`

## 3. Profiling Approach

Profiling was performed before and during Silver-layer construction.

The following areas were investigated:

1. Row counts
2. Duplicate business keys
3. Missing values
4. Blank values
5. Invalid values
6. Data type compatibility
7. Date conversion
8. Numeric conversion
9. Categorical consistency
10. Referential integrity
11. Cross-table relationships
12. Business-rule exceptions
13. Final Silver reconciliation
14. Gold reconciliation
15. Quality-status completeness

The principle followed throughout the project was:

> Do not automatically modify a value when its correct business meaning cannot be proven from the available data.

Where the correct replacement value was not known, the value was retained and explicitly classified.

# 4. Customers Profiling

## 4.1 Source Row Count

`stg.Customers_Raw` contained:

- 15,150 rows

Duplicate analysis identified:

- 150 duplicate CustomerID groups
- 150 redundant rows

After deduplication:

- `dbo.Customers_Silver` = 15,000 rows

## 4.2 CustomerID

CustomerID was profiled for NULL values, blank values, and duplicate values.

Result:

- Missing/blank CustomerID: 0
- Final distinct CustomerID values: 15,000
- Final duplicate CustomerID values: 0

CustomerID was therefore retained as the business key.

## 4.3 Duplicate Customer Records

There were 150 duplicate CustomerID groups.

The duplicate records were investigated before deletion.

Most duplicates differed only by text capitalization.

Two notable examples were investigated:

### CUST05808

The duplicate records had:

- Same CustomerName
- Same demographic attributes
- Same phone
- Same location
- Same signup date
- Email differed only by capitalization

### CUST12229

The duplicate records had:

- CustomerName differing by capitalization
- Email differing by capitalization
- Same phone
- Same location
- Same signup date
- CustomerSegment NULL in both records

CustomerName was standardized before deduplication.

Email was also standardized before deduplication.

The duplicate records were then removed using `ROW_NUMBER()` partitioned by CustomerID.

Final result:

- 15,000 customers
- 0 duplicate CustomerIDs

## 4.4 CustomerName

CustomerName contained capitalization and whitespace inconsistencies.

Standardization applied:

```sql
UPDATE dbo.Customers_Silver
SET CustomerName = UPPER(LTRIM(RTRIM(CustomerName)));
```

## 4.5 Gender

Final Silver profiling:

| Gender | Count |
|---|---:|
| Female | 5,007 |
| Male | 4,880 |
| Other | 4,954 |
| NULL | 159 |

No blank values were identified.

A `GenderQualityStatus` column was added.

Classification:

- NULL → `Missing Gender`
- Non-NULL → `Valid Gender`

Final validation:

- Missing Gender: 159
- Valid Gender: 14,841
- Total: 15,000

## 4.6 DateOfBirth

DateOfBirth was initially stored as VARCHAR.

Profiling found:

- Total: 15,000
- NULL: 0
- Blank: 0
- Invalid date conversion: 0
- Future DOB: 0

All 15,000 records converted successfully to DATE.

## 4.7 Email

Email profiling found:

- NULL: 243
- Blank: 0
- Values containing `@`: 14,629
- Values without `@`: 128

All complete email domains were `example.com`.

Email was standardized using:

```sql
UPDATE dbo.Customers_Silver
SET Email = LOWER(LTRIM(RTRIM(Email)));
```

The 128 incomplete email values were investigated.

A deterministic repair rule was established from the existing CustomerName and CustomerID structure:

```text
lowercase(CustomerName with spaces replaced by dots)
+
numeric portion of CustomerID with leading zeros removed
+
@example.com
```

Validation showed:

- 128 matching repaired emails
- 0 remaining emails without `@`

The repair was applied only to rows where an existing non-NULL email did not contain `@`.

Documentation limitation: the existing `EmailQualityStatus` classification was not separately changed to indicate that those 128 values had been repaired. They remained classified as present email values.

## 4.8 Phone

Final profiling:

- Present: 14,814
- NULL: 186
- Blank: 0
- Present values with length 10: 14,814
- Numeric: 14,814
- Non-numeric: 0

A `PhoneQualityStatus` column was added.

Final classification:

- Missing Phone: 186
- Valid Phone: 14,814

## 4.9 City and State

City and State were profiled for missing values, blank values, whitespace issues, case consistency, and geographic conflicts.

Final findings:

- City present for all 15,000 customers
- State present for all 15,000 customers
- No confirmed city/state conflict
- State contained 16 consistent values

Previously completed whitespace checks did not identify an issue requiring transformation.

## 4.10 Region

All 15,000 customers had a Region.

Final distribution:

| Region | Count |
|---|---:|
| South | 4,105 |
| East | 4,061 |
| North | 3,458 |
| West | 3,376 |

## 4.11 SignupDate

SignupDate was initially stored as VARCHAR.

Profiling found:

- Total: 15,000
- NULL: 0
- Blank: 0
- Invalid dates: 0

All 15,000 records converted successfully to DATE.

## 4.12 CustomerSegment

Final distribution:

| CustomerSegment | Count |
|---|---:|
| Premium | 3,736 |
| Consumer | 3,733 |
| Small Business | 3,689 |
| Corporate | 3,656 |
| NULL | 186 |

No blank or unexpected non-NULL values were found.

A `CustomerSegmentQualityStatus` column was added.

Final classification:

- Missing Customer Segment: 186
- Valid Customer Segment: 14,814

## 4.13 Customer Email Uniqueness

Duplicate non-NULL email values were checked.

Result:

- Duplicate non-NULL emails: 0

## 4.14 Final Customers Silver Integrity

Final result:

- Total rows: 15,000
- Distinct CustomerIDs: 15,000
- Duplicate CustomerIDs: 0

Quality-status control showed no rows with missing quality-status classifications.

# 5. Products Profiling

## 5.1 Source Row Count

`stg.Products_Raw` contained:

- 515 rows

Duplicate analysis identified:

- 15 duplicate ProductID groups
- 15 redundant rows

After deduplication:

- `dbo.Products_Silver` = 500 rows

## 5.2 Duplicate Product Records

The duplicate ProductIDs were:

- PROD00017
- PROD00047
- PROD00053
- PROD00088
- PROD00107
- PROD00156
- PROD00162
- PROD00247
- PROD00250
- PROD00311
- PROD00331
- PROD00340
- PROD00355
- PROD00444
- PROD00454

Duplicate inspection showed:

- ProductNameVariants = 2
- Other attribute variants = 1

The differences were capitalization differences.

ProductName was standardized before deduplication.

Final result:

- 500 products
- 0 duplicate ProductIDs

## 5.3 ProductID

Final profiling:

- Missing ProductID: 0
- Blank ProductID: 0
- Final ProductID count: 500
- Distinct ProductID count: 500

ProductID was made NOT NULL.

## 5.4 ProductName

ProductName was standardized using:

```sql
UPPER(LTRIM(RTRIM(ProductName)))
```

No missing ProductName values were identified.

## 5.5 Category

Final Silver category distribution:

- Electronics: 100
- Furniture: 100
- Home Appliances: 100
- Mobile & Accessories: 100
- Office Equipment: 100

Missing Category values:

- 0

## 5.6 SubCategory

SubCategory completeness:

- Missing: 0

## 5.7 Brand

Brand completeness:

- Missing: 0

## 5.8 UnitCost

UnitCost was initially stored as VARCHAR.

Conversion profiling found:

- Invalid numeric conversions: 0
- Missing: 6
- Zero: 0
- Negative: 0
- Positive: 494

The six missing UnitCost values were preserved as NULL.

UnitCost was converted to `DECIMAL(18,2)`.

A `UnitCostQualityStatus` column was added.

Final classification:

- Valid UnitCost: 494
- Missing UnitCost: 6

## 5.9 UnitPrice

UnitPrice was initially stored as text.

Profiling found:

- Invalid conversions: 0
- Positive: 500

All values converted successfully to `DECIMAL(18,2)`.

## 5.10 Supplier

Supplier profiling found:

- NULL: 8
- Blank: 0

Exact ProductIDs with missing Supplier:

- PROD00457
- PROD00021
- PROD00075
- PROD00024
- PROD00149
- PROD00042
- PROD00231
- PROD00406

A `SupplierQualityStatus` column was added.

Final classification:

- Missing Supplier: 8
- Valid Supplier: 492

## 5.11 ProductStatus

Final distribution:

| ProductStatus | Count |
|---|---:|
| Active | 448 |
| Discontinued | 52 |

## 5.12 LaunchDate

Bronze `LaunchDate` was VARCHAR(30).

Profiling found:

- Total: 515
- Missing/blank: 0
- Invalid dates: 0
- Earliest: 2022-01-02
- Latest: 2026-02-09

LaunchDate was initially omitted from Silver by mistake and subsequently added back.

It was converted to DATE.

Final validation:

- Products: 500
- Missing LaunchDate: 0
- Earliest LaunchDate: 2022-01-02
- Latest LaunchDate: 2026-02-09

## 5.13 Final Products Silver Integrity

Final result:

- Total products: 500
- Distinct ProductIDs: 500
- Duplicate ProductIDs: 0

Quality-status control:

- Missing UnitCost status: 0
- Missing Supplier status: 0

# 6. Stores Profiling

## 6.1 Source Row Count

`stg.Stores_Raw` contained:

- 52 rows

Duplicate analysis found:

- STORE017 duplicated
- STORE045 duplicated
- 4 physical rows affected
- 2 duplicate StoreID groups

## 6.2 Duplicate Store Records

Duplicate inspection showed:

- Name variants existed
- Other attributes were consistent
- Conflicting names after normalization: 0

StoreName normalization was applied before deduplication.

Final Stores Silver:

- 50 rows
- 50 distinct StoreIDs

## 6.3 StoreName

StoreName was standardized using:

```sql
UPPER(LTRIM(RTRIM(StoreName)))
```

Known affected normalized names included:

- NEXMART CHANDIGARH FLAGSHIP
- NEXMART MYSURU STANDARD

## 6.4 StoreType

Raw values included capitalization variants:

- Standard
- Flagship
- Express
- Outlet
- flagship
- standard

Final standardized distribution:

| StoreType | Count |
|---|---:|
| Express | 10 |
| Flagship | 16 |
| Outlet | 6 |
| Standard | 18 |

No missing, blank, or invalid StoreType values were found.

## 6.5 StoreStatus

Raw StoreStatus:

- Active: 39
- Temporarily Closed: 13

After deduplication:

- Active: 38
- Temporarily Closed: 12

No missing, blank, or invalid status values were found.

## 6.6 ManagerEmployeeID

ManagerEmployeeID profiling found:

- Missing/invalid manager IDs: 0

## 6.7 Manager Job Titles

The assigned manager job-title distribution included:

- Sales Executive: 29
- Senior Sales Executive: 10
- Operations Executive: 4
- Regional Sales Manager: 4
- Store Manager: 2
- Assistant Manager: 1
- Customer Service Executive: 1
- Inventory Executive: 1

The presence of some non-managerial job titles was treated as a business clarification rather than an automatic data error.

## 6.8 Geography

Results:

- No city variation requiring correction
- No state variation requiring correction
- City → State conflicts: 0
- State → Region conflicts: 0

## 6.9 Region

Raw values contained capitalization variants.

Final standardized distribution:

| Region | Count |
|---|---:|
| East | 12 |
| North | 12 |
| South | 14 |
| West | 12 |

## 6.10 SalesChannel

Final Store SalesChannel values:

- Omnichannel: 27
- Physical Store: 23

No missing, invalid, or case-variation issue was identified.

## 6.11 StoreID

Final Stores Silver:

- Total: 50
- Distinct StoreIDs: 50
- Missing StoreID: 0

StoreID was made NOT NULL.

# 7. Employees Profiling

## 7.1 Source Row Count

`stg.Employees_Raw` contained:

- 300 rows

Duplicate analysis identified:

- 10 duplicate EmployeeID groups
- 20 affected physical rows
- 10 redundant rows

The duplicate EmployeeIDs were:

- EMP0005
- EMP0016
- EMP0028
- EMP0063
- EMP0082
- EMP0193
- EMP0228
- EMP0233
- EMP0289
- EMP0300

Duplicates differed by EmployeeName capitalization.

## 7.2 EmployeeID

Final profiling:

- Total: 300
- Distinct EmployeeID: 300
- Missing/blank EmployeeID: 0

## 7.3 Gender

Final distribution:

| Gender | Count |
|---|---:|
| Female | 90 |
| Male | 102 |
| Other | 108 |

## 7.4 JobTitle

Final distribution:

| JobTitle | Count |
|---|---:|
| Assistant Manager | 16 |
| Customer Service Executive | 24 |
| Inventory Executive | 13 |
| Regional Sales Manager | 12 |
| Sales Executive | 143 |
| Senior Sales Executive | 53 |
| Store Manager | 14 |

## 7.5 Department

Final distribution:

| Department | Count |
|---|---:|
| Sales | 238 |
| Operations | 38 |
| Customer Service | 24 |

## 7.6 HireDate

HireDate profiling found:

- Missing: 0
- Blank: 0
- Unparseable: 0
- Future dates: 0

The column was converted to DATE.

## 7.7 EmploymentStatus

Final distribution:

| EmploymentStatus | Count |
|---|---:|
| Active | 280 |
| Inactive | 7 |
| On Leave | 13 |

## 7.8 Employee → Store Relationship

One employee had a missing StoreID:

- EMP0058
- NIKHIL SHARMA
- Customer Service Executive
- Customer Service
- Active
- StoreID = NULL

The source also contained NULL.

The StoreID was not guessed.

Decision:

- Preserve NULL
- Flag through StoreQualityStatus

Final validation:

- Total employees: 300
- Missing StoreQualityStatus: 0

## 7.9 Sales → Employee Referential Exception

Sales profiling identified:

- 75 invalid EmployeeID references
- Invalid ID: EMP9999
- 75 transactions reference this ID
- EMP9999 does not exist in Employees_Raw

The records were retained and mapped to the Gold Unknown Employee member.

## 7.10 Stores → Employees

Store manager references were checked against Employees.

Result:

- Invalid ManagerEmployeeID references: 0

# 8. Sales Profiling

## 8.1 Source Row Count

`stg.Sales_Raw` contained:

- 420,306 rows

Duplicate TransactionID analysis found:

- 300 duplicate groups
- 600 physical rows involved

The duplicate records were exact duplicate loads.

After deduplication:

- `dbo.Sales_Silver` = 420,006 rows

## 8.2 TransactionID

Final Silver profiling:

- Total: 420,006
- Missing/blank: 0
- Distinct: 420,006
- Duplicate: 0

## 8.3 OrderID

Profiling found:

- Missing/blank OrderID: 0

## 8.4 OrderLineNumber

Profiling found:

- Non-numeric values: 0
- Non-positive values: 0

Final data type:

```text
INT NOT NULL
```

## 8.5 OrderDate

OrderDate was initially stored as text.

Profiling found:

- Unparseable dates: 0
- Earliest: 2023-01-01
- Latest: 2026-06-30

All 420,006 records converted successfully to DATE.

## 8.6 CustomerID Referential Quality

Sales profiling found:

- Invalid non-NULL CustomerID references: 250
- Missing CustomerID values: 420

Final `CustomerQualityStatus`:

- Valid: 419,336
- Invalid: 250
- Missing: 420

Total: 420,006

## 8.7 ProductID Referential Quality

Sales profiling found:

- Invalid ProductID references: 150
- Missing ProductID values: 0

Final `ProductQualityStatus`:

- Valid: 419,856
- Invalid: 150
- Missing: 0

## 8.8 StoreID Referential Quality

Sales profiling found:

- Invalid StoreID references: 75
- Missing StoreID values: 0

Final `StoreQualityStatus`:

- Valid: 419,931
- Invalid: 75
- Missing: 0

## 8.9 EmployeeID Referential Quality

Sales profiling found:

- Invalid EmployeeID references: 75
- Missing EmployeeID values: 336

Final `EmployeeQualityStatus`:

- Valid: 419,595
- Invalid: 75
- Missing: 336

Total: 420,006

## 8.10 Quantity

Raw Quantity profiling found:

- NULL: 512
- Zero: 94
- Negative: 76
- Total invalid Quantity records: 683

For Cancelled:

- Invalid: 231
- NULL: 166
- Negative: 38
- Zero: 27

For Returned:

- Invalid: 227
- NULL: 162
- Negative: 36
- Zero: 29

Business assumption:

> Quantity represents the number of units associated with a sales order line. For Completed, Cancelled, and Returned transactions, Quantity is expected to be greater than zero.

This is a business assumption rather than a fact proven directly by the source data.

Invalid values were preserved because replacement quantities could not be established reliably.

Final QuantityQualityStatus:

- Valid: 418,866
- Invalid: 1,140
- Not Evaluated: 0

Quantity was stored as `INT NULL`.

## 8.11 UnitPrice

Profiling found:

- Positive: 419,276
- NULL: 630
- Zero: 100
- Negative: 0
- Non-numeric: 0
- Maximum: 125,000
- Minimum: 0

NULL and zero values were preserved because their business meaning was not established.

Final data type:

```text
DECIMAL(18,2) NULL
```

Final UnitPriceQualityStatus:

- Valid: 419,276
- Missing: 630
- Zero: 100
- Invalid: 0

## 8.12 DiscountPercent

Final distribution:

| DiscountPercent | Count |
|---|---:|
| 0 | 105,121 |
| 5 | 105,082 |
| 10 | 92,348 |
| 15 | 62,890 |
| 20 | 41,990 |
| 25 | 12,575 |

Non-numeric values:

- 0

## 8.13 TaxPercent

Final distribution:

| TaxPercent | Count |
|---|---:|
| 5 | 84,248 |
| 12 | 127,901 |
| 18 | 207,857 |

Non-numeric values:

- 0

## 8.14 PaymentMethod

Final distribution:

| PaymentMethod | Count |
|---|---:|
| UPI | 125,779 |
| Credit Card | 96,275 |
| Debit Card | 67,131 |
| EMI | 54,757 |
| Net Banking | 42,182 |
| Cash | 33,882 |

Missing/unexpected values:

- 0

## 8.15 SalesChannel

Raw:

- Physical Store: 260,876
- Online: 159,430

Final Silver:

- Physical Store: 260,693
- Online: 159,313

No missing, blank, or unexpected SalesChannel values were found.

## 8.16 OrderStatus

Final distribution:

| OrderStatus | Count |
|---|---:|
| Completed | 252,268 |
| Cancelled | 83,979 |
| Returned | 83,759 |

## 8.17 SalesChannel vs Store SalesChannel

Cross-table results:

| SalesChannel | Store SalesChannel | Rows |
|---|---|---:|
| Online | Omnichannel | 85,727 |
| Online | Physical Store | 73,556 |
| Physical Store | Omnichannel | 140,449 |
| Physical Store | Physical Store | 120,199 |

Matched rows:

- 419,931

The remaining 75 sales rows were associated with invalid StoreIDs.

The Online/Physical Store combination was treated as a business clarification rather than an automatic error.

Temporarily Closed stores were not automatically excluded because no effective closure dates existed.

# 9. Cross-Table Referential Integrity

Final Silver checks identified:

| Relationship | Exception |
|---|---:|
| Sales → Customers | 250 invalid non-NULL references |
| Sales → Products | 150 invalid references |
| Sales → Stores | 75 invalid references |
| Sales → Employees | 75 invalid references |
| Stores → Employees | 0 invalid references |
| Employees → Stores | 1 missing StoreID |

Sales missing-reference totals:

- CustomerID missing: 420
- EmployeeID missing: 336

These records were not deleted.

# 10. Silver Quality Status Controls

## Sales

Total: 420,006

Missing quality-status classifications:

- Customer: 0
- Product: 0
- Store: 0
- Employee: 0
- Quantity: 0
- UnitPrice: 0

## Products

Total: 500

Missing quality-status classifications:

- UnitCost: 0
- Supplier: 0

## Employees

Total: 300

Missing StoreQualityStatus:

- 0

## Customers

Total: 15,000

Missing quality-status classifications:

- Gender: 0
- Phone: 0
- CustomerSegment: 0

## Stores

Total: 50

Missing quality-status classifications:

- StoreID: 0
- StoreType: 0
- StoreStatus: 0
- Region: 0

# 11. Final Silver Row Counts

| Silver Table | Row Count |
|---|---:|
| Customers_Silver | 15,000 |
| Products_Silver | 500 |
| Stores_Silver | 50 |
| Employees_Silver | 300 |
| Sales_Silver | 420,006 |

# 12. Gold Dimensional Model

The Gold layer uses a star-schema design.

```text
                 DimDate
                    |
                    |
DimCustomer ---- FactSales ---- DimProduct
                    |
                    |
                 DimStore
                    |
                    |
               DimEmployee
```

FactSales contains surrogate dimension keys.

Dimensions contain business attributes.

Unknown members use surrogate key `0` to preserve fact records whose source business keys cannot be resolved.

# 13. Gold Dimensions

## DimCustomer

Final rows:

- 15,001
- 15,000 real customers
- 1 Unknown Customer

Real business-key uniqueness:

- 15,000 rows
- 15,000 distinct CustomerIDs

Unknown member:

- CustomerKey = 0
- CustomerID = UNKNOWN
- CustomerName = Unknown Customer

## DimProduct

Final rows:

- 501
- 500 real products
- 1 Unknown Product

Unknown member:

- ProductKey = 0
- ProductID = UNKNOWN
- ProductName = Unknown Product

## DimStore

Final rows:

- 51
- 50 real stores
- 1 Unknown Store

Unknown member:

- StoreKey = 0
- StoreID = UNKNOWN
- StoreName = Unknown Store

## DimEmployee

Final rows:

- 301
- 300 real employees
- 1 Unknown Employee

Unknown member:

- EmployeeKey = 0
- EmployeeID = UNKNOWN
- EmployeeName = Unknown Employee

# 14. DimDate

DimDate covers:

- 2023-01-01 through 2026-06-30

Final rows:

- 1,277
- 1,277 distinct dates
- No date gaps

Columns include:

- DateKey
- FullDate
- Year
- Quarter
- Month
- MonthName
- MonthNumber
- Week
- Day
- DayName

# 15. FactSales

## 15.1 Grain

One row per sales transaction line represented by TransactionID.

## 15.2 Structure

FactSales contains:

- SalesKey
- TransactionID
- OrderID
- OrderLineNumber
- DateKey
- CustomerKey
- ProductKey
- StoreKey
- EmployeeKey
- Quantity
- UnitPrice
- DiscountPercent
- TaxPercent
- PaymentMethod
- SalesChannel
- OrderStatus

## 15.3 Fact Reconciliation

Silver Sales rows:

- 420,006

Gold FactSales rows:

- 420,006

Distinct FactSales TransactionIDs:

- 420,006

Missing TransactionIDs:

- 0

# 16. Gold Unknown Member Mapping

| Dimension | Unknown Rows |
|---|---:|
| Customer | 670 |
| Product | 150 |
| Store | 75 |
| Employee | 411 |
| Date | 0 |

Customer unknown rows:

- 420 missing CustomerIDs
- 250 invalid CustomerIDs

Employee unknown rows:

- 336 missing EmployeeIDs
- 75 invalid EmployeeIDs

# 17. Gold Referential Integrity

Physical foreign keys were created between FactSales and:

- DimCustomer
- DimProduct
- DimStore
- DimEmployee
- DimDate

Final referential-integrity validation returned zero invalid foreign-key references.

FactSales key NULL validation:

| Key | NULL Rows |
|---|---:|
| DateKey | 0 |
| CustomerKey | 0 |
| ProductKey | 0 |
| StoreKey | 0 |
| EmployeeKey | 0 |

# 18. Important Business/Data-Quality Decisions

### Raw data remains immutable

The Bronze/staging layer was not used as the transformation target. Cleaning and standardization were performed in Silver.

### Duplicates were investigated before deletion

Duplicates were profiled before deletion. Where records represented repeated versions of the same business entity, one record was retained.

### Unknown values were not invented

Where the correct business value could not be determined:

- NULL was preserved
- Quality-status fields were used where appropriate
- Gold used Unknown members for unresolved references

### Referential exceptions were retained

Invalid Sales references were retained rather than deleting transactions.

### Quantity was not automatically corrected

Invalid Quantity values were preserved because replacement values could not be established reliably.

### UnitPrice NULL and zero were preserved

Their business meaning was not established from the available source data.

### Missing product Supplier and UnitCost were preserved

No reliable replacement source existed.

### Store/channel relationships were treated as business clarification

Online sales associated with Physical Store classifications were not automatically considered invalid.

### Temporarily Closed stores were retained

No effective closure dates existed, so historical sales were not automatically removed.

### UnitCost was not copied into FactSales

Silver Product UnitCost represents the current product master cost, not historical cost-at-sale.

### Revenue measures were deferred

Revenue, gross sales, tax amount, discount amount, and net sales were not calculated during the warehouse build because business treatment of Cancelled/Returned transactions and invalid Quantity/UnitPrice values had not been formally established.

# 19. Known Limitations

1. No historical effective dates exist for StoreStatus.
2. No historical product cost-at-sale exists.
3. Some sales references cannot be resolved to master data.
4. Some customer demographic attributes are missing.
5. Some customer emails required deterministic repair based on the structure present in the dataset.
6. Quantity contains invalid values that remain unresolved.
7. UnitPrice contains NULL and zero values whose business meaning is not established.
8. Employee EMP0058 has no StoreID in the source.
9. Quality-status fields identify data conditions but do not provide full historical audit lineage for every transformation.
10. Revenue calculations were intentionally deferred until business rules are defined.

# 20. Final Project 1 Data State

The completed Silver layer contains:

- 15,000 Customers
- 500 Products
- 50 Stores
- 300 Employees
- 420,006 Sales transaction lines

The completed Gold layer contains:

- 15,001 DimCustomer rows
- 501 DimProduct rows
- 51 DimStore rows
- 301 DimEmployee rows
- 1,277 DimDate rows
- 420,006 FactSales rows

The warehouse preserves all sales records while resolving unavailable master-data relationships through Unknown dimension members.

The project demonstrates:

- Bronze ingestion
- Data profiling
- Duplicate detection
- Standardization
- Type conversion
- Data-quality classification
- Referential-integrity analysis
- Silver-layer transformation
- Dimensional modeling
- Surrogate-key mapping
- Unknown-member handling
- Gold-layer validation
- End-to-end row-count reconciliation
