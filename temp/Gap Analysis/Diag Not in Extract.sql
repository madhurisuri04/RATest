

drop table ProdSupport.dbo.cwfdetails_03312022

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
into ProdSupport.dbo.cwfdetails_03312022
from aetna_report.dbo.cwfdetails cwf
join Aetna_CN_ClientLevel.dbo.Diagnosis c (nolock) on cwf.DiagnosisID=c.ID
where 1=1
and CodingCompleteDate <= '12/31/2021'
and CurrentImageStatus in ('Coding/Review Complete','Ready for Release','Cannot be Coded')
and c.DiagnosisStatusID = 11
and SubprojectID in (
	select ID from Aetna_CN_ClientLevel.dbo.vwSubProject where ProjectID in (
		1299, 1300, 1301, 1302, 1308, 1309, 1411, 1306, 1307, 1345, 1347, 1355, 1357,--Aetna/ AetIH/ DSNP 
		1303, 1304, 1305,--Duals 
		1310, 1311, 1409, 1412--Allina
		)
)



select cwf.*
into ProdSupport.dbo.cwfdetails_Not_In_Extract_03312022
from 
	ProdSupport.dbo.cwfdetails_03312022 cwf
where not exists (
	select 1 from Aetna_CN_ClientLevel.dbo.MRAExtract mra where	cwf.hicn = mra.HICN and cwf.DiagnosisCode = mra.Diagnosiscode and cwf.DOSStartDt = mra.DOSStart and cwf.DOSEndDt = mra.DOSEnd
	)
and cwf.ProviderNPIStatus = 'GOOD'


select * from ProdSupport.dbo.cwfdetails_Not_In_Extract_03312022

select cwf.*
into ProdSupport.dbo.cwfdetails_Not_In_Extract_04042022
from 
	ProdSupport.dbo.cwfdetails_03312022 cwf
where not exists (
	select 1 from Aetna_CN_ClientLevel.dbo.MRAExtract mra where	cwf.hicn = mra.HICN and cwf.DiagnosisCode = mra.Diagnosiscode
	)
and cwf.ProviderNPIStatus = 'GOOD'

select * from ProdSupport.dbo.cwfdetails_Not_In_Extract_04042022