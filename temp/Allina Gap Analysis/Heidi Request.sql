--EDSSubmitStatus	RAPSSubmitStatus

select top 10 * from aetna_report.dbo.cwfdetails
select top 10 * from Aetna_CN_ClientLevel.dbo.MRAExtract

drop table ProdSupport.dbo.cwfdetails_Allina_02102021

select distinct
	ProjectID,
	SubprojectID,
	HICN,
	PlanID,
	ListChaseID,
	MedicalRecordImageID,
	SubprojectMedicalRecordID,
	DiagnosisID,
	c.DiagnosisStatusID,
	DiagnosisCode,
	DOSStartDt,
	DOSEndDt,
	CurrentImageStatus,
	CodingCompleteDate,
	CNCodingDiagnosisStatus,
	OverallDiagnosisStatus,
	ProviderNPI,
	case when (ISNUMERIC(ProviderNPI)=0 OR LEN(ProviderNPI) <> 10 OR LEFT(ProviderNPI, 1) NOT IN ('1', '2') OR ISNULL(ProviderNPI,'')='') then 'BAD' else 'GOOD' end ProviderNPIStatus
into ProdSupport.dbo.cwfdetails_Allina_02102021
from aetna_report.dbo.cwfdetails cwf
join Aetna_CN_ClientLevel.dbo.Diagnosis c (nolock) on cwf.DiagnosisID=c.ID
where CodingCompleteDate <= '12/21/2021'
and CurrentImageStatus in ('Coding/Review Complete','Ready for Release','Cannot be Coded')
and c.DiagnosisStatusID = 11
and SubprojectID in (
	select ID from Aetna_CN_ClientLevel.dbo.vwSubProject where ProjectID in (
		--1299, 1300, 1301, 1302, 1308, 1309, 1411, 1306, 1307, 1345, 1347, 1355, 1357,--Aetna/ AetIH/ DSNP 
		--1303, 1304, 1305,--Duals 
		1310, 1311, 1409, 1412--Allina
		)
)

drop table ProdSupport.dbo.cwfdetails_Aetna_02102021

select distinct
	ProjectID,
	SubprojectID,
	HICN,
	PlanID,
	ListChaseID,
	MedicalRecordImageID,
	SubprojectMedicalRecordID,
	DiagnosisID,
	c.DiagnosisStatusID,
	DiagnosisCode,
	DOSStartDt,
	DOSEndDt,
	CurrentImageStatus,
	CodingCompleteDate,
	CNCodingDiagnosisStatus,
	OverallDiagnosisStatus,
	ProviderNPI,
	case when (ISNUMERIC(ProviderNPI)=0 OR LEN(ProviderNPI) <> 10 OR LEFT(ProviderNPI, 1) NOT IN ('1', '2') OR ISNULL(ProviderNPI,'')='') then 'BAD' else 'GOOD' end ProviderNPIStatus
into ProdSupport.dbo.cwfdetails_Aetna_02102021
from aetna_report.dbo.cwfdetails cwf
join Aetna_CN_ClientLevel.dbo.Diagnosis c (nolock) on cwf.DiagnosisID=c.ID
where CodingCompleteDate <= '12/21/2021'
and CurrentImageStatus in ('Coding/Review Complete','Ready for Release','Cannot be Coded')
and c.DiagnosisStatusID = 11
and SubprojectID in (
	select ID from Aetna_CN_ClientLevel.dbo.vwSubProject where ProjectID in (
		1299, 1300, 1301, 1302, 1308, 1309, 1411, 1306, 1307, 1345, 1347, 1355, 1357--Aetna/ AetIH/ DSNP 
		--,1303, 1304, 1305--Duals 
		--,1310, 1311, 1409, 1412--Allina
		)
)


drop table ProdSupport.dbo.cwfdetails_AetnaDuals_02102021

select distinct
	ProjectID,
	SubprojectID,
	HICN,
	PlanID,
	ListChaseID,
	MedicalRecordImageID,
	SubprojectMedicalRecordID,
	DiagnosisID,
	c.DiagnosisStatusID,
	DiagnosisCode,
	DOSStartDt,
	DOSEndDt,
	CurrentImageStatus,
	CodingCompleteDate,
	CNCodingDiagnosisStatus,
	OverallDiagnosisStatus,
	ProviderNPI,
	case when (ISNUMERIC(ProviderNPI)=0 OR LEN(ProviderNPI) <> 10 OR LEFT(ProviderNPI, 1) NOT IN ('1', '2') OR ISNULL(ProviderNPI,'')='') then 'BAD' else 'GOOD' end ProviderNPIStatus
into ProdSupport.dbo.cwfdetails_AetnaDuals_02102021
from aetna_report.dbo.cwfdetails cwf
join Aetna_CN_ClientLevel.dbo.Diagnosis c (nolock) on cwf.DiagnosisID=c.ID
where CodingCompleteDate <= '12/21/2021'
and CurrentImageStatus in ('Coding/Review Complete','Ready for Release','Cannot be Coded')
and c.DiagnosisStatusID = 11
and SubprojectID in (
	select ID from Aetna_CN_ClientLevel.dbo.vwSubProject where ProjectID in (
		--1299, 1300, 1301, 1302, 1308, 1309, 1411, 1306, 1307, 1345, 1347, 1355, 1357--Aetna/ AetIH/ DSNP 
		1303, 1304, 1305--Duals 
		--,1310, 1311, 1409, 1412--Allina
		)
)


select ProviderNPIStatus, count(1) from ProdSupport.dbo.cwfdetails_Allina_02102021 group by ProviderNPIStatus 
select ProviderNPIStatus, count(1) from ProdSupport.dbo.cwfdetails_Aetna_02102021 group by ProviderNPIStatus 
select ProviderNPIStatus, count(1) from ProdSupport.dbo.cwfdetails_AetnaDuals_02102021 group by ProviderNPIStatus 


select * into #MissingDiagsInExtract
from
(
select hicn, DiagnosisCode, DOSStartDt, DOSEndDt from #cwfdetails_Allina where ProviderNPIStatus = 'GOOD'
except
select hicn, DiagnosisCode, DosStart, DOSEnd from Aetna_CN_ClientLevel.dbo.MRAExtract  m (nolock)
) a


select cwf.*
into ProdSupport.dbo.cwfdetails_Not_In_Extract_Allina_02102021
from 
	ProdSupport.dbo.cwfdetails_Allina_02102021 cwf
where not exists (
	select 1 from Aetna_CN_ClientLevel.dbo.MRAExtract mra where	cwf.hicn = mra.HICN and cwf.DiagnosisCode = mra.Diagnosiscode and cwf.DOSStartDt = mra.DOSStart and cwf.DOSEndDt = mra.DOSEnd
	)
and cwf.ProviderNPIStatus = 'GOOD'

select cwf.*
into ProdSupport.dbo.cwfdetails_Not_In_Extract_Aetna_02102021
from 
	ProdSupport.dbo.cwfdetails_Aetna_02102021 cwf
where not exists (
	select 1 from Aetna_CN_ClientLevel.dbo.MRAExtract mra where	cwf.hicn = mra.HICN and cwf.DiagnosisCode = mra.Diagnosiscode and cwf.DOSStartDt = mra.DOSStart and cwf.DOSEndDt = mra.DOSEnd
	)
and cwf.ProviderNPIStatus = 'GOOD'

select cwf.*
into ProdSupport.dbo.cwfdetails_Not_In_Extract_AetnaDuals_02102021
from 
	ProdSupport.dbo.cwfdetails_AetnaDuals_02102021 cwf
where not exists (
	select 1 from Aetna_CN_ClientLevel.dbo.MRAExtract mra where	cwf.hicn = mra.HICN and cwf.DiagnosisCode = mra.Diagnosiscode and cwf.DOSStartDt = mra.DOSStart and cwf.DOSEndDt = mra.DOSEnd
	)
and cwf.ProviderNPIStatus = 'GOOD'



select * into ProdSupport.dbo.cwfdetails_Bad_NPI_Allina_02102021 from ProdSupport.dbo.cwfdetails_Allina_02102021 where ProviderNPIStatus = 'BAD'
select * into ProdSupport.dbo.cwfdetails_Bad_NPI_Aetna_02102021 from ProdSupport.dbo.cwfdetails_Aetna_02102021 where ProviderNPIStatus = 'BAD'
select * into ProdSupport.dbo.cwfdetails_Bad_NPI_AetnaDuals_02102021 from ProdSupport.dbo.cwfdetails_AetnaDuals_02102021 where ProviderNPIStatus = 'BAD'


select * from ProdSupport.dbo.cwfdetails_Allina_02102021 
select * from ProdSupport.dbo.cwfdetails_Aetna_02102021 
select * from ProdSupport.dbo.cwfdetails_AetnaDuals_02102021 

select * from ProdSupport.dbo.cwfdetails_Bad_NPI_Allina_02102021 
select * from ProdSupport.dbo.cwfdetails_Bad_NPI_Aetna_02102021 
select * from ProdSupport.dbo.cwfdetails_Bad_NPI_AetnaDuals_02102021 

select * from ProdSupport.dbo.cwfdetails_Not_In_Extract_Allina_02102021
select * from ProdSupport.dbo.cwfdetails_Not_In_Extract_Aetna_02102021
select * from ProdSupport.dbo.cwfdetails_Not_In_Extract_AetnaDuals_02102021

select count(1) from ProdSupport.dbo.cwfdetails_Allina_02102021 -- 29456
select count(1) from ProdSupport.dbo.cwfdetails_Aetna_02102021 -- 10461591
select count(1) from ProdSupport.dbo.cwfdetails_AetnaDuals_02102021 -- 595784

select count(1) from ProdSupport.dbo.cwfdetails_Bad_NPI_Allina_02102021 -- 422
select count(1) from ProdSupport.dbo.cwfdetails_Bad_NPI_Aetna_02102021 -- 103430
select count(1) from ProdSupport.dbo.cwfdetails_Bad_NPI_AetnaDuals_02102021 -- 0

select count(1) from ProdSupport.dbo.cwfdetails_Not_In_Extract_Allina_02102021 -- 26291
select count(1) from ProdSupport.dbo.cwfdetails_Not_In_Extract_Aetna_02102021 -- 421880
select count(1) from ProdSupport.dbo.cwfdetails_Not_In_Extract_AetnaDuals_02102021 -- 3907


select count(distinct ListChaseID) from ProdSupport.dbo.cwfdetails_Not_In_Extract_Allina_02102021 -- 2786
select count(distinct ListChaseID) from ProdSupport.dbo.cwfdetails_Not_In_Extract_Aetna_02102021 -- 41076
select count(distinct ListChaseID) from ProdSupport.dbo.cwfdetails_Not_In_Extract_AetnaDuals_02102021 -- 418


select * from Aetna_CN_ClientLevel.dbo.MRAExtract
where ChaseID = 'MRA20216808202'


select distinct lm.ListChaseID, lm.LoadDate from Aetna_CN_ClientLevel.dbo.ListManagementUploadRecords lm (nolock)
left join Aetna_CN_ClientLevel.dbo.ChartNavChaseUploadRecords cr (nolock) on lm.ListChaseID=cr.CHASE_ID
where lm.loaddate>='2021-03-01' and cr.CHASE_ID is null and lm.ListChaseID<>''
order by lm.LoadDate
