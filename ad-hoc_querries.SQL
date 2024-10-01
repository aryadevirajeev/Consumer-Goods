
SELECT * FROM gdb023.dim_customer;

-- REQ 1 - APAC markets of Atliq Exclusive
SELECT * FROM gdb023.dim_customer
WHERE customer="Atliq Exclusive" AND region="APAC";

SELECT * FROM gdb023.fact_sales_monthly;

SELECT COUNT(*) AS total_rows
FROM fact_sales_monthly;


SELECT product_code, COUNT(DISTINCT product_code) 
FROM gdb023.fact_sales_monthly
WHERE fiscal_year = '2020'
GROUP BY product_code
ORDER BY COUNT(DISTINCT product_code)  DESC;


ALTER TABLE fact_sales_monthly DROP COLUMN unique_products_2020;

-- REQ 2 - Percentage change of unique products in the year 2020 and 2021
WITH SalesSummary AS (
    SELECT
        product_code,
        fiscal_year,
        COUNT(DISTINCT customer_code) AS unique_customers
    FROM fact_sales_monthly
    WHERE fiscal_year IN ('2020', '2021')
    GROUP BY product_code, fiscal_year
)
SELECT
    COUNT(DISTINCT CASE WHEN fiscal_year = '2020' THEN unique_customers ELSE 0 END) AS unique_products_2020,
    COUNT(DISTINCT CASE WHEN fiscal_year = '2021' THEN unique_customers ELSE 0 END) AS unique_products_2021,
    ROUND(
        (SUM(CASE WHEN fiscal_year = '2021' THEN unique_customers ELSE 0 END) -
         SUM( CASE WHEN fiscal_year = '2020' THEN unique_customers ELSE 0 END)) * 100.0 /
        NULLIF(SUM(CASE WHEN fiscal_year = '2020' THEN unique_customers ELSE 0 END), 0),
        2
    ) AS percentage_change
FROM SalesSummary
GROUP BY product_code;


SELECT * FROM gdb023.dim_product;

-- REQ 3 - Unique product count from each segment
SELECT segment,COUNT(DISTINCT product_code) AS product_count 
FROM dim_product
GROUP BY segment
ORDER BY COUNT(DISTINCT product_code) DESC;

-- REQ 4 - Unique product increase by each segment for th year 2020 and 2021
SELECT dp.segment,
		COUNT(DISTINCT CASE WHEN fsm.fiscal_year='2020' THEN fsm.product_code  END) AS product_count_2020,
		COUNT(DISTINCT CASE WHEN fsm.fiscal_year='2021' THEN fsm.product_code  END) AS product_count_2021,
        ROUND(
        (COUNT(DISTINCT CASE WHEN fsm.fiscal_year = '2021' THEN fsm.product_code END) -
         COUNT(DISTINCT CASE WHEN fsm.fiscal_year = '2020' THEN fsm.product_code END))) AS difference
        FROM dim_product dp
INNER JOIN fact_sales_monthly AS fsm ON dp.product_code = fsm.product_code
GROUP BY dp.segment
ORDER BY difference DESC;
SELECT * FROM gdb023.fact_manufacturing_cost;

-- REQ 5 - Products with highest and lowest manufacturing cost
SELECT fmc.product_code,dp.product,fmc.manufacturing_cost
FROM fact_manufacturing_cost AS fmc
INNER JOIN dim_product AS dp ON fmc.product_code=dp.product_code
WHERE fmc.manufacturing_cost=(SELECT MAX(manufacturing_cost) FROM fact_manufacturing_cost) OR 
	  fmc.manufacturing_cost=(SELECT MIN(manufacturing_cost) FROM fact_manufacturing_cost);


SELECT * FROM gdb023.fact_pre_invoice_deductions;

-- REQ 6 - Top 5 Indian customers which received average high pre_invoice_discount_pct for FY 2021
SELECT
    pid.customer_code,
    dc.customer,
    AVG(pid.pre_invoice_discount_pct) AS avg_discount_pct
FROM fact_pre_invoice_deductions AS pid
INNER JOIN dim_customer AS dc ON pid.customer_code = dc.customer_code
WHERE pid.fiscal_year='2021' AND market='India'
GROUP BY pid.customer_code, dc.customer
ORDER BY avg_discount_pct DESC
LIMIT 5;


-- REQ 7 - Gross sales amount month year trend for Atliq Exclusive
SELECT DATE_FORMAT(fsm.sales_date, '%M') AS Sales_Month,fsm.fiscal_year AS Year, ROUND((fgp.gross_price*fsm.sold_quantity),2) AS Gross_Sales_Amount
FROM dim_customer AS dc
INNER JOIN fact_sales_monthly AS fsm ON dc.customer_code=fsm.customer_code
INNER JOIN fact_gross_price AS fgp ON fsm.product_code=fgp.product_code
WHERE dc.customer="Atliq Exclusive"
ORDER BY Sales_Month;

-- REQ 8 - Maximum sold Quarter in 2020
WITH QuarterlySales AS (
    SELECT
        SUM(sold_quantity) AS Total_Sold_Quantity,
        EXTRACT(YEAR FROM sales_date) AS Sale_Year,
        EXTRACT(QUARTER FROM sales_date) AS Sale_Quarter
    FROM fact_sales_monthly AS fsm
    WHERE EXTRACT(YEAR FROM sales_date)='2020' -- Specify your date range
    GROUP BY EXTRACT(YEAR FROM sales_date) ,EXTRACT(QUARTER FROM sales_date)
)
SELECT
    CASE
        WHEN Sale_Quarter = 1 THEN 'Q1'
        WHEN Sale_Quarter = 2 THEN 'Q2'
        WHEN Sale_Quarter = 3 THEN 'Q3'
        WHEN Sale_Quarter = 4 THEN 'Q4'
    END AS Quarter,
    Total_Sold_Quantity
FROM QuarterlySales
ORDER BY Total_Sold_Quantity DESC
LIMIT 1; 

-- REQ 9 - Maximum gross sales channel in the FY 2021
WITH total_sales AS (
    SELECT SUM(fsm.sold_quantity * fgp.gross_price ) AS total
    FROM fact_sales_monthly fsm
    INNER JOIN fact_gross_price fgp ON fsm.product_code = fgp.product_code and fsm.fiscal_year=fgp.fiscal_year
    WHERE fsm.fiscal_year = '2021' 
)
-- Main query to calculate gross sales and percentage contribution by channel
SELECT 
    dc.channel,
    ROUND(SUM(fsm.sold_quantity * fgp.gross_price) / 1e6, 2) AS gross_sales_amount_mln,
    ROUND((SUM(fsm.sold_quantity * fgp.gross_price) / ts.total) * 100, 2) AS percentage
FROM fact_sales_monthly fsm
INNER JOIN dim_customer dc ON fsm.customer_code = dc.customer_code
INNER JOIN fact_gross_price fgp ON fsm.product_code = fgp.product_code AND fsm.fiscal_year = fgp.fiscal_year
INNER JOIN total_sales ts
WHERE fsm.fiscal_year = '2021'
GROUP BY dc.channel, ts.total
ORDER BY gross_sales_amount_mln DESC

-- REQ 10 - Top 3 sold products in FY 2021 by division
WITH ProductSales AS (
	SELECT dp.division,dp.product_code,dp.product,SUM(fsm.sold_quantity) AS total_sold_quantity
	FROM dim_product dp
	INNER JOIN fact_sales_monthly AS fsm ON dp.product_code = fsm.product_code
	GROUP BY dp.division,dp.product_code,dp.product
)
SELECT
    division,
    product_code,
    product,
    total_sold_quantity,
    rank_within_division AS product_rank
FROM (
    SELECT
        division,
        product_code,
        product,
        total_sold_quantity,
        RANK() OVER (PARTITION BY division ORDER BY total_sold_quantity DESC) AS rank_within_division
    FROM ProductSales
) RankedProducts
WHERE rank_within_division <= 3
ORDER BY division, total_sold_quantity DESC;











