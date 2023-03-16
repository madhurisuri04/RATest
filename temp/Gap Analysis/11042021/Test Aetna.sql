4NY7HT3JJ55	HCC 55

select * from ReportingETL.[HRP\hasan.farooqui].AETGapCheck_000a_Source
where FinalMemberNumber = '4NY7HT3JJ55'

select * from AetIH_Report.[rev].[tbl_Summary_RskAdj_AltHICN]
where hicn = '4NY7HT3JJ55' or finalHICN = '4NY7HT3JJ55'

select * from AetIH_Report.rev.[tbl_Summary_RskAdj_EDS_Source]
where HICN = '4NY7HT3JJ55'
and diagnosisCode = 'F1420'

select * from AetIH_Report.[rev].[tbl_Summary_RskAdj_EDS_Preliminary]
where HICN = '4NY7HT3JJ55'
and diagnosisCode = 'F1420'
and paymentYear = 2020
and RiskAdjustable = 1

--
select 
	MAO004ResponseID, HICN, PlanSubmissionDate, ServiceStartDate, ServiceEndDate, DiagnosisCode, SentEncounterRiskAdjustableFlag
from AetIH_Report.rev.[tbl_Summary_RskAdj_EDS_Source]
where HICN = '4NY7HT3JJ55'
and diagnosisCode = 'F1420'

select 
	MAO004ResponseID, HICN, PlanSubmissionDate, ServiceStartDate, ServiceEndDate, DiagnosisCode, RiskAdjustable
from AetIH_Report.[rev].[tbl_Summary_RskAdj_EDS_Preliminary]
where HICN = '4NY7HT3JJ55'
and diagnosisCode = 'F1420'
and paymentYear = 2020

--


select * from AetIH_Report.[rev].[tbl_Summary_RskAdj_EDS_Preliminary]
where paymentYear = 2020
and HICN = '4NY7HT3JJ55'
and HCC_Label in ('HCC 55')
and RiskAdjustable = 1

select * from ProdSupport.dbo.tbl_GAP_All_Diags_EDS_PartC_AetIH
where HICN = '4NY7HT3JJ55'
and diagnosisCode = 'F1420'


select * from AetIH_Report.[rev].[tbl_Summary_RskAdj_RAPS_Preliminary]
where HICN = '4NY7HT3JJ55'
and diagnosisCode = 'F1420'
and paymentYear = 2020


select * from ProdSupport.dbo.tbl_GAP_All_Diags_EDS_PartC_HCC_AetIH
where HICN = '4NY7HT3JJ55'

select * from HRPReporting.dbo.lk_Risk_Models_Hierarchy
where Payment_Year = 2020
and (HCC_DROP_NUMBER = 55 or HCC_KEEP_NUMBER = 55)

select * from HRPReporting.dbo.lk_Risk_Models_DiagHCC_ICD10
where Payment_Year = 2020
and ICD10CD = 'F1420'


Select distinct 
	b.Payment_Year
	,b.Factor_Type
	,b.ICD10CD
	,b.HCC_Label
from
	HRPReporting.dbo.lk_Risk_Models_DiagHCC_ICD10 B  (nolock)  
where  
	B.Payment_Year in (2020) 
	and b.Factor_Type not in ('E','E1','E2','SE','ED')
	and b.ICD10CD = 'F1420'


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
	B.Payment_Year in (2020) 
	and b.Factor_Type not in ('E','E1','E2','SE','ED')


select distinct 
	EncounterSource = 'EDS', 
	PaymentYear = cast(year([ServiceEndDate]) as int) + 1, 
	a.HICN, 
	[ServiceStartDate], 
	[ServiceEndDate], 
	DiagnosisCode, 
	NULL ProviderType,
	HCC = lk.HCC_Label,
	'N' IsAdded,
	m.PartCRAFTMMR RAFactorType,
	m.PlanID
into #temp
from AetIH_Report.rev.[tbl_Summary_RskAdj_EDS_Source] a
	inner join ProdSupport.dbo.Temp_SummaryMMR_AetIH m
	on a.hicn = m.hicn
	left join #Diag_HCC_Lookup lk
	on a.DiagnosisCode = lk.ICD10CD
    AND m.PaymentYear = lk.Payment_Year
	and m.PartCRAFTMMR = lk.Factor_Type
where year([ServiceEndDate]) = '2019' -- DOS Year parameter 
and [SentEncounterRiskAdjustableFlag] = 'A' and [IsDelete] is null
and a.HICN = '4NY7HT3JJ55'


select * from ProdSupport.dbo.tbl_GAP_All_Diags_EDS_PartC_AetIH
where HICN = '4NY7HT3JJ55'
and isAdded = 'Y'

select * from #temp

select distinct 
	'EDS', 
	YEAR(DOSEnd) + 1, 	
	a.HICN, 
	DOSStart, 
	DOSEnd, 
	DiagnosisCode,
	null ProviderType,
	HCC = lk.HCC_Label,
	'Y' as IsAdded,
	m.PartCRAFTMMR RAFactorType,
	m.PlanID
from 
	ProdSupport.dbo.tbl_GAP_Diags_Add a 
	inner join ProdSupport.dbo.Temp_SummaryMMR_AetIH m
	on a.HICN = m.HICN
	left join #Diag_HCC_Lookup lk
	on a.DiagnosisCode = lk.ICD10CD
    AND m.PaymentYear = lk.Payment_Year
	and m.PartCRAFTMMR = lk.Factor_Type
where a.DOS_year = 2019 
and a.HICN = '4NY7HT3JJ55'



select distinct 
	EncounterSource = 'EDS', 
	PaymentYear = cast(year([ServiceEndDate]) as int) + 1, 
	a.HICN, 
	[ServiceStartDate], 
	[ServiceEndDate], 
	DiagnosisCode, 
	NULL ProviderType,
--	HCC = lk.HCC_Label,
	'N' IsAdded
from AetIH_Report.rev.[tbl_Summary_RskAdj_EDS_Source] a
	--inner join ProdSupport.dbo.Temp_SummaryMMR_AetIH m
	--on a.hicn = m.hicn
	--left join #Diag_HCC_Lookup lk
	--on a.DiagnosisCode = lk.ICD10CD
 --   AND m.PaymentYear = lk.Payment_Year
	--and m.PartCRAFTMMR = lk.Factor_Type
where year([ServiceEndDate]) = '2019' -- DOS Year parameter 
--and [SentEncounterRiskAdjustableFlag] = 'A' and [IsDelete] is null
and a.HICN = '4NY7HT3JJ55'
and diagnosisCode = 'F1420'



select distinct mbi, hicn from ProdSupport.dbo.tbl_GAP_Diags_Add where mbi <> hicn

select distinct hicn, finalhicn from AetIH_Report.[rev].[tbl_Summary_RskAdj_AltHICN]
where hicn in (select mbi from ProdSupport.dbo.tbl_GAP_Diags_Add)
and hicn <> finalhicn

union 

select distinct hicn, finalhicn from Aetna_Report.[rev].[tbl_Summary_RskAdj_AltHICN]
where hicn in (select mbi from ProdSupport.dbo.tbl_GAP_Diags_Add)
and hicn <> finalhicn


drop table if exists #tbl_GAP_Diags_Add_AltHICN

select distinct MBI, HICN
into #tbl_GAP_Diags_Add_AltHICN
from ProdSupport.dbo.tbl_GAP_Diags_Add
where MBI <> HICN

select * from AetIH_Report.rev.[tbl_Summary_RskAdj_EDS_Source]
where HICN in (select mbi from #tbl_GAP_Diags_Add_AltHICN)


select top 10 * from Aetna_Report.dbo.RAPS_DiagHCC_rollup
select top 10 * from AetIH_Report.dbo.RAPS_DiagHCC_rollup


select PlanIdentifier, count(1) from Aetna_Report.dbo.RAPS_DiagHCC_rollup
where year(ThruDate) = '2019'
group by PlanIdentifier


select PlanIdentifier, count(1) from AetIH_Report.dbo.RAPS_DiagHCC_rollup
where year(ThruDate) = '2019'
group by PlanIdentifier


select PlanIdentifier, count(1) from ReportingETL.[HRP\hasan.farooqui].AETGapCheck_002d_RAPS_Source
where year(ThruDate) = '2019'
group by PlanIdentifier

select * from ReportingETL.[HRP\hasan.farooqui].AETGapCheck_002a_MMR
select * from ReportingETL.[HRP\hasan.farooqui].AETGapCheck_002d_RAPS_Source


select * from ReportingETL.[HRP\hasan.farooqui].AETGapCheck_002d_RAPS_Source
where hicn = '5D41P00WA33'

select * from ReportingETL.[HRP\hasan.farooqui].AETGapCheck_002a_MMR
where hicn = '3V44WT2VC93'

select * from AetIH_Report.dbo.RAPS_DiagHCC_rollup
where year(ThruDate) = '2019'
and hicn in (
--'5D41P00WA33 ','1DM8AV6XJ45 ','4TG6FY3JW61 ','4G13H95WK88 ','4YW4H37DX93 ','5UR5A92ME74 ','4X23X09VG86 ','7F82VM5JY06 ','4WU9GF1QW21 ','9FD2AR8RQ13 ','3A14YJ0FX78 ','1FQ4D06HG86 ','6PK4J63EC70 ','8G64G81EM64 ','9PE1JJ2FD94 ','2TV2PW7NM94 ','6VV4P03NE98 ','9X45E22DY62 ','6J34MU4TH68 ','9HU8N82WG69 ','3PJ8TT8QG61 ','2Y35U48NN72 ','3DH5Q05WM54 ','3E71QY0QT29 ','6AR2UF9YN82 ','9JT3AW9NA73'
'3V44WT2VC93 ','2RE7AY5DE35 ','9G29XK6GT35 ','4H73H55HD88 ','4J90N56MG13 ','7P29EM5TR24 ','2VU0VK8KD26 ','6X12GM4HH26 ','8T40HV6HX11 ','4Q85NR2QV63 ','7GM8T76JC48 ','5NN1NA7TR92 ','4NM7FD6FN60 ','4N31N61HD34 ','2GR7A60FE74 ','7EC2J74VF04 ','7D39MX8QX29 ','7Q55FR5PX52 ','1XN4JD9KM88 ','2GE3P96MJ89 ','6GE8HF2PM31 ','8C99Y35JF52 ','5VR1JM3WQ04 ','5PY9MP7MQ59 ','4RF8VF7YY32 ','2PH4VA8AF99'
)

select * from 
ProdSupport.dbo.tbl_GAP_All_Diags_RAPS_PartC_AetIH
where hicn in (
--'5D41P00WA33 ','1DM8AV6XJ45 ','4TG6FY3JW61 ','4G13H95WK88 ','4YW4H37DX93 ','5UR5A92ME74 ','4X23X09VG86 ','7F82VM5JY06 ','4WU9GF1QW21 ','9FD2AR8RQ13 ','3A14YJ0FX78 ','1FQ4D06HG86 ','6PK4J63EC70 ','8G64G81EM64 ','9PE1JJ2FD94 ','2TV2PW7NM94 ','6VV4P03NE98 ','9X45E22DY62 ','6J34MU4TH68 ','9HU8N82WG69 ','3PJ8TT8QG61 ','2Y35U48NN72 ','3DH5Q05WM54 ','3E71QY0QT29 ','6AR2UF9YN82 ','9JT3AW9NA73'
'3V44WT2VC93 ','2RE7AY5DE35 ','9G29XK6GT35 ','4H73H55HD88 ','4J90N56MG13 ','7P29EM5TR24 ','2VU0VK8KD26 ','6X12GM4HH26 ','8T40HV6HX11 ','4Q85NR2QV63 ','7GM8T76JC48 ','5NN1NA7TR92 ','4NM7FD6FN60 ','4N31N61HD34 ','2GR7A60FE74 ','7EC2J74VF04 ','7D39MX8QX29 ','7Q55FR5PX52 ','1XN4JD9KM88 ','2GE3P96MJ89 ','6GE8HF2PM31 ','8C99Y35JF52 ','5VR1JM3WQ04 ','5PY9MP7MQ59 ','4RF8VF7YY32 ','2PH4VA8AF99'
)



select count(1) from Aetna_Report.rev.[tbl_Summary_RskAdj_EDS_Source]
select count(1) from AetIH_Report.rev.[tbl_Summary_RskAdj_EDS_Source]


select * from ProdSupport.dbo.tbl_GAP_HCC_RAPS_PartC_Aetna
where Hierarchy = 'L'

select distinct hicn, hcc, IsAdded  from ProdSupport.dbo.tbl_GAP_All_Diags_RAPS_PartC_Aetna where hicn = '8UV3YN0NA85' and HCC is not null order by HCC  

select * from ProdSupport.dbo.tbl_GAP_HCC_RAPS_PartC_Aetna where hicn = '8UV3YN0NA85' order by HCC 

select 
hicn, count(distinct HCC)
from 
ProdSupport.dbo.tbl_GAP_All_Diags_RAPS_PartC_Aetna a
where hcc in ('HCC 17', 'HCC 18', 'HCC 19')
and exists (select 1 from ProdSupport.dbo.tbl_GAP_HCC_RAPS_PartC_Aetna b where a.hicn = b.hicn and hcc in ('HCC 17', 'HCC 18', 'HCC 19'))
group by hicn 
having count(distinct HCC) > 2


select * from ReportingETL.[HRP\hasan.farooqui].AETGapCheck_002d_RAPS_Source a
select * from ReportingETL.[HRP\hasan.farooqui].AETGapCheck_002a_MMR m
select * from ReportingETL.[HRP\hasan.farooqui].AETGapCheck_002e_EDS_Source
select * from ReportingETL.[HRP\hasan.farooqui].AETGapCheck_000a_Source


select distinct RunID from ReportingETL.[HRP\hasan.farooqui].AETGapCheck_000a_Source

select * from ReportingETL.[HRP\hasan.farooqui].AETGapCheck_002e_EDS_Source


select * from ProdSupport.dbo.tbl_GAP_NEW_HCC_RAPS_PartC_Aetna
select * from ProdSupport.dbo.tbl_GAP_NEW_HCC_EDS_PartC_Aetna

select * from ProdSupport.dbo.tbl_GAP_NEW_HCC_RAPS_PartD_Aetna
select * from ProdSupport.dbo.tbl_GAP_NEW_HCC_EDS_PartD_Aetna

-- Yesterday
select count(1) from ProdSupport.dbo.tbl_GAP_NEW_HCC_RAPS_PartC_Aetna_Run2 -- 20094
select count(1) from ProdSupport.dbo.tbl_GAP_NEW_HCC_EDS_PartC_Aetna_Run2 -- 16101

select count(1) from ProdSupport.dbo.tbl_GAP_NEW_HCC_RAPS_PartD_Aetna_Run2 -- 18748
select count(1) from ProdSupport.dbo.tbl_GAP_NEW_HCC_EDS_PartD_Aetna_Run2 -- 11836


-- Today
select count(1) from ProdSupport.dbo.tbl_GAP_NEW_HCC_RAPS_PartC_Aetna -- 20056
select count(1) from ProdSupport.dbo.tbl_GAP_NEW_HCC_EDS_PartC_Aetna -- 16071

select count(1) from ProdSupport.dbo.tbl_GAP_NEW_HCC_RAPS_PartD_Aetna -- 18706
select count(1) from ProdSupport.dbo.tbl_GAP_NEW_HCC_EDS_PartD_Aetna -- 11805

select count(distinct hicn+hcc) from ProdSupport.dbo.tbl_GAP_NEW_HCC_RAPS_PartC_Aetna -- 18923
select count(distinct hicn+hcc) from ProdSupport.dbo.tbl_GAP_NEW_HCC_EDS_PartC_Aetna -- 15205

select count(distinct hicn+hcc) from ProdSupport.dbo.tbl_GAP_NEW_HCC_RAPS_PartD_Aetna -- 17439
select count(distinct hicn+hcc) from ProdSupport.dbo.tbl_GAP_NEW_HCC_EDS_PartD_Aetna -- 10924

-------------------


select * into ProdSupport.dbo.tbl_GAP_NEW_HCC_RAPS_PartC_Aetna_Run2 from ProdSupport.dbo.tbl_GAP_NEW_HCC_RAPS_PartC_Aetna -- 20094
select * into ProdSupport.dbo.tbl_GAP_NEW_HCC_EDS_PartC_Aetna_Run2 from ProdSupport.dbo.tbl_GAP_NEW_HCC_EDS_PartC_Aetna -- 16101


select * into ProdSupport.dbo.tbl_GAP_NEW_HCC_RAPS_PartD_Aetna_Run2 from ProdSupport.dbo.tbl_GAP_NEW_HCC_RAPS_PartD_Aetna -- 18748
select * into ProdSupport.dbo.tbl_GAP_NEW_HCC_EDS_PartD_Aetna_Run2 from ProdSupport.dbo.tbl_GAP_NEW_HCC_EDS_PartD_Aetna -- 11836

------------------



select * into #InRAPSNotInEDS 
from
(
select hicn, hcc from ProdSupport.dbo.tbl_GAP_NEW_HCC_RAPS_PartC_Aetna
except
select hicn, hcc from ProdSupport.dbo.tbl_GAP_NEW_HCC_EDS_PartC_Aetna
) a

select * into #InEDSNotInRAPS
from
(
select hicn, hcc from ProdSupport.dbo.tbl_GAP_NEW_HCC_EDS_PartC_Aetna where HCC <> 'HCC 138'
except
select hicn, hcc from ProdSupport.dbo.tbl_GAP_NEW_HCC_RAPS_PartC_Aetna 
) a

select * from #InRAPSNotInEDS
select * from #InEDSNotInRAPS


1A61NG8KR80	HCC 52

select * from ProdSupport.dbo.tbl_GAP_Diags_Add where HICN = '1A61NG8KR80'

select * from ProdSupport.dbo.tbl_GAP_NEW_HCC_RAPS_PartC_Aetna where hicn = '1A61NG8KR80'
select * from ProdSupport.dbo.tbl_GAP_NEW_HCC_EDS_PartC_Aetna where hicn = '1A61NG8KR80'

select * from ProdSupport.dbo.tbl_GAP_All_Diags_RAPS_PartC_Aetna where hicn = '1A61NG8KR80' order by HCC
select * from ProdSupport.dbo.tbl_GAP_All_Diags_EDS_PartC_Aetna where hicn = '1A61NG8KR80' order by HCC

select * from Aetna_Report.dbo.RAPS_DiagHCC_rollup where hicn = '1A61NG8KR80' and Accepted = 1 and Deleted is NULL and YEAR(ThruDate) = '2019'
select * from AetIH_Report.dbo.RAPS_DiagHCC_rollup where hicn = '1A61NG8KR80' and Accepted = 1 and Deleted is NULL and YEAR(ThruDate) = '2019'

select * from Aetna_Report.[rev].[tbl_Summary_RskAdj_EDS_Source] where hicn = '1A61NG8KR80' and YEAR(ServiceEndDate) = '2019'
select * from AetIH_Report.[rev].[tbl_Summary_RskAdj_EDS_Source] where hicn = '1A61NG8KR80' and YEAR(ServiceEndDate) = '2019'

select * from ReportingETL.[HRP\hasan.farooqui].AETGapCheck_002d_RAPS_Source where hicn = '1A61NG8KR80' and Accepted = 1 and Deleted is null

select distinct HICN from ProdSupport.dbo.tbl_GAP_NEW_HCC_RAPS_PartC_Aetna --10608
except --2589
select distinct HICN from ProdSupport.dbo.tbl_GAP_NEW_HCC_EDS_PartC_Aetna --8655


select distinct HICN, HCC from ProdSupport.dbo.tbl_GAP_NEW_HCC_RAPS_PartC_Aetna --18961
--except --5823
intersect --13138
select distinct HICN, HCC from ProdSupport.dbo.tbl_GAP_NEW_HCC_EDS_PartC_Aetna --15235

select * 
from
	HRPReporting.dbo.lk_Risk_Models_DiagHCC_ICD10 B  (nolock)  
where  
	B.Payment_Year in (2018) 
	and ICD10CD = 'F0390'

select * 
from
	HRPReporting.dbo.lk_Risk_Models_DiagHCC_ICD10 B  (nolock)  
where  
	B.Payment_Year in (2020) 
	and ICD10CD = 'F0390'

select HICN, HCC from ProdSupport.dbo.tbl_Delete_New_HCC_EDS_PartC_Aetna
intersect
select HICN, HCC from ProdSupport.dbo.tbl_Delete_New_HCC_RAPS_PartC_Aetna

select HICN, HCC from ProdSupport.dbo.tbl_Delete_New_HCC_RAPS_PartC_Aetna
except
select HICN, HCC from ProdSupport.dbo.tbl_Delete_New_HCC_EDS_PartC_Aetna

select HICN, HCC from ProdSupport.dbo.tbl_Delete_New_HCC_EDS_PartC_Aetna
except
select HICN, HCC from ProdSupport.dbo.tbl_Delete_New_HCC_RAPS_PartC_Aetna

1DM2HX1CM87	HCC 111
1CU4HX7KX72	HCC 108
1DR1EG0KE15	HCC 12
1FW3J10XD88	HCC 87
1G66FP3KF49	HCC 85

select * from ProdSupport.dbo.tbl_GAP_Diags_Delete where HICN = '1DM2HX1CM87'

select * from ProdSupport.dbo.tbl_Delete_New_HCC_RAPS_PartC_Aetna where hicn = '1DM2HX1CM87'
select * from ProdSupport.dbo.tbl_Delete_NEW_HCC_EDS_PartC_Aetna where hicn = '1DM2HX1CM87'

select * from ProdSupport.dbo.tbl_Delete_All_Diags_RAPS_PartC_Aetna where hicn = '1DM2HX1CM87' order by HCC
select * from ProdSupport.dbo.tbl_Delete_All_Diags_EDS_PartC_Aetna where hicn = '1DM2HX1CM87' order by HCC

select * from Aetna_Report.dbo.RAPS_DiagHCC_rollup where hicn = '1DM2HX1CM87' and Accepted = 1 and Deleted is NULL and YEAR(ThruDate) = '2019' and DiagnosisCode = 'J439'
select * from AetIH_Report.dbo.RAPS_DiagHCC_rollup where hicn = '1DM2HX1CM87' and Accepted = 1 and Deleted is NULL and YEAR(ThruDate) = '2019' and DiagnosisCode = 'J439'

select * from Aetna_Report.[rev].[tbl_Summary_RskAdj_EDS_Source] where hicn = '1DM2HX1CM87' and YEAR(ServiceEndDate) = '2019' and DiagnosisCode = 'J439'

select * from ReportingETL.[HRP\hasan.farooqui].AETGapCheck_002e_EDS_Source where FinalHICN = '1DM2HX1CM87' and RiskAdjustable = 1 and DiagnosisCode = 'J439'


select count(1) 
from ProdSupport.dbo.tbl_GAP_NEW_HCC_RAPS_PartC_Aetna 
where HeirHCC is null
and hcc like 'HCC%'

select count(1) 
from ProdSupport.dbo.tbl_GAP_NEW_HCC_RAPS_PartC_Aetna 
where HeirHCC is not null


select count(1) from ProdSupport.dbo.tbl_GAP_NEW_HCC_EDS_PartC_Aetna -- 16071

select count(1) from ProdSupport.dbo.tbl_GAP_NEW_HCC_RAPS_PartD_Aetna -- 18706
select count(1) from ProdSupport.dbo.tbl_GAP_NEW_HCC_EDS_PartD_Aetna -- 11805



select finalhicn HICN
into #HICHNotinRAPS
from
(
select distinct FinalHICN from ReportingETL.[HRP\hasan.farooqui].AETGapCheck_002e_EDS_Source
except--3329
select distinct FinalHICN from ReportingETL.[HRP\hasan.farooqui].AETGapCheck_002d_RAPS_Source
) a

select * from ReportingETL.[HRP\hasan.farooqui].AETGapCheck_002e_EDS_Source a, #HICHNotinRAPS b where a.FinalHICN = b.HICN

select distinct a.HICN from Aetna_Report.rev.[tbl_Summary_RskAdj_EDS_Source] a, #HICHNotinRAPS b where a.HICN = b.HICN
and VendorID = 'Cotiviti'

select distinct a.HICN from Aetna_Report.rev.[tbl_Summary_RskAdj_EDS_Source] a, #HICHNotinRAPS b where a.HICN = b.HICN
and ReplacementEncounterSwitch >= 4


select distinct FinalHICN from ReportingETL.[HRP\hasan.farooqui].AETGapCheck_002d_RAPS_Source
except--31
select distinct FinalHICN from ReportingETL.[HRP\hasan.farooqui].AETGapCheck_002e_EDS_Source


select HICN, HCC from ProdSupport.dbo.tbl_Delete_New_HCC_EDS_PartD_Aetna
intersect
select HICN, HCC from ProdSupport.dbo.tbl_Delete_New_HCC_RAPS_PartD_Aetna

select HICN, HCC from ProdSupport.dbo.tbl_Delete_New_HCC_RAPS_PartD_Aetna
except
select HICN, HCC from ProdSupport.dbo.tbl_Delete_New_HCC_EDS_PartD_Aetna

select HICN, HCC from ProdSupport.dbo.tbl_Delete_New_HCC_EDS_PartD_Aetna
except
select HICN, HCC from ProdSupport.dbo.tbl_Delete_New_HCC_RAPS_PartD_Aetna

1DM2HX1CM87	HCC187
1DM2HX1CM87	HCC193
1DR1EG0KE15	HCC188

select * from ProdSupport.dbo.tbl_GAP_Diags_Delete where HICN = '1DM2HX1CM87'

select * from ProdSupport.dbo.tbl_Delete_New_HCC_RAPS_PartD_Aetna where hicn = '1DM2HX1CM87'
select * from ProdSupport.dbo.tbl_Delete_NEW_HCC_EDS_PartD_Aetna where hicn = '1DM2HX1CM87'

select * from ProdSupport.dbo.tbl_Delete_All_Diags_RAPS_PartD_Aetna where hicn = '1DM2HX1CM87' order by HCC
select * from ProdSupport.dbo.tbl_Delete_All_Diags_EDS_PartD_Aetna where hicn = '1DM2HX1CM87' order by HCC

select * from Aetna_Report.dbo.RAPS_DiagHCC_rollup where hicn = '1DM2HX1CM87' and Accepted = 1 and Deleted is NULL and YEAR(ThruDate) = '2019' and DiagnosisCode = 'J439'
select * from AetIH_Report.dbo.RAPS_DiagHCC_rollup where hicn = '1DM2HX1CM87' and Accepted = 1 and Deleted is NULL and YEAR(ThruDate) = '2019' and DiagnosisCode = 'J439'

select * from Aetna_Report.[rev].[tbl_Summary_RskAdj_EDS_Source] where hicn = '1DM2HX1CM87' and YEAR(ServiceEndDate) = '2019' and DiagnosisCode in ('I471','I471')

select * from ReportingETL.[HRP\hasan.farooqui].AETGapCheck_002e_EDS_Source where FinalHICN = '1DM2HX1CM87' and RiskAdjustable = 1 and DiagnosisCode = 'J439'

-------------------------------------
-- Aetna Starts Here
-------------------------------------

select distinct MemberNumber from ProdSupport.dbo.hst_AETGapCheck_000a_Source where RunID = 9
and FinalMemberNumber <> MemberNumber



--Part C Adds
Select ImpactType = CAST('Add' as varchar(10)), * from ProdSupport.dbo.hst_AETGapCheck_003a_RAPS_PartC_ADDs where RunID in (9)
union
select ImpactType = CAST('Add' as varchar(10)), * from ProdSupport.dbo.hst_AETGapCheck_003b_EDS_PartC_ADDs where RunID in (9)



--Part C Deletes
Select ImpactType = CAST('Delete' as varchar(10)), * from ProdSupport.dbo.hst_AETGapCheck_004a_RAPS_PartC_Deletes where RunID in (9)
union
select ImpactType = CAST('Delete' as varchar(10)), * from ProdSupport.dbo.hst_AETGapCheck_004b_EDS_PartC_Deletes where RunID in (9)





--Part D Adds
Select ImpactType = CAST('Add' as varchar(10)), * from ProdSupport.dbo.hst_AETGapCheck_003c_RAPS_PartD_ADDs where RunID in (9)
union
select ImpactType = CAST('Add' as varchar(10)), * from ProdSupport.dbo.hst_AETGapCheck_003d_EDS_PartD_ADDs where RunID in (9)



--Part D Deletes
Select ImpactType = CAST('Delete' as varchar(10)), * from ProdSupport.dbo.hst_AETGapCheck_004c_RAPS_PartD_Deletes where RunID in (9)
union
select ImpactType = CAST('Delete' as varchar(10)), * from ProdSupport.dbo.hst_AETGapCheck_004d_EDS_PartD_Deletes where RunID in (9)



-----------------------------------

Select ImpactType = CAST('Add' as varchar(10)), * from ProdSupport.dbo.hst_AETGapCheck_003a_RAPS_PartC_ADDs where RunID in (9)
union
select ImpactType = CAST('Add' as varchar(10)), * from ProdSupport.dbo.hst_AETGapCheck_003b_EDS_PartC_ADDs where RunID in (9)


drop table #MOR_RAPS
select distinct hicn, RAFT, factor_description hcc, HCC_Number
into #MOR_RAPS
from Aetna_Report.[rev].[tbl_Summary_RskAdj_MOR]
where paymentYear = 2020
and SubmissionModel = 'RAPS'
and PaymStart >= '8/1/2020'
and hicn in (select hicn from ProdSupport.dbo.tbl_GAP_NEW_HCC_RAPS_PartC_AetnaTest)

insert into #MOR_RAPS
select distinct hicn, RAFT, factor_description hcc, HCC_Number
from AetIH_Report.[rev].[tbl_Summary_RskAdj_MOR]
where paymentYear = 2020
and SubmissionModel = 'RAPS'
and PaymStart >= '8/1/2020'
and hicn in (select hicn from ProdSupport.dbo.tbl_GAP_NEW_HCC_RAPS_PartC_AetnaTest)

drop table #MOR_EDS
select distinct hicn, RAFT, factor_description hcc, HCC_Number
into #MOR_EDS
from Aetna_Report.[rev].[tbl_Summary_RskAdj_MOR]
where paymentYear = 2020
and SubmissionModel = 'EDS'
and PaymStart >= '8/1/2020'
and hicn in (select hicn from ProdSupport.dbo.tbl_GAP_NEW_HCC_EDS_PartC_AetnaTest)

insert into #MOR_EDS
select distinct hicn, RAFT, factor_description hcc, HCC_Number
from AetIH_Report.[rev].[tbl_Summary_RskAdj_MOR]
where paymentYear = 2020
and SubmissionModel = 'EDS'
and PaymStart >= '8/1/2020'
and hicn in (select hicn from ProdSupport.dbo.tbl_GAP_NEW_HCC_EDS_PartC_AetnaTest)


select hicn, hcc from ProdSupport.dbo.tbl_GAP_NEW_HCC_RAPS_PartC_AetnaTest a
where not exists (select 1 from #mor_raps b where a.hicn = b.hicn and a.HCC_Number = b.HCC_Number)
except
Select hicn, hcc from ProdSupport.dbo.hst_AETGapCheck_003a_RAPS_PartC_ADDs where RunID in (9)

1A61NG8KR80	HCC 10
1AH1UP9RP36	HCC 19

Select hicn, hcc from ProdSupport.dbo.hst_AETGapCheck_003a_RAPS_PartC_ADDs where RunID in (9)
except
select hicn, hcc from ProdSupport.dbo.tbl_GAP_NEW_HCC_RAPS_PartC_AetnaTest a
where not exists (select 1 from #mor_raps b where a.hicn = b.hicn and a.HCC_Number = b.HCC_Number)


select hicn, hcc from ProdSupport.dbo.tbl_GAP_NEW_HCC_EDS_PartC_AetnaTest a
where not exists (select 1 from #mor_eds b where a.hicn = b.hicn and a.HCC_Number = b.HCC_Number)
except
select hicn, hcc from ProdSupport.dbo.hst_AETGapCheck_003b_EDS_PartC_ADDs where RunID in (9)

-- This look good

select hicn, hcc from ProdSupport.dbo.hst_AETGapCheck_003b_EDS_PartC_ADDs where RunID in (9)
except
select hicn, hcc from ProdSupport.dbo.tbl_GAP_NEW_HCC_EDS_PartC_AetnaTest a
where not exists (select 1 from #mor_eds b where a.hicn = b.hicn and a.HCC_Number = b.HCC_Number)


1A61NG8KR80	HCC 35
1A83GC9KP70	HCC 19
1AJ9YP4YV42	HCC 108
1AM2GC3HP19	HCC 18
1AN2P07PH05	HCC 135
1EQ5YR9FW80	HCC 23
1EW8G05CR69	HCC 22

select * from ProdSupport.dbo.hst_AETGapCheck_000a_Source where RunID = 9
and finalmembernumber = '1A61NG8KR80'

select * from [AetIH_Report].[rev].[tbl_Summary_RskAdj_MMR] where hicn = '1A61NG8KR80' and paymentyear = 2020

select distinct hicn, Factor_Description, HCC_Number from [AetIH_Report].[rev].[tbl_Summary_RskAdj_MOR] where hicn = '1A61NG8KR80' and paymentyear = 2020
and SubmissionModel = 'RAPS'
and PaymStart >= '8/1/2020'
and PaymentYear = 2020
and Factor_Description is not null
order by HCC_Number

select distinct hicn, Factor_Description, HCC_Number from [AetIH_Report].[rev].[tbl_Summary_RskAdj_MOR] where hicn = '1A61NG8KR80' and paymentyear = 2020
and SubmissionModel = 'EDS'
and PaymStart >= '8/1/2020'
and PaymentYear = 2020
and Factor_Description is not null
order by HCC_Number

select * from ProdSupport.dbo.tbl_GAP_NEW_HCC_RAPS_PartC_AetnaTest where hicn = '1A61NG8KR80'
select * from ProdSupport.dbo.tbl_GAP_NEW_HCC_EDS_PartC_AetnaTest where hicn = '1A61NG8KR80'

select * from ProdSupport.dbo.tbl_GAP_All_Diags_RAPS_PartC_AetnaTest where hicn = '1A61NG8KR80' order by HCC
select * from ProdSupport.dbo.tbl_GAP_All_Diags_EDS_PartC_AetnaTest where hicn = '1A61NG8KR80' order by HCC

select * from Aetna_Report.dbo.RAPS_DiagHCC_rollup where hicn = '1A61NG8KR80' and Accepted = 1 and Deleted is NULL and YEAR(ThruDate) = '2019'
select * from AetIH_Report.dbo.RAPS_DiagHCC_rollup where hicn = '1A61NG8KR80' and Accepted = 1 and Deleted is NULL and YEAR(ThruDate) = '2019'

select * from Aetna_Report.[rev].[tbl_Summary_RskAdj_EDS_Source] where hicn = '1A61NG8KR80' and YEAR(ServiceEndDate) = '2019'
select * from AetIH_Report.[rev].[tbl_Summary_RskAdj_EDS_Source] where hicn = '1A61NG8KR80' and YEAR(ServiceEndDate) = '2019'

select * from ProdSupport.dbo.EDSSource_AetnaTest where hicn = '1A61NG8KR80' and YEAR(ThroughDateofService) = '2019'

Select hicn, hcc from ProdSupport.dbo.hst_AETGapCheck_003a_RAPS_PartC_ADDs where RunID in (9) and hicn = '1A61NG8KR80'
select hicn, hcc from ProdSupport.dbo.hst_AETGapCheck_003b_EDS_PartC_ADDs where RunID in (9) and hicn = '1A61NG8KR80'

select hicn, hcc from ProdSupport.dbo.tbl_GAP_NEW_HCC_RAPS_PartC_AetnaTest a
where not exists (select 1 from #mor_raps b where a.hicn = b.hicn and a.HCC_Number = b.HCC_Number)
and hicn = '1A61NG8KR80'

select hicn, hcc from ProdSupport.dbo.tbl_GAP_NEW_HCC_EDS_PartC_AetnaTest a
where not exists (select 1 from #mor_raps b where a.hicn = b.hicn and a.HCC_Number = b.HCC_Number)
and hicn = '1A61NG8KR80'

select 
	hicn, 
	hcc, 
	cast (LTRIM(REVERSE(LEFT(REVERSE(hcc), PATINDEX('%[A-Z]%',REVERSE(hcc)) - 1))) as int) hcc_number
from 
	ProdSupport.dbo.tbl_GAP_NEW_HCC_EDS_PartC_AetnaTest


select * from HRPReporting.dbo.lk_Risk_Models_Hierarchy
where Payment_Year = 2020
and (HCC_KEEP_NUMBER = 88 or HCC_DROP_NUMBER = 88)



select * from ProdSupport.dbo.AETGapCheck_002e_EDS_Source
where runid = 9
