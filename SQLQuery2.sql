----PROJECT NUM 2----
GO
USE WideWorldImporters
GO



--1--
WITH TBL 
AS
    (SELECT O.OrderID, 
            SUM(IL.ExtendedPrice - IL.TaxAmount) AS Total,
            YEAR(O.OrderDate) AS 'Year',
            MONTH(O.OrderDate) AS 'Month'
     FROM Sales.Orders O
     JOIN Sales.Invoices I 
	 ON O.OrderID = I.OrderID
     JOIN Sales.InvoiceLines IL
	 ON I.InvoiceID = IL.InvoiceID
     GROUP BY O.OrderID, YEAR(O.OrderDate), MONTH(O.OrderDate)),

TBL2 
AS
    (SELECT Year, 
            SUM(Total) AS IncomePerYear, 
            COUNT(DISTINCT Month) AS NumberOfDistinctMonths,
            CAST(SUM(Total) / COUNT(DISTINCT Month) * 12 AS MONEY) AS YearlyLinearIncome,
            LAG(SUM(Total), 1) OVER (ORDER BY Year) AS LG
     FROM TBL
     GROUP BY Year)

SELECT Year, 
       IncomePerYear, 
       NumberOfDistinctMonths, 
       YearlyLinearIncome,
       CAST(ROUND(((YearlyLinearIncome - LG) * 100 / LG), 2) AS MONEY) AS GrowthRate
FROM TBL2




--2--
SELECT *
FROM 
	(SELECT TheYear ,
			TheQuarter, 
			T.CustomerName, 
			SUM (Total) AS IncomePerYear,
			ROW_NUMBER () OVER (PARTITION BY  TheYear ,TheQuarter ORDER BY SUM (Total)DESC) AS DNR
	FROM	
		(SELECT O.OrderID, 
				SUM (il.ExtendedPrice - il.TaxAmount) AS Total,
				YEAR(O.OrderDate) AS TheYear,
				DATEPART(q,O.OrderDate) AS TheQuarter,
				C.CustomerName
		FROM Sales.Orders O
		JOIN Sales.Invoices I
		ON O.OrderID = I.OrderID
		JOIN Sales.InvoiceLines IL
		ON I.InvoiceID = IL.InvoiceID
		JOIN Sales.Customers C
		ON O.CustomerID = C.CustomerID
		GROUP BY C.CustomerName, O.OrderID, O.OrderDate) T
GROUP BY T.CustomerName, TheYear ,TheQuarter) TB
WHERE DNR <=5
ORDER BY TheYear ,TheQuarter




--3--
SELECT 
TOP (10) WITH TIES 
si.StockItemID, 
si.StockItemName,
SUM (il.ExtendedPrice - il.TaxAmount) AS 'Total Profit'
FROM Warehouse.StockItems SI JOIN Sales.InvoiceLines IL
ON si.StockItemID = il.StockItemID
GROUP BY si.StockItemID, si.StockItemName
ORDER BY [Total Profit] DESC
	



--4--
SELECT 
ROW_NUMBER () OVER (ORDER BY SUM(si.RecommendedRetailPrice - si.UnitPrice)DESC) AS RN,
si.StockItemID, si.StockItemName, 
SUM(si.UnitPrice) AS UnitPrice, 
SUM(si.RecommendedRetailPrice) AS RecommendedRetailPrice,
SUM(si.RecommendedRetailPrice - si.UnitPrice) AS NumialProductProfit,
DENSE_RANK () OVER (ORDER BY SUM(si.RecommendedRetailPrice - si.UnitPrice)DESC) AS DNR
FROM Warehouse.StockItems SI 
GROUP BY si.StockItemID, si.StockItemName 
ORDER BY NumialProductProfit DESC




--5--
SELECT  
CONCAT_WS(' - ',s.SupplierID, s.SupplierName) AS SupplierDeatails,
STRING_AGG(CONCAT_WS(' ', si.StockItemID, si.StockItemName), ' / ,')AS ProductDeatails
FROM Purchasing.Suppliers S JOIN Warehouse.StockItems SI
ON S.SupplierID = SI.SupplierID
GROUP BY s.SupplierID, s.SupplierName




--6--
SELECT  TOP (5)
		A.CustomerID,
		A.CityName,
		A.CountryName,
		A.Continent,
		A.Region,
		TotalExtendedPrice

FROM	(SELECT I.CustomerID, CI.CityName, CO.CountryName, CO.Continent, CO.Region,
				SUM(IL.ExtendedPrice) AS ExtendedPrice,
				FORMAT(SUM(IL.ExtendedPrice), '#,#.00') AS TotalExtendedPrice
		FROM Sales.Invoices I 
		JOIN Sales.InvoiceLines IL
		ON I.InvoiceID = IL.InvoiceID
		JOIN Sales.Customers C
		ON I.CustomerID = C.CustomerID
		JOIN Application.Cities CI
		ON C.PostalCityID = CI.CityID
		JOIN Application.StateProvinces S
		ON CI.StateProvinceID = S.StateProvinceID
		JOIN Application.Countries CO
		ON S.CountryID = CO.CountryID
		GROUP BY I.CustomerID, CI.CityName, CO.CountryName, CO.Continent, CO.Region) A
ORDER BY ExtendedPrice DESC




--7--
SELECT 
OrderYear, 
REPLACE(MM, '13', 'GrandTotal') AS OrderMonth,
FORMAT(TotalExtendedPrice,'#,#.00')  AS MonthlyToatl,
CASE WHEN MM = '13'
	 THEN FORMAT(TotalExtendedPrice,'#,#.00') 
	 ELSE FORMAT(SUM(TotalExtendedPrice) OVER (PARTITION BY OrderYear ORDER BY MM), '#,#.00')
	 END AS CumulativeTotal
FROM 
		(SELECT
			YEAR(O.OrderDate) AS OrderYear, 
			MONTH(O.OrderDate) AS MM,
			SUM(IL.ExtendedPrice - IL.TaxAmount) AS TotalExtendedPrice
		FROM Sales.Orders O 
		JOIN Sales.Invoices I ON O.OrderID = I.OrderID
		JOIN Sales.InvoiceLines IL ON I.InvoiceID = IL.InvoiceID
		GROUP BY YEAR(O.OrderDate), MONTH(O.OrderDate)
UNION
		SELECT 
			YEAR(O.OrderDate) AS OrderYear, 
			13 AS MM,
			SUM(IL.ExtendedPrice - IL.TaxAmount) OVER (PARTITION BY YEAR(O.OrderDate)) AS TotalExtendedPrice
			FROM Sales.Orders O 
			JOIN Sales.Invoices I ON O.OrderID = I.OrderID
			JOIN Sales.InvoiceLines IL ON I.InvoiceID = IL.InvoiceID ) T
	
	


--8--
SELECT OrderMonth, [2013], [2014], [2015], [2016]
FROM	(SELECT OrderID,
				MONTH(OrderDate) AS OrderMonth,
				YEAR(OrderDate) AS Orderyear
		FROM Sales.Orders) T
PIVOT (COUNT(OrderID)FOR Orderyear IN ([2013], [2014], [2015], [2016])) PVT
ORDER BY OrderMonth




--9--
 WITH TB
AS
	(SELECT C.CustomerID,
			C.CustomerName,
			O.OrderDate,
			MAX(O.OrderDate) OVER (PARTITION BY C.CustomerID) AS LastOrder,
			LAG (O.orderdate,1) OVER (PARTITION BY  C.CustomerID ORDER BY O.orderdate) AS PreviousOrderDate,
			DATEDIFF (DD, LAG (O.orderdate,1) OVER (PARTITION BY  C.CustomerID ORDER BY O.orderdate),O.orderdate)AS DaysSinceLastOrder1
	FROM Sales.Orders O
	JOIN Sales.Customers C
	ON O.CustomerID = C.CustomerID)

SELECT  
TB.CustomerID, 
TB.CustomerName,
TB.OrderDate, 
PreviousOrderDate,
DATEDIFF(DD, LastOrder, '2016-05-31') AS DaysSinceLastOrder,
AVG (DaysSinceLastOrder1) OVER (PARTITION BY CustomerID ) AS AvgDaysBetweenOrders,
IIF((AVG (DaysSinceLastOrder1) OVER (PARTITION BY CustomerID))*2 >= (DATEDIFF(DD, LastOrder, '2016-05-31')),'Active', 'Potential churn') AS CustomerStatus
FROM TB




--10-- 
GO
WITH P
AS
		(SELECT C.CustomerID, 
				CC.CustomerCategoryName,
				CASE 
				     WHEN C.CustomerName LIKE 'Tailspin%' THEN 'Tailspin Toys'
				     WHEN C.CustomerName LIKE 'Wingtip%' THEN 'Wingtip Toys'
				    ELSE C.CustomerName 
				END AS CustomerName
		FROM Sales.Customers C
		JOIN Sales.CustomerCategories CC
		ON C.CustomerCategoryID = CC.CustomerCategoryID),

P1
AS
		(SELECT P.CustomerCategoryName,
				COUNT (DISTINCT P.CustomerName) AS CustomerCOUNT
		FROM P 
		GROUP BY P.CustomerCategoryName)

SELECT 
P1.CustomerCategoryName, 
P1.CustomerCOUNT,
(SELECT SUM(CustomerCOUNT) FROM P1) AS TotalCustCount,
CONCAT((CAST(CustomerCOUNT AS MONEY) / (SUM(CustomerCOUNT) OVER()) * 100),'%') AS DistributionFactor
FROM P1
ORDER BY P1.CustomerCategoryName
		
















