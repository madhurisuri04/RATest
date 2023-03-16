
-- List of all accepted diags from cwfdetails which are coded before 9/14 for Aetna Projects
drop table #cwfdetails

select distinct
	ProjectID,
	SubprojectID,
	HICN,
	PlanID,
	ListChaseID,
	DiagnosisID,
	c.DiagnosisStatusID,
	DiagnosisCode,
	DOSStartDt,
	DOSEndDt,
	CurrentImageStatus,
	CNCodingDiagnosisStatus,
	OverallDiagnosisStatus,
	ProviderNPI,
	case when (ISNUMERIC(ProviderNPI)=0 OR LEN(ProviderNPI) <> 10 OR LEFT(ProviderNPI, 1) NOT IN ('1', '2') OR ISNULL(ProviderNPI,'')='') then 'BAD' else 'GOOD' end ProviderNPIStatus
into #cwfdetails
from aetna_report.dbo.cwfdetails cwf
join Aetna_CN_ClientLevel.dbo.Diagnosis c (nolock) on cwf.DiagnosisID=c.ID
where CodingCompleteDate <= '10/19/2021'
and CurrentImageStatus in ('Coding/Review Complete','Ready for Release','Cannot be Coded')
and c.DiagnosisStatusID = 11
and CNCodingDiagnosisStatus <> 'Rejected'
and SubprojectID in (
	select ID from Aetna_CN_ClientLevel.dbo.vwSubProject where ProjectID in (
		1299, 1300, 1301, 1302, 1308, 1309, 1411, 1306, 1307, 1345, 1347, 1355, 1357,--Aetna/ AetIH/ DSNP 
		1303, 1304, 1305,--Duals 
		1310, 1311, 1409, 1412--Allina
		)
)

-- Diag HCC mapping for 2021 PY

DROP TABLE IF EXISTS #Diag_HCC_Lookup
Select distinct 
	b.Payment_Year
	,b.Factor_Type
	,b.ICD10CD
	,b.HCC_Label
into 
	#Diag_HCC_Lookup
from
	HRPReporting.dbo.lk_Risk_Models_DiagHCC_ICD10 B  (nolock)  
where  
	B.Payment_Year in (2021) 

-- Eligibility check
drop table #MMR
select distinct m.HICN, m.PartCRAFTProjected RAFactorType, m.PlanID
into #MMR
from 
	[Aetna_Report].[rev].[tbl_Summary_RskAdj_MMR] m,
	#cwfdetails a
where 
	a.HICN = m.hicn
	and m.PaymentYear = 2021

insert into #MMR
select distinct m.HICN, m.PartCRAFTProjected RAFactorType, m.PlanID
from 
	[AetIH_Report].[rev].[tbl_Summary_RskAdj_MMR] m,
	#cwfdetails a
where 
	a.HICN = m.hicn
	and m.PaymentYear = 2021


-- Diag clusters not in MRA Extract table 
select * into #MissingDiagsInExtract
from
(
select hicn, DiagnosisCode, DOSStartDt, DOSEndDt from #cwfdetails where ProviderNPIStatus = 'GOOD'
except
select hicn, DiagnosisCode, DosStart, DOSEnd from Aetna_CN_ClientLevel.dbo.MRAExtract  m (nolock)
) a

-- Diag clusters IN MRA Extract table 
select hicn, DiagnosisCode, DOSStartDt, DOSEndDt  
into 
	#DiagsInExtract
from
	#cwfdetails a
where exists ( select 1 from Aetna_CN_ClientLevel.dbo.MRAExtract m (nolock) where a.hicn = m.hicn and a.DiagnosisCode = m.diagnosisCode and a.DOSStartDt = m.DosStart and a.DOSEndDt = m.DOSEnd) 
and ProviderNPIStatus = 'GOOD'

-- select * from #DiagsInExtract
-- 74475

/*
-- Diags not in CodingDetailFile table 
select * into #MissingDiagsInCDF
from
(
select hicn, DiagnosisCode from #cwfdetails 
except
select MBI, ICD_Diagnosis_Code from Aetna_CN_ClientLevel.dbo.CodingDetailFile  m (nolock)
) a

-- select * from #MissingDiagsInCDF
-- 21043

*/


-- Filter out diags that dont map to HCC, for clusters not in Extract
drop table #cwfdetails_HCC_Not_In_Extract
select distinct 
	ProjectID,
	SubprojectID,
	a.HICN,
	ListChaseID,
	DiagnosisID,
	DiagnosisStatusID,
	a.DiagnosisCode,
	a.DOSStartDt,
	a.DOSEndDt,
	HCC = lk.HCC_Label,
	RAFactorType = m.RAFactorType,
	CurrentImageStatus,
	CNCodingDiagnosisStatus,
	OverallDiagnosisStatus,
	PlanID = m.PlanID
into #cwfdetails_HCC_Not_In_Extract
from #cwfdetails a
	inner join #MMR m
	on a.HICN = m.hicn
	inner join #Diag_HCC_Lookup lk
	on a.DiagnosisCode = lk.ICD10CD
    AND lk.Payment_Year = 2021
	and m.RAFactorType = lk.Factor_Type
	inner join #MissingDiagsInExtract e
	on a.HICN = e.hicn
	and a.DiagnosisCode = e.DiagnosisCode
	and a.DOSStartDt = e.DOSStartDt
	and a.DOSEndDt = e.DOSEndDt
where YEAR(a.DOSEndDt) = 2020 



-- Get the list of all realized HCC from EDS Preliminary
drop table #EDSPreliminary_Not_In_Extract
select distinct	
	a.HICN,
	PlanSubmissionDate,
	ServiceStartDate,
	ServiceEndDate,
	a.DiagnosisCode,
	IsDelete,
	RecordID,
	a.SubProjectID,
	RiskAdjustable,
	HCC_Label,
	HCC_Number
into #EDSPreliminary_Not_In_Extract
from [Aetna_Report].[rev].[tbl_Summary_RskAdj_EDS_Preliminary] a
	join #cwfdetails_HCC_Not_In_Extract b
	on a.hicn = b.hicn
where PaymentYear = 2021

insert into #EDSPreliminary_Not_In_Extract
select distinct	
	a.HICN,
	PlanSubmissionDate,
	ServiceStartDate,
	ServiceEndDate,
	a.DiagnosisCode,
	IsDelete,
	RecordID,
	a.SubProjectID,
	RiskAdjustable,
	HCC_Label,
	HCC_Number
from [AetIH_Report].[rev].[tbl_Summary_RskAdj_EDS_Preliminary] a
	join #cwfdetails_HCC_Not_In_Extract b
	on a.hicn = b.hicn
where PaymentYear = 2021


-- Coded HCC from Chase missing in Extract that do not have other source
drop table #missingHCC
select * 
into #missingHCC
from
(
select hicn, HCC from #cwfdetails_HCC_Not_In_Extract
except
select hicn, HCC_Label from #EDSPreliminary_Not_In_Extract
) a

-- 


drop table #cwfdetails_HCC_In_Extract
select distinct 
	ProjectID,
	SubprojectID,
	a.HICN,
	ListChaseID,
	DiagnosisID,
	DiagnosisStatusID,
	a.DiagnosisCode,
	a.DOSStartDt,
	a.DOSEndDt,
	HCC = lk.HCC_Label,
	RAFactorType = m.RAFactorType,
	CurrentImageStatus,
	CNCodingDiagnosisStatus,
	OverallDiagnosisStatus,
	PlanID = m.PlanID
into #cwfdetails_HCC_In_Extract
from #cwfdetails a
	inner join #MMR m
	on a.HICN = m.hicn
	inner join #Diag_HCC_Lookup lk
	on a.DiagnosisCode = lk.ICD10CD
    AND lk.Payment_Year = 2021
	and m.RAFactorType = lk.Factor_Type
	inner join #DiagsInExtract e
	on a.HICN = e.hicn
	and a.DiagnosisCode = e.DiagnosisCode
	and a.DOSStartDt = e.DOSStartDt
	and a.DOSEndDt = e.DOSEndDt
where YEAR(a.DOSEndDt) = 2020 


drop table #EDSPreliminary_In_Extract
select distinct	
	a.HICN,
	PlanSubmissionDate,
	ServiceStartDate,
	ServiceEndDate,
	a.DiagnosisCode,
	IsDelete,
	RecordID,
	a.SubProjectID,
	RiskAdjustable,
	HCC_Label,
	HCC_Number
into #EDSPreliminary_In_Extract
from [Aetna_Report].[rev].[tbl_Summary_RskAdj_EDS_Preliminary] a
	join #cwfdetails_HCC_In_Extract b
	on a.hicn = b.hicn
where PaymentYear = 2021

insert into #EDSPreliminary_In_Extract
select distinct	
	a.HICN,
	PlanSubmissionDate,
	ServiceStartDate,
	ServiceEndDate,
	a.DiagnosisCode,
	IsDelete,
	RecordID,
	a.SubProjectID,
	RiskAdjustable,
	HCC_Label,
	HCC_Number
from [AetIH_Report].[rev].[tbl_Summary_RskAdj_EDS_Preliminary] a
	join #cwfdetails_HCC_In_Extract b
	on a.hicn = b.hicn
where PaymentYear = 2021


drop table #missingHCCInMAO004
select * 
into #missingHCCInMAO004
from
(
	select hicn, HCC from #cwfdetails_HCC_In_Extract
	except
	select hicn, HCC_Label from #EDSPreliminary_In_Extract
) a


select * from #missingHCCInMAO004

select * 
into #cwfdetails_NotInMAO4
from #cwfdetails_HCC_In_Extract a
where exists (select 1 from #missingHCCInMAO004 b where a.hicn = b.hicn and a.hcc = b.hcc) 

--- Test Starts here

select * from #missingHCCInMAO004
select * from #cwfdetails_NotInMAO4

select * from #cwfdetails_HCC_In_Extract
where hicn = '3AD0U80KP12' and hcc = 'HCC 111'


select * from [Aetna_Report].[rev].[tbl_Summary_RskAdj_EDS_Preliminary]
where hicn in ('3AD0U80KP12','8EW6E07TV82', 'MA229361822') and DiagnosisCode = 'J449' and PaymentYear = 2021

select * from [AetIH_Report].[rev].[tbl_Summary_RskAdj_EDS_Preliminary]
where hicn in ('3AD0U80KP12','8EW6E07TV82', 'MA229361822') and DiagnosisCode = 'J449' and PaymentYear = 2021

select * from Aetna_CN_ClientLevel.dbo.MRAExtract
where hicn = '3AD0U80KP12' and DiagnosisCode = 'J449'

select * from [Aetna_Report].[rev].[tbl_Summary_RskAdj_AltHICN]
where hicn = '3AD0U80KP12' or finalhicn = '3AD0U80KP12'

select * from [Aetna_Report].[rev].[tbl_Summary_RskAdj_EDS_Source]
where hicn = '3AD0U80KP12' and DiagnosisCode = 'J449'


select * from [Aetna_Report].[rev].[tbl_Summary_RskAdj_MMR]
where hicn = '3AD0U80KP12' 
and PaymentYear = 2021

select * from [AetIH_Report].[rev].[tbl_Summary_RskAdj_MMR]
where hicn = '3AD0U80KP12' 
and PaymentYear = 2021


select top 100 * from Aetna_CN_ClientLevel.dbo.MRAExtract
where (ISNUMERIC(ProviderNPI)=0 OR LEN(ProviderNPI) <> 10 OR LEFT(ProviderNPI, 1) NOT IN ('1', '2') OR ISNULL(ProviderNPI,'')='')

select top 100 * from aetna_report.dbo.cwfdetails

select ProviderNPIStatus, count(1) from #cwfdetails
group by ProviderNPIStatus

select 1.000*4464400/6185764

drop table prodsupport.dbo.temp
select distinct a.*
into prodsupport.dbo.temp
from 
	#cwfdetails_NotInMAO4 a,
	[Aetna_Report].[rev].[tbl_Summary_RskAdj_EDS_Source] (nolock) b
where
	b.hicn = b.hicn
	and a.DiagnosisCode = b.diagnosisCode
	and year(ServiceEndDate) = '2020'
	and EncounterRiskAdjustable = 1


select * from #cwfdetails_NotInMAO4
select * into prodsupport.dbo.temp from #temp

select top 100 hicn, servicestartDate, ServiceEndDate, DiagnosisCode, * from prodsupport.dbo.temp

select * from prodsupport.dbo.temp
where hicn = '5NK1V25HK35'
and DiagnosisCode = 'G309'

select IsDelete, EncounterRiskAdjustable, * from
	[Aetna_Report].[rev].[tbl_Summary_RskAdj_EDS_Source] (nolock)
where
	year(ServiceEndDate) = '2020'
	and hicn = '5NK1V25HK35'
	and DiagnosisCode = 'G309'
	
select IsDelete, EncounterRiskAdjustable, * from
	[AetIH_Report].[rev].[tbl_Summary_RskAdj_EDS_Source] (nolock)
where
	year(ServiceEndDate) = '2020'
	and hicn = '5NK1V25HK35'
	and DiagnosisCode = 'G309'

