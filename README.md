# UK Government Programs

## Overview:

This project analyzes the performance and feedback of five key government programs in the UK. Using an interactive dashboard, it provides insights into critical metrics, including budget allocation, expenditure, program ratings, and feedback trends. Key KPIs such as negative feedback rate (39%) and budget overspend rate (22%) highlight areas of public dissatisfaction and financial inefficiencies. Feedback and spending data were broken down by program names and months to reveal trends and categorical insights. The project aims to drive actionable recommendations for improved public satisfaction, efficient resource allocation, and targeted program enhancements.

## Dataset Description:

This dataset represents a set of government programs, their associated spending, and citizen feedback. It is structured across three main tables:
### 1.	Programs Table: Contains information about various government programs.

-  	Program_ID: Unique identifier for each program.

-  	Program_Name: Name of the program.

-  	Start_Date: The starting date of the program.

-  	End_Date: The ending date of the program.

-  	Sector: The sector under which the program operates (e.g., Education, Healthcare, Infrastructure).
### 2.	Spending Table: Tracks the spending associated with each program.
-  	Spending_ID: Unique identifier for each spending record.

-  	Program_ID: The associated program.

-  	Amount_Spent: The amount of money spent.

-  	Spend_Date: The date the spending occurred (adjusted to fit within 2024).
### 3.	Citizen_Feedback Table: Contains citizen feedback for each program.
-  	Feedback_ID: A unique identifier is used for each feedback entry.

-  	Program_ID: The associated program.

-  	Rating: The rating the citizen provides (e.g., 1 to 5).

-  	Comments: Textual feedback provided by the citizen.
## Research Questions and Methodology
### Research Questions:
#### 1.	Budget Allocation:
-  	Which sectors receive the highest funding, and how does funding vary across programs?
#### 2.	Citizen Satisfaction:
-  	How do citizen ratings and feedback correlate with the amount spent on programs?
#### 3.	Spending Efficiency:
-  	Are programs staying within their allocated budgets, or is there evidence of overspending?
### Methodology:
#### 1.	Data Cleaning:
-  	The dataset underwent cleaning to ensure consistency in program names, spending amounts, and feedback.

-  	Null values were handled, and text was standardized.

-  	Duplicate records in the feedback were identified and removed.
#### 2.	Data Analysis:
-  	Various SQL queries were created to explore the relationships between program funding, citizen feedback, and spending efficiency.

-  	Aggregation queries were used to calculate total spending per program and compare it to allocated budgets.

-  	A categorization of citizen feedback was performed using SQL CASE statements to categorize comments into positive, negative, and neutral feedback.
#### 3.	Key Metrics:
-  	Total budget allocation by sector.

-  	Average citizen rating for each program.

-  	Total spending vs. allocated budget for each program.

## Key findings, insights, and recommendations.
### 1. Which sectors receive the highest funding, and how does funding vary across programs?
#### Purpose: 
To understand government funding priorities and identify potential gaps in funding allocation. 

```sql
SELECT 
    Sector AS Program_Sector,
    SUM(Budget) AS Total_Budget
FROM Programs
GROUP BY Sector
ORDER BY Total_Budget DESC;
```
![image](https://github.com/user-attachments/assets/69cc12aa-2401-42ac-a474-5e7864f34470)

### 2. Which programs receive the high and low citizen ratings, and what patterns emerge in feedback?
#### Purpose:
To gauge program success based on citizen satisfaction and identify areas for improvement. 
```sql
SELECT 
    p.Program_Name AS Program_Name,
    SUM(cf.Rating) AS Total_Ratings,
    COUNT(cf.Feedback_ID) AS Total_Feedbacks
FROM Programs AS p
JOIN Citizen_Feedback AS cf ON p.Program_ID = cf.Program_ID
GROUP BY p.Program_Name
ORDER BY Total_Ratings DESC;
```
![image](https://github.com/user-attachments/assets/9b85fc38-16d4-4cce-ad3f-1798cd38929c)
### 3. Are programs staying within their allocated budgets, or are there patterns of overspending or underspending?
#### Purpose: 
To evaluate financial efficiency and identify programs that may require budget adjustments.
```sql
SELECT 
    p.Program_Name AS Program_Name,
    p.Budget AS Allocated_Budget,
    SUM(s.Amount_Spent) AS Total_Spent,
    (p.Budget - SUM(s.Amount_Spent)) AS Remaining_Budget
FROM Programs AS p
LEFT JOIN Spending AS s ON p.Program_ID = s.Program_ID
GROUP BY p.Program_Name, p.Budget
ORDER BY Remaining_Budget ASC;
```
![image](https://github.com/user-attachments/assets/cc12c5fb-8c87-43d3-957b-1abcd611b9b7)
```sql
SELECT 
    p.Program_ID AS Program_ID,
    p.Budget AS Allocated_Budget,
    s.Amount_Spent AS Actual_Amount_Spent
FROM Programs p
JOIN Spending s
    ON p.Program_ID = s.Program_ID;
```

![image](https://github.com/user-attachments/assets/f2698087-e290-4800-9c88-4aefaefdb9a6)

### 4. Which programs are receiving the most positive or negative feedback based on specific comments?
#### Purpose: 
Identify programs with specific positive or negative trends in feedback to guide future actions.
```sql
SELECT 
    p.Program_Name AS Program_Name,
    COUNT(cf.Feedback_ID) AS Total_Feedbacks,
    SUM(CASE 
        WHEN cf.Comments LIKE '%Highly effective%' OR cf.Comments LIKE '%Excellent initiative%' THEN 1
        ELSE 0 
    END) AS Highly_Positive_Feedbacks,
    SUM(CASE 
        WHEN cf.Comments LIKE '%Good progress%' THEN 1
        ELSE 0 
    END) AS Moderately_Positive_Feedbacks,
    SUM(CASE 
        WHEN cf.Comments LIKE '%Poor execution%' OR cf.Comments LIKE '%Needs improvement%' THEN 1
        ELSE 0 
    END) AS Negative_Feedbacks,
    SUM(CASE 
        WHEN cf.Comments LIKE '%No comments provided%' THEN 1
        ELSE 0 
    END) AS No_Comment_Feedbacks,
    SUM(CASE 
        WHEN cf.Comments NOT LIKE '%Highly effective%'
          AND cf.Comments NOT LIKE '%Excellent initiative%'
          AND cf.Comments NOT LIKE '%Good progress%'
          AND cf.Comments NOT LIKE '%Poor execution%'
          AND cf.Comments NOT LIKE '%Needs improvement%'
          AND cf.Comments NOT LIKE '%No comments provided%' THEN 1
        ELSE 0
    END) AS Uncategorized_Feedbacks
FROM Programs AS p
JOIN Citizen_Feedback AS cf ON p.Program_ID = cf.Program_ID
GROUP BY p.Program_Name        --Combines categorization with program-level aggregation and Provides a breakdown of all feedback categories per program.
ORDER BY Total_Feedbacks DESC; 
```
![image](https://github.com/user-attachments/assets/46b951d2-b06f-4373-9f6d-58f6d73d664a)

### 5. Trends in Budget Allocation by Sector
#### A. Purpose: 
To track how funding priorities for each sector have evolved.
```sql
SELECT 
    Sector AS Program_Sector,
    DATENAME(MONTH, Start_Date) AS Month_Name,
    SUM(Budget) AS Total_Budget
FROM Programs
WHERE YEAR(Start_Date) = 2023
GROUP BY Sector, DATENAME(MONTH, Start_Date), MONTH(Start_Date)
ORDER BY MONTH(Start_Date), Total_Budget DESC;
```

![image](https://github.com/user-attachments/assets/f8f44f8f-7171-4ed7-8bb8-0f29d9e18df3)

#### B. Purpose: 
To track how funding priorities have evolved over time.
```sql
SELECT 
    DATENAME(MONTH, Start_Date) AS Month_Name,
    SUM(Budget) AS Total_Budget
FROM Programs
WHERE YEAR(Start_Date) = 2023
GROUP BY DATENAME(MONTH, Start_Date), MONTH(Start_Date)
ORDER BY MONTH(Start_Date);
```
![image](https://github.com/user-attachments/assets/d53dbbb0-02d5-4841-8a37-6de65f3bfa2e)
### 6. Outliers in Spending: Categorize programs based on spending efficiency.
#### Purpose: 
Identifying overspending programs for budget review.
```sql
SELECT 
    p.Program_Name AS Program_Name,
    SUM(s.Amount_Spent) AS Total_Spent,
    p.Budget AS Allocated_Budget,
    CASE 
        WHEN SUM(s.Amount_Spent) > p.Budget THEN 'Overspent'
        WHEN SUM(s.Amount_Spent) < p.Budget THEN 'Underspent'
        ELSE 'On Budget'
    END AS Budget_Status
FROM Programs AS p
LEFT JOIN Spending AS s ON p.Program_ID = s.Program_ID
GROUP BY p.Program_Name, p.Budget
ORDER BY Total_Spent DESC;
```
![image](https://github.com/user-attachments/assets/959e7a5b-cff0-4430-ba41-bc570873cb39)
### 7. What is the distribution of citizen feedback over time, and does feedback intensity correlate with program stages (start, middle, or end)?
#### Purpose:
•	To analyze whether citizens are more likely to provide feedback at specific stages of a program's lifecycle:

-  	At the beginning (initial impressions),
  
*  	During the middle (progress assessments), or
  
-  	At the end (outcome evaluations).
  
•	This can help the government time surveys or feedback collection more effectively.
```sql
SELECT 
    p.Program_Name AS Program_Name,
    p.Start_Date AS Program_Start_Date,
    p.End_Date AS Program_End_Date,
    cf.Feedback_Date AS Feedback_Date,
    CASE 
        WHEN cf.Feedback_Date BETWEEN p.Start_Date AND DATEADD(DAY, DATEDIFF(DAY, p.Start_Date, p.End_Date) / 3, p.Start_Date)
             THEN 'Start Phase'
        WHEN cf.Feedback_Date BETWEEN DATEADD(DAY, DATEDIFF(DAY, p.Start_Date, p.End_Date) / 3, p.Start_Date)
                                 AND DATEADD(DAY, 2 * DATEDIFF(DAY, p.Start_Date, p.End_Date) / 3, p.Start_Date)
             THEN 'Middle Phase'
        ELSE 'End Phase'
    END AS Feedback_Stage,
    COUNT(cf.Feedback_ID) AS Total_Feedbacks
FROM Programs p
JOIN Citizen_Feedback cf ON p.Program_ID = cf.Program_ID
GROUP BY p.Program_Name, p.Start_Date, p.End_Date, cf.Feedback_Date
ORDER BY p.Program_Name, Feedback_Stage;
```
![image](https://github.com/user-attachments/assets/1f0b30cc-7219-4c09-81e1-46d90c36da7d)

### 8. How quickly do citizens provide feedback after a program starts, and does response speed correlate with satisfaction ratings?
#### Purpose:
•	Assess citizen engagement levels by analyzing the average time between program start and feedback submission.

•	Determine if faster feedback correlates with higher or lower satisfaction ratings.
```sql
SELECT 
    p.Program_Name AS Program_Name,
    AVG(DATEDIFF(DAY, p.Start_Date, cf.Feedback_Date)) AS Avg_Days_To_Feedback,
    SUM(cf.Rating) AS Total_Rating,
    COUNT(cf.Feedback_ID) AS Total_Feedbacks
FROM Programs p
JOIN Citizen_Feedback cf ON p.Program_ID = cf.Program_ID
GROUP BY p.Program_Name
ORDER BY Avg_Days_To_Feedback ASC;
```
![image](https://github.com/user-attachments/assets/93f4bfc9-fe40-4e8e-aaba-da9ca5b81a16)
### 9. Feedback Ratings by Month
#### Purpose:
•	To determine if citizen satisfaction fluctuates over different months.

•	To uncover if specific months consistently show higher or lower satisfaction.
```sql
SELECT 
    DATENAME(MONTH, cf.Feedback_Date) AS Feedback_Month,
    MONTH(cf.Feedback_Date) AS Month_Number,
    SUM(cf.Rating) AS Total_Rating,
    COUNT(cf.Feedback_ID) AS Total_Feedbacks
FROM Citizen_Feedback cf
GROUP BY DATENAME(MONTH, cf.Feedback_Date), MONTH(cf.Feedback_Date)
ORDER BY Month_Number;
```
### 10. Feedback Categorization by Month
#### Purpose:
To systematically organize citizen comments into distinct groups—positive, negative, and uncategorized to provide meaningful insights and actionable intelligence.
```sql
SELECT 
    DATENAME(MONTH, cf.Feedback_Date) AS Feedback_Month,
    MONTH(cf.Feedback_Date) AS Month_Number,
    COUNT(cf.Feedback_ID) AS Total_Feedbacks,
    SUM(CASE 
        WHEN cf.Comments LIKE '%Highly effective%' OR cf.Comments LIKE '%Excellent initiative%' OR cf.Comments LIKE '%Good progress%' THEN 1
        ELSE 0 
    END) AS Positive_Feedbacks,
    SUM(CASE 
        WHEN cf.Comments LIKE '%Poor execution%' OR cf.Comments LIKE '%Needs improvement%' THEN 1
        ELSE 0 
    END) AS Negative_Feedbacks,
    SUM(CASE 
        WHEN cf.Comments NOT LIKE '%Highly effective%' 
          AND cf.Comments NOT LIKE '%Excellent initiative%' 
          AND cf.Comments NOT LIKE '%Good progress%' 
          AND cf.Comments NOT LIKE '%Poor execution%' 
          AND cf.Comments NOT LIKE '%Needs improvement%' THEN 1
        ELSE 0
    END) AS No_Feedbacks
FROM Citizen_Feedback AS cf
GROUP BY DATENAME(MONTH, cf.Feedback_Date), MONTH(cf.Feedback_Date)
ORDER BY Month_Number;
```
![image](https://github.com/user-attachments/assets/43bb0224-5524-463e-935b-229b0c6b2f76)
![image](https://github.com/user-attachments/assets/1b2b4441-e8bb-41c8-9adc-9cb0843e64de)
## Recommendations
To enhance governance and program performance:
### 1.	Optimize Spending Efficiency:
-  	Reallocate funds from underspent programs to those with demonstrated impact.

-  	Monitor quarterly spending to ensure alignment with planned budgets.
### 2.	Increase Citizen Engagement:
-  	Improve public outreach and transparency for programs with low engagement.

-  	Focus on sectors where feedback indicates dissatisfaction.
### 3.	Enhance Feedback Systems:
-  	Use digital tools to simplify feedback collection and analysis.

-  	Train staff to act on citizen feedback more efficiently.
### 4.	Plan for Seasonality:
-  	Leverage peak months for program launches and promotional campaigns.

-  	Ensure steady program visibility during off-peak months.
### 5.  Enhanced Budget Planning:
-  	Conduct pre-implementation cost analysis for major programs to minimize overspending.
### 6.  Improved Monitoring Mechanisms:
-  	Establish real-time monitoring tools for spending to track fund utilization against the allocated budget dynamically.

-  	Ensure regular audits for programs to maintain transparency and identify areas of overspending early.
### 7.  Reallocation of Resources:
-  	Programs in sectors like Education and Digital Literacy should receive increased funding, given their potential impact on long-term growth.

-  	Reallocate funds from consistently underutilized programs to those with higher efficiency or citizen satisfaction.
### 8.  Citizen-Centric Approach:
-  	Incorporate citizen feedback data into budget planning to prioritize programs that directly address public needs.

-  	Develop surveys post-program implementation to assess impact and align future spending priorities accordingly.
This integrated approach will enable the government to allocate resources effectively, improve citizen satisfaction, and enhance overall program performance.

## Challenges Faced and Solutions
### 1. Data Inconsistencies
-  	Challenge: Variability in program names and descriptions caused misalignment in analysis.

-  	Solution: Used SQL functions like TRIM, LOWER, and conditional updates to standardize text data.
### 2. Missing Data
-   Challenge: Null values in feedback and spending records affected analysis completeness.

-   Solution: Replaced null values with placeholders and categorized them as "No Comments Provided."
### 3. Overspending Detection
-  	Challenge: Identifying programs that exceeded their budgets required multiple calculations.

-  	Solution: Used SQL SUM and CASE statements to flag programs with significant budget variances.
 
## Conclusion
The project demonstrates the value of leveraging citizen feedback for informed decision-making and program optimization, ultimately improving government transparency and responsiveness. This analysis can serve as a foundation for iterative program evaluation and citizen-centric policy development.
## DASHBOARD 1
![image](https://github.com/user-attachments/assets/c37fde22-fd8b-4b33-85bf-8ec3617ec719)
## DASHBOARD 2
![image](https://github.com/user-attachments/assets/0206dbd0-75ea-4bb3-bee8-412f374b3054)
