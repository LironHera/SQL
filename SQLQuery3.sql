----PROJECT NUM 2 - Second Option----
GO
USE WideWorldImporters
GO


--1--
SELECT *,
(YearlyLinearIncome / LAG(YearlyLinearIncome) OVER (ORDER BY Year) -1) * 100 AS GrowthRate 
FROM(
SELECT YEAR(O.OrderDate) AS Year, 
SUM(IL.ExtendedPrice - IL.TaxAmount) AS IncomePerYear,
COUNT (DISTINCT MONTH(O.OrderDate)) AS NumberOfDistinctMonths,
CAST((SUM(IL.ExtendedPrice - IL.TaxAmount) * 12) / COUNT (DISTINCT MONTH(O.OrderDate)) AS MONEY) AS YearlyLinearIncome
--CAST(ROUND(((((SUM(IL.ExtendedPrice - IL.TaxAmount) * 12) / COUNT (DISTINCT MONTH(O.OrderDate))) / (LAG((SUM(IL.ExtendedPrice - IL.TaxAmount) * 12) / COUNT (DISTINCT MONTH(O.OrderDate)),1) OVER (ORDER BY YEAR(O.OrderDate)))-1)*100) ,2) AS MONEY) AS GrowthRate 
FROM Sales.Orders O 
JOIN Sales.Invoices I ON O.OrderID = I.OrderID
JOIN Sales.InvoiceLines IL ON I.InvoiceID = IL.InvoiceID
GROUP BY YEAR(O.OrderDate)) A
ORDER BY Year



--2--
WITH T
AS
(SELECT  YEAR(O.OrderDate) AS TheYear, 
DATEPART(QUARTER, O.OrderDate) AS TheQuarter, 
C.CustomerName,
SUM(OL.UnitPrice * OL.Quantity) AS IncomePerYear,
ROW_NUMBER () OVER (PARTITION BY YEAR(O.OrderDate), DATEPART(QUARTER, O.OrderDate) ORDER BY SUM(OL.UnitPrice * OL.Quantity) DESC ) AS DNR
FROM Sales.Orders O 
JOIN Sales.Customers C ON O.CustomerID = C.CustomerID
JOIN Sales.OrderLines OL ON O.OrderID = OL.OrderID
GROUP BY YEAR(O.OrderDate), DATEPART (QUARTER, O.OrderDate), C.CustomerName
)

SELECT *
FROM T
WHERE DNR <=5



--3--
SELECT  TOP 10  SI.StockItemID, 
SI.StockItemName, 
SUM(IL.ExtendedPrice - IL.TaxAmount) AS TotalProfit
FROM Sales.InvoiceLines AS IL JOIN Warehouse.StockItems AS SI
ON IL.StockItemID = SI.StockItemID
GROUP BY SI.StockItemID, SI.StockItemName
ORDER BY TotalProfit DESC



--4--
SELECT ROW_NUMBER() OVER (ORDER BY SI.RecommendedRetailPrice - SI.UnitPrice DESC) AS Rn,
SI.StockItemID, 
SI.StockItemName, 
SI.UnitPrice, 
SI.RecommendedRetailPrice,
SI.RecommendedRetailPrice - SI.UnitPrice AS NuminalProductProfit,
DENSE_RANK() OVER (ORDER BY SI.RecommendedRetailPrice - SI.UnitPrice DESC) AS DNR
FROM Warehouse.StockItems SI



--5--
SELECT CONCAT(S.SupplierID ,' - ' , S.SupplierName) AS SupplierDetails,
STRING_AGG (CONCAT (SI.StockItemID, ' ', SI.StockItemName), ' /,') AS ProductDetails
FROM Purchasing.Suppliers AS S JOIN Warehouse.StockItems AS SI 
ON S.SupplierID = SI.SupplierID
GROUP BY s.SupplierID, s.SupplierName
ORDER BY s.SupplierID



--6--
SELECT  TOP 5 I.CustomerID, 
CI.CityName, 
CO.CountryName, 
CO.Continent, 
CO.Region, 
FORMAT(SUM(IL.ExtendedPrice),'#,#.00') AS TotalExtendedPrice
FROM Sales.Invoices I 
JOIN Sales.InvoiceLines IL ON I.InvoiceID = IL.InvoiceID
JOIN Sales.Customers C ON I.CustomerID = C.CustomerID
JOIN Application.Cities CI ON C.PostalCityID = CI.CityID
JOIN Application.StateProvinces SP ON SP.StateProvinceID = CI.StateProvinceID
JOIN Application.Countries CO ON CO.CountryID = SP.CountryID
GROUP BY I.CustomerID, CI.CityName, CO.CountryName, CO.Continent, CO.Region
ORDER BY SUM(IL.ExtendedPrice) DESC



--7--
WITH T 
AS
(SELECT YEAR(O.OrderDate) AS OrderYear, 
CASE
WHEN MONTH(O.OrderDate)=99 THEN 'GrandTotal'
ELSE CAST (MONTH(O.OrderDate) AS varchar)
END AS OrderMonth,
FORMAT(SUM(il.UnitPrice *  il.Quantity), '#,#.00') AS MonthlyTotal,
FORMAT(SUM(SUM(il.UnitPrice *  il.Quantity))OVER(PARTITION BY YEAR(O.OrderDate) ORDER BY YEAR(O.OrderDate) ,MONTH(o.OrderDate)),'#,#.00') AS 'Cumulative Total'
FROM Sales.Orders O 
JOIN Sales.Invoices I ON O.OrderID = I.OrderID
JOIN Sales.InvoiceLines IL ON I.InvoiceID = IL.InvoiceID
GROUP BY YEAR(O.OrderDate), MONTH(O.OrderDate)


UNION

SELECT YEAR(O.OrderDate), 99 , FORMAT(SUM(il.UnitPrice *  il.Quantity), '#,#.00'), FORMAT(SUM(il.UnitPrice *  il.Quantity), '#,#.00')
FROM Sales.Orders O 
JOIN Sales.Invoices I ON O.OrderID = I.OrderID
JOIN Sales.InvoiceLines IL ON I.InvoiceID = IL.InvoiceID
GROUP BY YEAR(O.OrderDate)
)

SELECT OrderYear, 
REPLACE(OrderMonth, 99, 'GrandTotal') AS OrderMonth, 
MonthlyTotal,
[Cumulative Total]
FROM T
ORDER BY OrderYear



--8--
SELECT OrderMonth, [2013],[2014],[2015],[2016]
FROM(SELECT O.OrderID, YEAR(O.OrderDate) AS YY, MONTH(O.OrderDate) AS OrderMonth
FROM Sales.Orders O) T
PIVOT(COUNT(orderid) FOR YY IN ([2013],[2014],[2015],[2016])) PVT
ORDER BY OrderMonth



--9--
WITH T
AS
(SELECT C.CustomerID, 
C.CustomerName, 
O.OrderDate,
LAG(O.OrderDate,1) OVER (PARTITION BY C.CustomerID ORDER BY O.OrderDate ) AS PreviousOrderDate,
DATEDIFF (DD, MAX(O.OrderDate) OVER (PARTITION BY C.CustomerID), '2016-05-31') AS DaysSinceLastOrder,
DATEDIFF(DD, LAG(O.OrderDate, 1) OVER (PARTITION BY C.CustomerID ORDER BY O.OrderDate), O.OrderDate) AS DatediffBetweenOrders
FROM Sales.Customers C 
JOIN Sales.Orders O ON C.CustomerID = O.CustomerID)


SELECT T.CustomerID, T.CustomerName, T.OrderDate, T.PreviousOrderDate, T.DaysSinceLastOrder,
AVG(T.DatediffBetweenOrders) OVER (PARTITION BY T.CustomerID) AS AvgDaysBetweenOrders,
CASE WHEN T.DaysSinceLastOrder > 2* AVG(T.DatediffBetweenOrders) OVER (PARTITION BY T.CustomerID)
THEN 'Potential Chum' 
ELSE 'Active'
END AS CustomerStatus
FROM T


GO
--10--
WITH T
AS 
(SELECT CC.CustomerCategoryName, 
        C.CustomerName,
        CASE 
            WHEN C.CustomerName LIKE 'Tailspin%' THEN 'Tailspin Toys'
            WHEN C.CustomerName LIKE 'Wingtip%' THEN 'Wingtip Toys'
            ELSE C.CustomerName
        END AS UnifiedCustomerName
    FROM Sales.Customers C 
    JOIN Sales.CustomerCategories CC ON C.CustomerCategoryID = CC.CustomerCategoryID)

SELECT T.CustomerCategoryName, 
COUNT(DISTINCT UnifiedCustomerName) AS CustomerCOUNT,
SUM(COUNT(DISTINCT UnifiedCustomerName)) OVER() AS TotalCustCount,
FORMAT(COUNT(DISTINCT UnifiedCustomerName) * 100.0 / SUM(COUNT(DISTINCT UnifiedCustomerName)) OVER(), 'N2')  + '%' AS DistributionFactor
FROM T
GROUP BY T.CustomerCategoryName
ORDER BY T.CustomerCategoryName




--10--
--second option--
WITH T
AS 
(SELECT CC.CustomerCategoryName, 
        C.CustomerName,
        CASE 
            WHEN C.CustomerName LIKE 'Tailspin%' THEN 'Tailspin Toys'
            WHEN C.CustomerName LIKE 'Wingtip%' THEN 'Wingtip Toys'
            ELSE C.CustomerName
        END AS UnifiedCustomerName
    FROM Sales.Customers C 
    JOIN Sales.CustomerCategories CC ON C.CustomerCategoryID = CC.CustomerCategoryID)

SELECT *, 
FORMAT(CustomerCOUNT * 100.0 / TotalCustCount, 'N2') +'%' AS DistributionFactor
FROM(
SELECT T.CustomerCategoryName, 
COUNT(DISTINCT UnifiedCustomerName) AS CustomerCOUNT,
SUM(COUNT(DISTINCT UnifiedCustomerName)) OVER() AS TotalCustCount
FROM T
GROUP BY T.CustomerCategoryName) M
ORDER BY CustomerCategoryName
