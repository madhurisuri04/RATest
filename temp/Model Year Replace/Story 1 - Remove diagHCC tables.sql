--Remove all these following lookup tables from database and scripts

use HRPReporting

select top 10 * from lk_DDiagnosesHCC
select top 10 * from lk_DDiagnosesHCC_new
select top 10 * from lk_DiagnosesHCC
select top 10 * from lk_DiagnosesHCC_new
select top 10 * from lk_DiagnosesHCC_PartC
select top 10 * from lk_DiagnosesHCC_PartC_ICD10
select top 10 * from lk_DiagnosesHCC_PartD
select top 10 * from lk_DiagnosesHCC_PartD_ICD10
select top 10 * from lk_Risk_Models_DiagHCC

select * from lk_DDiagnosesHCC -- DROP
select * from lk_DDiagnosesHCC_new order by year desc -- DROP
select * from lk_DiagnosesHCC -- DROP
select * from lk_DiagnosesHCC_new order by year desc -- DROP
select Payment_Year, count(1) from lk_DiagnosesHCC_PartC group by Payment_Year order by Payment_Year desc -- DROP
select Payment_Year, count(1) from lk_DiagnosesHCC_PartC_ICD10 group by Payment_Year order by Payment_Year desc -- DROP
select Payment_Year, count(1) from lk_DiagnosesHCC_PartD group by Payment_Year order by Payment_Year desc -- DROP
select Payment_Year, count(1) from lk_DiagnosesHCC_PartD_ICD10 group by Payment_Year order by Payment_Year desc -- DROP
select Payment_Year, Factor_Type, count(1) from lk_Risk_Models_DiagHCC group by Payment_Year, Factor_Type order by 1 desc,2 -- DROP

-- Why do we need this view? Can this view be dropped?
select top 10 * from Vw_LkRiskModelsDiagHCC
select PaymentYear, FactorType, count(1) from Vw_LkRiskModelsDiagHCC group by PaymentYear, FactorType order by 1 desc,2
