--1: List All Customers and Their Region
SELECT customer_id, customer_name, region
FROM customers;

--2: Find Total Number of Orders
SELECT COUNT(order_id) AS total_orders
FROM orders;

--3: Total Sales by Product 
--Get the total quantity sold and total revenue for each product.
SELECT p.product_name, 
       SUM(oi.quantity) AS total_quantity_sold, 
       SUM(oi.quantity * p.price) AS total_revenue
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
GROUP BY p.product_name
ORDER BY total_revenue DESC;

--4: Revenue by Region
--Calculate total revenue by region.
SELECT c.region, 
       SUM(oi.quantity * p.price) AS region_revenue
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
GROUP BY c.region
ORDER BY region_revenue DESC;

--5: Top 3 Best-Selling Products by Total Quantity
--Get the names of the top 3 best-selling products.
SELECT product_name, total_quantity_sold
FROM (
    SELECT p.product_name, 
           SUM(oi.quantity) AS total_quantity_sold,
           RANK() OVER (ORDER BY SUM(oi.quantity) DESC) AS rank
    FROM order_items oi
    JOIN products p ON oi.product_id = p.product_id
    GROUP BY p.product_name
) AS ranked_sales
WHERE rank <= 3;

--6: Cumulative Sales by Date
--Calculate cumulative sales over time, useful for tracking performance.
SELECT order_date, 
       SUM(quantity * price) OVER (ORDER BY order_date) AS cumulative_sales
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
ORDER BY order_date;

--7: Average Order Value by Customer
--Using window functions, find each customer's average order value.
SELECT customer_id, 
       AVG(total_order_value) OVER (PARTITION BY customer_id) AS avg_order_value
FROM (
    SELECT o.customer_id, 
           o.order_id, 
           SUM(oi.quantity * p.price) AS total_order_value
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    JOIN products p ON oi.product_id = p.product_id
    GROUP BY o.customer_id, o.order_id
) AS customer_orders;

--8: Identify Repeat Customers
--Identify customers who placed more than one order in a specific period (e.g., 2023).
SELECT customer_id, 
       COUNT(order_id) AS order_count
FROM (
    SELECT o.customer_id, 
           o.order_id,
           COUNT(*) OVER (PARTITION BY o.customer_id ORDER BY o.order_date) AS order_count
    FROM orders o
    WHERE EXTRACT(YEAR FROM o.order_date) = 2023
) AS repeat_customers
WHERE order_count > 1
GROUP BY customer_id;

--9: Monthly Revenue Growth
--Calculate month-over-month revenue growth to track sales progress.
SELECT month, 
       SUM(monthly_revenue) AS revenue,
       LAG(SUM(monthly_revenue)) OVER (ORDER BY month) AS last_month_revenue,
       (SUM(monthly_revenue) - LAG(SUM(monthly_revenue)) OVER (ORDER BY month)) / NULLIF(LAG(SUM(monthly_revenue)) OVER (ORDER BY month), 0) * 100 AS growth_rate
FROM (
    SELECT DATE_TRUNC('month', o.order_date) AS month,
           SUM(oi.quantity * p.price) AS monthly_revenue
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    JOIN products p ON oi.product_id = p.product_id
    GROUP BY month
) AS monthly_sales
ORDER BY month;