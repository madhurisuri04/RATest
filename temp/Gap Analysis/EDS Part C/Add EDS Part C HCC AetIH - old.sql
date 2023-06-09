/**********************************************************************************
Get Source Gap data and populate it into temp prodsupport table
**********************************************************************************/

drop table if exists ProdSupport.dbo.tbl_GAP_Diags_Add 

select 
	left(DOSEnd, 4) as DOS_year,
	MemberNumber as MBI,
	FinalMemberNumber as HICN,
	DiagnosisCode,
	DOSStart,
	DOSEnd,
	ProviderType
into ProdSupport.dbo.tbl_GAP_Diags_Add 
from ReportingETL.[HRP\hasan.farooqui].AETGapCheck_000a_Source
where RunID = 1 and Status = 'A'


/**********************************************************************************
Diag HCC Mapping for 2020 PY
**********************************************************************************/

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
	B.Payment_Year in (2020) 
	and b.Factor_Type not in ('E','E1','E2','SE','ED')

select * from #Diag_HCC_Lookup


/**********************************************************************************
Combine with MMR
Get enrollment info and only perform analysis for eligible members
**********************************************************************************/

--Get Add Members from MMR

drop table if exists ProdSupport.dbo.Temp_SummaryMMR_AetIH
select 
	PaymentYear, 
	HICN, 
	PartCRaftMMR,
	min(PartDRaftMMR) PartDRaftMMR, 
	max(PaymStart) PaymStart,
	max(PlanID) PlanID,
	count(distinct PaymStart) PaymentMonths 
into ProdSupport.dbo.Temp_SummaryMMR_AetIH
from 
	AetIH_report.rev.tbl_Summary_RskAdj_MMR (nolock)
where 
	HICN in (select HICN from ProdSupport.dbo.tbl_GAP_Diags_Add) 
	and PaymentYear in (2020) -- Payment Year Parameter
group by 
	PaymentYear, 
	HICN, 
	PartCRaftMMR


--select * from ProdSupport.dbo.Temp_SummaryMMR_AetIH


/**********************************************************************************
Combine with other HCC records and join with MMR
**********************************************************************************/

--Get all diagnoses from EDS
drop table if exists ProdSupport.dbo.tbl_GAP_All_Diags_EDS_PartC_AetIH

truncate table ProdSupport.dbo.tbl_GAP_All_Diags_EDS_PartC_AetIH

insert into ProdSupport.dbo.tbl_GAP_All_Diags_EDS_PartC_AetIH
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
into ProdSupport.dbo.tbl_GAP_All_Diags_EDS_PartC_AetIH
from AetIH_Report.rev.[tbl_Summary_RskAdj_EDS_Source] a
	inner join ProdSupport.dbo.Temp_SummaryMMR_AetIH m
	on a.hicn = m.hicn
	left join #Diag_HCC_Lookup lk
	on a.DiagnosisCode = lk.ICD10CD
    AND m.PaymentYear = lk.Payment_Year
	and m.PartCRAFTMMR = lk.Factor_Type
where year([ServiceEndDate]) = '2019' -- DOS Year parameter 
and [SentEncounterRiskAdjustableFlag] = 'A' and [IsDelete] is null



--Add all diagnoses from Adds
insert into ProdSupport.dbo.tbl_GAP_All_Diags_EDS_PartC_AetIH
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


--Get New HCCs generated by Add file
drop table if exists ProdSupport.dbo.tbl_GAP_All_Diags_EDS_PartC_HCC_AetIH

truncate table ProdSupport.dbo.tbl_GAP_All_Diags_EDS_PartC_HCC_AetIH

insert into ProdSupport.dbo.tbl_GAP_All_Diags_EDS_PartC_HCC_AetIH
select distinct 
	PaymentYear, 
	HICN, 
	HCC, 
	Hierarchy = CAST(NULL as varchar(1)), 
	HeirHCC = CAST(NULL as varchar(10)), 
	PlanID,
	RAFactorType
into ProdSupport.dbo.tbl_GAP_All_Diags_EDS_PartC_HCC_AetIH
from 
	ProdSupport.dbo.tbl_GAP_All_Diags_EDS_PartC_AetIH
where 
	HCC is not null 
	and IsAdded = 'Y'
Except
select distinct 
	PaymentYear, 
	HICN, 
	HCC, 
	NULL, 
	NULL,
	PlanID,
	RAFactorType
from 
	ProdSupport.dbo.tbl_GAP_All_Diags_EDS_PartC_AetIH
where 
	HCC is not null 
	and IsAdded = 'N'


--Apply Heirarchy

UPDATE A
SET Hierarchy = 'L'
FROM ProdSupport.dbo.tbl_GAP_All_Diags_EDS_PartC_HCC_AetIH A
WHERE 
	EXISTS
    (SELECT 1
		from ProdSupport.dbo.tbl_GAP_All_Diags_EDS_PartC_AetIH B
		JOIN HRPReporting.dbo.lk_Risk_Models_Hierarchy C
            ON A.HICN = B.HICN
               AND B.HCC = C.HCC_KEEP
               AND A.HCC = C.HCC_DROP
               AND A.PaymentYear = B.PaymentYear
               AND C.RA_FACTOR_TYPE = B.RAFactorType
        where IsAdded = 'N'
	)


UPDATE A
SET Hierarchy = 'H'
FROM ProdSupport.dbo.tbl_GAP_All_Diags_EDS_PartC_HCC_AetIH A
WHERE Hierarchy is null
AND	EXISTS
    (SELECT 1
		from ProdSupport.dbo.tbl_GAP_All_Diags_EDS_PartC_AetIH B
		JOIN HRPReporting.dbo.lk_Risk_Models_Hierarchy C
            ON A.HICN = B.HICN
               AND A.HCC = C.HCC_KEEP
               AND B.HCC = C.HCC_DROP
               AND A.PaymentYear = B.PaymentYear
               AND C.RA_FACTOR_TYPE = B.RAFactorType
        where IsAdded = 'N'
	)


drop table #HierHCC

select distinct a.PaymentYear, a.HICN, a.HCC, b.HCC HierHCC, RANK() over (partition by a.hicn, a.hcc order by b.hcc) rnk
into #HierHCC
from 
      ProdSupport.dbo.tbl_GAP_All_Diags_EDS_PartC_HCC_AetIH a
      join ProdSupport.dbo.tbl_GAP_All_Diags_EDS_PartC_AetIH b
      on a.PaymentYear = b.PaymentYear
      and a.HICN = b.HICN
      join HRPReporting.dbo.lk_Risk_Models_Hierarchy C
      on a.HCC = c.HCC_KEEP
      and b.HCC = c.HCC_DROP
      and b.PaymentYear = c.Payment_Year
      and b.RAFactorType = c.RA_FACTOR_TYPE 
where 
      a.Hierarchy = 'H'


update a
set 
	a.HeirHCC = b.HierHCC
from ProdSupport.dbo.tbl_GAP_All_Diags_EDS_PartC_HCC_AetIH a
join #HierHCC b
on a.HICN = b.HICN
and a.HCC = b.HCC
and a.PaymentYear = b.PaymentYear
and b.rnk = 1


/**********************************************************************************

**********************************************************************************/

drop table #temp
select	
	a.PaymentYear, 
	a.HICN, 
	a.HCC, 
	a.HeirHCC, 
	a.PlanID, 
	a.RAFactorType
into #temp
from
	ProdSupport.dbo.tbl_GAP_All_Diags_EDS_PartC_HCC_AetIH a
Where
	a.Hierarchy is NULL or a.Hierarchy = 'H'




--------------------------------------------



select loaddatetime, count(1) from AetIH_Report.[rev].[tbl_Summary_RskAdj_EDS_Preliminary]
where paymentYear = 2020
group by loaddatetime

select hicn, hcc from #temp
intersect
select hicn, hcc_label from AetIH_Report.[rev].[tbl_Summary_RskAdj_EDS_Preliminary]
where paymentYear = 2020
and RiskAdjustable = 1


select rafactortype, count(1) from #temp
group by rafactortype


select * from #Diag_HCC_Lookup



select hicn from ProdSupport.dbo.tbl_GAP_Diags_Add
except
select hicn from ProdSupport.dbo.Temp_SummaryMMR_AetIH


select hicn, hcc from #temp
intersect
select hicn, hcc 
from	ProdSupport.dbo.tbl_GAP_All_Diags_EDS_PartC_AetIH
where 
	HCC is not null 
	and IsAdded = 'N'

select * from AetIH_report.rev.tbl_Summary_RskAdj_MMR

--------------------------------------


