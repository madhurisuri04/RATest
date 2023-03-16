
use HRPReporting

select * from [dbo].[lk_Risk_Score_Factors_PartC]
where PaymentYear = 2021
order by PaymentYear desc


select * from EDSRAPSSubmissionSplit

select distinct 
	PaymentYear, RAFactorType, ModelYear, [Version], SubmissionModel, SubmissionModelNumber
from [dbo].[lk_Risk_Score_Factors_PartC]
where PaymentYear = 2020
order by RAFactorType


select Payment_Year, Part_C_D_Flag, Factor_Type, demo_risk_type, count(1)
from [dbo].[lk_Risk_Models]
where Payment_Year= 2020
group by Payment_Year, Part_C_D_Flag, Factor_Type, demo_risk_type
order by Payment_Year, demo_risk_type, Part_C_D_Flag, Factor_Type 


select Payment_Year, RA_Factor_Type, count(1) from lk_Risk_Models_Hierarchy
where Payment_Year = 2020
group by Payment_Year, RA_Factor_Type
order by Payment_Year desc, RA_Factor_Type

select Payment_Year, Factor_Type, count(1) from lk_Risk_Models_Interactions
where Payment_Year = 2020
group by Payment_Year, Factor_Type
order by Payment_Year desc, Factor_Type


select 
	PaymentYear, SplitSegmentNumber, SplitSegmentWeight, ModelYear, PaymStart, PaymEnd, RecordType, RAFactorType, [Version], SubmissionModel, SubmissionModelNumber
from [dbo].[lk_Risk_Score_Factors_PartC]
where PaymentYear = 2020
order by SubmissionModel, RecordType, RAFactorType

select * from lk_Risk_Models_DiagHCC_ICD10 

select Payment_Year, Factor_Type, count(1) from lk_Risk_Models_DiagHCC_ICD10 group by Payment_Year, Factor_Type order by 1 desc,2

select PaymentYear, FactorType, count(1) from Vw_LkRiskModelsDiagHCC group by PaymentYear, FactorType order by 1 desc,2


select schema_name(tab.schema_id) as schema_name,
    tab.name as table_name, 
    col.column_id,
    col.name as column_name, 
    t.name as data_type,    
    col.max_length,
    col.precision
from sys.tables as tab
    inner join sys.columns as col
        on tab.object_id = col.object_id
    left join sys.types as t
    on col.user_type_id = t.user_type_id
where col.name like '%model%'
order by schema_name,
    table_name, 
    column_id;


select year, count(1) from lk_AgeGroupTransplantDurationFactors_PartC
group by year 
order by 1

select Payment_Year, count(1) from lk_AgeGroupTransplantDurationFactors_PartC
group by Payment_Year
order by 1


select * from lk_AgeGroupTransplantDurationFactors_PartC


select payment_year, Demo_Risk_Type, count(2) from lk_Risk_Models
group by payment_year, Demo_Risk_Type
order by 1,2




select Payment_Year, count(1) from lk_DisabilityMedicaidFactorsGender_PartC
group by Payment_Year
order by 1

select * from lk_DisabilityMedicaidFactorsGender_PartC
where Payment_Year = 2020

select * from lk_Risk_Models
where Payment_Year = 2020
and Factor_Description = 'Medicaid Disability'

select * from [dbo].[lk_Risk_Score_Factors_PartC]
where PaymentYear = 2021

select distinct PaymentYear, Version from [dbo].[lk_Risk_Score_Factors_PartC]
order by PaymentYear 

select * from [dbo].[lk_Risk_Score_Factors_PartC]
where PaymentYear = 2007


select * from [dbo].[lk_normalization_factors] -- QUESTION
where year = 2021

select * from HRPReporting.dbo.lk_MORType





select Payment_Year, RA_Factor_Type, count(1) from lk_Risk_Models_Hierarchy
where Payment_Year = 2020
group by Payment_Year, RA_Factor_Type
order by Payment_Year desc, RA_Factor_Type


payment year = 2020 Version = 24 ModelYear = 2020 EDS
payment year = 2020 Version = 22 ModelYear = 2018 RAPS

insert into new table for Payment year 2020/2021

for Version 24, use payment year = 2020 from old hierarchy/interaction table
for Version 22, use payment year = 2018 from old hierarchy/interaction table

use same for lk_risk_model


------------------

