use HRPReporting


select top 10 * from lk_Risk_Models_Hierarchy
where Payment_Year = 2020

select RA_FACTOR_TYPE, count(1) from lk_Risk_Models_Hierarchy
where Payment_Year = 2020
group by RA_FACTOR_TYPE
order by RA_FACTOR_TYPE

select top 10 * from lk_Risk_Models_Interactions
where Payment_Year = 2020

select factor_type, count(1) from lk_Risk_Models_Interactions
where Payment_Year = 2020
group by Factor_Type
order by Factor_Type


select * from [dbo].[lk_Hierarchy] -- DROP Table

select top 10 * from [dbo].[lk_Hierarchy_PartC] -- DROP Table
where Payment_Year = 2020

select top 10 * from [dbo].[lk_Hierarchy_PartD] -- DROP Table
where Payment_Year = 2020

select * from [dbo].[lk_Interactions_PartC] -- DROP table 
where payment_year = 2020

Drop tables lk_Hierarchy, lk_Hierarchy_PartC and lk_Hierarchy_PartD
Modify scripts that use above tables
Drop table lk_Interactions_PartC
Modify scripts that use above tables

Add [Version] to lk_Risk_Models_Hierarchy, lk_Risk_Models_Interactions
Remove PaymentYear from lk_Risk_Models_Hierarchy, lk_Risk_Models_Interactions
Modify scripts to reflect these changes

-- Create new tables and leave the current tables untouched?


