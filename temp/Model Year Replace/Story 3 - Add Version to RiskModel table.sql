use HRPReporting

select top 10 * from lk_Risk_Models
where Payment_Year = 2020

select top 10 * from [dbo].[lk_Factors] -- DROP 
select top 10 * from [dbo].[lk_Factors_New] -- DROP 

select top 10 * from [dbo].[lk_Factors_PartC]
select top 10 * from [dbo].[lk_Factors_PartD]
select top 10 * from [dbo].[lk_Factors_PartG]

select * from [dbo].[lk_Factors_PartC]
where Payment_Year = 2020

select * from [dbo].[lk_Factors_PartD]
where Payment_Year = 2020

select * from [dbo].[lk_Factors_PartG]
where Payment_Year = 2020

Drop tables [lk_Factors] and [lk_Factors_New]
Add [Version] to lk_Risk_Models, lk_Factors_PartC, lk_Factors_PartD and lk_Factors_PartG
Remove PaymentYear from lk_Risk_Models , lk_Factors_PartC, lk_Factors_PartD and lk_Factors_PartG
Modify scripts to reflect these changes

-- Create new tables and leave the current tables untouched?



