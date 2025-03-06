
##Introduction to SQL
#Problem Statement
A lot of people in the world share a common desire: to own a vehicle. A car or an
automobile is seen as an object that gives the freedom of mobility. Many now prefer
pre-owned vehicles because they come at an affordable cost, but at the same time, they
are also concerned about whether the after-sales service provided by the resale
vendors is as good as the care you may get from the actual manufacturers.
New-Wheels, a vehicle resale company, has launched an app with an end-to-end
service from listing the vehicle on the platform to shipping it to the customerlocation.
This app also captures the overall after-sales feedback given by the customer.
Objective
New-Wheels sales have been dipping steadily in the past year, and due to the critical
customer feedback and ratings online, there has been a drop in new customers every
quarter, which is concerning to the business. The CEO of the company now wants a
quarterly report with all the key metrics sent to him so he can assess the health of the
business and make the necessary decisions.
As a data analyst, you see that there is an array of questions that are being asked at
the leadership level that need to be answered using data. Import the dump file that
contains various tables that are present in the database. Use the data to answer the
questions posed and create a quarterly business report for the CEO


##Question:Find the percentage distribution of feedback from the
customers. Are customers getting more dissatisfied over time?
SELECT 
    q.quarter_number,
    ROUND(100.0 * SUM(CASE WHEN customer_feedback = 'Very Bad' THEN 1 ELSE 0 END) / COUNT(*), 2) AS very_bad_pct,
    ROUND(100.0 * SUM(CASE WHEN customer_feedback = 'Bad' THEN 1 ELSE 0 END) / COUNT(*), 2) AS bad_pct,
    ROUND(100.0 * SUM(CASE WHEN customer_feedback = 'Okay' THEN 1 ELSE 0 END) / COUNT(*), 2) AS okay_pct,
    ROUND(100.0 * SUM(CASE WHEN customer_feedback = 'Good' THEN 1 ELSE 0 END) / COUNT(*), 2) AS good_pct,
    ROUND(100.0 * SUM(CASE WHEN customer_feedback = 'Very Good' THEN 1 ELSE 0 END) / COUNT(*), 2) AS very_good_pct
FROM (
    SELECT 
        order_id,
        customer_feedback,
        quarter_number
    FROM order_t
) AS q
GROUP BY q.quarter_number
ORDER BY q.quarter_number;  

SET SESSION sql_mode = '';

#Question: What is the trend of the number of orders by quarter?
SELECT 
quarter_number,
COUNT(order_id) AS total_orders
FROM order_t
GROUP BY quarter_number
ORDER BY quarter_number;
  
#Question: What is the trend of net revenue and orders by quarters?
SELECT 
quarter_number,
SUM(quantity * (vehicle_price-discount)) AS net_revenue,
COUNT(order_id) AS number_of_orders
FROM order_t
GROUP BY quarter_number
ORDER BY quarter_number;

#Question: What is the average discount offered for different types of credit cards?
SELECT c.credit_card_type,
ROUND(AVG(o.discount),2) AS average_discount
FROM customer_t AS c
JOIN order_t AS o ON c.customer_id=o.customer_id
GROUP BY c.credit_card_type
ORDER BY average_discount DESC; 

#Question: What is the average time taken to ship the placed orders for each quarter?
SELECT 
quarter_number,
AVG(DATEDIFF(ship_date,order_date)) AS average_time_to_ship
FROM order_t
GROUP BY 1
ORDER BY 1;

#Question: Find the total number of customers who have placed orders. What is the distribution of the customers across states?
SELECT state,COUNT( DISTINCT o.customer_id) AS total_customers
FROM customer_t AS c
JOIN order_t AS o ON c.customer_id=o.customer_id
GROUP BY 1
ORDER BY 2 DESC
LIMIT 5;

#Question: Which are the top 5 vehicle makers preferred by the customers?
SELECT vehicle_maker,COUNT(DISTINCT o.customer_id) AS customers_preferred
FROM product_t AS p
JOIN order_t AS o ON p.product_id=o.product_id
GROUP BY 1
ORDER BY 2 DESC
LIMIT 5;

#Question: Which is the most preferred vehicle maker in each state?
SELECT c.state, p.vehicle_maker, COUNT(DISTINCT c.customer_id) AS customer_count
FROM customer_t AS c
JOIN order_t AS o ON c.customer_id = o.customer_id
JOIN product_t AS p ON o.product_id = p.product_id
GROUP BY c.state, p.vehicle_maker
HAVING COUNT(DISTINCT c.customer_id) = (
    SELECT MAX(customer_count)
    FROM (
        SELECT c.state, p.vehicle_maker, COUNT(DISTINCT c.customer_id) AS customer_count
        FROM customer_t AS c
        JOIN order_t AS o ON c.customer_id = o.customer_id
        JOIN product_t AS p ON o.product_id = p.product_id
        GROUP BY c.state, p.vehicle_maker
    ) AS state_vehicle_counts
    WHERE state_vehicle_counts.state = c.state
)
ORDER BY c.state;

#Question : Find the overall average rating given by the customers.
#What is the average rating in each quarter?
#Consider the following mapping for ratings: “Very Bad”: 1, “Bad”: 2, “Okay”: 3,“Good”: 4, “Very Good”: 5
SELECT period, ROUND(AVG(rating), 2) AS avg_rating
FROM (
    SELECT 'Overall' AS period, 
           CASE 
               WHEN customer_feedback = 'Very Bad' THEN 1
               WHEN customer_feedback = 'Bad' THEN 2
               WHEN customer_feedback = 'Okay' THEN 3
               WHEN customer_feedback = 'Good' THEN 4
               WHEN customer_feedback = 'Very Good' THEN 5
           END AS rating
    FROM order_t

    UNION ALL

    SELECT CONCAT('Q', quarter_number) AS period, 
           CASE 
               WHEN customer_feedback = 'Very Bad' THEN 1
               WHEN customer_feedback = 'Bad' THEN 2
               WHEN customer_feedback = 'Okay' THEN 3
               WHEN customer_feedback = 'Good' THEN 4
               WHEN customer_feedback = 'Very Good' THEN 5
           END AS rating
    FROM order_t
) AS FeedbackData
GROUP BY period
ORDER BY period;

#Question: Calculate the net revenue generated by the company.What is the quarter-over-quarter % change in net revenue?
SELECT 
    q.quarter_number,
    q.net_revenue,
    LAG(q.net_revenue) OVER (ORDER BY q.quarter_number) AS prev_quarter_revenue,
    ROUND(
        100.0 * (q.net_revenue - LAG(q.net_revenue) OVER (ORDER BY q.quarter_number)) / 
        NULLIF(LAG(q.net_revenue) OVER (ORDER BY q.quarter_number), 0), 2
    ) AS qoq_change_pct
FROM (
    SELECT 
        quarter_number,
        SUM(quantity * (vehicle_price - discount)) AS net_revenue
    FROM order_t
    GROUP BY quarter_number
) q
ORDER BY q.quarter_number;







