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
--and CodingCompleteDate <= '12/21/2021'
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

select * from ProdSupport.dbo.cwfdetails_02142022

select * from ProdSupport.dbo.cwfdetails_Not_In_Extract_Allina_02102021 a where not exists (select 1 from ProdSupport.dbo.cwfdetails_02142022 b where a.ListChaseID = b.ListChaseID)
select * from ProdSupport.dbo.cwfdetails_Not_In_Extract_Aetna_02102021 a where not exists (select 1 from ProdSupport.dbo.cwfdetails_02142022 b where a.ListChaseID = b.ListChaseID)
select * from ProdSupport.dbo.cwfdetails_Not_In_Extract_AetnaDuals_02102021 a where not exists (select 1 from ProdSupport.dbo.cwfdetails_02142022 b where a.ListChaseID = b.ListChaseID)

select * into ProdSupport.dbo.cwfdetails_Not_In_Extract_New_Allina_02102021 from ProdSupport.dbo.cwfdetails_Not_In_Extract_Allina_02102021 a where not exists (select 1 from #ChaseMissinginExtract b where a.ListChaseID = b.ListChaseID)
select * into ProdSupport.dbo.cwfdetails_Not_In_Extract_New_Aetna_02102021 from ProdSupport.dbo.cwfdetails_Not_In_Extract_Aetna_02102021 a where not exists (select 1 from #ChaseMissinginExtract b where a.ListChaseID = b.ListChaseID)
select * into ProdSupport.dbo.cwfdetails_Not_In_Extract_New_AetnaDuals_02102021 from ProdSupport.dbo.cwfdetails_Not_In_Extract_AetnaDuals_02102021 a where not exists (select 1 from #ChaseMissinginExtract b where a.ListChaseID = b.ListChaseID)

select * from ProdSupport.dbo.cwfdetails_Not_In_Extract_New_Allina_02102021 where year(DOSEndDt) = 2020
select * from ProdSupport.dbo.cwfdetails_Not_In_Extract_New_Aetna_02102021  where year(DOSEndDt) = 2020
select * from ProdSupport.dbo.cwfdetails_Not_In_Extract_New_AetnaDuals_02102021  where year(DOSEndDt) = 2020

