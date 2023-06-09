-- Run this in RQIRPTDBS904 and clone to other servers

/****** Script for SelectTopNRows command from SSMS  ******/
SELECT TOP 1000 [Payment Year]
      ,[Diagnosis Code]
      ,[Description]
      ,[CMS-HCC ESRD Model Category V21]
      ,[CMS-HCC Model Category V22]
      ,[CMS-HCC Model Category V23]
      ,[CMS-HCC Model Category V24]
      ,[RxHCC Model Category V05]
      ,[CMS-HCC ESRD Model Category V21 for Current Payment Year]
      ,[CMS-HCC Model Category V22 for Current Payment Year]
      ,[CMS-HCC Model Category V23 for Current Payment Year]
      ,[CMS-HCC Model Category V24 for Current Payment Year]
      ,[RxHCC Model Category V05 for Current Payment Year]
  FROM [ProdSupport].[dbo].[ICD-10-CM Mappings]

--select * into [ProdSupport].[dbo].[lkRiskModelsDiagHCC_bk] from [ProdSupport].[dbo].[lkRiskModelsDiagHCC]

 -- IsChronic calculation
drop table #HCC_Is_Chronic

select distinct HCC_Number, HCC_is_Chronic 
into #HCC_Is_Chronic
from  [HRPReporting].[dbo].[lk_Factors_PartC] 
where HCC_Label like 'HCC%'

insert into #HCC_Is_Chronic
select distinct HCC_Number, HCC_is_Chronic 
from  [HRPReporting].[dbo].[lk_Factors_PartD] d
where HCC_Label like 'HCC%'
and not exists (select 1 from #HCC_Is_Chronic c where c.HCC_Number = d.HCC_Number)


delete from #HCC_Is_Chronic
where HCC_is_Chronic is null
and HCC_Number in ('113','120','121','123','125','126','14','142','20','49','50','61','62','63','89','93')

delete from #HCC_Is_Chronic
where isnull(HCC_is_Chronic,9) <> 0
and HCC_Number in ('176','33','54','80','83')

delete from #HCC_Is_Chronic
where isnull(HCC_is_Chronic,9) <> 1
and HCC_Number in ('111', '112', '51','74','75','78')

delete from #HCC_Is_Chronic
where isnull(HCC_is_Chronic,9) <> 0
and HCC_Number in ('30','41','42','43','65','66','97','98','145','147','156','165','168','187')

delete from #HCC_Is_Chronic
where isnull(HCC_is_Chronic,9) <> 0
and HCC_Number in ('113','120','121','123','126','20')



drop table #PartCFactorTypes
select 'CN' FactorType into #PartCFactorTypes 
insert into #PartCFactorTypes select 'CP' 
insert into #PartCFactorTypes select 'CF' 
insert into #PartCFactorTypes select 'I' 


drop table #ESRDFactorTypes 
select 'C1' FactorType into #ESRDFactorTypes 
insert into #ESRDFactorTypes select 'C2' 
insert into #ESRDFactorTypes select 'I1' 
insert into #ESRDFactorTypes select 'I2' 
insert into #ESRDFactorTypes select 'D' 

drop table #RxFactorTypes 
select 'D1' FactorType into #RxFactorTypes 
insert into #RxFactorTypes select 'D2'
insert into #RxFactorTypes select 'D3'

-- Part C 
-- Version 22
INSERT INTO [dbo].[lkRiskModelsDiagHCC](
	[ICD10CD] 
	,[HCCLabel] 
	,[PaymentYear] 
	,[ModelVersion] 
	,[HCCNumber] 
	,[FactorType] 
	,[HCCIsChronic] 
	,[LoadID] 
	,[LoadDate] 
)
SELECT 
	[ICD10CD] = [Diagnosis Code]
	,[HCCLabel] = 'HCC ' + ltrim(rtrim(cast([CMS-HCC Model Category V22] as char)))
	,[PaymentYear] = a.[Payment Year]
	,[ModelVersion] = 22
	,[HCCNumber] = [CMS-HCC Model Category V22]
	,[FactorType] = c.RAFactorType
	,[HCCIsChronic] = b.HCC_is_Chronic
	,[LoadDate] = 0
	,[LoadDate] = GETDATE()
FROM 
	[ProdSupport].[dbo].[ICD-10-CM Mappings] a
	left join #HCC_Is_Chronic b
	on a.[CMS-HCC Model Category V22] = b.HCC_Number 
	join (
		select distinct PaymentYear, RAFactorType from dbo.[lkRiskModelsMaster]
		where ModelVersion = 22
		and rafactortype in (select FactorType from #PartCFactorTypes)
	) c
	on a.[Payment Year] = c.PaymentYear
WHERE 
	[CMS-HCC Model Category V22 for current Payment Year] = 'YES'


-- Version 23
INSERT INTO [dbo].[lkRiskModelsDiagHCC](
	[ICD10CD] 
	,[HCCLabel] 
	,[PaymentYear] 
	,[ModelVersion] 
	,[HCCNumber] 
	,[FactorType] 
	,[HCCIsChronic] 
	,[LoadID] 
	,[LoadDate] 
)
SELECT 
	[ICD10CD] = [Diagnosis Code]
	,[HCCLabel] = 'HCC ' + ltrim(rtrim(cast([CMS-HCC Model Category V23] as char)))
	,[PaymentYear] = a.[Payment Year]
	,[ModelVersion] = 23
	,[HCCNumber] = [CMS-HCC Model Category V23]
	,[Factor_Type] = c.RAFactorType
	,[HCCIsChronic] = b.HCC_is_Chronic
	,[LoadDate] = 0
	,[LoadDate] = GETDATE()
FROM 
	[ProdSupport].[dbo].[ICD-10-CM Mappings] a
	left join #HCC_Is_Chronic b
	on a.[CMS-HCC Model Category V23] = b.HCC_Number 
	join (
		select distinct PaymentYear, RAFactorType from dbo.[lkRiskModelsMaster]
		where ModelVersion = 23
		and rafactortype in (select FactorType from #PartCFactorTypes)
	) c
	on a.[Payment Year] = c.PaymentYear
WHERE 
	[CMS-HCC Model Category V23 for current Payment Year] = 'YES'

-- Version 24
INSERT INTO [dbo].[lkRiskModelsDiagHCC](
	[ICD10CD] 
	,[HCCLabel] 
	,[PaymentYear] 
	,[ModelVersion] 
	,[HCCNumber] 
	,[FactorType] 
	,[HCCIsChronic] 
	,[LoadID] 
	,[LoadDate] 
)
SELECT 
	[ICD10CD] = [Diagnosis Code]
	,[HCCLabel] = 'HCC ' + ltrim(rtrim(cast([CMS-HCC Model Category V24] as char)))
	,[PaymentYear] = a.[Payment Year]
	,[ModelVersion] = 24
	,[HCCNumber] = [CMS-HCC Model Category V24]
	,[FactorType] = c.RAFactorType
	,[HCCIsChronic] = b.HCC_is_Chronic
	,[LoadDate] = 0
	,[LoadDate] = GETDATE()
FROM 
	[ProdSupport].[dbo].[ICD-10-CM Mappings] a
	left join #HCC_Is_Chronic b
	on a.[CMS-HCC Model Category V24] = b.HCC_Number 
	join (
		select distinct PaymentYear, RAFactorType from dbo.[lkRiskModelsMaster]
		where ModelVersion = 24
		and rafactortype in (select FactorType from #PartCFactorTypes)
	) c
	on a.[Payment Year] = c.PaymentYear
WHERE 
	[CMS-HCC Model Category V24 for current Payment Year] = 'YES'


-- Part C ESRD 
-- Version 21
INSERT INTO [dbo].[lkRiskModelsDiagHCC](
	[ICD10CD] 
	,[HCCLabel] 
	,[PaymentYear] 
	,[ModelVersion] 
	,[HCCNumber] 
	,[FactorType] 
	,[HCCIsChronic] 
	,[LoadID] 
	,[LoadDate] 
)
SELECT 
	[ICD10CD] = [Diagnosis Code]
	,[HCCLabel] = 'HCC'+right(ltrim(rtrim(REPLICATE('0', 4) + rtrim(cast([CMS-HCC ESRD Model Category V21] as char)))),3)
	,[PaymentYear] = a.[Payment Year]
	,[ModelVersion] = 21
	,[HCCNumber] = [CMS-HCC ESRD Model Category V21]
	,[FactorType] = c.RAFactorType
	,[HCCIsChronic] = b.HCC_is_Chronic
	,[LoadDate] = 0
	,[LoadDate] = GETDATE()
FROM 
	[ProdSupport].[dbo].[ICD-10-CM Mappings] a
	left join #HCC_Is_Chronic b
	on a.[CMS-HCC ESRD Model Category V21] = b.HCC_Number 
	join (
		select distinct PaymentYear, RAFactorType from dbo.[lkRiskModelsMaster]
		where ModelVersion = 21
		and rafactortype in (select FactorType from #ESRDFactorTypes)
	) c
	on a.[Payment Year] = c.PaymentYear
WHERE 
	[CMS-HCC ESRD Model Category V21 for current Payment Year] = 'YES'

-- Part D
-- Version 05
INSERT INTO [dbo].[lkRiskModelsDiagHCC](
	[ICD10CD] 
	,[HCCLabel] 
	,[PaymentYear] 
	,[ModelVersion] 
	,[HCCNumber] 
	,[FactorType] 
	,[HCCIsChronic] 
	,[LoadID] 
	,[LoadDate] 
)
SELECT 
	[ICD10CD] = [Diagnosis Code]
	,[HCCLabel] = 'HCC'+rtrim(cast([RxHCC Model Category V05] as char))
	,[PaymentYear] = a.[Payment Year]
	,[ModelVersion] = 5
	,[HCCNumber] = [RxHCC Model Category V05]
	,[FactorType] = c.RAFactorType
	,[HCCIsChronic] = b.HCC_is_Chronic
	,[LoadDate] = 0
	,[LoadDate] = GETDATE()
FROM 
	[ProdSupport].[dbo].[ICD-10-CM Mappings] a
	left join #HCC_Is_Chronic b
	on a.[RxHCC Model Category V05] = b.HCC_Number 
	join (
		select distinct PaymentYear, RAFactorType from dbo.[lkRiskModelsMaster]
		where ModelVersion = 5
		and rafactortype in (select FactorType from #RxFactorTypes)
	) c
	on a.[Payment Year] = c.PaymentYear
WHERE 
	[RXHCC Model Category V05 for current Payment Year] = 'YES'


/*
-- Test

select 
	Payment_Year, ModelVersion, Factor_Type, count(1)
from
[dbo].[lkRiskModelsDiagHCC]
group by Payment_Year, ModelVersion, Factor_Type
order by Payment_Year, ModelVersion, Factor_Type
*/

-- Insert Historical records for PY 2017
/*
select Payment_Year, Factor_Type, count(1) from HRPReporting.dbo.lk_Risk_Models_DiagHCC_ICD10 
where Payment_Year = 2017
group by Payment_Year, Factor_Type order by 1 desc,2

select top 10 * from HRPReporting.dbo.lk_Risk_Models_DiagHCC_ICD10 
where Payment_Year = 2017
*/

INSERT INTO [dbo].[lkRiskModelsDiagHCC](
	[ICD10CD] 
	,[HCCLabel] 
	,[PaymentYear] 
	,[ModelVersion] 
	,[HCCNumber] 
	,[FactorType] 
	,[HCCIsChronic] 
	,[LoadID] 
	,[LoadDate] 
)
SELECT 
	[ICD10CD] = [ICD10CD]
	,[HCCLabel] = [HCC_Label]
	,[PaymentYear] = [Payment_Year]
	,[ModelVersion] = case when [Factor_Type] in ('CN','CP','CF','I') then 22 when [Factor_Type] in ('C1','C2','I1','I2','D') then 21 when [Factor_Type] in ('D1','D2','D3') then 5 end
	,[HCCNumber] = [HCC_Number]
	,[FactorType] = [Factor_Type]
	,[HCCIsChronic] = [HCCIsChronic]
	,[LoadDate] = 0
	,[LoadDate] = GETDATE()
FROM 
	HRPReporting.dbo.lk_Risk_Models_DiagHCC_ICD10 a
WHERE 
	Payment_Year = 2017

