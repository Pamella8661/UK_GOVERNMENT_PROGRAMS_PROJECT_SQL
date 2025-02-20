SELECT * FROM programs;
SELECT * FROM citizen_feedback;
SELECT * FROM spending;


--Data Cleaning & Preparation
--1. Checking for duplicates

SELECT program_id, COUNT(*)
FROM programs
GROUP BY program_id
HAVING COUNT(*) > 1;

SELECT feedback_id,program_id, COUNT(*)
FROM citizen_feedback
GROUP BY feedback_id,program_id
HAVING COUNT(*) > 1;

SELECT spending_id, COUNT(*)
FROM spending
GROUP BY spending_id
HAVING COUNT(*) > 1;

--2. Identifying missing values

SELECT *
FROM programs
WHERE budget IS NULL OR program_name IS NULL;

SELECT *
FROM citizen_feedback
WHERE rating IS NULL OR comments IS NULL OR feedback_date IS NULL OR citizen_id IS NULL;

--There are null values in citizen_feedback table, let's fix it

UPDATE citizen_feedback
SET comments = 'No comments provided'
WHERE comments IS NULL;

UPDATE citizen_feedback
SET rating = 0
WHERE rating IS NULL;


SELECT *  --checking for null values in spending table
FROM spending
WHERE amount_spent IS NULL OR spend_date IS NULL OR description IS NULL;

--3. Standardizing texts

UPDATE programs 
SET sector = 'Public Safety' 
WHERE sector = 'Publiic Safety';

UPDATE spending
SET description = 'Advertising'
WHERE description = 'advertisinng';

SELECT DISTINCT description  --To verify update
FROM spending;

--4. Standardize Column Data Types
ALTER TABLE programs
ALTER COLUMN start_date DATE;

ALTER TABLE programs
ALTER COLUMN end_date DATE;

ALTER TABLE programs
ALTER COLUMN budget DECIMAL(15, 2);

ALTER TABLE Spending
ALTER COLUMN amount_Spent FLOAT;


--5. Remove Leading and Trailing Spaces

UPDATE programs 
SET sector = TRIM(sector);

UPDATE citizen_feedback
SET comments = TRIM(comments);

UPDATE Programs
SET End_Date = DATEADD(YEAR, 1, Start_Date);


UPDATE Spending
SET Spend_Date = DATEADD(DAY, ABS(CHECKSUM(NEWID())) % DATEDIFF(DAY, p.Start_Date, p.End_Date), p.Start_Date)
FROM Spending AS s
JOIN Programs AS p ON s.Program_ID = p.Program_ID
WHERE YEAR(p.Start_Date) = 2023 
  AND YEAR(p.End_Date) = 2024
  AND p.Start_Date <= p.End_Date;  -- Ensuring no invalid date range

--6. Correcting the sector column because it was mismatched with the program name
CREATE TABLE Program_Sector_Reference (
    Program_Name VARCHAR(255),
    Sector VARCHAR(255)
);

-- Insert correct mappings
INSERT INTO Program_Sector_Reference (Program_Name, Sector)
VALUES
('Clean Water', 'Utilities'),
('Digital Literacy', 'Education'),
('Public Safety Program', 'Public Safety'),
('Road Development', 'Infrastructure'),
('Healthcare Access', 'Healthcare');

-- Update the original dataset
UPDATE Programs
SET Sector = r.Sector
FROM Programs p
JOIN Program_Sector_Reference r
ON p.Program_Name = r.Program_Name;


--Research question development

--1. Which sectors receive the highest funding, and how does funding vary across programs?
--To understand government funding priorities and identify potential gaps in funding allocation.

SELECT 
    Sector AS Program_Sector,
    SUM(Budget) AS Total_Budget
FROM Programs
GROUP BY Sector
ORDER BY Total_Budget DESC;

--2. Which programs receive the best and worst citizen ratings, and what patterns emerge in feedback?
-- To gauge program success based on citizen satisfaction and identify areas for improvement.
SELECT 
    p.Program_Name AS Program_Name,
    SUM(cf.Rating) AS Total_Ratings,
    COUNT(cf.Feedback_ID) AS Total_Feedbacks
FROM Programs AS p
JOIN Citizen_Feedback AS cf ON p.Program_ID = cf.Program_ID
GROUP BY p.Program_Name
ORDER BY Total_Ratings DESC;


--3. Are programs staying within their allocated budgets, or are there patterns of overspending or underspending?
-- To evaluate financial efficiency and identify programs that may require budget adjustments.

SELECT 
    p.Program_Name AS Program_Name,
    p.Budget AS Allocated_Budget,
    SUM(s.Amount_Spent) AS Total_Spent,
    (p.Budget - SUM(s.Amount_Spent)) AS Remaining_Budget
FROM Programs AS p
LEFT JOIN Spending AS s ON p.Program_ID = s.Program_ID
GROUP BY p.Program_Name, p.Budget
ORDER BY Remaining_Budget ASC;



SELECT 
    p.Program_ID AS Program_ID,
    p.Budget AS Allocated_Budget,
    s.Amount_Spent AS Actual_Amount_Spent
FROM Programs p
JOIN Spending s
    ON p.Program_ID = s.Program_ID;

--4. What are the key factors influencing citizen satisfaction in government programs (e.g., sector, program type)?
-- To understand what drives high or low citizen feedback (e.g., budget allocation, program type).

SELECT 
    p.Sector AS Program_Sector,
    AVG(cf.Rating) AS Average_Rating
FROM Programs AS p
JOIN Citizen_Feedback AS cf ON p.Program_ID = cf.Program_ID
GROUP BY p.Sector
ORDER BY Average_Rating DESC;

SELECT 
    p.Sector AS Program_Sector,
    SUM(cf.Rating) AS Total_Rating
FROM Programs AS p
JOIN Citizen_Feedback AS cf ON p.Program_ID = cf.Program_ID
GROUP BY p.Sector
ORDER BY Total_Rating DESC;



--5. How does the budget distribution vary across different program types within the same sector?

--Identify if some types of programs (e.g., healthcare, infrastructure) within a sector receive significantly more funding than others.

SELECT 
    Sector AS Program_Sector,
    Program_Name,
    Budget        
FROM Programs             
ORDER BY Sector, Budget DESC; --This query looks at the individual programs within each sector to see the variation in budgets.


--6. How do changes in budget allocation impact program performance or citizen satisfaction over time?

--To understand if increased funding for programs leads to better outcomes or higher citizen satisfaction.

SELECT 
    p.Program_Name AS Program_Name,
    p.Budget AS Allocated_Budget,
    SUM(cf.Rating) AS Total_Ratings
FROM Programs AS p
JOIN Citizen_Feedback AS cf ON p.Program_ID = cf.Program_ID
GROUP BY p.Program_Name, p.Budget
ORDER BY p.Budget DESC;

SELECT 
    p.Program_Name AS Program_Name,
    p.Budget AS Allocated_Budget,
    AVG(cf.Rating) AS Average_Rating    --This query compares budget allocations with average citizen ratings to identify any correlations between funding levels and citizen satisfaction.
FROM Programs AS p
JOIN Citizen_Feedback AS cf ON p.Program_ID = cf.Program_ID
GROUP BY p.Program_Name, p.Budget
ORDER BY p.Budget DESC;


--7. Which programs are receiving the most positive or negative feedback based on specific comments?

--Identify programs with specific positive or negative trends in feedback to guide future actions.

SELECT DISTINCT Comments
FROM Citizen_Feedback;


UPDATE Citizen_Feedback
SET Comments = TRIM(LOWER(Comments));

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


--Detailed Analysis & Insights
--A. Trends in Budget Allocation by Sector

--To track how funding priorities for each sector have evolved over time.

SELECT 
    Sector AS Program_Sector,
    DATENAME(MONTH, Start_Date) AS Month_Name,
    SUM(Budget) AS Total_Budget
FROM Programs
WHERE YEAR(Start_Date) = 2023
GROUP BY Sector, DATENAME(MONTH, Start_Date), MONTH(Start_Date)
ORDER BY MONTH(Start_Date), Total_Budget DESC;

SELECT 
    DATENAME(MONTH, Start_Date) AS Month_Name,
    SUM(Budget) AS Total_Budget
FROM Programs
WHERE YEAR(Start_Date) = 2023
GROUP BY DATENAME(MONTH, Start_Date), MONTH(Start_Date)
ORDER BY MONTH(Start_Date);

SELECT 
    DATENAME(MONTH, Start_Date) AS Month_Name,
    SUM(Budget) AS Total_Budget
FROM Programs
WHERE YEAR(Start_Date) = 2023
GROUP BY DATENAME(MONTH, Start_Date), MONTH(Start_Date)
ORDER BY MONTH(Start_Date);


--B. Outliers in Spending

--Categorize programs based on spending efficiency.
--Identifying overspending programs for budget review.

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


--C. Spending Trends by Program

--Analyze monthly spending trends for each program.
--To identify seasonal spikes or irregular spending patterns.

SELECT 
    p.Sector AS Program_Sector,
    DATENAME(MONTH, s.Spend_Date) AS Month_Name,
    SUM(s.Amount_Spent) AS Total_Amount_Spent
FROM Programs AS p
JOIN Spending AS s ON p.Program_ID = s.Program_ID
GROUP BY p.Sector, DATENAME(MONTH, s.Spend_Date), MONTH(s.Spend_Date)
ORDER BY p.Sector, MONTH(s.Spend_Date), Total_Amount_Spent DESC;

/** D. What is the distribution of citizen feedback over time, and does feedback intensity correlate with program stages (start, middle, or end)?
Purpose:
To analyze whether citizens are more likely to provide feedback at specific stages of a program's lifecycle:
At the beginning (initial impressions),
During the middle (progress assessments), or
At the end (outcome evaluations).
This can help the government time surveys or feedback collection more effectively.**/

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


/**E. Are programs implemented during specific months or seasons more likely to receive feedback?

 Purpose:
Identify if feedback is seasonally driven (e.g., higher during the summer or holidays).
Help governments plan resource allocation and outreach campaigns based on when citizens are most engaged.**/

SELECT 
    DATENAME(MONTH, cf.Feedback_Date) AS Feedback_Month,
    COUNT(cf.Feedback_ID) AS Total_Feedbacks
FROM Citizen_Feedback cf
GROUP BY DATENAME(MONTH, cf.Feedback_Date), MONTH(cf.Feedback_Date)
ORDER BY MONTH(cf.Feedback_Date);


/** F. How quickly do citizens provide feedback after a program starts, and does response speed correlate with satisfaction ratings?
Purpose:
Assess citizen engagement levels by analyzing the average time between program start and feedback submission.
Determine if faster feedback correlates with higher or lower satisfaction ratings.**/

SELECT 
    p.Program_Name AS Program_Name,
    AVG(DATEDIFF(DAY, p.Start_Date, cf.Feedback_Date)) AS Avg_Days_To_Feedback,
    SUM(cf.Rating) AS Total_Rating,
    COUNT(cf.Feedback_ID) AS Total_Feedbacks
FROM Programs p
JOIN Citizen_Feedback cf ON p.Program_ID = cf.Program_ID
GROUP BY p.Program_Name
ORDER BY Avg_Days_To_Feedback ASC;

/** G. Feedback Ratings by Month
Identify Monthly Rating Trends:

Determine if citizen satisfaction fluctuates over different months.
Uncover if specific months consistently show higher or lower satisfaction and engagement**/

SELECT 
    DATENAME(MONTH, cf.Feedback_Date) AS Month_Name,
    SUM(cf.Rating) AS Total_Rating,
    COUNT(cf.Feedback_ID) AS Total_Feedbacks
FROM Citizen_Feedback cf
GROUP BY DATENAME(MONTH, cf.Feedback_Date), MONTH(cf.Feedback_Date)
ORDER BY Month_Name;

SELECT 
    DATENAME(MONTH, cf.Feedback_Date) AS Feedback_Month,
    MONTH(cf.Feedback_Date) AS Month_Number,
    SUM(cf.Rating) AS Total_Rating,
    COUNT(cf.Feedback_ID) AS Total_Feedbacks
FROM Citizen_Feedback cf
GROUP BY DATENAME(MONTH, cf.Feedback_Date), MONTH(cf.Feedback_Date)
ORDER BY Month_Number;


/**H. Feedback Categorization by Month
Purpose:
To systematically organize citizen comments into distinct groups—positive, negative, and uncategorized—in order to provide meaningful insights and actionable intelligence.**/

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
