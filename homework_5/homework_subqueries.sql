/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.
Занятие "03 - Подзапросы, CTE, временные таблицы".
Задания выполняются с использованием базы данных WideWorldImporters.
Бэкап БД можно скачать отсюда:
https://github.com/Microsoft/sql-server-samples/releases/tag/wide-world-importers-v1.0
Нужен WideWorldImporters-Full.bak
Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

-- ---------------------------------------------------------------------------
-- Задание - написать выборки для получения указанных ниже данных.
-- Для всех заданий, где возможно, сделайте два варианта запросов:
--  1) через вложенный запрос
--  2) через WITH (для производных таблиц)
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. Выберите сотрудников (Application.People), которые являются продажниками (IsSalesPerson), 
и не сделали ни одной продажи 04 июля 2015 года. 
Вывести ИД сотрудника и его полное имя. 
Продажи смотреть в таблице Sales.Invoices.
*/

Declare @invoiceDate date = '2015-07-14';

-- 1. вариант 1
SELECT DISTINCT People.PersonID as PersonID,
People.FullName as FullName
FROM [Application].[People] AS [People]
WHERE [People].IsSalesperson = 1
AND NOT [People].PersonID IN 
(SELECT SalespersonPersonID
FROM Sales.Invoices AS Invoices
WHERE Invoices.InvoiceDate = @invoiceDate
GROUP BY SalespersonPersonID)
ORDER BY People.PersonID;

-- 1. вариант 2
WITH Invoices_CTE (SalespersonPersonID)
AS (SELECT SalespersonPersonID
FROM Sales.Invoices AS Invoices
WHERE Invoices.InvoiceDate = @invoiceDate
GROUP BY SalespersonPersonID)

SELECT DISTINCT People.PersonID as PersonID,
People.FullName as FullName
FROM [Application].[People] AS [People]
WHERE [People].IsSalesperson = 1
AND NOT [People].PersonID IN 
(SELECT SalespersonPersonID
FROM Invoices_CTE)
ORDER BY People.PersonID;

/*
2. Выберите товары с минимальной ценой (подзапросом). Сделайте два варианта подзапроса. 
Вывести: ИД товара, наименование товара, цена.
*/

-- 2. вариант 1
SELECT [StockItems].StockItemID,
[StockItems].StockItemName,
[StockItems].UnitPrice
FROM [Warehouse].[StockItems] AS [StockItems]
WHERE 
[StockItems].UnitPrice IN (
SELECT TOP 1 UnitPrice
FROM [Warehouse].[StockItems]
ORDER BY UnitPrice);

-- 2. вариант 2
WITH MIN_PRICE_CTE (UnitPrice)
AS (SELECT TOP 1 UnitPrice
FROM [Warehouse].[StockItems]
ORDER BY UnitPrice) 

SELECT [StockItems].StockItemID,
[StockItems].StockItemName,
[StockItems].UnitPrice
FROM [Warehouse].[StockItems] AS [StockItems]
INNER JOIN MIN_PRICE_CTE 
ON [StockItems].UnitPrice = MIN_PRICE_CTE.UnitPrice;

/*
3. Выберите информацию по клиентам, которые перевели компании пять максимальных платежей 
из Sales.CustomerTransactions. 
Представьте несколько способов (в том числе с CTE). 
*/

-- 3.ВАРИАНТ 1
SELECT 
CustomerTransactions.CustomerID,
[Customers].CustomerName
FROM Sales.CustomerTransactions AS CustomerTransactions
INNER JOIN 
(SELECT DISTINCT TOP 5
[TransactionAmount]
FROM Sales.CustomerTransactions AS CustomerTransactions
ORDER BY [TransactionAmount] DESC) AS Max_Transactions
ON CustomerTransactions.[TransactionAmount] = Max_Transactions.[TransactionAmount]
LEFT JOIN [Sales].[Customers] AS [Customers]
ON CustomerTransactions.CustomerID = [Customers].CustomerID
GROUP BY 
CustomerTransactions.CustomerID,
[Customers].CustomerName
ORDER BY CustomerTransactions.CustomerID;

-- 3.ВАРИАНТ 2
WITH Max_Transactions_CTE ([TransactionAmount])
AS 
(SELECT DISTINCT TOP 5
[TransactionAmount]
FROM Sales.CustomerTransactions AS CustomerTransactions
ORDER BY [TransactionAmount] DESC)

SELECT 
CustomerTransactions.CustomerID,
[Customers].CustomerName
FROM Sales.CustomerTransactions AS CustomerTransactions
INNER JOIN Max_Transactions_CTE AS Max_Transactions
ON CustomerTransactions.[TransactionAmount] = Max_Transactions.[TransactionAmount]
LEFT JOIN [Sales].[Customers] AS [Customers]
ON CustomerTransactions.CustomerID = [Customers].CustomerID
GROUP BY 
CustomerTransactions.CustomerID,
[Customers].CustomerName
ORDER BY CustomerTransactions.CustomerID;

-- 3. ВАРИАНТ 3
WITH Max_Transactions_CTE ([TransactionAmount])
AS 
(SELECT DISTINCT TOP 5
[TransactionAmount]
FROM Sales.CustomerTransactions AS CustomerTransactions
ORDER BY [TransactionAmount] DESC)

SELECT 
CustomerTransactions.CustomerID,
[Customers].CustomerName
FROM Sales.CustomerTransactions AS CustomerTransactions
LEFT JOIN [Sales].[Customers] AS [Customers]
ON CustomerTransactions.CustomerID = [Customers].CustomerID
WHERE CustomerTransactions.[TransactionAmount] IN 
( SELECT [TransactionAmount] FROM Max_Transactions_CTE)
GROUP BY 
CustomerTransactions.CustomerID,
[Customers].CustomerName
ORDER BY CustomerTransactions.CustomerID;

/*
4. Выберите города (ид и название), в которые были доставлены товары, 
входящие в тройку самых дорогих товаров, а также имя сотрудника, 
который осуществлял упаковку заказов (PackedByPersonID).
*/

WITH MaxUnitPrice_CTE AS 
(SELECT DISTINCT TOP 3 UnitPrice
FROM [Warehouse].[StockItems]
ORDER BY UnitPrice DESC),

MaxPriceStockItems_CTE AS
(SELECT StockItemID
FROM [Warehouse].[StockItems] AS [StockItems]
WHERE [StockItems].UnitPrice IN 
(SELECT UnitPrice FROM MaxUnitPrice_CTE))

SELECT 
Customers.DeliveryCityID,
Cities.CityName,
[People].FullName
FROM 
MaxPriceStockItems_CTE
INNER JOIN [Sales].[InvoiceLines] AS [InvoiceLines]
ON MaxPriceStockItems_CTE.StockItemID = [InvoiceLines].StockItemID
INNER JOIN [Sales].[Invoices] AS [Invoices]
ON [InvoiceLines].InvoiceID = [Invoices].InvoiceID
INNER JOIN [Sales].[Customers] AS [Customers]
ON [Invoices].CustomerID = Customers.CustomerID
INNER JOIN Application.Cities AS Cities
ON Customers.DeliveryCityID = Cities.CityID
LEFT JOIN [Application].[People] AS [People]
ON [Invoices].PackedByPersonID = [People].PersonID

GROUP BY Customers.DeliveryCityID,
Cities.CityName,
[People].FullName;





-- ---------------------------------------------------------------------------
-- Опциональное задание
-- ---------------------------------------------------------------------------
-- Можно двигаться как в сторону улучшения читабельности запроса, 
-- так и в сторону упрощения плана\ускорения. 
-- Сравнить производительность запросов можно через SET STATISTICS IO, TIME ON. 
-- Если знакомы с планами запросов, то используйте их (тогда к решению также приложите планы). 
-- Напишите ваши рассуждения по поводу оптимизации. 

-- 5. Объясните, что делает и оптимизируйте запрос

/*
SELECT 
	Invoices.InvoiceID, 
	Invoices.InvoiceDate,
	(SELECT People.FullName
		FROM Application.People
		WHERE People.PersonID = Invoices.SalespersonPersonID
	) AS SalesPersonName,
	SalesTotals.TotalSumm AS TotalSummByInvoice, 
	(SELECT SUM(OrderLines.PickedQuantity*OrderLines.UnitPrice)
		FROM Sales.OrderLines
		WHERE OrderLines.OrderId = (SELECT Orders.OrderId 
			FROM Sales.Orders
			WHERE Orders.PickingCompletedWhen IS NOT NULL	
				AND Orders.OrderId = Invoices.OrderId)	
	) AS TotalSummForPickedItems
FROM Sales.Invoices 
	JOIN
	(SELECT InvoiceId, SUM(Quantity*UnitPrice) AS TotalSumm
	FROM Sales.InvoiceLines
	GROUP BY InvoiceId
	HAVING SUM(Quantity*UnitPrice) > 27000) AS SalesTotals
		ON Invoices.InvoiceID = SalesTotals.InvoiceID
ORDER BY TotalSumm DESC

*/

-- --
--напишите здесь свое решение
