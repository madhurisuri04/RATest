

select count(1), PaymentYear, loaddatetime
from [ProdSupport].dbo.tbl_Summary_RskAdj_EDS_Preliminary_Before_2021 
group by PaymentYear

select count(1), PaymentYear, loaddatetime
from [ProdSupport].dbo.tbl_Summary_RskAdj_EDS_Preliminary_After_2021 
group by PaymentYear



select HICN
from [ProdSupport].dbo.tbl_Summary_RskAdj_EDS_Preliminary_Before_2021 
except
select HICN
from [ProdSupport].dbo.tbl_Summary_RskAdj_EDS_Preliminary_After_2021 

select HICN
from [ProdSupport].dbo.tbl_Summary_RskAdj_EDS_Preliminary_After_2021 
except
select HICN
from [ProdSupport].dbo.tbl_Summary_RskAdj_EDS_Preliminary_Before_2021 

select * 
into #temp
from 
(
select PaymentYear, HICN,MAO004ResponseID,DiagnosisCode, DiagnosisFlag, HCC_Label , PartCRAFTProjected, Deleted
from [ProdSupport].dbo.tbl_Summary_RskAdj_EDS_Preliminary_After_2021 
except
select PaymentYear, HICN,MAO004ResponseID,DiagnosisCode, DiagnosisFlag, HCC_Label , PartCRAFTProjected, Deleted
from [ProdSupport].dbo.tbl_Summary_RskAdj_EDS_Preliminary_Before_2021 
) a


select * 
into #temp2
from 
(
select PaymentYear, HICN,MAO004ResponseID,DiagnosisCode, DiagnosisFlag, HCC_Label , PartCRAFTProjected, Deleted
from [ProdSupport].dbo.tbl_Summary_RskAdj_EDS_Preliminary_Before_2021 
except
select PaymentYear, HICN,MAO004ResponseID,DiagnosisCode, DiagnosisFlag, HCC_Label , PartCRAFTProjected, Deleted
from [ProdSupport].dbo.tbl_Summary_RskAdj_EDS_Preliminary_After_2021 
) a


select 'Before', PaymentYear, HICN,MAO004ResponseID,DiagnosisCode, DiagnosisFlag, HCC_Label , PartCRAFTProjected, Deleted
from [ProdSupport].dbo.tbl_Summary_RskAdj_EDS_Preliminary_Before_2021
where hicn =  '6RW8E70XU51'
union all
select 'After', PaymentYear, HICN,MAO004ResponseID,DiagnosisCode, DiagnosisFlag, HCC_Label , PartCRAFTProjected, Deleted
from [ProdSupport].dbo.tbl_Summary_RskAdj_EDS_Preliminary_After_2021 
where hicn =  '6RW8E70XU51'

select * from #temp2

select DiagnosisCode, HCC_Label, count(2) cnt
from #temp
group by DiagnosisCode, HCC_Label
order by cnt desc

select HCC_Label, count(distinct HICN) cnt
from #temp
group by HCC_Label
order by cnt desc

select distinct DiagnosisCode
into #DiagnosisCode
from #temp

select distinct hicn, HCC_Label 
from #temp

select * from #DiagnosisCode

select * FROM [HRPReporting].[dbo].[Vw_LkRiskModelsDiagHCC] 
where PaymentYear = 2020
and ICDCode in (select diagnosisCode from #DiagnosisCode)


select * FROM [HRPReporting].[dbo].lkRiskModelsDiagHCC 
where PaymentYear = 2021
and ICD10CD in (select diagnosisCode from #DiagnosisCode)


select * FROM [HRPReporting].[dbo].[Vw_LkRiskModelsDiagHCC] 
where PaymentYear = 2021
and ICDCode in ('G71220')


select * FROM [HRPReporting].[dbo].lkRiskModelsFactors
where PaymentYear = 2021
--and RAFactorType = 'CN'
and HCCNumber = 138



select * FROM [HRPReporting].[dbo].lkRiskModelsFactors


select distinct PaymentYear, submissionModel, Modelyear, RAFactorTYpe, APCCFlag from [HRPReporting].[dbo].[lk_Risk_Score_Factors_PartC]
where paymentYear in (2021)

