/*
select distinct lm.ListChaseID, lm.LoadDate from Aetna_CN_ClientLevel.dbo.ListManagementUploadRecords lm (nolock)
left join Aetna_CN_ClientLevel.dbo.ChartNavChaseUploadRecords cr (nolock) on lm.ListChaseID=cr.CHASE_ID
where lm.loaddate>='2021-03-01' and cr.CHASE_ID is null and lm.ListChaseID<>''
order by lm.LoadDate

*/


select distinct lm.ListChaseID
into #ChaseMissinginExtract
from Aetna_CN_ClientLevel.dbo.ListManagementUploadRecords lm (nolock)
left join Aetna_CN_ClientLevel.dbo.ChartNavChaseUploadRecords cr (nolock) on lm.ListChaseID=cr.CHASE_ID
where lm.loaddate>='2021-03-01' and cr.CHASE_ID is null and lm.ListChaseID<>''

select count(distinct ListChaseID) from #ChaseMissinginExtract -- 41385

select count(distinct cwf.ListChaseID) -- 24514
from aetna_report.dbo.cwfdetails cwf
join #ChaseMissinginExtract mMRA on cwf.ListChaseID = mMRA.ListChaseID
where SubprojectID in (
	select ID from Aetna_CN_ClientLevel.dbo.vwSubProject where ProjectID in (
		1299, 1300, 1301, 1302, 1308, 1309, 1411, 1306, 1307, 1345, 1347, 1355, 1357,--Aetna/ AetIH/ DSNP 
		1303, 1304, 1305,--Duals 
		1310, 1311, 1409, 1412--Allina
		)
)
and CurrentImageStatus in ('Coding/Review Complete','Ready for Release','Cannot be Coded') -- 21192

/*
select a.* from Aetna_CN_ClientLevel.dbo.MRAExtract a, #ChaseMissinginExtract b
where a.chaseID = b.ListChaseID
*/


drop table ProdSupport.dbo.cwfdetails_02142022

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
into ProdSupport.dbo.cwfdetails_02142022
from aetna_report.dbo.cwfdetails cwf
join #ChaseMissinginExtract mMRA on cwf.ListChaseID = mMRA.ListChaseID
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

select count(distinct ListChaseID) from ProdSupport.dbo.cwfdetails_02142022 -- 15856

select CodingCompleteDate, count(1) from ProdSupport.dbo.cwfdetails_02142022
group by CodingCompleteDate
order by 1

/*
A little bit of stats:

Total unique chase from above query: 41385
Count of chase pertaining to Aetna/Allina/Dual projects: 24514
Count of chase ready to release pertaining to Aetna/Allina/Dual projects: 21192
Count of chase having valid diagnosis Status = 15856

Total count of chase missing in extract (with valid diagnosis status) ~ 44000
*/

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
	ProdSupport.dbo.cwfdetails_02142022 a
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
from ProdSupport.dbo.cwfdetails_02142022 a
	inner join #MMR m
	on a.HICN = m.hicn
	inner join #Diag_HCC_Lookup lk
	on a.DiagnosisCode = lk.ICD10CD
    AND lk.Payment_Year = 2021
	and m.RAFactorType = lk.Factor_Type
where YEAR(a.DOSEndDt) = 2020 
and a.ProviderNPIStatus = 'GOOD'

select * from ProdSupport.dbo.cwfdetails_02142022

-- Get the list of all realized HCC from EDS Preliminary
drop table #EDSPreliminary
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
into #EDSPreliminary
from [Aetna_Report].[rev].[tbl_Summary_RskAdj_EDS_Preliminary] a
	join #cwfdetails_1 b
	on a.hicn = b.hicn
where PaymentYear = 2021

select * from #EDSPreliminary

-- Coded HCC from Chase missing in Extract that do not have other source

select *, cast('N' as varchar(1)) HierHCC 
into #missinginPrelim 
from #cwfdetails_1 cwf
where not exists (select 1 from #EDSPreliminary pre where cwf.hicn = pre.hicn and cwf.hcc = hcc_label)

select * from #missinginPrelim 


UPDATE A
SET hierHCC = 'Y'
FROM #missinginPrelim A
WHERE EXISTS
    (SELECT 1
		from #EDSPreliminary B
		JOIN HRPReporting.dbo.lk_Risk_Models_Hierarchy C
            ON A.HICN = B.HICN
               AND A.HCC = C.HCC_DROP
               AND B.HCC_Label = C.HCC_KEEP
               AND C.Payment_Year = B.PaymentYear
               AND C.RA_FACTOR_TYPE = B.RAFactorType
	)



select distinct hicn, HCC  from #missinginPrelim where HierHCC = 'Y'

select distinct hicn, HCC, SubprojectID from #missinginPrelim where HierHCC = 'N'

select distinct hicn, HCC
from #missinginPrelim a
join Aetna_CN_ClientLevel.dbo.vwSubProject b on a.SubProjectID = b.ID
where HierHCC = 'N'
and b.ProjectID in (
		1299, 1300, 1301, 1302, 1308, 1309, 1411, 1306, 1307, 1345, 1347, 1355, 1357--Aetna/ AetIH/ DSNP 
		--1303, 1304, 1305--Duals 
		--1310, 1311, 1409, 1412--Allina
)

2437 = 1982 + 455

Value:

select 1982*2400 -- 4 756 800 -- Aetna
select 455*2400 -- 1 092 000 - Allina

select (270217161 + 4756800)/ 1041698 -- 263

select (63857 + 1092000)/ 4785 -- 273


SELECT ProjectID, 
	SubProjectID,
	SUM(ChartsRequested) as ChartsRequested,
	SUM(ChartsRetrieved) as ChartsVHRetrieved,
	SUM(ChartsRequested) - SUM(ChartsRetrieved) as ChartsNotRetrieved,
	SUM(ChartsAdded)as ChartsAdded, 
	SUM(ChartsFPC) as ChartsFPC, 
	SUM(ChartsComplete) as ChartsComplete, ROUND(100*SUM(ChartsComplete)/SUM(ChartsRequested),2) as Percent_Complete
FROM HRPClientGlobal_Report.dbo.CTR_Summary 
  where ClientID=19 
  and PlanID in ('H0318', 'H0523', 'H0628', 'H0901', 'H1100', 'H1109', 'H1110', 'H1419', 'H1608', 'H1609', 'H1610', 'H1692', 'H2056', 
					'H2112', 'H2506', 'H2663', 'H2829', 'H3146', 'H3152', 'H3192', 'H3219', 'H3239', 'H3288', 'H3312', 'H3597', 'H3623',
					'H3748', 'H3928', 'H3931', 'H3959', 'H4523', 'H4524', 'H4711', 'H4835', 'H4910', 'H4982', 'H5302', 'H5325', 'H5337', 
					'H5521', 'H5522', 'H5593', 'H5736', 'H6399', 'H5793', 'H5813', 'H5832', 'H5950', 'H6560', 'H6923', 'H7149', 'H7172', 
					'H7301', 'H7908', 'H8026', 'H8056', 'H8332', 'H8597', 'H8649', 'H8684', 'H9431', 'R6694')
				 --What is HPlan Z0019?? Has charts, but not in DB list
  and ProjectID in (1310, 1311, 1409, 1412)
  and Summary_Type='CHARTS' 
  and LoadDate='01-01-2022'  --Monday of the week (or 2 if submissions were early in week) prior to most recent EDS data found21
  group by ProjectID, SubProjectID with rollup
  order by ProjectID, SubProjectID