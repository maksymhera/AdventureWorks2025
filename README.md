# 📊 Executive Analytics Dashboard — AdventureWorks 2025

A professional BI analytics solution built on top of the **AdventureWorks2025** relational database. This project includes a T-SQL database deployment script for data mart modeling and an interactive **Power BI** dashboard designed with a dark corporate aesthetic.

---

## 📁 Project Structure

* **`AdventureWorks2025_SQL.sql`** — Full T-SQL script for database restoration and creation of the analytical view layer (Data Mart).


* **`AdventureWorks2025_PowerBI.pbix`** — Power BI report file containing the **Executive Overview** and **Customers & Products Performance** analytical pages.



---

## ⚙️ 1. Technical Stack & Data Architecture (SQL Engine)

To maximize Power BI performance and avoid complex runtime joins, all business logic and transformations are offloaded to prepared SQL views:

### Data Mart Views



1. **`dbo.vw_sales_flat`** — Denormalized core sales fact table combining order header details, line items, customer info, product hierarchy, and geography.


2. **`dbo.vw_dim_date`** — Comprehensive date dimension (2010–2030) containing fiscal quarter labels, week numbers, and explicit sorting keys (`MonthName`, `YearMonthKey`).


3. **`dbo.vw_customer_summary`** — Aggregated customer metrics (LTV, total order count, first/last purchase dates, and `New` vs `Returned` segmentation logic).


4. **`dbo.vw_product_performance`** — Product performance metrics with SQL window functions calculating revenue share percentages (`RevenueSharePercent`).


5. **`dbo.vw_customer_rfm`** — Customer segmentation using the **RFM** framework (Recency, Frequency, Monetary) powered by T-SQL `NTILE(4)` ranking.


6. **`dbo.vw_monthly_sales`** & **`dbo.vw_category_monthly_matrix`** — Aggregated matrices designed for line chart performance and matrix heatmaps.



---

## 🎨 2. Visual Styling & UI Guidelines

The dashboard strictly adheres to modern Senior BI dark UI design principles:

* **Canvas Background:** `#12161F` (Deep dark navy)


* **Card & Visual Containers:** `#1E293B` (Dark slate with subtle borders)


* **Primary Accent Color:** `#A7620D` (Warm amber/gold accent for chart series and focus elements)


* **Typography:** `Segoe UI` (Crisp white `#FFFFFF` for data callouts, muted `#94A3B8` gray for axis labels and category descriptors)



---

## 📈 3. Dashboard Page Overview

### 1️⃣ Page 1: Executive Overview



Designed for executive decision-makers to track high-level company health:

* **KPI Header Block:** `Total Revenue` ($109.85M), `Total Orders` (31K), `AVG Order Value` ($3.49K), and `Total Customers` (19K).


* **Monthly Revenue Trend:** Smooth line chart displaying month-over-month revenue dynamics sorted chronologically (Jan–Dec).


* **Top Cities by Revenue:** Horizontal bar chart highlighting top-performing geographic markets (led by Toronto at $4.5M).


* **Revenue by Product Category:** Column chart breakdown across major lines (`Bikes`, `Components`, `Clothing`, `Accessories`).



### 2️⃣ Page 2: Customers & Products Performance



Deep-dive page focusing on product traction and customer retention dynamics:

* **Customer Acquisition & Retention:** Donut chart for customer types paired with a dedicated `Repeat Customer Rate` KPI card (39.07%).


* **Top 10 Rankings:** Dedicated ranking charts for `Top 10 Customers` and `Top 10 Products` with clean inline data labels.


* **Monthly Category Matrix:** Heatmap matrix showing revenue distribution across product categories over time.



---

## 🚀 4. Deployment Instructions

### Step 1: Database Restoration & View Deployment

1. Ensure the `AdventureWorks2025.bak` file is placed in your SQL Server default backup directory.


2. Open **SQL Server Management Studio (SSMS)**.


3. Execute the provided `AdventureWorks2025_Setup.sql` script. The script will:


* Restore the `AdventureWorks2025` database with overwrite permissions.


* Automatically generate all required database views (`vw_sales_flat`, `vw_dim_date`, etc.).





### Step 2: Power BI Connection

1. Launch **Power BI Desktop**.


2. Connect to your local SQL Server instance (`Get Data` $\rightarrow$ `SQL Server`).


3. Select `AdventureWorks2025` and import the generated views.


4. Establish a 1-to-Many relationship between `vw_dim_date[DateKey]` and `vw_sales_flat[OrderDate]`.


5. Ensure `MonthName` is set to **Sort by Column** $\rightarrow$ `CalendarMonth` for accurate chronological display.
