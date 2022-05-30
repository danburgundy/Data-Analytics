

--DAwSQL Session -8 

--E-Commerce Project Solution



--1. Join all the tables and create a new table called combined_table. (market_fact, cust_dimen, orders_dimen, prod_dimen, shipping_dimen)

SELECT m.Ord_id,m.Prod_id,m.Ship_id,m.Cust_id,m.Discount,m.Order_Quantity,m.Product_Base_Margin,
p.Product_Category,p.Product_Sub_Category,
c.Province,c.Region,c.Customer_Segment,c.Customer_Name,
o.Order_Priority,o.Order_Date,
s.Ship_Mode,s.Ship_Date
INTO combined_table
from orders_dimen o,market_fact m,cust_dimen c,prod_dimen p, shipping_dimen s 
where o.Ord_id = m.Ord_id 
and m.Prod_id = p.Prod_id 
and m.Ship_id = s.Ship_id 
and m.Cust_id = c.Cust_id

select * from combined_table



--///////////////////////


--2. Find the top 3 customers who have the maximum count of orders.


select Top 3 Cust_id,Customer_Name,count(*) order_num from combined_table
group by Cust_id,Customer_Name
order by 3 DESC




--/////////////////////////////////



--3.Create a new column at combined_table as DaysTakenForDelivery that contains the date difference of Order_Date and Ship_Date.
--Use "ALTER TABLE", "UPDATE" etc.
ALTER TABLE combined_table 
    ADD DaysTakenForDelivery INT


UPDATE combined_table
SET DaysTakenForDelivery =DATEDIFF(day, Order_date, Ship_date)
from combined_table


--////////////////////////////////////


--4. Find the customer whose order took the maximum time to get delivered.
--Use "MAX" or "TOP"

select Top 1 Customer_Name,Ord_id,DaysTakenForDelivery from combined_table
ORDER BY 3 DESC 




--////////////////////////////////



--5. Count the total number of unique customers in January and how many of them came back every month over the entire year in 2011
--You can use date functions and subqueries


select month(Order_Date),count(Cust_id) from combined_table
where YEAR(Order_Date)=2011
GROUP BY month(Order_Date)
ORDER BY month(Order_Date) ASC









--////////////////////////////////////////////


--6. write a query to return for each user acording to the time elapsed between the first purchasing and the third purchasing, 
--in ascending order by Customer ID
--Use "MIN" with Window Functions
WITH sub1 AS (
SELECT Cust_id,
       MAX(CASE WHEN ord_num = 1 THEN C.Order_Date END) as OrderDate_1,
       MAX(CASE WHEN ord_num = 3 THEN C.Order_Date END) as OrderDate_3,
       COUNT(DISTINCT C.Ord_id) AS TotalNumberOfOrders   
FROM (SELECT *, ROW_NUMBER() OVER (PARTITION BY Cust_id ORDER BY Order_Date) as ord_num
      FROM combined_table 
     ) C 
GROUP BY Cust_id
)
select CONVERT(VARCHAR(5),DATEDIFF(s, OrderDate_1, OrderDate_3)/3600)+':'+convert(varchar(5),DATEDIFF(s, OrderDate_1, OrderDate_3)%3600/60)+':'+convert(varchar(5),DATEDIFF(s, OrderDate_1, OrderDate_3)%60) from sub1 where OrderDate_3 is Not null



--//////////////////////////////////////

--7. Write a query that returns customers who purchased both product 11 and product 14, 
--as well as the ratio of these products to the total number of products purchased by all customers.
--Use CASE Expression, CTE, CAST and/or Aggregate Functions
WITH sub2 AS (
select * 
from combined_table
where Cust_id in 
(
  select Cust_id
  from combined_table
  where Prod_id in ('Prod_11','Prod_14')
  group by Cust_id
  having count(distinct Prod_id) = 2
)),
sub3 AS(
    select distinct prod_id,
SUM(Order_Quantity*Product_Base_Margin) OVER(PARTITION BY Prod_id) total_prod,
SUM(Order_Quantity*Product_Base_Margin) OVER() total,
SUM(Order_Quantity*Product_Base_Margin) OVER(PARTITION BY Prod_id) / SUM(Order_Quantity*Product_Base_Margin) OVER() ratio
from combined_table
)
select * from sub3 ORDER BY Prod_id

--/////////////////



--CUSTOMER SEGMENTATION



--1. Create a view that keeps visit logs of customers on a monthly basis. (For each log, three field is kept: Cust_id, Year, Month)
--Use such date functions. Don't forget to call up columns you might need later.

CREATE VIEW logs AS
SELECT Cust_id,MONTH(Order_Date) month,YEAR(Order_Date) year
FROM combined_table


--//////////////////////////////////



  --2.Create a “view” that keeps the number of monthly visits by users. (Show separately all months from the beginning  business)
--Don't forget to call up columns you might need later.

CREATE VIEW visit AS
SELECT MONTH(Order_Date) month,COUNT(Cust_id) total
FROM combined_table
GROUP BY MONTH(Order_Date)





--//////////////////////////////////


--3. For each visit of customers, create the next month of the visit as a separate column.
--You can order the months using "DENSE_RANK" function.
--then create a new column for each month showing the next month using the order you have made above. (use "LEAD" function.)
--Don't forget to call up columns you might need later.


select Cust_id,MONTH(Order_Date) month,
COUNT(Cust_id) OVER(PARTITION BY Cust_id ORDER BY MONTH(Order_Date) ASC) AS "visit_num",
LEAD(MONTH(Order_Date)) OVER(PARTITION BY Cust_id ORDER BY MONTH(Order_Date) ASC) AS "Next Month",
LEAD(COUNT(Cust_id)) OVER(PARTITION BY Cust_id ORDER BY MONTH(Order_Date) ASC) AS "Next Month Visit",
DENSE_RANK() OVER(PARTITION BY Cust_id ORDER BY MONTH(Order_Date) ASC) AS "Dense_Rank ile Sıralama"
FROM combined_table
GROUP BY Cust_id,MONTH(Order_Date)




--/////////////////////////////////



--4. Calculate monthly time gap between two consecutive visits by each customer.
--Don't forget to call up columns you might need later.

WITH sub1 as(
select Cust_id,MONTH(Order_Date) month1,
LEAD(MONTH(Order_Date)) OVER(PARTITION BY Cust_id ORDER BY MONTH(Order_Date) ASC) AS "next_month"
FROM combined_table
GROUP BY Cust_id,MONTH(Order_Date)
)
select Cust_id,next_month-month1 from sub1





--///////////////////////////////////


--5.Categorise customers using average time gaps. Choose the most fitted labeling model for you.
--For example: 
--Labeled as “churn” if the customer hasn't made another purchase for the months since they made their first purchase.
--Labeled as “regular” if the customer has made a purchase every month.
--Etc.
WITH sub1 as(
select Cust_id,MONTH(Order_Date) month1,
LEAD(MONTH(Order_Date)) OVER(PARTITION BY Cust_id ORDER BY MONTH(Order_Date) ASC) AS "next_month"
FROM combined_table
GROUP BY Cust_id,MONTH(Order_Date)
),
sub2 as(
select Cust_id,next_month-month1 dif from sub1
)
select Cust_id,avg(dif),
    CASE
        WHEN avg(dif)=1 THEN 'Loyal'
        WHEN avg(dif)=2 THEN 'Discount'
        WHEN avg(dif)=3 THEN 'Impulse'
        WHEN avg(dif)=4 THEN 'Need-based'
        WHEN avg(dif)>4 THEN 'Wandering'
        ELSE
        'One Time Order'
    END 
    from sub2
GROUP by Cust_id







--/////////////////////////////////////




--MONTH-WISE RETENTÝON RATE


--Find month-by-month customer retention rate  since the start of the business.


--1. Find the number of customers retained month-wise. (You can use time gaps)
--Use Time Gaps


WITH sub1 as(
select Distinct Cust_id,MONTH(Order_Date) month1,YEAR(Order_Date) year1,
LEAD(MONTH(Order_Date)) OVER(PARTITION BY Cust_id ORDER BY Cust_id,YEAR(Order_Date) ASC,MONTH(Order_Date)) month2,
LEAD(YEAR(Order_Date)) OVER(PARTITION BY Cust_id ORDER BY Cust_id,YEAR(Order_Date) ASC,MONTH(Order_Date)) year2
from combined_table
GROUP BY Cust_id,MONTH(Order_Date),YEAR(Order_Date)

),
sub2 as(
    select *,
    CASE
        WHEN year1 = year2 and month2 - month1 = 1 THEN 1
        ELSE 0
    END as loyality
    from sub1
)
select sum(loyality) loyal_cust ,count(Cust_id) total_cust
 from sub2



--//////////////////////


--2. Calculate the month-wise retention rate.

--Basic formula: o	Month-Wise Retention Rate = 1.0 * Number of Customers Retained in The Current Month / Total Number of Customers in the Current Month

--It is easier to divide the operations into parts rather than in a single ad-hoc query. It is recommended to use View. 
--You can also use CTE or Subquery if you want.

--You should pay attention to the join type and join columns between your views or tables.

WITH sub1 as(
select Distinct Cust_id,MONTH(Order_Date) month1,YEAR(Order_Date) year1,
LEAD(MONTH(Order_Date)) OVER(PARTITION BY Cust_id ORDER BY Cust_id,YEAR(Order_Date) ASC,MONTH(Order_Date)) month2,
LEAD(YEAR(Order_Date)) OVER(PARTITION BY Cust_id ORDER BY Cust_id,YEAR(Order_Date) ASC,MONTH(Order_Date)) year2
from combined_table
GROUP BY Cust_id,MONTH(Order_Date),YEAR(Order_Date)

),
sub2 as(
    select *,
    CASE
        WHEN year1 = year2 and month2 - month1 = 1 THEN 1
        ELSE 0
    END as loyality
    from sub1
)
select sum(loyality) loyal_cust ,count(Cust_id) toatl_cust,
sum(loyality)*1.0 / count(Cust_id) retained_ratio
from sub2

select Distinct Cust_id,MONTH(Order_Date) month,YEAR(Order_Date) year from combined_table where Cust_id = 'Cust_1001'
ORDER BY YEAR(Order_Date) ASC,MONTH(Order_Date) ASC





---///////////////////////////////////
--Good luck!
