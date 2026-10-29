/*

This is to create three views in Azure SQL database, namely 
vw_MonthlySales, vw_SalesbyStates, vw_CustomerBehavior.
vw_MOnthlySales is to show bookstore sales by month;
vw_SalesbyStates is to show bookstore sales by state;
vw_CustomerBehavior is to show how many coders and how much in total each customer paid. 

*/

/*
vw_MOnthlySales is to show bookstore sales by month;
*/
CREATE OR ALTER VIEW dbo.vw_MonthlySales
AS
SELECT
    DATEFROMPARTS(YEAR(o.placed_at), MONTH(o.placed_at), 1)
        AS SalesMonth,
    SUM(ol.line_total) AS TotalSales
FROM dbo.orders AS o
JOIN dbo.order_lines AS ol
    ON o.id = ol.order_id
WHERE o.[status] = N'delivered'
GROUP BY
    DATEFROMPARTS(YEAR(o.placed_at), MONTH(o.placed_at), 1);
    
/*
vw_SalesbyStates is to show bookstore sales by state;
*/    

create or alter view dbo.vw_SalesbyStates
as 
SELECT
    c.[state] AS CustomerState,
    SUM(ol.line_total) AS TotalSales
FROM dbo.customers AS c
JOIN dbo.orders AS o
    ON c.id = o.customer_id
JOIN dbo.order_lines AS ol
    ON o.id = ol.order_id
WHERE o.[status] = N'delivered'
GROUP BY
    c.[state]
    
    
/*
vw_CustomerBehavior is to show how many coders and how much in total each customer paid. 
*/     


create or alter view dbo.vw_CustomerBehavior
as 
WITH OrderTotals AS (
    SELECT
        o.id AS OrderID,
        o.customer_id,
        COALESCE(SUM(ol.line_total), 0) 
            AS OrderTotal
    FROM dbo.orders AS o
    LEFT JOIN dbo.order_lines AS ol
        ON o.id = ol.order_id
    WHERE o.[status] = N'delivered'
    GROUP BY
        o.id,
        o.customer_id,
        o.shipping_fee
)
SELECT
    c.id AS CustomerID,
    c.first_name AS FirstName,
    c.last_name AS LastName,
    COUNT(ot.OrderID) AS OrderCount,
    COALESCE(SUM(ot.OrderTotal), 0) AS TotalPaid
FROM dbo.customers AS c
LEFT JOIN OrderTotals AS ot
    ON c.id = ot.customer_id
GROUP BY
    c.id,
    c.first_name,
    c.last_name










    
    