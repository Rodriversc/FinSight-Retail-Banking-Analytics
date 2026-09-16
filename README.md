# FinSight — Retail Banking Analytics
 
An end-to-end data analytics portfolio project using **Microsoft SQL Server, Python, pandas and matplotlib**.
 
FinSight simulates a retail banking environment with customer, account, loan and transaction data. The project demonstrates the complete analytical workflow: from raw data validation and SQL cleaning to customer segmentation, credit-risk analysis, suspicious-transaction analysis and Python-based exploratory data analysis.
 
> **Important:** All data used in this project is fully synthetic.  
> No real customer, account, loan or transaction data is included.
 
---
 
## Project Overview
 
The project analyses four related datasets:
 
| Dataset | Records |
|---|---:|
| Customers | 2,500 |
| Accounts | 4,088 |
| Loans | 700 |
| Raw Transactions | 10,040 |
| Clean Unique Transactions | 10,000 |
 
The raw transaction dataset deliberately contains duplicate transaction IDs and missing categorical values to create a realistic data-cleaning workflow.
 
The dataset covers activity from **January 2024 to August 2026**.
 
---
 
## Business Questions
 
This project investigates questions such as:
 
- How do inflows, outflows and net cash flow evolve over time?
- Which transaction categories account for the highest spending?
- How do customer segments differ in income, product usage and digital adoption?
- How does loan performance differ across risk groups?
- Which customers show payment delinquency or default signals?
- Which transaction channels show higher levels of suspicious activity?
- Is suspicious activity different between domestic and international transactions?
- Which customers combine multiple financial risk indicators?
- How can customer, account, loan and transaction data be combined into a Customer 360 view?
 
---
 
## Technology Stack
 
| Technology | Purpose |
|---|---|
| Microsoft SQL Server 2022 | Database and SQL analysis |
| SQL Server Management Studio | Database management and queries |
| Python | Exploratory analysis |
| pandas | Data manipulation |
| matplotlib | Data visualisation |
| SQLAlchemy | SQL Server connection |
| pyodbc | ODBC database connectivity |
| Jupyter / VS Code | Python notebook environment |
| GitHub | Portfolio and version control |
 
---
 
## Repository Structure
 
```text
FinSight-Retail-Banking-Analytics/
│
├── Data/
│   ├── customers.csv
│   ├── accounts.csv
│   ├── loans.csv
│   └── transactions.csv
│
├── Sql/
│   ├── 01_data_quality_and_cleaning.sql
│   ├── 02_financial_and_customer_analysis.sql
│   ├── 03_credit_risk_analysis.sql
│   ├── 04_suspicious_transaction_analysis.sql
│   ├── 05_monthly_trend_analysis.sql
│   ├── 06_account_and_product_analysis.sql
│   ├── 07_customer_360_analysis.sql
│   └── 08_views_and_final_kpis.sql
│
├── Notebooks/
│   └── FinSight_EDA.ipynb
│
├── Images/
│
├── Outputs/
│
├── README.md
├── requirements.txt
└── .gitignore
```
 
---
 
# SQL Analysis
 
## 1. Data Quality & Cleaning
 
The SQL workflow starts by validating the raw imported tables.
 
Checks include:
 
- table row counts
- duplicate transaction IDs
- missing categorical values
- account/customer relationships
- transaction deduplication
 
Duplicate transactions are identified using:
 
```sql
ROW_NUMBER() OVER (
    PARTITION BY transaction_id
    ORDER BY transaction_datetime
)
```
 
The original raw table is preserved, while a separate cleaned table is created:
 
```text
dbo.transactions_clean
```
 
Missing category and merchant-country values are labelled:
 
```text
Unknown
```
 
A new feature is also created:
 
```text
flow_direction
```
 
with transactions classified as either:
 
```text
Inflow
Outflow
```
 
---
 
## 2. Financial Analysis
 
Financial analysis includes:
 
- total inflow
- total outflow
- net cash flow
- monthly cash-flow trends
- transaction volume
- spending by category
- customer-level financial behaviour
 
Monthly analysis is used to identify changes in transaction activity and spending patterns over time.
 
---
 
## 3. Customer Segmentation
 
Customer behaviour is compared across banking segments using metrics such as:
 
- annual income
- risk score
- number of accounts
- number of loans
- net cash flow
- outstanding credit
- digital adoption
 
This creates a clearer view of how different customer groups interact with the bank.
 
---
 
## 4. Credit Risk Analysis
 
Loan analysis evaluates:
 
- loan status
- outstanding balances
- interest rates
- days past due
- customer risk scores
- defaults
- default rates
 
Customers are grouped into three synthetic risk categories:
 
```text
High Risk     risk score < 600
Medium Risk   risk score 600–699
Low Risk      risk score >= 700
```
 
Higher synthetic risk scores represent lower modelled credit risk.
 
SQL Server `BIT` fields such as `default_flag` are converted to integers during aggregation:
 
```sql
SUM(CAST(default_flag AS INT))
```
 
---
 
## 5. Suspicious Transaction Analysis
 
The project also investigates transaction records flagged as suspicious.
 
Analysis includes:
 
- overall suspicious transaction rate
- domestic vs international activity
- transaction channel
- transaction category
- transaction size
- customer segment
- customer risk group
 
These flags are synthetic analytical indicators and should **not** be interpreted as confirmed fraud.
 
---
 
## 6. Product & Account Analysis
 
Account analysis investigates:
 
- account types
- account status
- opening balances
- interest rates
- product penetration
- credit-card usage
- number of products per customer
 
The analysis helps identify differences in banking-product usage between customer segments.
 
---
 
## 7. Customer 360
 
Customer, account, loan and transaction information is combined into a customer-level analytical dataset.
 
Separate aggregation steps are performed before joining the tables. This prevents many-to-many joins from artificially multiplying values.
 
The resulting Customer 360 view contains information such as:
 
- customer profile
- account ownership
- number of financial products
- loan exposure
- outstanding credit
- delinquency
- defaults
- transaction activity
- inflows and outflows
- net cash flow
- suspicious activity
 
---
 
## 8. SQL Views
 
Three reusable analytical SQL views are created:
 
```text
dbo.vw_customer_summary
dbo.vw_monthly_financial_kpis
dbo.vw_risk_monitoring
```
 
These views form the main data source for the Python analysis.
 
---
 
# Python Exploratory Data Analysis
 
The SQL Server views and cleaned transaction data are imported directly into Python.
 
The notebook includes:
 
### Data Quality & Descriptive Statistics
 
Validation of:
 
- missing values
- duplicate rows
- descriptive statistics
- data distributions
 
### Cash Flow & Transaction EDA
 
Visual analysis of:
 
- monthly inflows
- monthly outflows
- net cash flow
- transaction volumes
- transaction categories
- transaction channels
- transaction amount distributions
 
### Customer Segmentation
 
Comparison of customer segments using:
 
- income
- risk score
- account usage
- loan usage
- cash flow
- digital adoption
 
### Credit Risk EDA
 
Investigation of:
 
- risk-score distributions
- default rates
- outstanding credit
- loan delinquency
- debt-to-income indicators
- customer risk profiles
 
### Suspicious Transaction EDA
 
Investigation of suspicious activity by:
 
- channel
- category
- international status
- transaction amount
- customer segment
- risk group
 
### Correlation & Deeper Analysis
 
Customer-level financial metrics are used to explore relationships between variables including:
 
```text
Annual Income
Risk Score
Outstanding Credit
Cash Flow
Days Past Due
Defaults
Transaction Activity
Suspicious Transactions
```
 
Correlation represents association only and does not imply causation.
 
---
 
# Final Portfolio Outputs
 
Python automatically exports final analytical tables to the `Outputs/` directory.
 
Examples include:
 
```text
executive_kpis.csv
customer_segment_summary.csv
credit_risk_summary.csv
suspicious_channel_summary.csv
risk_monitoring_summary.csv
domestic_international_summary.csv
business_insights.txt
```
 
Final visualisations are stored in:
 
```text
Images/
```
 
Selected portfolio visuals include:
 
```text
Monthly Inflow vs Outflow
Spending by Category
Average Income by Customer Segment
Default Rate by Risk Group
Suspicious Transaction Rate by Channel
Customers by Monitoring Level
Customer Correlation Matrix
Loan Delinquency Distribution
```
 
---
 
# Running the Project
 
## Python Requirements
 
Install the required Python libraries using:
 
```bash
pip install -r requirements.txt
```
 
The project uses:
 
```text
pandas
matplotlib
sqlalchemy
pyodbc
jupyter
```
 
---
 
## SQL Server Connection
 
The Python notebook connects to a local Microsoft SQL Server database called:
 
```text
FinSight
```
 
Before running the notebook, replace:
 
```python
server = r"YOUR_SERVER_NAME"
```
 
with the name of your own SQL Server instance.
 
Example connection configuration:
 
```python
from sqlalchemy import create_engine
from sqlalchemy.engine import URL
 
connection_string = (
    "DRIVER={ODBC Driver 18 for SQL Server};"
    "SERVER=YOUR_SERVER_NAME;"
    "DATABASE=FinSight;"
    "Trusted_Connection=yes;"
    "TrustServerCertificate=yes;"
)
 
connection_url = URL.create(
    "mssql+pyodbc",
    query={"odbc_connect": connection_string}
)
 
engine = create_engine(connection_url)
```
 
Local server names, passwords or other credentials should never be committed to GitHub.
 
---
 
# Skills Demonstrated
 
This project demonstrates practical experience with:
 
### SQL
 
```text
SELECT
JOIN
GROUP BY
CASE
CTEs
ROW_NUMBER()
LAG()
HAVING
Conditional Aggregation
SQL Views
Data Cleaning
Data Validation
Customer 360 Modelling
```
 
### Python
 
```text
pandas
matplotlib
SQLAlchemy
pyodbc
Data Cleaning
Exploratory Data Analysis
Data Visualisation
Correlation Analysis
Business KPI Development
```
 
### Business Analytics
 
```text
Retail Banking Analytics
Customer Segmentation
Cash Flow Analysis
Credit Risk
Loan Delinquency
Product Analysis
Suspicious Transaction Analysis
Customer Monitoring
Business Insight Generation
```
 
---
 
# Analytical Disclaimer
 
This project was designed as a **data analytics portfolio case study**.
 
All customers, financial products, loans and transactions are synthetically generated.
 
The synthetic dataset includes intentionally designed behavioural patterns for analytical purposes.
 
Results therefore demonstrate the analytical workflow and should not be interpreted as findings about real banking customers.
 
---
 
## Author
 
**Rodrigo V.**
 
Data Analytics Portfolio Project  
FinSight — Retail Banking Analytics