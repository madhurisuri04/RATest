
drop table ProdSupport.dbo.cwfdetails_03032022

select distinct
	ProjectID,
	SubprojectID,
	HICN,
	PlanID,
	cwf.ListChaseID,
	DiagnosisID,
	c.DiagnosisStatusID,
	DiagnosisCode,
	DOSStartDt,
	DOSEndDt,
	CodingCompleteDate,
	CurrentImageStatus,
	CNCodingDiagnosisStatus,
	OverallDiagnosisStatus,
	ProviderNPI,
	case when (ISNUMERIC(ProviderNPI)=0 OR LEN(ProviderNPI) <> 10 OR LEFT(ProviderNPI, 1) NOT IN ('1', '2') OR ISNULL(ProviderNPI,'')='') then 'BAD' else 'GOOD' end ProviderNPIStatus
into ProdSupport.dbo.cwfdetails_03032022
from aetna_report.dbo.cwfdetails cwf
join Aetna_CN_ClientLevel.dbo.Diagnosis c (nolock) on cwf.DiagnosisID=c.ID
where 1=1
and CodingCompleteDate <= '12/21/2021'
and CurrentImageStatus in ('Coding/Review Complete','Ready for Release','Cannot be Coded')
and c.DiagnosisStatusID = 11
and SubprojectID in (
	select ID from Aetna_CN_ClientLevel.dbo.vwSubProject where ProjectID in (
		1299, 1300, 1301, 1302, 1308, 1309, 1411, 1306, 1307, 1345, 1347, 1355, 1357,--Aetna/ AetIH/ DSNP 
		1303, 1304, 1305,--Duals 
		1310, 1311, 1409, 1412--Allina
		)
)

select count(distinct ListChaseID) from ProdSupport.dbo.cwfdetails_03032022 -- 15856


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
	ProdSupport.dbo.cwfdetails_03032022 a
where 
	a.HICN = m.hicn
	and m.PaymentYear = 2021



drop table #cwfdetails_1
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
into #cwfdetails_1 
from ProdSupport.dbo.cwfdetails_03032022 a
	inner join #MMR m
	on a.HICN = m.hicn
	inner join #Diag_HCC_Lookup lk
	on a.DiagnosisCode = lk.ICD10CD
    AND lk.Payment_Year = 2021
	and m.RAFactorType = lk.Factor_Type
where YEAR(a.DOSEndDt) = 2020 
and a.ProviderNPIStatus = 'GOOD'

select * from ProdSupport.dbo.cwfdetails_03032022

-- Get the list of all realized HCC from EDS Preliminary
drop table #EDS_Preliminary
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
	HCC_Number,
	b.RAFactorType,
	PaymentYear
into #EDS_Preliminary
from [Prodsupport].dbo.[tbl_Summary_RskAdj_EDS_Preliminary_03032022_After] a
	join #cwfdetails_1 b
	on a.hicn = b.hicn
where PaymentYear = 2021


-- Coded HCC from Chase missing in Extract that do not have other source
drop table #missinginPrelim 
select *, cast('N' as varchar(1)) HierHCC 
into #missinginPrelim 
from #cwfdetails_1 cwf
where not exists (select 1 from [#EDS_Preliminary] pre where cwf.hicn = pre.hicn and cwf.hcc = hcc_label)



UPDATE A
SET hierHCC = 'Y'
FROM #missinginPrelim A
WHERE EXISTS
    (SELECT 1
		from [#EDS_Preliminary] B
		JOIN HRPReporting.dbo.lk_Risk_Models_Hierarchy C
            ON A.HICN = B.HICN
               AND A.HCC = C.HCC_DROP
               AND B.HCC_Label = C.HCC_KEEP
               AND C.Payment_Year = B.PaymentYear
               AND C.RA_FACTOR_TYPE = B.RAFactorType
	)



select distinct hicn, HCC  from #missinginPrelim where HierHCC = 'Y'

select distinct hicn, HCC, SubprojectID from #missinginPrelim where HierHCC = 'N'

select * 
into [Prodsupport].dbo.[MissinginPrelim_After]
from #missinginPrelim where HierHCC = 'N'

select * 
into [Prodsupport].dbo.[MissinginPrelim_After2]
from #missinginPrelim where HierHCC = 'N'

select distinct hicn, HCC from [Prodsupport].dbo.[MissinginPrelim_After2]
except
select distinct hicn, HCC from [Prodsupport].dbo.[MissinginPrelim_Before]
