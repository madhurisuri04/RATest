
CREATE VIEW [dbo].[vw_revenue_code]
AS
SELECT     REPLACE(STR(Rev_Code, 4, 0), ' ', '0') AS rev_code
FROM         dbo.lk_Revenue_code 
