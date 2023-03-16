--drop table ProdSupport.dbo.EDSSource_AetnaTest
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
into ProdSupport.dbo.EDSSource_AetnaTest
from
	[Aetna_ClientRepo].[dbo].[MAO004Response] MAO,
	[Aetna_ClientRepo].[dbo].[MAO004ResponseDiagnosisCode] Diag
where
	MAO.MAO004ResponseID = diag.MAO004ResponseID
	and MAO.BeneficiaryIdentifier in (select FinalMemberNumber from ProdSupport.dbo.hst_AETGapCheck_000a_Source where RunID = 9)
	and AllowedDisallowedFlagRiskAdjustment = 'A'

select * from ProdSupport.dbo.EDSSource_AetnaTest

drop table #MMR
select distinct m.HICN, m.PartCRAFTProjected RAFactorType, m.PlanID
into #MMR
from 
	[Aetna_Report].[rev].[tbl_Summary_RskAdj_MMR] m,
	ProdSupport.dbo.hst_AETGapCheck_000a_Source a
where 
	RunID = 9
	and a.FinalMemberNumber = m.hicn
	and m.PaymentYear = 2020

insert into #MMR
select distinct m.HICN, m.PartCRAFTProjected RAFactorType, m.PlanID
from 
	[AetIH_Report].[rev].[tbl_Summary_RskAdj_MMR] m,
	ProdSupport.dbo.hst_AETGapCheck_000a_Source a
where 
	RunID = 9
	and a.FinalMemberNumber = m.hicn
	and m.PaymentYear = 2020

/**********************************************************************************
Get Source Gap data and populate it into temp ProdSupport table
**********************************************************************************/

drop table if exists ProdSupport.dbo.tbl_AetnaTest_GAP_Diags_Add 

select 
	left(DOSEnd, 4) as DOS_year,
	MemberNumber as MBI,
	FinalMemberNumber as HICN,
	DiagnosisCode,
	DOSStart,
	DOSEnd,
	ProviderType
into ProdSupport.dbo.tbl_AetnaTest_GAP_Diags_Add 
from ProdSupport.dbo.hst_AETGapCheck_000a_Source
where RunID = 9 and Status = 'A'


/**********************************************************************************
Diag HCC Mapping for 2020 PY
Use 2020 Model Year for EDS
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
Create ALL Diag table for population members and check eligibility with MMR

Use already created EDS Source table  - ProdSupport.[HRP\hasan.farooqui].AETGapCheck_002e_EDS_Source
Use already created MMR Source table - ProdSupport.[HRP\hasan.farooqui].AETGapCheck_002a_MMR

**********************************************************************************/
drop table if exists ProdSupport.dbo.tbl_GAP_All_Diags_EDS_PartC_AetnaTest

/**********************************************************************************
Insert all diagnoses from EDS Source table 
**********************************************************************************/


-- truncate table ProdSupport.dbo.tbl_GAP_All_Diags_EDS_PartC_AetnaTest

-- insert into ProdSupport.dbo.tbl_GAP_All_Diags_EDS_PartC_AetnaTest
select distinct 
	EncounterSource = 'EDS', 
	PaymentYear = YEAR(ThroughDateofService) + 1, 
	a.HICN, 
	FromDate = FromDateofService, 
	ThruDate = ThroughDateofService, 
	DiagnosisCode, 
	ProviderType = '',
	HCC = lk.HCC_Label,
	'N' IsAdded,
	m.RAFactorType,
	m.PlanID
--into ProdSupport.dbo.tbl_GAP_All_Diags_EDS_PartC_AetnaTest
from ProdSupport.dbo.EDSSource_AetnaTest a
	inner join #MMR m
	on a.HICN = m.hicn
	left join #Diag_HCC_Lookup lk
	on a.DiagnosisCode = lk.ICD10CD
    AND lk.Payment_Year = 2020
	and m.RAFactorType = lk.Factor_Type
where YEAR(ThroughDateofService) = 2019 
	and AllowedDisallowedFlagRiskAdjustment = 'A'
	and AddOrDeleteFlag = 'A'
	and a.HICN in (select HICN from ProdSupport.dbo.tbl_AetnaTest_GAP_Diags_Add)

/**********************************************************************************
insert all Add diagnoses from Extract file
**********************************************************************************/

insert into ProdSupport.dbo.tbl_GAP_All_Diags_EDS_PartC_AetnaTest
select distinct 
	'EDS', 
	YEAR(DOSEnd) + 1, 	
	a.HICN, 
	DOSStart, 
	DOSEnd, 
	DiagnosisCode,
	'' ProviderType,
	HCC = lk.HCC_Label,
	'Y' as IsAdded,
	m.RAFactorType,
	m.PlanID
from 
	ProdSupport.dbo.tbl_AetnaTest_GAP_Diags_Add a 
	inner join #MMR m
	on a.HICN = m.hicn
	left join #Diag_HCC_Lookup lk
	on a.DiagnosisCode = lk.ICD10CD
    AND lk.Payment_Year = 2020
	and m.RAFactorType = lk.Factor_Type
where a.DOS_year = 2019 


/**********************************************************************************
Get all New HCC that do not exist in current diag list
**********************************************************************************/

drop table if exists ProdSupport.dbo.tbl_GAP_ALL_NEW_HCC_EDS_PartC_AetnaTest

--truncate table ProdSupport.dbo.tbl_GAP_ALL_NEW_HCC_EDS_PartC_AetnaTest

--insert into ProdSupport.dbo.tbl_GAP_ALL_NEW_HCC_EDS_PartC_AetnaTest
select distinct 
	PaymentYear, 
	HICN, 
	HCC, 
	Hierarchy = CAST(NULL as varchar(1)), 
	HeirHCC = CAST(NULL as varchar(10)), 
	PlanID,
	RAFactorType
--into ProdSupport.dbo.tbl_GAP_ALL_NEW_HCC_EDS_PartC_AetnaTest
from 
	ProdSupport.dbo.tbl_GAP_All_Diags_EDS_PartC_AetnaTest
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
	ProdSupport.dbo.tbl_GAP_All_Diags_EDS_PartC_AetnaTest
where 
	HCC is not null 
	and IsAdded = 'N'


/**********************************************************************************
Apply Hierarchy
**********************************************************************************/

UPDATE A
SET Hierarchy = 'L'
FROM ProdSupport.dbo.tbl_GAP_ALL_NEW_HCC_EDS_PartC_AetnaTest A
WHERE 
	EXISTS
    (SELECT 1
		from ProdSupport.dbo.tbl_GAP_All_Diags_EDS_PartC_AetnaTest B
		JOIN HRPReporting.dbo.lk_Risk_Models_Hierarchy C
            ON A.HICN = B.HICN
               AND B.HCC = C.HCC_KEEP
               AND A.HCC = C.HCC_DROP
               AND C.Payment_Year = B.PaymentYear
               AND C.RA_FACTOR_TYPE = B.RAFactorType
        where IsAdded = 'N'
	)

UPDATE A
SET Hierarchy = 'L'
FROM ProdSupport.dbo.tbl_GAP_ALL_NEW_HCC_EDS_PartC_AetnaTest A
WHERE 
	EXISTS
    (SELECT 1
		from ProdSupport.dbo.tbl_GAP_ALL_NEW_HCC_EDS_PartC_AetnaTest B
		JOIN HRPReporting.dbo.lk_Risk_Models_Hierarchy C
            ON A.HICN = B.HICN
               AND B.HCC = C.HCC_KEEP
               AND A.HCC = C.HCC_DROP
               AND C.Payment_Year = B.PaymentYear
               AND C.RA_FACTOR_TYPE = B.RAFactorType
	)

UPDATE A
SET Hierarchy = 'H'
FROM ProdSupport.dbo.tbl_GAP_ALL_NEW_HCC_EDS_PartC_AetnaTest A
WHERE Hierarchy is null
AND	EXISTS
    (SELECT 1
		from ProdSupport.dbo.tbl_GAP_All_Diags_EDS_PartC_AetnaTest B
		JOIN HRPReporting.dbo.lk_Risk_Models_Hierarchy C
            ON A.HICN = B.HICN
               AND A.HCC = C.HCC_KEEP
               AND B.HCC = C.HCC_DROP
               AND C.Payment_Year = B.PaymentYear
               AND C.RA_FACTOR_TYPE = B.RAFactorType
        where IsAdded = 'N'
	)

drop table if exists #HierHCC

select distinct a.PaymentYear, a.HICN, a.HCC, b.HCC HierHCC, RANK() over (partition by a.hicn, a.hcc order by b.hcc) rnk
into #HierHCC
from 
      ProdSupport.dbo.tbl_GAP_ALL_NEW_HCC_EDS_PartC_AetnaTest a
      join ProdSupport.dbo.tbl_GAP_All_Diags_EDS_PartC_AetnaTest b
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
from ProdSupport.dbo.tbl_GAP_ALL_NEW_HCC_EDS_PartC_AetnaTest a
join #HierHCC b
on a.HICN = b.HICN
and a.HCC = b.HCC
and a.PaymentYear = b.PaymentYear
and b.rnk = 1

/**********************************************************************************
Final list of New HCC after filtering out lower Hierarchy HCC
Final New HCC table - ProdSupport.dbo.tbl_GAP_NEW_HCC_EDS_PartC_AetnaTest
**********************************************************************************/

drop table if exists ProdSupport.dbo.tbl_GAP_NEW_HCC_EDS_PartC_AetnaTest

--truncate table ProdSupport.dbo.tbl_GAP_NEW_HCC_EDS_PartC_AetnaTest
insert into ProdSupport.dbo.tbl_GAP_NEW_HCC_EDS_PartC_AetnaTest
select distinct
	a.PaymentYear, 
	a.HICN, 
	a.HCC, 
	a.HeirHCC
--into ProdSupport.dbo.tbl_GAP_NEW_HCC_EDS_PartC_AetnaTest
from
	ProdSupport.dbo.tbl_GAP_ALL_NEW_HCC_EDS_PartC_AetnaTest a
Where
	a.Hierarchy is NULL or a.Hierarchy = 'H'


/**********************************************************************************
Add Interaction 
**********************************************************************************/

drop table if exists #tbl_GAP_All_HCC_EDS_PartC_AetnaTest

select distinct PaymentYear, HICN, HCC, RAFactorType, IsAdded 
into #tbl_GAP_All_HCC_EDS_PartC_AetnaTest
from ProdSupport.dbo.tbl_GAP_All_Diags_EDS_PartC_AetnaTest
where HCC is not null

-- Interaction before Newly added HCC
drop table if exists #tbl_GAP_All_INT_EDS_PartC_AetnaTest

select distinct
	a.PaymentYear,
	a.HICN,
	i.Interaction_Label HCC,
	a.RAFactorType
into #tbl_GAP_All_INT_EDS_PartC_AetnaTest
from 
	HRPReporting.dbo.lk_Risk_Models_Interactions i
	join #tbl_GAP_All_HCC_EDS_PartC_AetnaTest a
	on	a.RAFactorType = i.Factor_Type
	and a.HCC = i.HCC_Label_1
	join #tbl_GAP_All_HCC_EDS_PartC_AetnaTest b
	on	b.RAFactorType = i.Factor_Type
	and b.HCC = i.HCC_Label_2
	and a.HICN = b.HICN
	join #tbl_GAP_All_HCC_EDS_PartC_AetnaTest c
	on  c.RAFactorType = i.Factor_Type
	and c.HCC = i.HCC_Label_3
	and a.HICN = c.HICN
	and b.HICN = c.HICN
where i.Payment_Year = 2020
	and a.IsAdded = 'N'
	and b.IsAdded = 'N'
	and c.IsAdded = 'N'

-- Interaction after Newly added HCC

drop table if exists #tbl_GAP_NEW_INT_EDS_PartC_AetnaTest

select distinct
	a.PaymentYear,
	a.HICN,
	i.Interaction_Label HCC,
	a.RAFactorType
into #tbl_GAP_NEW_INT_EDS_PartC_AetnaTest
from 
	HRPReporting.dbo.lk_Risk_Models_Interactions i
	join #tbl_GAP_All_HCC_EDS_PartC_AetnaTest a
	on	a.RAFactorType = i.Factor_Type
	and a.HCC = i.HCC_Label_1
	join #tbl_GAP_All_HCC_EDS_PartC_AetnaTest b
	on	b.RAFactorType = i.Factor_Type
	and b.HCC = i.HCC_Label_2
	and a.HICN = b.HICN
	join #tbl_GAP_All_HCC_EDS_PartC_AetnaTest c
	on  c.RAFactorType = i.Factor_Type
	and c.HCC = i.HCC_Label_3
	and a.HICN = c.HICN
	and b.HICN = c.HICN
where i.Payment_Year = 2020

/**********************************************************************************
New Interaction triggered by New HCC
**********************************************************************************/
insert into ProdSupport.dbo.tbl_GAP_NEW_HCC_EDS_PartC_AetnaTest
select Distinct
	PaymentYear,
	HICN,
	HCC,
	NULL HeirHCC
from
(
select PaymentYear, HICN, HCC from #tbl_GAP_NEW_INT_EDS_PartC_AetnaTest
except
select PaymentYear, HICN, HCC from #tbl_GAP_All_INT_EDS_PartC_AetnaTest
) a

/**********************************************************************************
 Final list of New HCC with Intaction
 The records with Non NULL HierHCC means they are partially impacted
**********************************************************************************/

select * from ProdSupport.dbo.tbl_GAP_NEW_HCC_EDS_PartC_AetnaTest


alter table ProdSupport.dbo.tbl_GAP_NEW_HCC_EDS_PartC_AetnaTest add HCC_Number int

update ProdSupport.dbo.tbl_GAP_NEW_HCC_EDS_PartC_AetnaTest
set HCC_Number = cast (LTRIM(REVERSE(LEFT(REVERSE(hcc), PATINDEX('%[A-Z]%',REVERSE(hcc)) - 1))) as int)











