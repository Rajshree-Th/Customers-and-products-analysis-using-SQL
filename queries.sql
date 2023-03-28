/*displaying table names with number of columns and rows*/
SELECT 
    'Customers' AS table_name,
    COUNT(*) AS number_of_attributes,
    COUNT(*) AS number_of_rows
FROM
    customers 
UNION SELECT 
    'Employees' AS table_name,
    COUNT(*) AS number_of_attributes,
    COUNT(*) AS number_of_rows
FROM
    employees 
UNION SELECT 
    'Offices' AS table_name,
    COUNT(*) AS number_of_attributes,
    COUNT(*) AS number_of_rows
FROM
    offices 
UNION SELECT 
    'Orderdetails' AS table_name,
    COUNT(*) AS number_of_attributes,
    COUNT(*) AS number_of_rows
FROM
    orderdetails 
UNION SELECT 
    'Orders' AS table_name,
    COUNT(*) AS number_of_attributes,
    COUNT(*) AS number_of_rows
FROM
    orders 
UNION SELECT 
    'Payments' AS table_name,
    COUNT(*) AS number_of_attributes,
    COUNT(*) AS number_of_rows
FROM
    payments 
UNION SELECT 
    'Productlines' AS table_name,
    COUNT(*) AS number_of_attributes,
    COUNT(*) AS number_of_rows
FROM
    productlines 
UNION SELECT 
    'Products' AS table_name,
    COUNT(*) AS number_of_attributes,
    COUNT(*) AS number_of_rows
FROM
    products;


/*to display 10 products with lowest current stock percentage*/
/*dividing the current quantityInStock value for each product by the total number of products and multiplies the result by 100 to obtain a percentage*/
SELECT 
    productCode,
    ROUND(MIN(quantityInStock / (SELECT COUNT(*) FROM products) * 100), 2) 
    AS lowStockPercentage
FROM
    products
GROUP BY productCode
ORDER BY lowStockPercentage
LIMIT 10;
/*from this result we can determine which products need to be restocked*/


/*finding the best performed products in terms of demand and price*/
SELECT 
    products.productCode,
    ROUND((SUM(quantityOrdered * priceEach) - SUM(quantityOrdered * buyPrice)) / COUNT(*) / SUM(quantityOrdered * buyPrice) * 100, 2) 
    AS productPerformance
FROM
    orderDetails orderdetails
        JOIN
    products products ON orderdetails.productCode = products.productCode
GROUP BY products.productCode
ORDER BY productPerformance DESC
LIMIT 10;


/*finding top priority product which needs to be restocked*/
/*combining the above two queries with IN operator, Common Table Operator(CTO)*/
WITH low_stock_products AS (
	SELECT 
    productCode,
    ROUND(MIN(quantityInStock / (SELECT COUNT(*) FROM products) * 100), 2) 
    AS lowStockPercentage
FROM
    products
GROUP BY productCode
ORDER BY lowStockPercentage ASC
LIMIT 10
    ),
product_performance AS (
	SELECT 
    prod.productCode,
    ROUND((SUM(quantityOrdered * priceEach) - SUM(quantityOrdered * buyPrice)) / COUNT(*) / SUM(quantityOrdered * buyPrice) * 100, 2) 
    AS productPerformance
FROM
    orderDetails ordd
        JOIN
    products prod ON ordd.productCode = prod.productCode
GROUP BY prod.productCode
ORDER BY productPerformance DESC
LIMIT 10
    )
SELECT 
    productCode
FROM
    low_stock_products
WHERE
    productCode IN (SELECT 
            productCode
        FROM
            product_performance);


/*finding profit per customer*/
SELECT 
    customerNumber,
    SUM(ordd.quantityOrdered * (ordd.priceEach - prod.buyPrice)) 
    AS profit
FROM
    products prod
        JOIN
    orderdetails ordd ON prod.productCode = ordd.productCode
        JOIN
    orders ord ON ord.orderNumber = ordd.orderNumber
GROUP BY customerNumber;


/*finding 5 highest profitted customers*/
WITH profitPerCustomer AS (
	SELECT 
    customerNumber,
    SUM(ordd.quantityOrdered * (ordd.priceEach - prod.buyPrice)) 
    AS profit
FROM
    products prod
        JOIN
    orderdetails ordd ON prod.productCode = ordd.productCode
        JOIN
    orders ord ON ord.orderNumber = ordd.orderNumber
GROUP BY customerNumber
    )
SELECT 
    contactLastName, contactFirstName, city, country, profit
FROM
    customers cus
        JOIN
    profitPerCustomer ppc ON ppc.customerNumber = cus.customerNumber
ORDER BY ppc.profit DESC
LIMIT 5;


/*finding 5 least profitted customers*/
WITH profitPerCustomer AS (
	SELECT 
    customerNumber,
    SUM(ordd.quantityOrdered * (ordd.priceEach - prod.buyPrice)) AS profit
FROM
    products prod
        JOIN
    orderdetails ordd ON prod.productCode = ordd.productCode
        JOIN
    orders ord ON ord.orderNumber = ordd.orderNumber
GROUP BY customerNumber
    )
SELECT 
    contactLastName, contactFirstName, city, country, profit
FROM
    customers cus
        JOIN
    profitPerCustomer ppc ON ppc.customerNumber = cus.customerNumber
ORDER BY ppc.profit ASC
LIMIT 5;


/*finding 5 least engaged customers*/
WITH customerOrders AS (
	SELECT 
    customerNumber, COUNT(*) AS orderCount
FROM
    orders
GROUP BY customerNumber
	)
SELECT 
    contactLastName, contactFirstName, city, country, orderCount
FROM
    customers cus
        LEFT JOIN
    customerOrders co ON cus.customerNumber = co.customerNumber
GROUP BY cus.customerNumber
ORDER BY orderCount ASC
LIMIT 5;


/*finding 5 top engaged customers*/
WITH customerOrders AS (
	SELECT 
    customerNumber, COUNT(*) AS orderCount
FROM
    orders
GROUP BY customerNumber
	)
SELECT 
    contactLastName, contactFirstName, city, country, orderCount
FROM
    customers cus
        LEFT JOIN
    customerOrders co ON cus.customerNumber = co.customerNumber
GROUP BY cus.customerNumber
ORDER BY orderCount DESC
LIMIT 5;


/*finding average profit a customer generates*/
/*how much we can spend on acquiring new customers*/
WITH profitPerCustomer AS (
	SELECT 
    customerNumber,
    SUM(ordd.quantityOrdered * (ordd.priceEach - prod.buyPrice)) AS profit
FROM
    products prod
        JOIN
    orderdetails ordd ON prod.productCode = ordd.productCode
        JOIN
    orders ord ON ord.orderNumber = ordd.orderNumber
GROUP BY customerNumber
    )
SELECT 
    ROUND(AVG(profit),1) 
    AS avgProfit
FROM
    profitPerCustomer;


/*finding top 10 customers who have spent the most money*/
SELECT 
    cus.customerName, cus.city, cus.country,
    SUM(ordd.quantityOrdered * ordd.priceEach) AS totalSpent
FROM
    customers cus
        JOIN
    orders ord ON cus.customerNumber = ord.customerNumber
        JOIN
    orderdetails ordd ON ord.orderNumber = ordd.orderNumber
GROUP BY cus.customerName
ORDER BY totalSpent DESC
;


/*finding numbers of product in each category*/
SELECT
    pl.productLine AS productCategory,
    COUNT(p.productCode) AS numProducts
FROM
    productlines pl
    JOIN products p ON pl.productLine = p.productLine
GROUP BY
    pl.productLine;


/*finding top 5 product with highest profit margin*/
SELECT 
    prod.productName,
    ROUND((SUM(ordd.priceEach - prod.buyPrice) / SUM(ordd.priceEach)) * 100, 2) AS profitMargin
FROM
	products prod
	JOIN orderdetails ordd ON prod.productCode = ordd.productCode
GROUP BY prod.productCode
ORDER BY profitMargin DESC
LIMIT 5;


/*finding average order value per customer*/
SELECT cus.customerName, 
	ROUND(AVG(ordd.quantityOrdered * ordd.priceEach),2) AS avgOrderPerCustomer
FROM customers cus
	JOIN orders ord ON ord.customerNumber = cus.customerNumber
    JOIN orderdetails ordd ON ordd.orderNumber = ord.orderNumber
GROUP BY cus.customerNumber;


/*finding total number of orders placed by each customer*/
SELECT cus.customerNumber, cus.customerName,
	COUNT(ord.orderNumber) AS orderCountPerCustomer
FROM customers cus
    JOIN orders ord ON ord.customerNumber = cus.customerNumber
GROUP BY cus.customerNumber
ORDER BY orderCountPerCustomer DESC;


/*finding number of products sold in each year*/
SELECT  
	YEAR(ord.orderDate) AS orderYear,
    COUNT(quantityOrdered) AS totalProductSold
FROM orders ord
	JOIN orderdetails ordd ON ordd.orderNumber = ord.orderNumber
GROUP BY orderYear;


/*finding top 3 products with highest sales growth rate*/
WITH sales AS (
	SELECT 
		prod.productCode,
		EXTRACT(YEAR FROM ord.orderDate) AS orderYear,
        SUM(ordd.quantityOrdered * ordd.priceEach) AS totalSales
	FROM
		products prod
        JOIN orderdetails ordd ON ordd.productCode = prod.productCode
        JOIN orders ord ON ord.orderNumber = ordd.orderNumber
	GROUP BY
		prod.productCode,
        orderYear
	)
SELECT 
	s1.productCode,
    ROUND(((s2.totalSales - s1.totalSales) / s1.totalSales) * 100, 2) AS growthRate
FROM
	sales s1
    JOIN sales s2 ON s1.productCode = s2.productCode AND s1.orderYear = s2.orderYear - 1
ORDER BY growthRate DESC
LIMIT 5;


/*finding the average shipping time for each product category*/
SELECT 
    prod.productLine AS productCategory,
    ROUND(AVG(DATEDIFF(ord.shippedDate, ord.orderDate)), 2) AS avgShippingTime
FROM
    products prod
        JOIN
    orderdetails ordd ON prod.productCode = ordd.productCode
        JOIN
    orders ord ON ordd.orderNumber = ord.orderNumber
GROUP BY productCategory
ORDER BY avgShippingTime;
 

/*finding the top 5 salespeople who have sold the most products*/
SELECT
	emp.employeeNumber AS employeeNumber,
    emp.firstName AS firstName,
    emp.lastName AS lastName,
    SUM(ordd.quantityOrdered) AS productsSold
FROM 
	employees emp
		JOIN
	customers cus ON emp.employeeNumber = cus.salesRepEmployeeNumber
		JOIN
	orders ord ON cus.customerNumber = ord.customerNumber
		JOIN
	orderdetails ordd ON ord.orderNumber = ordd.orderNumber
GROUP BY emp.employeeNumber
ORDER BY productsSold DESC
LIMIT 5;


/*finding number of orders placed in each month*/
SELECT 
    EXTRACT(YEAR FROM orderDate) AS years,
    EXTRACT(MONTH FROM orderDate) AS months,
    COUNT(orderNumber) AS orderCount
FROM
    orders
GROUP BY years, months;


SHOW TABLES;


















