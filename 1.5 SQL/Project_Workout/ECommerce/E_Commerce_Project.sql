USE E_Commerce


-- 1. Join all the tables and create a new table with all of the columns, called combined_table. (market_fact, cust_dimen, orders_dimen, prod_dimen, shipping_dimen)

SELECT * INTO combined_table
FROM
   (SELECT m.Sales, m.Discount, m.Order_Quantity, m.Product_Base_Margin, o.*, pd.*, sd.*, cd.*
    FROM market_fact m 
    FULL OUTER JOIN orders_dimen_new o ON m.Ord_id = o.Ord_id
    FULL OUTER JOIN prod_dimen_new pd ON pd.Prod_id = m.Prod_id  
    FULL OUTER JOIN shipping_dimen_new sd ON sd.Ship_id = m.Ship_id
    FULL OUTER JOIN cust_dimen_new cd ON cd.Cust_id = m.Cust_id) new_table;

SELECT * 
FROM combined_table


--/////////////////////////////


-- 2. Find the top 3 customers who have the maximum count of orders.

SELECT TOP 3 Customer_Name, COUNT(Ord_id) max_orders
FROM combined_table
GROUP BY Customer_Name
ORDER BY max_orders DESC;


--/////////////////////////////


-- 3. Create a new column at combined_table as DaysTakenForDelivery that contains the date difference of Order_Date and Ship_Date.

ALTER TABLE combined_table
ADD DaysTakenForDelivery INT


UPDATE combined_table
SET DaysTakenForDelivery = DATEDIFF(day, Order_Date, Ship_Date);

SELECT * FROM combined_table


--////////////////////////////////


-- 4. Find the customer whose order took the maximum time to get delivered.

SELECT TOP 1 cust_id, customer_name, MAX(DaysTakenForDelivery) max_delivered
FROM combined_table
GROUP BY Cust_id, customer_name
ORDER BY max_delivered DESC;


--/////////////////////////////////


-- 5. Count the total number of unique customers in January and how many of them came back every month over the entire year in 2011.

SELECT MONTH(Order_Date) month_order, COUNT(DISTINCT Cust_id) monthly_cust_of_num
FROM combined_table
WHERE Cust_id IN
(
SELECT Cust_id
FROM combined_table
WHERE DATEPART(month, Order_Date) = '01' AND DATEPART(year, Order_Date) = '2011'
)
AND YEAR(Order_Date) = 2011
GROUP BY MONTH(Order_Date)
ORDER BY month_order


--/////////////////////////////////////


-- 6. Write a query to return for each user the time elapsed between the first purchasing and the third purchasing, in ascending order by Customer ID.

SELECT DISTINCT Cust_id, Order_Date, dense_number, First_Order_Date, DATEDIFF(day, First_Order_Date, Order_Date) Days_Elapsed
FROM 
(SELECT Cust_id, Order_Date, DENSE_RANK() OVER (PARTITION BY Cust_id ORDER BY Order_Date) dense_number, MIN(Order_Date) OVER (PARTITION BY Cust_id) First_Order_Date
FROM combined_table) A
WHERE dense_number = 3
ORDER BY Cust_id

--SOLUTION 2
/*
WITH T1 AS
(SELECT Cust_id, Order_Date, DENSE_RANK() OVER (PARTITION BY Cust_id ORDER BY Order_Date) dense_number, MIN(Order_Date) OVER (PARTITION BY Cust_id) First_Order_Date
FROM combined_table)

SELECT DISTINCT Cust_id, Order_Date, dense_number, First_Order_Date, DATEDIFF(day, First_Order_Date, Order_Date) Days_Elapsed
FROM T1
WHERE dense_number = 3
ORDER BY Cust_id
*/ 

--///////////////////////////////////////

-- 7. Write a query that returns customers who purchased both product 11 and product 14 as well as the ratio of these products to the total number of products purchased by the customer.

WITH T1 AS (
SELECT Cust_id,
    SUM(CASE WHEN Prod_id = '11' THEN Order_Quantity ELSE 0 END) P11,
    SUM(CASE WHEN Prod_id = '14' THEN Order_Quantity ELSE 0 END) P14, SUM(Order_Quantity) Total_Prod
FROM combined_table
GROUP BY Cust_id
HAVING  SUM(CASE WHEN Prod_id = '11' THEN Order_Quantity ELSE 0 END) > 0 AND SUM(CASE WHEN Prod_id = '14' THEN Order_Quantity ELSE 0 END) > 0
)
SELECT Cust_id, P11, P14, Total_Prod, ROUND(CAST(P11 AS FLOAT) / CAST(Total_Prod AS FLOAT), 2) Ratio_P11,
                                      ROUND(CAST(P14 AS FLOAT) / CAST(Total_Prod AS FLOAT), 2) RATIO_P14
FROM T1
ORDER BY Cust_id;


--//////////////////////////////////////////
--//////////////////////////////////////////

-- CUSTOMER RETENTION ANALYSIS


-- 1. Create a view that keeps visit logs of customers on a monthly basis. (For each log, three field is kept: Cust_id, Year, Month)

CREATE VIEW customer_logs AS 
            SELECT cust_id, YEAR(Order_Date) [Year], MONTH(Order_Date) [Month]
            FROM combined_table; 

SELECT * 
FROM customer_logs 
ORDER BY Cust_id;


--/////////////////////////////////////////////


-- 2. Createa view that keeps the number of monthly visits byusers.(Separately for all months from the business beginning)

CREATE VIEW monthly_visits_num AS
            SELECT Cust_id, [Year], [Month], COUNT(*) Num_Of_Log
            FROM customer_logs
            GROUP BY Cust_id, [Year], [Month];

SELECT * 
FROM monthly_visits_num 
ORDER BY Cust_id;


--///////////////////////////////////////////////


-- 3. For each visit of customers, create the next month of the visit as a separate column.

CREATE VIEW Next_Visit AS
SELECT Cust_id, [Year], [Month], Num_Of_Log, Current_Month, LEAD(Current_Month) OVER (PARTITION BY Cust_id ORDER BY Current_Month) Next_Visit_Month
FROM 
    (SELECT *, DENSE_RANK() OVER (ORDER BY [Year], [Month]) Current_Month
     FROM monthly_visits_num) sub_q

SELECT *
FROM Next_Visit
ORDER BY Current_Month


--///////////////////////////////////////////////


-- 4. Calculate the monthly time gap between two consecutive visits by each customer.

CREATE VIEW Time_Gap AS
SELECT *, (Next_Visit_Month - Current_Month) Time_Gaps
FROM Next_Visit


SELECT *
FROM Time_Gap


--///////////////////////////////////////////////////


-- 5. Categorise customers using average time gaps.Choose the most fitted labeling model for you.
-- For example:
-- Labeled as churn if the customer hasn't made another purchase in the months since they made their first purchase.
-- Labeled as regular if the customer has made a purchase every month. Etc.

SELECT Cust_id, Avg_Time_Gap, 
       CASE WHEN Avg_Time_Gap IS NULL THEN 'Churn'
            WHEN Avg_Time_Gap = 1 THEN 'Regular' 
            WHEN Avg_Time_Gap > 1 THEN 'Irregular' END Cust_Labels
FROM 
      (SELECT Cust_id, AVG(Time_Gaps) Avg_Time_Gap
      FROM Time_Gap
      GROUP BY Cust_id) A


--/////////////////////////////////////////////
--////////////////////////////////////////////


/* Month-Wise Retention Rate
Find month-by-month customer retention ratei since the start of the business.
There are many different variations in the calculation of Retention Rate. 
But we will try to calculate the month-wise retention rate in this project.
So, we will be interested in how many of the customers in the previous month could be retained in the next month.
Proceed step by step by creating views. 
You can use the view you got at the end of the Customer Segmentation section as a source. */

-- 1. Find the number of customers retained month-wise. (You can use time gaps)


SELECT *, COUNT(Cust_id) OVER (PARTITION BY Next_Visit_Month) Retentition_Month_Wise
FROM Time_Gap
WHERE Time_Gaps = 1
ORDER BY Cust_id, Next_Visit_Month


--//////////////////////////////////////////////


-- 2. Calculate the month-wise retention rate.
--    Month-Wise Retention Rate = 1.0 * Total Number of Customers in The Previous Month / Number of Customers Retained in The Next Month

CREATE VIEW Current_Cust AS (
            SELECT DISTINCT Cust_id, [Year], [Month], Current_Month, COUNT(Cust_id) OVER (PARTITION BY Current_Month) current_num 
            FROM Time_Gap
)

CREATE VIEW Next_Cust AS  (
            SELECT DISTINCT Cust_id, Current_Month, Next_Visit_Month, COUNT(Cust_id) OVER (PARTITION BY Current_Month) next_num
            FROM Time_Gap
            WHERE Time_Gaps = 1 AND Current_Month > 1 

)


SELECT *
FROM Current_Cust

SELECT *
FROM Next_Cust


SELECT DISTINCT c.[Year], c.[Month], ROUND((CAST(n.next_num AS FLOAT) / CAST(c.current_num AS FLOAT)), 2) Retention_Rate 
FROM Current_Cust c INNER JOIN Next_Cust n
ON c.Cust_id = n.Cust_id AND c.Current_Month = n.Current_Month
ORDER BY [YEAR], [MONTH]

--//////////////////////////////////////////////////////////

-- SOLUTION 2 

SELECT *
FROM 
    (SELECT DISTINCT c.[Year], c.[Month], ROUND((CAST(n.next_num AS FLOAT) / CAST(c.current_num AS FLOAT)), 2) Retention_Rate
     FROM Current_Cust c INNER JOIN Next_Cust n
     ON c.Cust_id = n.Cust_id AND c.Current_Month = n.Current_Month) sub_q
ORDER BY [Year], [Month]
