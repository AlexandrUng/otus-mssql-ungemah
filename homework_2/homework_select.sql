/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.
Занятие "02 - Оператор SELECT и простые фильтры, JOIN".

Задания выполняются с использованием базы данных WideWorldImporters.

Бэкап БД WideWorldImporters можно скачать отсюда:
https://github.com/Microsoft/sql-server-samples/releases/download/wide-world-importers-v1.0/WideWorldImporters-Full.bak

Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

-- ---------------------------------------------------------------------------
-- Задание - написать выборки для получения указанных ниже данных.
-- ---------------------------------------------------------------------------

USE WideWorldImporters;

/*
1. Все товары, в названии которых есть "urgent" или название начинается с "Animal".

Вывести: ИД товара (StockItemID), наименование товара (StockItemName).
Таблицы: Warehouse.StockItems.
*/

SELECT StockItemID, StockItemName
FROM [Warehouse].[StockItems]
WHERE StockItemName LIKE '%urgent%' or StockItemName LIKE 'Animal%'
	

/*
2. Поставщиков (Suppliers), у которых не было сделано ни одного заказа (PurchaseOrders).
Сделать через JOIN, с подзапросом задание принято не будет.

Вывести: ИД поставщика (SupplierID), наименование поставщика (SupplierName).
Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders.
По каким колонкам делать JOIN подумайте самостоятельно.
*/

SELECT DISTINCT Suppliers.SupplierID,
Suppliers.SupplierName
FROM [Purchasing].[Suppliers] AS Suppliers
LEFT JOIN [Purchasing].[PurchaseOrders] AS [PurchaseOrders] 
ON Suppliers.SupplierID = PurchaseOrders.SupplierID
WHERE PurchaseOrderID IS NULL

/*
3. Заказы (Orders) с товарами ценой (UnitPrice) более 100$
либо количеством единиц (Quantity) товара более 20 штук
и присутствующей датой комплектации всего заказа (PickingCompletedWhen).

Вывести:
* OrderID
* дату заказа (OrderDate) в формате ДД.ММ.ГГГГ (10.01.2011)
* название месяца, в котором был сделан заказ (используйте функцию FORMAT или DATENAME)
* номер квартала, в котором был сделан заказ (используйте функцию DATEPART)
* треть года, к которой относится дата заказа (каждая треть по 4 месяца)
* имя заказчика (Customer)
Добавьте вариант этого запроса с постраничной выборкой,
пропустив первую 1000 и отобразив следующие 100 записей.

Сортировка должна быть по номеру квартала, трети года, дате заказа (везде по возрастанию).

Таблицы: Sales.Orders, Sales.OrderLines, Sales.Customers.
*/


SELECT Orders.OrderID, 
FORMAT(Orders.OrderDate, 'dd.MM.yyyy') as OrderDate, 
FORMAT(Orders.OrderDate, 'MMMM') as OrderMonth, 
DATEPART(quarter, Orders.OrderDate) as OrderQuarter, 
CASE WHEN DATEPART(MONTH, Orders.OrderDate) < 5 THEN 1
WHEN DATEPART(MONTH, Orders.OrderDate) > 4 AND DATEPART(MONTH, Orders.OrderDate)< 9 THEN 2
ELSE 3 END as ThirdOfYear,  
Customers.CustomerName AS Customer
FROM [Sales].[Orders] as [Orders]
LEFT JOIN [Sales].[OrderLines] AS [OrderLines]
ON Orders.OrderID = [OrderLines].OrderID
LEFT JOIN [Sales].[Customers] AS [Customers] ON [Orders].[CustomerID] = [Customers].CustomerID
WHERE ([OrderLines].UnitPrice > 100
OR [OrderLines].Quantity > 20) 
AND NOT OrderLines.PickingCompletedWhen IS NULL
ORDER BY OrderQuarter, ThirdOfYear, OrderDate;

SELECT Orders.OrderID, 
FORMAT(Orders.OrderDate, 'dd.MM.yyyy') as OrderDate, 
FORMAT(Orders.OrderDate, 'MMMM') as OrderMonth, 
DATEPART(quarter, Orders.OrderDate) as OrderQuarter, 
CASE WHEN DATEPART(MONTH, Orders.OrderDate) < 5 THEN 1
WHEN DATEPART(MONTH, Orders.OrderDate) > 4 AND DATEPART(MONTH, Orders.OrderDate)< 9 THEN 2
ELSE 3 END as ThirdOfYear,  
Customers.CustomerName AS Customer
FROM [Sales].[Orders] as [Orders]
LEFT JOIN [Sales].[OrderLines] AS [OrderLines]
ON Orders.OrderID = [OrderLines].OrderID
LEFT JOIN [Sales].[Customers] AS [Customers] ON [Orders].[CustomerID] = [Customers].CustomerID
WHERE ([OrderLines].UnitPrice > 100
OR [OrderLines].Quantity > 20) 
AND NOT OrderLines.PickingCompletedWhen IS NULL
ORDER BY OrderQuarter, ThirdOfYear, OrderDate
OFFSET 1000 ROWS FETCH FIRST 100 ROWS ONLY;

/*
4. Заказы поставщикам (Purchasing.Suppliers),
которые должны быть исполнены (ExpectedDeliveryDate) в январе 2013 года
с доставкой "Air Freight" или "Refrigerated Air Freight" (DeliveryMethodName)
и которые исполнены (IsOrderFinalized).

Вывести:
* способ доставки (DeliveryMethodName)
* дата доставки (ExpectedDeliveryDate)
* имя поставщика
* имя контактного лица принимавшего заказ (ContactPerson)

Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders, Application.DeliveryMethods, Application.People.
*/

SELECT 
[DeliveryMethods].DeliveryMethodName AS DeliveryMethodName,
PurchaseOrders.ExpectedDeliveryDate AS ExpectedDeliveryDate,
[Suppliers].[SupplierName] AS [SupplierName],
[People].FullName AS ContactPerson
FROM 
[Purchasing].[PurchaseOrders]  AS [PurchaseOrders]
INNER JOIN [Purchasing].[Suppliers] AS [Suppliers]
ON [PurchaseOrders].SupplierID = [Suppliers].SupplierID 
INNER JOIN [Application].[DeliveryMethods] AS [DeliveryMethods]
ON [Suppliers].[DeliveryMethodID] = [DeliveryMethods].[DeliveryMethodID]
LEFT JOIN [Application].[People] AS [People] ON PurchaseOrders.ContactPersonID = [People].[PersonID]
WHERE  
[PurchaseOrders].IsOrderFinalized = 1 
AND ExpectedDeliveryDate BETWEEN '2013-01-01' AND '2013-01-31'
AND ([DeliveryMethods].DeliveryMethodName = 'Air Freight' 
OR [DeliveryMethods].DeliveryMethodName = 'Refrigerated Air Freight')


/*
5. Десять последних продаж (по дате продажи - InvoiceDate) с именем клиента (клиент - CustomerID) и именем сотрудника,
который оформил заказ (SalespersonPerson).
Сделать без подзапросов.

Вывести: ИД продажи (InvoiceID), дата продажи (InvoiceDate), имя заказчика (CustomerName), имя сотрудника (SalespersonFullName)
Таблицы: Sales.Invoices, Sales.Customers, Application.People.
*/

SELECT top 10
[Invoices].InvoiceID as InvoiceID,
Invoices.InvoiceDate as InvoiceDate,
Customers.CustomerName as CustomerName,
People.FullName as SalespersonFullName
FROM [Sales].[Invoices] AS [Invoices]
LEFT JOIN Sales.Customers AS Customers
ON [Invoices].CustomerID = Customers.CustomerID
LEFT JOIN Application.People AS People
ON [Invoices].[SalespersonPersonID] = People.PersonID
ORDER BY [Invoices].[InvoiceDate] DESC

/*
6. Все ид и имена клиентов (клиент - CustomerID) и их контактные телефоны (PhoneNumber),
которые покупали товар "Chocolate frogs 250g".
Имя товара смотреть в таблице Warehouse.StockItems, имена клиентов и их контакты в таблице Sales.Customers.

Таблицы: Sales.Invoices, Sales.InvoiceLines, Sales.Customers, Warehouse.StockItems.
*/

SELECT DISTINCT
[Customers].CustomerID,
[Customers].CustomerName,
[Customers].PhoneNumber
FROM 
[Sales].[Invoices] AS [Invoices]
INNER JOIN [Sales].[InvoiceLines] AS [InvoiceLines]
ON [Invoices].InvoiceID = [InvoiceLines].InvoiceID
INNER JOIN [Sales].[Customers] AS [Customers]
ON [Invoices].CustomerID = [Customers].CustomerID
INNER JOIN [Warehouse].[StockItems] AS [StockItems]
ON [InvoiceLines].[StockItemID] = [StockItems].[StockItemID]
WHERE [StockItems].StockItemName = 'Chocolate frogs 250g'
ORDER BY [Customers].CustomerID;
