select * from reportingETL.dbo.SCFHPGapCheck_000a_Source
where status = 'D'

select * from [SCFHP_Report].dbo.raps_diagHCC_Rollup
select * from [SCFHP_Report].[rev].[tbl_Summary_RskAdj_MMR]

select top 10 * from [SCFHP_ClientRepo].[dbo].[MAO004Response]
select top 10 * from [SCFHP_ClientRepo].[dbo].[MAO004ResponseDiagnosisCode]

select 
	MAO.MAO004ResponseID ,
	BeneficiaryIdentifier HICN,
	EncounterICN ,
	EncounterTypeSwitch	,
	AllowedDisallowedFlagRiskAdjustment ,
	EncounterSubmissionDate ,
	FromDateofService ,
	ThroughDateofService ,
	ServiceType ,
	DiagnosisCode ,
	AddOrDeleteFlag ,
	IsActive
into reportingETL.dbo.EDSSourceSC
from
	[SCFHP_ClientRepo].[dbo].[MAO004Response] MAO,
	[SCFHP_ClientRepo].[dbo].[MAO004ResponseDiagnosisCode] Diag
where
	MAO.MAO004ResponseID = diag.MAO004ResponseID
	and MAO.BeneficiaryIdentifier in (select FinalHICN from reportingETL.dbo.SCFHPGapCheck_000a_Source)


select hicn, hcc from ReportingETL.dbo.tbl_GAP_NEW_HCC_EDS_PartC_SC
except
select hicn, hcc from ReportingETL.dbo.tbl_GAP_NEW_HCC_RAPS_PartC_SC


select hicn, hcc from ReportingETL.dbo.tbl_GAP_NEW_HCC_RAPS_PartC_SC
except
select hicn, hcc from ReportingETL.dbo.tbl_GAP_NEW_HCC_EDS_PartC_SC

8AV8WN7FF68	HCC 40
8GY0F86UW25	HCC 96

select * from ReportingETL.dbo.tbl_GAP_NEW_HCC_RAPS_PartC_SC where hicn = '1A51VD9GF28'
select * from ReportingETL.dbo.tbl_GAP_NEW_HCC_EDS_PartC_SC where hicn = '1A51VD9GF28'

select * from ReportingETL.dbo.tbl_GAP_All_Diags_RAPS_PartC_SC where hicn = '1A51VD9GF28' order by HCC
select * from ReportingETL.dbo.tbl_GAP_All_Diags_EDS_PartC_SC where hicn = '1A51VD9GF28' order by HCC

select * from SCFHP_Report.dbo.RAPS_DiagHCC_rollup where hicn = '1A51VD9GF28' and Accepted = 1 and Deleted is NULL and YEAR(ThruDate) = '2019'

select * from reportingETL.dbo.EDSSourceSC where hicn = '1A51VD9GF28' and YEAR(ThroughDateOfService) = '2019'

select * from ReportingETL.dbo.tbl_GAP_Diags_Add where hicn = '1A51VD9GF28'

select * 
from
	HRPReporting.dbo.lk_Risk_Models_DiagHCC_ICD10 B  (nolock)  
where  
	B.Payment_Year in (2018) 
	and ICD10CD = 'F339'

select * 
from
	HRPReporting.dbo.lk_Risk_Models_DiagHCC_ICD10 B  (nolock)  
where  
	B.Payment_Year in (2020) 
	and ICD10CD = 'F339'




Select * from ReportingETL.dbo.SCFHPGapCheck_004a_RAPS_PartC_ADDs where RunID = 2
Union
Select * from ReportingETL.dbo.SCFHPGapCheck_004b_EDS_PartC_ADDs where RunID = 2
Union
Select * from ReportingETL.dbo.SCFHPGapCheck_004c_RAPS_PartD_ADDs where RunID = 2
Union
Select * from ReportingETL.dbo.SCFHPGapCheck_004d_EDS_PartD_ADDs where RunID = 2

select hicn, hcc from ReportingETL.dbo.tbl_GAP_NEW_HCC_RAPS_PartC_SC 
intersect
Select hicn, hcc from ReportingETL.dbo.SCFHPGapCheck_004a_RAPS_PartC_ADDs where RunID = 2

select hicn, hcc from ReportingETL.dbo.tbl_GAP_NEW_HCC_RAPS_PartC_SC 
except
Select hicn, hcc from ReportingETL.dbo.SCFHPGapCheck_004a_RAPS_PartC_ADDs where RunID = 2

1GV7QA3NV51	HCC 58
1H40X39ED25	HCC 18
1H92M55AU83	HCC 161
1JX1T90CW24	HCC 108


select * from ReportingETL.[dbo].[SCFHPGapCheck_002b_MOR]
where HICN = '1JX1T90CW24'
and HCC_Number = 108
and PaymentYear = 2020

