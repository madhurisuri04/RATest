use HRPReporting

select top 10 * from [dbo].[lk_AgeGroupGenderFactors] -- DROP
select top 10 * from [dbo].[lk_AgeGroupGenderFactors_new] -- DROP

select year, count(1) from [dbo].[lk_AgeGroupGenderFactors_new]
group by year
order by year


select top 10 * from [dbo].[lk_AgeGroupGenderFactors_PartC] where Payment_Year = 2020
select top 10 * from [dbo].[lk_AgeGroupGenderFactors_PartD] where Payment_Year = 2020

select Payment_Year, count(1) from [dbo].[lk_AgeGroupGenderFactors_PartC]
group by Payment_Year
order by Payment_Year

select Payment_Year, count(1) from [dbo].[lk_AgeGroupGenderFactors_PartD]
group by Payment_Year
order by Payment_Year

Replace Payment_Year by Version for [lk_AgeGroupGenderFactors_PartC] and [lk_AgeGroupGenderFactors_PartD]
Modify script to reflect the changes


select top 10 * from [dbo].[lk_AgeGroupTransplantDurationFactors] -- DO we need this?
select top 10 * from [dbo].[lk_AgeGroupTransplantDurationFactors_PartC] -- DO we need this?

select year, count(1) from [dbo].[lk_AgeGroupTransplantDurationFactors]
group by year
order by year

select Payment_Year, count(1) from [dbo].[lk_AgeGroupTransplantDurationFactors_PartC]
group by Payment_Year
order by Payment_Year


select top 10 * from [dbo].[lk_DFactors] -- DROP
select top 10 * from [dbo].[lk_DFactors_new] -- DROP
select top 10 * from [dbo].[lk_DHierarchy] -- DROP

select HCC_Factor_Year, count(1) from [dbo].[lk_DFactors_new]
group by HCC_Factor_Year
order by HCC_Factor_Year

select top 10 * from [dbo].[lk_DisabilityMedicaidFactorsGender] -- DROP 
select top 10 * from [dbo].[lk_DisabilityMedicaidFactorsGender_new] -- DROP

select year, count(1) from [dbo].[lk_DisabilityMedicaidFactorsGender_new]
group by year
order by year

select top 10 * from [dbo].[lk_DisabilityMedicaidFactorsGender_PartC] where Payment_Year = 2020 -- QUESTION
select top 10 * from [dbo].[lk_DisabilityMedicaidFactorsGender_PartD] where Payment_Year = 2020 -- QUESTION

select Payment_Year, count(1) from [dbo].[lk_DisabilityMedicaidFactorsGender_PartC]
group by Payment_Year
order by Payment_Year

select Payment_Year, count(1) from [dbo].[lk_DisabilityMedicaidFactorsGender_PartD]
group by Payment_Year
order by Payment_Year

select top 10 * from [dbo].[lk_normalization_factors] -- QUESTION
select * from tbl_EstRecv_ModelSplits

--lk_LowIncomePremiumSubsidy and lk_normalization_factors based on year rather than version?
--Same for [lk_DisabilityMedicaidFactorsGender_PartC] and [lk_DisabilityMedicaidFactorsGender_PartD]



