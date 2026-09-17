# NexMart Enterprise Data Warehouse

## 1. Project Overview

NexMart requires an Enterprise Data Warehouse (EDW) to provide a
centralized and reliable data platform for business analysis and
reporting.

The warehouse will integrate data from multiple operational sources
and transform it into structured, clean, and business-ready analytical
data.

The solution will follow a layered data warehouse architecture:

Source Data → Bronze → Silver → Gold

The initial source data consists of:

- Customers
- Employees
- Products
- Stores
- Sales

The warehouse will be developed using Microsoft SQL Server and T-SQL.

---

## 2. Business Objective

The objective of the NexMart Enterprise Data Warehouse is to provide
a centralized source of reliable data that can be used to understand
and analyze the company's sales operations.

The warehouse should allow business users and analysts to analyze sales
from different business perspectives, including:

- Customer
- Employee
- Product
- Store
- Time

The solution should reduce the need to access operational source data
directly for analytical reporting and provide consistent information
for business intelligence and decision-making.

---

## 3. Business Requirements

The warehouse should provide the ability to analyze NexMart sales and
related business information.

The solution should support questions such as:

- What is the overall sales performance?
- How does sales performance change over time?
- Which products generate the most sales?
- Which stores generate the most sales?
- Which customers generate the most sales?
- What sales activity is associated with employees?
- How many sales transactions occur?
- How much revenue is generated?
- How are sales distributed across products?
- How are sales distributed across stores?
- How are sales distributed across customers?

The exact metrics and calculations will be based on the available source
data and agreed business definitions.

---

## 4. Source Data Requirements

The warehouse must integrate the following source datasets:

### Customers

Customer information required for customer-related analysis.

### Employees

Employee information required for employee-related analysis.

### Products

Product information required for product and sales analysis.

### Stores

Store information required for store-level analysis.

### Sales

Sales transaction information required for sales analysis.

The source data should be retained and made available for the warehouse
ingestion process.

The warehouse design should be based on the actual structure and
business meaning of these source datasets.

---

## 5. Data Integration Requirements

The solution must integrate the available source datasets into a
consistent warehouse environment.

The warehouse should identify and use valid relationships between
business entities where those relationships are supported by the
source data.

Potential relationships to be investigated include:

- Customers and Sales
- Employees and Sales
- Products and Sales
- Stores and Sales

Relationships must be based on valid business keys and actual source
data.

The solution should not assume a relationship solely because two
columns have similar names.

---

## 6. Data Quality Requirements

The warehouse must provide reliable data for analytical use.

The source data should be assessed for common data-quality problems,
including:

- Missing values
- NULL values
- Blank values
- Duplicate records
- Invalid identifiers
- Invalid dates
- Invalid numerical values
- Inconsistent text values
- Inconsistent formats
- Invalid categorical values
- Invalid relationships
- Referential integrity issues

Appropriate data-quality rules should be established for identified
problems.

Data-quality handling should preserve the business meaning of the data.

---

## 7. Bronze Layer Requirements

The Bronze layer will serve as the raw or minimally transformed
landing layer.

The Bronze layer should:

- Receive data from the source datasets.
- Preserve source information.
- Maintain the original meaning of the source data.
- Minimize transformations.
- Provide a reliable input for downstream processing.
- Support traceability back to the source.

The Bronze layer should not be used as the primary business-facing
analytical layer.

---

## 8. Silver Layer Requirements

The Silver layer will contain cleaned and standardized data.

The Silver layer should:

- Clean source data.
- Standardize data formats.
- Standardize values where required.
- Handle missing values according to defined rules.
- Handle duplicate records according to defined rules.
- Validate identifiers.
- Validate dates.
- Validate numerical values.
- Handle invalid values appropriately.
- Apply data-quality rules.
- Prepare consistent data for the analytical layer.

The Silver layer should retain the business entities required for
downstream analytical modeling.

Logical relationships between entities should be validated as part of
the data-quality process.

---

## 9. Gold Layer Requirements

The Gold layer will contain business-ready analytical data.

The Gold layer should:

- Provide data suitable for reporting and analytics.
- Organize data around business processes.
- Provide appropriate fact and dimension structures where required.
- Provide reliable measures.
- Provide descriptive business attributes.
- Support analytical queries efficiently.
- Provide a consistent foundation for business intelligence tools.

The final Gold model should be based on the business requirements and
the validated source and Silver-layer data.

---

## 10. Sales Analysis Requirements

Sales is the primary business process for the initial analytical
requirements.

The warehouse should support analysis of:

- Total sales
- Sales transactions
- Sales by date
- Sales by product
- Sales by store
- Sales by customer
- Sales by employee
- Sales trends
- Sales quantities where available
- Sales amounts where available

The final definitions of sales metrics must be consistent throughout
the warehouse and reporting layer.

---

## 11. Customer Analysis Requirements

The warehouse should support customer-related sales analysis where a
valid relationship between Customers and Sales exists.

Analysis should include, where supported by the source data:

- Sales by customer
- Customer transaction activity
- Customer purchasing activity
- Customer contribution to sales

---

## 12. Employee Analysis Requirements

The warehouse should support employee-related sales analysis where a
valid relationship between Employees and Sales exists.

Analysis should include, where supported by the source data:

- Sales associated with employees
- Employee transaction activity
- Employee-related sales performance

---

## 13. Product Analysis Requirements

The warehouse should support product-level sales analysis.

Analysis should include, where supported by the source data:

- Sales by product
- Quantity sold
- Sales amount
- Product sales performance
- Product trends over time

---

## 14. Store Analysis Requirements

The warehouse should support store-level sales analysis.

Analysis should include, where supported by the source data:

- Sales by store
- Store transaction activity
- Store sales performance
- Store contribution to sales
- Store trends over time

Store relationships must be based on valid source data.

---

## 15. Time Analysis Requirements

The warehouse should support analysis of sales over time where valid
sales-date information is available.

The solution should support appropriate time-based analysis, including:

- Daily analysis
- Monthly analysis
- Quarterly analysis
- Yearly analysis

A dedicated date dimension may be used in the Gold layer where it is
appropriate for the analytical requirements.

---

## 16. Data Validation Requirements

The warehouse should include validation processes to ensure the
accuracy and reliability of the data.

Validation should cover:

- Completeness
- Duplicate records
- NULL values
- Invalid values
- Referential integrity
- Data consistency
- Transformation accuracy
- Business rules
- Analytical calculations

Data should be validated after major processing stages.

---

## 17. Data Reconciliation Requirements

The warehouse should provide reconciliation between processing layers
where applicable.

Reconciliation should be used to verify that:

- Source data is loaded correctly.
- Bronze data represents the source correctly.
- Silver transformations produce the expected results.
- Gold data is consistent with the validated Silver data.
- Analytical measures are calculated correctly.

Records intentionally excluded or transformed should have an
understandable reason.

---

## 18. Data Traceability Requirements

The warehouse should maintain a clear flow of data:

Source
  ↓
Bronze
  ↓
Silver
  ↓
Gold
  ↓
Reporting / Analytics

The transformation process should be understandable and traceable.

SQL transformation logic should be maintained in version-controlled
scripts.

---

## 19. Technical Requirements

The initial implementation will use:

- Microsoft SQL Server
- T-SQL
- Git
- GitHub

The warehouse should use SQL-based processes for:

- Data loading
- Data transformation
- Data validation
- Data-quality checks
- Analytical querying

---

## 20. Maintainability Requirements

The solution should be structured so that it can be maintained and
extended in the future.

The warehouse should follow:

- Clear layer separation
- Consistent naming conventions
- Organized SQL scripts
- Reusable transformation logic
- Documented business rules
- Documented data models
- Version-controlled development

---

## 21. Reporting and Business Intelligence Requirements

The Gold layer should provide a suitable foundation for business
intelligence and reporting.

Business users should be able to use the analytical data without
having to work directly with the raw operational source data.

The warehouse should provide consistent definitions for important
business metrics.

The final Gold layer should be suitable for integration with a
business intelligence tool such as Power BI.

---

## 22. Documentation Requirements

The project should maintain documentation covering:

- Business requirements
- Source data
- Data dictionary
- Data-quality rules
- Data warehouse architecture
- Data model
- Transformation logic
- Testing
- Analytical requirements
- Project setup and usage

Documentation should be maintained as part of the project lifecycle.

---

## 23. Version Control Requirements

The project will be maintained using Git and GitHub.

Development should be organized into logical commits.

Examples include:

- `docs: add business requirements`
- `docs: add source data documentation`
- `bronze: create bronze tables`
- `bronze: implement data loading`
- `silver: implement data cleaning`
- `silver: implement data standardization`
- `gold: create analytical model`
- `gold: implement gold transformations`
- `test: add data quality tests`
- `docs: update data model`
- `docs: update project README`

The repository should maintain the development history of the
warehouse.

---

## 24. Expected Deliverables

The completed project should provide:

- Source data
- Bronze layer
- Silver layer
- Gold layer
- Data-quality rules
- Data-validation tests
- Data reconciliation
- Analytical SQL queries
- Data model documentation
- Architecture documentation
- Business requirements documentation
- Project documentation
- GitHub repository
- Business intelligence/reporting output where applicable

---

## 25. Project Success Criteria

The NexMart Enterprise Data Warehouse will meet the project
requirements when it provides:

1. A centralized warehouse for the required source data.
2. A functioning Bronze, Silver, and Gold architecture.
3. Reliable and standardized analytical data.
4. Valid relationships between business entities where supported by
   the source data.
5. Appropriate handling of data-quality problems.
6. Reliable sales metrics.
7. Support for customer, employee, product, store, and time-based
   analysis where applicable.
8. Data validation and reconciliation processes.
9. A business-ready analytical model.
10. Documentation and version-controlled development.

---

## 26. Scope

### In Scope

- Customers
- Employees
- Products
- Stores
- Sales
- Data ingestion
- Data cleaning
- Data transformation
- Data quality
- Data validation
- Data modeling
- Sales analytics
- Business intelligence readiness
- Documentation
- Git and GitHub version control

### Out of Scope

The following are outside the initial scope of this project:

- Real-time data streaming
- Machine learning
- Predictive analytics
- Advanced data science
- Production cloud deployment
- Automated enterprise orchestration

These capabilities may be considered as future extensions.
