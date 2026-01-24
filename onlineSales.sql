-- Import dataset into a backup table
SELECT *
INTO onlineSales_backup
FROM portfolioProject01.dbo.onlineSales
;


-- Creating VIEW to explore, clean and validate dataset
GO
CREATE VIEW Ecommerce_clean AS ( 
SELECT
	Transaction_ID,
	Product_ID,
	Product_name,
	Units_sold,
	Price_per_Unit,
	Units_sold * Price_per_Unit AS Revenue,
	CAST(Transaction_Date AS DATE) AS Transaction_Date,
	Customer_ID,
	Customer_country
FROM onlineSales_backup
WHERE Units_Sold > 0 -- remove negative and '0' values in product sold column
	AND Price_per_Unit > 0 -- remove negative values
	AND Customer_ID IS NOT NULL
)
GO
;

SELECT COUNT(*) FROM onlineSales_backup; -- checking if the view has been cleaned, fewer rows means it is clean
SELECT COUNT(*) FROM Ecommerce_Clean;


-- Sales Performance Over Time
SELECT -- Monthly revenue Trend
	YEAR(Transaction_Date) AS Year,
	MONTH(Transaction_Date) AS Month,
	SUM(Revenue) AS Total_Revenue,
	Customer_country
FROM Ecommerce_clean
GROUP BY YEAR(Transaction_Date), MONTH(Transaction_Date), Customer_country
ORDER BY Year, Month
;

SELECT -- Revenue by Country
	SUM(Revenue) AS Total_Revenue,
	Customer_country
FROM Ecommerce_clean
GROUP BY Customer_country
;

SELECT -- KPI card
    SUM(Revenue) AS Total_Revenue,
    COUNT(DISTINCT Transaction_ID) AS Total_Orders,
    SUM(Revenue) * 1.0 / COUNT(DISTINCT Transaction_ID) AS Avg_Order_Value
FROM Ecommerce_clean
;


-- Top Sold Prodcuts by Revenue
SELECT --Product performance
	Product_name,
	SUM(Revenue) AS Total_Revenue
FROM Ecommerce_clean
GROUP BY Product_name
ORDER BY Total_Revenue DESC
;

SELECT -- Units sold vs Rev
    Product_name,
    SUM(Units_sold) AS Total_Units_Sold,
    SUM(Revenue) AS Total_Revenue
FROM Ecommerce_clean
GROUP BY Product_name
;


-- Top Customers (Revenue based)
SELECT 
	Customer_ID,
	SUM(Revenue) AS Customer_Revenue
FROM Ecommerce_clean
GROUP BY Customer_ID
ORDER BY Customer_Revenue DESC
;

-- Customer Segmentation (RFM - Recency, Frequecy, Monetary Model)
SELECT
	Customer_ID,
	MAX(Transaction_Date) AS Last_Purchase_Date, -- How recently customer purchased
	COUNT(DISTINCT Product_ID) AS Frequency, -- How often customer purchased
	SUM(Revenue) AS Monetary -- How much customer spent
FROM Ecommerce_clean
GROUP BY Customer_ID
;

