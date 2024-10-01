# Consumer Goods Analysis  
## Table of Contents  
- [Project Overview](#project-overview)
- [Data Source](#data-source)
- [Results](#results)
- [Conclusion](#conclusion)
- [Recommendation](#recommendation)

## Project Overview  
**Atliq Hardwares** is one of the leading computer hardware producers in India and well expanded in other countries too. The management require more insights to make quick and smart decisions. So they are planning to expand their teams of analyst by hiring some junior analyst. Their data analytics director wanted to hire someone who is good at both tech and soft skills. Hence, he decided to conduct a **SQL** challenge which will help him understand both the skills.  
There are 10 ad-hoc requests for which business insights are required. To run these requests SQL is used.  
## Data Source  
A dump file **atliq_hardware_db.sql**  was provided to load the **`gdb023`** database. There were 6 tables used for this analysis in this database:  
**dim_customer** This tables conatins the details of the customers of Atliq  
**dim_product** This table shows the products manufactured by the company  
**fact_gross_price** This table shows the gross price of each product  
**fact_manufacturing_cost** This table gives the manufacturing cost of each product  
**fact_sales_monthly** This tables gives the sales transactions with sales date, customer code and product code  
**fact_preinvoice_deductions** This table informs the invoice discounts earned by each customer in each fiscal year  
### Tools Used  
**MySQL Workbench** MySQL workbench was used to load the dump file and run the requests.  
**Power BI** Data transformation and creating visuals  
#### Data loading and EDA  
Dump file was loaded into MySQL workbench and all the querries was fired. In Power BI, the metrics for creating all the requests were created. Following are the metrics created:  
- **Distinct product count** - Unique products sold in 2020 and 2021 counted from fact_sales_monthy
- **Percentage change** - This is calculated from the unique product count from 2020 and 2021
- **Difference** - Difference between distinct product count in 2020 and 2021
- **Min and Max manufacturing cost** - Minimum and maximum manufacturing cost is calculated from fact_manufacturing_cost
- **Avg_pre_invoice_ct** - This is calculated from fact_preinvoice_deductions
- **Gross_sales_amount** - This metric is calculated by inner joining tables fact_sales_monthly, fact_gross_price and multiplying sold_quantity and gross_price
- **Total_sold_quantity** - This is calculated by summing sold_quantity from fact_sales_monthly

#### Ad-hoc querries and visuals in Power BI
 1. List of markets in which **Atliq Exclusive** operates its business in the **APAC region** 
```sql
SELECT * FROM gdb023.dim_customer
WHERE customer = "Atliq Exclusive" AND region = "APAC";
```

![REQ1_OP](https://github.com/user-attachments/assets/6c8b2e46-a6ff-432d-9a79-c900f2e8248e)  

![REQ1](https://github.com/user-attachments/assets/a83d0588-85db-4296-a9f5-b4f81013b3a7)



2.  Percentage of **unique product** increase in **2021 vs. 2020**
```sql
WITH SalesSummary AS (
    SELECT
        product_code,
        fiscal_year,
        COUNT(DISTINCT product_code) AS unique_products
    FROM fact_sales_monthly
    WHERE fiscal_year IN ('2020', '2021')
    GROUP BY product_code, fiscal_year
)
SELECT
    COUNT(DISTINCT CASE WHEN fiscal_year = '2020' THEN unique_products ELSE 0 END) AS unique_products_2020,
    COUNT(DISTINCT CASE WHEN fiscal_year = '2021' THEN unique_products  ELSE 0 END) AS unique_products_2021,
    ROUND(
        (SUM(CASE WHEN fiscal_year = '2021' THEN unique_products  ELSE 0 END) -
         SUM( CASE WHEN fiscal_year = '2020' THEN unique_products  ELSE 0 END)) * 100.0 /
        NULLIF(SUM(CASE WHEN fiscal_year = '2020' THEN unique_products  ELSE 0 END), 0),
        2
    ) AS percentage_change
FROM SalesSummary
GROUP BY product_code;
```   

  ![REQ2](https://github.com/user-attachments/assets/0d1be99f-7a17-48bf-8bdd-8e6360b1b720)  

  

  ![REQ2_OP](https://github.com/user-attachments/assets/39e89332-470e-44df-b7d3-ba19afb9de19)




3. Report with all the unique product counts for each  **segment**  and sort them in descending order of product counts
 ```sql
SELECT segment,COUNT(DISTINCT product_code) AS product_count 
FROM dim_product
GROUP BY segment
ORDER BY COUNT(DISTINCT product_code) DESC;
```
![REQ3_OP](https://github.com/user-attachments/assets/da018420-3519-48d0-8a38-72e34bf42726)  

 
![REQ3](https://github.com/user-attachments/assets/9a899553-f890-4bf1-add5-dcf6b58af9e1)  

 4.  The **segment** which had the most increase in unique products in 2021 vs 2020
```sql
SELECT dp.segment,
		count(distinct CASE WHEN fsm.fiscal_year='2020' THEN fsm.product_code  END) AS product_count_2020,
		count(distinct CASE WHEN fsm.fiscal_year='2021' THEN fsm.product_code  END) AS product_count_2021,
        ROUND(
        (COUNT(DISTINCT CASE WHEN fsm.fiscal_year = '2021' THEN fsm.product_code END) -
         COUNT(DISTINCT CASE WHEN fsm.fiscal_year = '2020' THEN fsm.product_code END))
    ) AS difference
        FROM dim_product dp
INNER JOIN fact_sales_monthly AS fsm ON dp.product_code = fsm.product_code
GROUP BY dp.segment
ORDER BY difference DESC;
```

![REQ4_OP](https://github.com/user-attachments/assets/45cb97f8-4da7-4a82-af04-c70b44a08daf)


![REQ4](https://github.com/user-attachments/assets/02a33f40-2b09-440b-9740-1cf84d826070)  


5. Products with highest and lowest **manufacturing cost**
 ```sql
SELECT fmc.product_code,dp.product,fmc.manufacturing_cost
FROM fact_manufacturing_cost AS fmc
INNER JOIN dim_product AS dp ON fmc.product_code=dp.product_code
WHERE fmc.manufacturing_cost=(SELECT MAX(manufacturing_cost) FROM fact_manufacturing_cost) OR 
	  fmc.manufacturing_cost=(SELECT MIN(manufacturing_cost) FROM fact_manufacturing_cost);
```
  
![REQ5_OP](https://github.com/user-attachments/assets/5d83818e-642f-4b17-b7b8-6e9253f3bb95)   

  
![REQ5](https://github.com/user-attachments/assets/eae116a5-7911-463d-95c0-b5f15f228f1d)




6. Top 5 customers who received an average high pre_invoice_discount_pct  for the  **fiscal  year 2021** and in the 
**Indian**  market
 ```sql
SELECT
    pid.customer_code,
    dc.customer,
    ROUND(AVG(pid.pre_invoice_discount_pct) * 100,2) AS avg_discount_pct
FROM fact_pre_invoice_deductions AS pid
INNER JOIN dim_customer AS dc ON pid.customer_code = dc.customer_code
WHERE pid.fiscal_year='2021' AND market='India'
GROUP BY pid.customer_code, dc.customer
ORDER BY avg_discount_pct DESC
LIMIT 5;
```
![REQ6_OP](https://github.com/user-attachments/assets/8aa429f6-0164-422b-ba51-31cab09b0a28)

![REQ6](https://github.com/user-attachments/assets/11e62c34-ff80-482c-acd2-0bb6a3b5e4f4)





 


7.  The complete report of the Gross sales amount for the customer  **“Atliq Exclusive”**  for each month
 ```sql
SELECT DATE_FORMAT(fsm.sales_date, '%M') AS Sales_Month,fsm.fiscal_year AS Year, ROUND((fgp.gross_price*fsm.sold_quantity),2) AS Gross_Sales_Amount
FROM dim_customer AS dc
INNER JOIN fact_sales_monthly AS fsm ON dc.customer_code=fsm.customer_code
INNER JOIN fact_gross_price AS fgp ON fsm.product_code=fgp.product_code
WHERE dc.customer="Atliq Exclusive"
ORDER BY Sales_Month;
```
![REQ7_OP](https://github.com/user-attachments/assets/9b7fbec0-227c-4e1b-92aa-c816c8dadef2)   


![REQ7](https://github.com/user-attachments/assets/fa726aa5-ddf4-4fdc-bded-4c5e9ed32128)  


8. Quarter in 2020 that got the maximum total_sold_quantity
  ```sql
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
```
  
![REQ8_OP](https://github.com/user-attachments/assets/ff212dbb-854c-4f32-a1c3-babb375e3a73)

![REQ8](https://github.com/user-attachments/assets/6c38efd3-74dd-4e02-99b3-edeeb59583bc)  



9. Channel that helped to bring more gross sales in the fiscal year 2021 and the percentage of contribution
  ```sql
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
ORDER BY gross_sales_amount_mln DESC;
```
 
![REQ9_OP](https://github.com/user-attachments/assets/b403c8cf-167e-406d-b241-0adb21591d74)

![REQ9](https://github.com/user-attachments/assets/76239fcc-dcb1-43a8-9087-7112c48e0dd5)

 


10. Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021
  ```sql
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
```  

![REQ10_OP](https://github.com/user-attachments/assets/25c0b862-ec38-479c-94da-87fd161c3c9b)  


![REQ10-N S](https://github.com/user-attachments/assets/d3b486ff-4cff-4011-9653-d64bdecefe4b)  


![REQ10-P A](https://github.com/user-attachments/assets/3b5dc510-e896-4041-a792-1c6a0df6e2dc)  


![REQ10-PC](https://github.com/user-attachments/assets/f7d56236-306f-4d37-92ba-3795d7c80acb)  

## Results  
Results of the ad-hoc requests are given below:  
1. List of markets in which **Atliq Exclusive** operates its business in the **APAC region**
   - India
   - Indonesia
   - Japan
   - Philiphines
   - South Korea
   - Australia
   - New Zealand
   - Bangladesh
   - India
2. Percentage of **unique product** increase in **2021 vs 2020** is **36.33%**
3. Report with all the **unique product** counts for each  **segment**  and sorting them in descending order of product counts is:
   - Notebook - 129
   - Accessories - 116
   - Peripherals - 84
   - Desktop - 32
   - Storage - 27
   - Networking - 9
4. The **segment** which had the most increase in unique products in 2021 vs 2020
   - **Accessories - 34** (Highest product increase is for accessories segment)
   - Notebook - 16
   - Peripherals - 16
   - Desktop - 15
   - Storage - 5
   - Networking - 3

       
5. Products with highest and lowest **manufacturing cost** are **personal desktop** with $240.54 and **mouse** with $0.89

6. Top 5 customers who received an average high pre_invoice_discount_pct  for the  **fiscal  year 2021** and in the **Indian** markets are as follows:
   - Flipkart - 30.83%
   - Viveks - 30.38%
   - Ezone - 30.28%
   - Croma - 30.25%
   - Vijay Sales - 27.53%
7. The complete report of the Gross sales amount for the customer  **“Atliq Exclusive”**  for each month.

    **2019**: November recorded the highest gross sales, surpassing the average, while the rest of the months remained below average. Post-November, sales stayed below average until September 2020.
   
    **2020**: March and April saw the lowest gross sales across the three years. Following this significant drop, there was a gradual increase, peaking in November 2020, which marked the highest gross sales among all three years. Despite a subsequent decline, the   
    company managed to keep sales above average, except for April and August 2021.  

    **2021**: The highest gross sales were in January, while August recorded the lowest.
8. **Quarter in 2020** that got the maximum total_sold_quantity is the 4th quarter with 1704M.
9. **Channel** that helped to bring more gross sales in the fiscal year 2021 and the percentage of contribution is **retailer** with 72.32% contribution with $1198.20M gross sales.
10. Top **3 products** in each division that have a high total_sold_quantity in the fiscal_year 2021:

    **N & S division** - A6720160103, A6818160201, A6218160101. First two are **USB Flash drives** and third one is **External Solid State Drives**
    
    **P & A division** - A2319150302, A2219150204, A2218150202. These are all **mouses**
    
    **PC division**    - A4218110202, A4319110306, A4218110205. These are all **personal laptops**
## Conclusion  
- The project successfully addressed ad-hoc requests to develop business insights, aiding management in strategic decision-making.
- It provided an in-depth study of the consumer goods domain and its metrics.
- Stakeholders can now draw valuable conclusions regarding gross sales across various products and markets globally, enabling the development of new strategies to boost sales.
## Recommendation  
1. **Focus on Gross Sales**: The company should prioritize increasing gross sales, as there is clear potential for higher revenue.
2. **Review and Revive Successful Strategies**: Analyze and reinstate past strategies that previously led to significant sales growth.
3. **Develop New Strategies**: Utilize insights from this project to create innovative strategies aimed at escalating gross sales.
4. **Continuous Monitoring**: Regularly review sales data to ensure strategies are effective and adjust as needed to maintain and enhance revenue growth.
   
 
                               
                             
  
   
   
  
    




