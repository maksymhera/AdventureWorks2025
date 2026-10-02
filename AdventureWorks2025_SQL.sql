USE [master];
GO

RESTORE DATABASE AdventureWorks2025
FROM DISK = 'C:\Program Files\Microsoft SQL Server\MSSQL17.MSSQLSERVER\MSSQL\Backup\AdventureWorks2025.bak'
WITH
    MOVE 'AdventureWorks' TO 'C:\Program Files\Microsoft SQL Server\MSSQL17.MSSQLSERVER\MSSQL\DATA\AdventureWorks2025.mdf',
    MOVE 'AdventureWorks_log' TO 'C:\Program Files\Microsoft SQL Server\MSSQL17.MSSQLSERVER\MSSQL\DATA\AdventureWorks2025.ldf',
    REPLACE;
GO

USE [AdventureWorks2025];
GO

USE [AdventureWorks2025];
GO

CREATE OR ALTER VIEW dbo.vw_sales_flat AS
SELECT 
    -- Заказ
    soh.SalesOrderID,
    soh.OrderDate,
    YEAR(soh.OrderDate) AS OrderYear,
    DATEPART(QUARTER, soh.OrderDate) AS OrderQuarter,
    MONTH(soh.OrderDate) AS OrderMonth,
    soh.Status AS OrderStatus,
    
    -- Клиент
    c.CustomerID,
    COALESCE(s.Name, CONCAT(per.FirstName, ' ', per.LastName)) AS CustomerName,
    cr.Name AS CountryRegion,
    a.City,
    
    -- Товар
    p.ProductID,
    p.Name AS ProductName,
    p.Color,
    pcat.Name AS CategoryName,      -- Верхнеуровневая категория (Bikes, Components и т.д.)
    psub.Name AS SubcategoryName,   -- Листовая категория (Mountain Bikes, Road Bikes)
    
    -- Метрики позиции
    sod.OrderQty,
    sod.UnitPrice,
    sod.UnitPriceDiscount,
    sod.LineTotal
FROM Sales.SalesOrderHeader soh
JOIN Sales.SalesOrderDetail sod 
    ON soh.SalesOrderID = sod.SalesOrderID
JOIN Sales.Customer c 
    ON soh.CustomerID = c.CustomerID
LEFT JOIN Person.Person per 
    ON c.PersonID = per.BusinessEntityID
LEFT JOIN Sales.Store s 
    ON c.StoreID = s.BusinessEntityID
LEFT JOIN Person.Address a 
    ON soh.ShipToAddressID = a.AddressID
LEFT JOIN Person.StateProvince sp 
    ON a.StateProvinceID = sp.StateProvinceID
LEFT JOIN Person.CountryRegion cr 
    ON sp.CountryRegionCode = cr.CountryRegionCode
JOIN Production.Product p 
    ON sod.ProductID = p.ProductID
LEFT JOIN Production.ProductSubcategory psub 
    ON p.ProductSubcategoryID = psub.ProductSubcategoryID
LEFT JOIN Production.ProductCategory pcat 
    ON psub.ProductCategoryID = pcat.ProductCategoryID;
GO

USE [AdventureWorks2025];
GO

CREATE OR ALTER VIEW dbo.vw_customer_summary AS
SELECT 
    CustomerID,
    CustomerName,
    CountryRegion,
    COUNT(DISTINCT SalesOrderID) AS TotalOrders,
    SUM(LineTotal) AS TotalRevenue,
    MIN(OrderDate) AS FirstOrderDate,
    MAX(OrderDate) AS LastOrderDate,
    AVG(LineTotal) AS AvgLineValue,
    SUM(LineTotal) / NULLIF(COUNT(DISTINCT SalesOrderID), 0) AS AvgCheck,
    CASE 
        WHEN COUNT(DISTINCT SalesOrderID) >= 2 THEN 'Returned'
        ELSE 'New'
    END AS CustomerSegment
FROM dbo.vw_sales_flat
GROUP BY 
    CustomerID, 
    CustomerName, 
    CountryRegion;
GO

USE [AdventureWorks2025];
GO

CREATE OR ALTER VIEW dbo.vw_product_performance AS
WITH ProductAgg AS (
    SELECT 
        ProductID,
        ProductName,
        ISNULL(CategoryName, 'No Category') AS CategoryName,
        SUM(OrderQty) AS TotalUnitsSold,
        SUM(LineTotal) AS TotalRevenue,
        COUNT(DISTINCT SalesOrderID) AS TotalOrders
    FROM dbo.vw_sales_flat
    GROUP BY 
        ProductID, 
        ProductName, 
        ISNULL(CategoryName, 'No Category')
)
SELECT 
    ProductID,
    ProductName,
    CategoryName,
    TotalUnitsSold,
    TotalRevenue,
    TotalOrders,
    CAST(TotalRevenue * 100.0 / SUM(TotalRevenue) OVER () AS DECIMAL(5,2)) AS RevenueSharePercent
FROM ProductAgg;
GO

USE [AdventureWorks2025];
GO

CREATE OR ALTER VIEW dbo.vw_monthly_sales AS
SELECT 
    OrderYear,
    OrderMonth,
    DATEFROMPARTS(OrderYear, OrderMonth, 1) AS YearMonthDate,
    SUM(LineTotal) AS MonthlyRevenue,
    COUNT(DISTINCT SalesOrderID) AS TotalOrders,
    SUM(OrderQty) AS TotalUnitsSold,
    SUM(LineTotal) / NULLIF(COUNT(DISTINCT SalesOrderID), 0) AS AvgCheck
FROM dbo.vw_sales_flat
GROUP BY 
    OrderYear, 
    OrderMonth;
GO

USE [AdventureWorks2025];
GO

CREATE OR ALTER VIEW dbo.vw_dim_date AS
WITH N1 AS (SELECT 1 AS n UNION ALL SELECT 1),
N2 AS (SELECT 1 AS n FROM N1 a, N1 b),
N3 AS (SELECT 1 AS n FROM N2 a, N2 b),
N4 AS (SELECT 1 AS n FROM N3 a, N3 b),
N5 AS (SELECT 1 AS n FROM N4 a, N4 b),
Numbers AS (SELECT ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1 AS N FROM N5),
Dates AS (
    SELECT DATEADD(DAY, N, '2010-01-01') AS CalendarDate
    FROM Numbers
    WHERE DATEADD(DAY, N, '2010-01-01') <= '2030-12-31'
)
SELECT 
    CalendarDate AS DateKey,
    YEAR(CalendarDate) AS CalendarYear,
    MONTH(CalendarDate) AS CalendarMonth,
    FORMAT(CalendarDate, 'MMMM') AS MonthName,
    DATEPART(QUARTER, CalendarDate) AS CalendarQuarter,
    CONCAT('Q', DATEPART(QUARTER, CalendarDate)) AS QuarterLabel,
    DATEPART(WEEK, CalendarDate) AS WeekNumberOfYear,
    FORMAT(CalendarDate, 'yyyy-MM') AS YearMonthKey
FROM Dates;
GO

USE [AdventureWorks2025];
GO
USE [AdventureWorks2025];
GO

CREATE OR ALTER VIEW dbo.vw_customer_rfm AS
WITH MaxDate AS (
    SELECT MAX(OrderDate) AS ReferenceDate FROM dbo.vw_sales_flat
),
CustomerMetrics AS (
    SELECT 
        f.CustomerID,
        f.CustomerName,
        DATEDIFF(DAY, MAX(f.OrderDate), (SELECT ReferenceDate FROM MaxDate)) AS RecencyDays,
        COUNT(DISTINCT f.SalesOrderID) AS FrequencyOrders,
        SUM(f.LineTotal) AS MonetaryValue
    FROM dbo.vw_sales_flat f
    GROUP BY f.CustomerID, f.CustomerName
)
SELECT 
    CustomerID,
    CustomerName,
    RecencyDays,
    FrequencyOrders,
    MonetaryValue,
    NTILE(4) OVER (ORDER BY RecencyDays DESC) AS R_Score,
    NTILE(4) OVER (ORDER BY FrequencyOrders ASC) AS F_Score,
    NTILE(4) OVER (ORDER BY MonetaryValue ASC) AS M_Score
FROM CustomerMetrics;
GO

CREATE OR ALTER VIEW dbo.vw_category_monthly_matrix AS
SELECT 
    ISNULL(CategoryName, 'No Category') AS MainCategory,
    OrderYear,
    OrderMonth,
    FORMAT(DATEFROMPARTS(OrderYear, OrderMonth, 1), 'yyyy-MM') AS YearMonthKey,
    SUM(LineTotal) AS CategoryRevenue,
    SUM(OrderQty) AS CategoryUnitsSold
FROM dbo.vw_sales_flat
GROUP BY 
    ISNULL(CategoryName, 'No Category'),
    OrderYear,
    OrderMonth;
GO