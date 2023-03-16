use HRPReporting

select top 10 * from lk_Risk_Models_DiagHCC_ICD10

select Payment_Year, Factor_Type, count(1) from lk_Risk_Models_DiagHCC_ICD10 group by Payment_Year, Factor_Type order by 1 desc,2


Add [Version] to lk_Risk_Models_DiagHCC_ICD10 
Remove Payment_Year from lk_Risk_Models_DiagHCC_ICD10 
Modify scripts to reflect the changes mentioned

--- Create new table lk_Risk_Models_DiagHCC? And leave the current one untouched?