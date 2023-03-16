
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
	OverallDiagnosisStatus
into #cwfdetails
from aetna_report.dbo.cwfdetails cwf
join Aetna_CN_ClientLevel.dbo.Diagnosis c (nolock) on cwf.DiagnosisID=c.ID
where CodingCompleteDate <= '09/14/2021'
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

-- Chase not in MRA Extract table 
select * into #MissingChaseInExtract
from
(
select ListChaseID from #cwfdetails 
except
select ChaseID from Aetna_CN_ClientLevel.dbo.MRAExtract  m (nolock)
) a

--select * from #MissingChaseInExtract
-- 30233

-- Diag codes not in MRA Extract table 
select * into #MissingDiagsInExtract
from
(
select hicn, DiagnosisCode from #cwfdetails 
except
select hicn, DiagnosisCode from Aetna_CN_ClientLevel.dbo.MRAExtract  m (nolock)
) a

-- select * from #MissingDiagsInExtract
-- 74475

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

-- Filter out diags that dont map to HCC, for Chase not in Extract
drop table #cwfdetails_HCC
select distinct 
	ProjectID,
	SubprojectID,
	a.HICN,
	ListChaseID,
	DiagnosisID,
	DiagnosisStatusID,
	a.DiagnosisCode,
	DOSStartDt,
	DOSEndDt,
	HCC = lk.HCC_Label,
	RAFactorType = m.RAFactorType,
	CurrentImageStatus,
	CNCodingDiagnosisStatus,
	OverallDiagnosisStatus,
	PlanID = m.PlanID
into #cwfdetails_HCC
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
where YEAR(DOSEndDt) = 2020 



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
	HCC_Number
into #EDSPreliminary
from [Aetna_Report].[rev].[tbl_Summary_RskAdj_EDS_Preliminary] a
	join #cwfdetails_HCC b
	on a.hicn = b.hicn
where PaymentYear = 2021

insert into #EDSPreliminary
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
	join #cwfdetails_HCC b
	on a.hicn = b.hicn
where PaymentYear = 2021


-- Coded HCC from Chase missing in Extract that do not have other source
drop table #missingHCC
select * 
into #missingHCC
from
(
select hicn, HCC from #cwfdetails_HCC
except
select hicn, HCC_Label from #EDSPreliminary
) a

-- 2429

drop table #temp
select * 
into #temp
from #cwfdetails_HCC a
where exists (select 1 from #missingHCC b where a.hicn = b.hicn and a.HCC = b.HCC)

select top 10 * from #temp
select top 10 * from Aetna_CN_ClientLevel.dbo.MRAExtract

select hicn, DiagnosisCode 
into #temp2
from #temp
except
select hicn, diagnosisCode from Aetna_CN_ClientLevel.dbo.MRAExtract

select * from #cwfdetails_HCC a
where exists (select 1 from #temp b where a.DiagnosisCode = b.DiagnosisCode and a.hicn = b.hicn)





drop table #cwfdetails1_HCC
select distinct 
	ProjectID,
	SubprojectID,
	a.HICN,
	ListChaseID,
	DiagnosisID,
	DiagnosisStatusID,
	DiagnosisCode,
	DOSStartDt,
	DOSEndDt,
	HCC = lk.HCC_Label,
	RAFactorType = m.RAFactorType,
	CurrentImageStatus,
	CNCodingDiagnosisStatus,
	OverallDiagnosisStatus,
	PlanID = m.PlanID
into #cwfdetails1_HCC
from #cwfdetails a
	inner join #MMR m
	on a.HICN = m.hicn
	inner join #Diag_HCC_Lookup lk
	on a.DiagnosisCode = lk.ICD10CD
    AND lk.Payment_Year = 2021
	and m.RAFactorType = lk.Factor_Type
where YEAR(DOSEndDt) = 2020 
and ListChaseID not in (select ListChaseID from #MissingChaseInExtract)


select * 
into #temp1
from #cwfdetails1_HCC a
where not exists (
select 1 from [AetIH_Report].[rev].[tbl_Summary_RskAdj_EDS_Preliminary] b
where PaymentYear = 2021
and a.hicn = b.hicn and a.hcc = b.hcc_label
)

select * 
into #temp2
from #temp1 a
where not exists (
select 1 from [Aetna_Report].[rev].[tbl_Summary_RskAdj_EDS_Preliminary] b
where PaymentYear = 2021
and a.hicn = b.hicn and a.hcc = b.hcc_label
)


--select * from #temp2







-------------------------

MRA20212262840
MRA20212375829
MRA20212482175
MRA20212551305
MRA20212564732
MRA20212571654
MRA20212603308
MRA20212641207
MRA20212704508
MRA20212721035
MRA20212824355
MRA20212953324
MRA20212955993
MRA20212956169
MRA20213396826
MRA20213402943
MRA20213415798
MRA20213458647
MRA20213541530
MRA20213547209
MRA20213570962
MRA20213596840
MRA20213624040
MRA20213776761
MRA20213878766
MRA20213893437
MRA20213967659
MRA20214005797
MRA20214015115
MRA20214095766
MRA20214119354
MRA20214160705
MRA20214162588
MRA20214232515
MRA20214293025
MRA20214333694
MRA20214387562
MRA20214392198
MRA20214442283
MRA20214546664
MRA20214619655
MRA20214728965
MRA20214777513
MRA20214807018
MRA20214817329
MRA20214819125
MRA20215099231
MRA20215112237
MRA20215161519
MRA20215253551
MRA20215268029
MRA20215268836
MRA20215338877
MRA20215369153
MRA20215373833
MRA20215378484
MRA20215457361
MRA20215628361
MRA20215771604
MRA20215833693
MRA20215905933
MRA20215911366
MRA20215958787
MRA20215990320
MRA20216004546
MRA20216005309
MRA20216019881
MRA20216055524
MRA20216107803
MRA20216142465
MRA20216162974
MRA20216166336
MRA20216188956
MRA20216207696
MRA20216215892
MRA20216222265
MRA20216298324
MRA20216316621
MRA20216322053
MRA20216324311
MRA20216340196
MRA20216360619
MRA20216375214
MRA20216414551
MRA20216415619
MRA20216532582
MRA20216534838
MRA20216560716
MRA20216560974
MRA20216590448
MRA20216658464
MRA20216675995
MRA20216690241
MRA20216876470
MRA20216912663
MRA20216915530
MRA20216966919
MRA20216972042
MRA20216994545
MRA20217025545
MRA20217028580
MRA20217142102
MRA20217154421
MRA20217182105
MRA20217218043
MRA20217250886
MRA20217315747
MRA20217376778
MRA20217382706
MRA20217441337
MRA20217460316
MRA20217470173
MRA20217472291
MRA20217475382
MRA20217482008
MRA20217489024
MRA20217491442
MRA20217506509
MRA20217529377
MRA20217610350
MRA20217707255
MRA20217743442
MRA20217816235
MRA20217834957
