Use HRPReporting

-- Script 1 - Inserting values into [lkRiskModelsMaster]

if (object_id('[dbo].[lkRiskModelsMaster]') is not null)
BEGIN
  Truncate table [dbo].[lkRiskModelsMaster];
End

INSERT INTO dbo.[lkRiskModelsMaster](
	 [PaymentYear] 
	,[SplitSegmentNumber] 
	,[SplitSegmentWeight] 
	,[PaymStart] 
	,[PaymEnd] 
	,[RecordType] 
	,[PartCDFlag] 
	,[RAFactorType] 
	,[NormalizationFactor] 
	,[CodingIntensity] 
	,[MSP_Reduction] 
	,[ESRD_MSP_Reduction] 
	,[Segment] 
	,[CMSModel] 
	,[ModelVersion] 
	,[BidRate] 
	,[SubmissionModel] 
	,[SubmissionModelNumber] 
	,[UserID] 
	,[LoadDate] 
	,[APCCFlag] 
)
select 
	a.[PaymentYear] 
	,a.[SplitSegmentNumber] 
	,a.[SplitSegmentWeight] 
	,a.[PaymStart] 
	,a.[PaymEnd] 
	,a.[RecordType] 
	,[PartCDFlag] = 'C'
	,a.[RAFactorType] 
	,[NormalizationFactor] = case	
			when a.[RAFactorType] in ('C', 'CP', 'CF', 'CN', 'I', 'E', 'SE') then a.[PartCNormalizationFactor] 
			when a.[RAFactorType] in ('D', 'ED', 'G1', 'G2') then a.[ESRDDialysisFactor] 
			when a.[RAFactorType] in ('C1', 'C2', 'E1', 'E2', 'I1', 'I2') then a.[FunctioningGraftFactor] 
		end
	,a.[CodingIntensity] 
	,b.[MSP_Reduction] 
	,b.[ESRD_MSP_Reduction] 
	,a.[Segment] 
	,a.[CMSModel] 
	,a.[Version] 
	,a.[BidRate] 
	,a.[SubmissionModel] 
	,a.[SubmissionModelNumber] 
	,a.[UserID] 
	,a.[LoadDate] 
	,a.[APCCFlag] 
from [dbo].[lk_Risk_Score_Factors_PartC] a Inner Join 
	 [dbo].[lk_normalization_factors] b 
	 on a.[PaymentYear] = b.[year]
where a.PaymentYear in (2017, 2018, 2019, 2020, 2021)

union all

select 
	[PaymentYear] = b.Year
	,[SplitSegmentNumber] = 1
	,[SplitSegmentWeight] = 1.0000
	,[PaymStart] = b.Year+'-01-01 00:00:00.000'
	,[PaymEnd] = b.Year+'-12-31 00:00:00.000'
	,[RecordType] = '2'
	,[PartCDFlag] = 'D'
	,[RAFactorType] = c.[RAFactorType] 
	,[NormalizationFactor] = b.[PartD_Factor] 
	,[CodingIntensity] = b.[CodingIntensity] 
	,[MSPReduction] = NULL 
	,[ESRDMSPReduction] = NULL 
	,[Segment] = 'CMS-RxHCC' 
	,[CMSModel] = 'CMS-RxHCC'
	,[ModelVersion] = 5
	,[BidRate] = 'PD County bid rate' 
	,[SubmissionModel] = 'RAPS'
	,[SubmissionModelNumber] = 1
	,[UserID] = 'Manual' 
	,[LoadDate] = getdate()
	,[APCCFlag] = 'N'
from [dbo].[lk_normalization_factors] b
cross join (
	select 'D1' RAFactorType 
		union 
	select 'D2' RAFactorType 
		union 
	select 'D3' RAFactorType 
) c
where b.year in (2017, 2018, 2019, 2020, 2021)

union all

select 
	[PaymentYear] = b.Year
	,[SplitSegmentNumber] = 1
	,[SplitSegmentWeight] = 1.0000
	,[PaymStart] = b.Year+'-01-01 00:00:00.000'
	,[PaymEnd] = b.Year+'-12-31 00:00:00.000'
	,[RecordType] = '4' 
	,[PartCDFlag] = 'D'
	,[RAFactorType] = c.[RAFactorType] 
	,[NormalizationFactor] = b.[PartD_Factor] 
	,[CodingIntensity] = b.[CodingIntensity] 
	,[MSPReduction] = NULL 
	,[ESRDMSPReduction] = NULL 
	,[Segment] = 'CMS-RxHCC' 
	,[CMSModel] = 'CMS-RxHCC'
	,[ModelVersion] = 5
	,[BidRate] = 'PD County bid rate' 
	,[SubmissionModel] = 'EDS'
	,[SubmissionModelNumber] = 2
	,[UserID] = 'Manual' 
	,[LoadDate] = getdate()
	,[APCCFlag] = 'N'
from [dbo].[lk_normalization_factors] b
cross join (
	select 'D1' RAFactorType union select 'D2' RAFactorType union select 'D3' RAFactorType 
) c
where b.year in (2017, 2018, 2019, 2020, 2021)



--================================================================================================================================================================================================--


if (object_id('[dbo].[lkRiskModelsFactors]') is not null)
BEGIN
  Truncate table [dbo].[lkRiskModelsFactors];
End

-- Script 2 - Inserting values into [lkRiskModelsFactors]

IF (OBJECT_ID('tempdb.dbo.#Combination') IS NOT NULL)
BEGIN
    DROP TABLE [#Combination];
END;


CREATE TABLE [#Combination]
(
    [Id] INT IDENTITY(1, 1) PRIMARY KEY,
    [PaymentYear] [int] NOT NULL,
    [RAFactorType] [varchar](5) NULL,
    [ModelVersion] [smallint] NULL,
    [APCCFlag] [char](1) NULL
);

Insert INTO [#Combination]
(
	[PaymentYear],
    [RAFactorType],
    [ModelVersion],
    [APCCFlag]
)
select distinct 
		paymentyear, 
		RAFactorType, 
		ModelVersion, 
		APCCFlag 
from [dbo].[lkRiskModelsMaster]
where paymentyear > 2016


INSERT INTO [dbo].[lkRiskModelsFactors] (
	 [PaymentYear] 
	,[ModelVersion]
	,[RAFactorType]
	,[PartCDFlag]	
	,[OREC]
	,[LI]
	,[MedicaidFlag]	
	,[DemoRiskType]
	,[FactorDescription]
	,[HCCNumber]
	,[Gender]
	,[Factor] 
	,[Aged]
	,[APCCFlag]
	,[LoadID] 
	,[LoadDate]
)
select 
	 [Payment_Year] 
	,c.[ModelVersion]
	,[Factor_Type]
	,[Part_C_D_Flag]	
	,[OREC]
	,[LI]
	,[Medicaid_Flag]	
	,[Demo_Risk_Type]
	,[Factor_Description]
	,[HCCNumber] = cast(cast (case when [Demo_Risk_Type] = 'RISK' then LTRIM(REVERSE(LEFT(REVERSE([Factor_Description]), PATINDEX('%[A-Z]%',REVERSE([Factor_Description])) - 1))) else null end as int) as varchar)
	,[Gender]
	,[Factor] 
	,[Aged]
	,c.[APCCFlag]
	,0 as [LoadID]
	,getdate() as [LoadDate]
from dbo.lk_risk_models lk
join #combination c
on lk.Payment_Year = c.PaymentYear
and lk.Factor_Type = c.RAFactorType
where Payment_Year > 2016

INSERT INTO [dbo].[lkRiskModelsFactors] (
	[PaymentYear] 
	,[ModelVersion]
	,[RAFactorType]
	,[PartCDFlag]	
	,[OREC]
	,[LI]
	,[MedicaidFlag]	
	,[DemoRiskType]
	,[FactorDescription]
	,[HCCNumber]
	,[Gender]
	,[Factor] 
	,[Aged]
	,[APCCFlag]
	,[LoadID] 
	,[LoadDate]
)
select 
	 [Payment_Year] 
	,[ModelVersion] = 5
	,[Factor_Type]
	,[Part_C_D_Flag]	
	,[OREC]
	,[LI]
	,[Medicaid_Flag]	
	,[Demo_Risk_Type]
	,[Factor_Description]
	,[HCCNumber] = cast(cast (case when [Demo_Risk_Type] = 'RISK' then LTRIM(REVERSE(LEFT(REVERSE([Factor_Description]), PATINDEX('%[A-Z]%',REVERSE([Factor_Description])) - 1))) else null end as int) as varchar)
	,[Gender]
	,[Factor] 
	,[Aged]
	,'N' as [APCCFlag]
	,0 as [LoadID]
	,getdate() as [LoadDate]
from dbo.lk_risk_models lk
where Payment_Year > 2016
and Factor_Type in ('D4','D5','D6','D7','D8','D9');


update t
Set DemoRiskType = 'APCC',
	HCCNumber = null
from [dbo].[lkRiskModelsFactors] t
where
FactorDescription in ('D1','D2','D3','D4','D5','D6','D7','D8','D9','D10P','D10');


--================================================================================================================================================================================================--


-- Script 3 - Inserting values into [lkRiskModelsHierarchy]

if (object_id('[dbo].[lkRiskModelsHierarchy]') is not null)
BEGIN
  Truncate table [dbo].[lkRiskModelsHierarchy];
End


IF (OBJECT_ID('tempdb.dbo.#Combination1') IS NOT NULL)
BEGIN
    DROP TABLE [#Combination1];
END;

CREATE TABLE [#Combination1]
(
    [Id] INT IDENTITY(1, 1) PRIMARY KEY,
    [PaymentYear] [int] NOT NULL,
    [RAFactorType] [varchar](5) NULL,
    [ModelVersion] [smallint] NULL
);

Insert INTO [#Combination1]
(
	[PaymentYear],
    [RAFactorType],
    [ModelVersion]
)
select distinct 
	paymentyear, 
	RAFactorType, 
	ModelVersion 
from [dbo].[lkRiskModelsMaster]
where paymentyear > 2016
and RAFactorType in ('CN','CP','CF','I','C1','C2','I1','I2','D','D1','D2','D3');


INSERT INTO [dbo].[lkRiskModelsHierarchy](
	[PartCDFlag] , 
	[RAFACTORTYPE] , 
	[PaymentYear],
	[ModelVersion] , 
	[HCCKEEP], 
	[HCCDROP], 
	[HCCKEEPNUMBER] , 
	[HCCDROPNUMBER] ,
	[LoadID] ,
	[LoadDate]  
)
select 
	b.[Part_C_D_Flag],
	b.[RA_FACTOR_TYPE] ,
	b.[Payment_Year]  ,
	[ModelVersion] = c.[ModelVersion],
	b.[HCC_KEEP],
	b.[HCC_DROP],
	b.[HCC_KEEP_NUMBER] ,
	b.[HCC_DROP_NUMBER] ,
	0 as [LoadID],
	getdate() as [LoadDate] 
from dbo.lk_Risk_Models_Hierarchy b
	join [#Combination1] c
	on b.Payment_Year = c.PaymentYear
	and b.RA_FACTOR_TYPE = c.RAFactorType
where 
	Payment_Year > 2016
Group by 
	b.[Part_C_D_Flag],
	b.[RA_FACTOR_TYPE],
	b.[Payment_Year],
	c.[ModelVersion],
	b.[HCC_KEEP],
	b.[HCC_DROP],
	b.[HCC_KEEP_NUMBER],
	b.[HCC_DROP_NUMBER]


IF (OBJECT_ID('tempdb.dbo.#Combination1') IS NOT NULL)
BEGIN
    DROP TABLE [#Combination1];
END;

--================================================================================================================================================================================================--

-- Script 4 - Inserting values into [lkRiskModelsDiagHCC]


if (object_id('[dbo].[lkRiskModelsDiagHCC]') is not null)
BEGIN
  Truncate table [dbo].[lkRiskModelsDiagHCC];
End



IF (OBJECT_ID('tempdb.dbo.[#HCC_Is_Chronic]') IS NOT NULL)
BEGIN
    DROP TABLE [#HCC_Is_Chronic];
END;

CREATE TABLE [#HCC_Is_Chronic]
(
    [Id] INT IDENTITY(1, 1) PRIMARY KEY,
    [HCC_Number] [varchar](50) NULL,
    [HCC_is_Chronic] [bit] NULL
);

Insert INTO [#HCC_Is_Chronic]
(
	[HCC_Number],
	[HCC_is_Chronic]
)
Select distinct 
	HCC_Number, 
	HCC_is_Chronic 
from  [dbo].[lk_Factors_PartC] 
where HCC_Label like 'HCC%';

Insert INTO [#HCC_Is_Chronic]
(
	[HCC_Number],
	[HCC_is_Chronic]
)
Select distinct 
	HCC_Number,
	HCC_is_Chronic 
from [dbo].[lk_Factors_PartD] d
where HCC_Label like 'HCC%'
and not exists (select 1 from [#HCC_Is_Chronic] c where c.HCC_Number = d.HCC_Number);


Delete from 
	[#HCC_Is_Chronic]
	where HCC_is_Chronic is null
		  and HCC_Number in ('113','120','121','123','125','126','14','142','20','49','50','61','62','63','89','93')

Delete from 
	[#HCC_Is_Chronic]
where isnull(HCC_is_Chronic,9) <> 0
	  and HCC_Number in ('176','33','54','80','83')

Delete from 
	[#HCC_Is_Chronic]
where isnull(HCC_is_Chronic,9) <> 1
	  and HCC_Number in ('111', '112', '51','74','75','78')

Delete from 
	[#HCC_Is_Chronic]
where isnull(HCC_is_Chronic,9) <> 0
	  and HCC_Number in ('30','41','42','43','65','66','97','98','145','147','156','165','168','187')

Delete from 
	[#HCC_Is_Chronic]
where isnull(HCC_is_Chronic,9) <> 0
	  and HCC_Number in ('113','120','121','123','126','20')

  
IF (OBJECT_ID('tempdb.dbo.[#PartCFactorTypes]') IS NOT NULL)
BEGIN
    DROP TABLE [#PartCFactorTypes];
END;

CREATE TABLE [#PartCFactorTypes]
(
    [Id] INT IDENTITY(1, 1) PRIMARY KEY,
    FactorType [varchar](10) NULL
);

Insert INTO [#PartCFactorTypes]
	(
	FactorType
	)
Values
	('CN'),
	('CP'),
	('CF'),
	('I');


IF (OBJECT_ID('tempdb.dbo.[#ESRDFactorTypes]') IS NOT NULL)
BEGIN
    DROP TABLE [#ESRDFactorTypes];
END;

CREATE TABLE [#ESRDFactorTypes]
(
    [Id] INT IDENTITY(1, 1) PRIMARY KEY,
    FactorType [varchar](10) NULL
);

Insert INTO [#ESRDFactorTypes]
	(
	FactorType
	)
Values
	('C1'),
	('C2'),
	('I1'),
	('I2'),
	('D');



IF (OBJECT_ID('tempdb.dbo.[#RxFactorTypes]') IS NOT NULL)
BEGIN
    DROP TABLE [#RxFactorTypes];
END;

CREATE TABLE [#RxFactorTypes]
(
    [Id] INT IDENTITY(1, 1) PRIMARY KEY,
    FactorType [varchar](10) NULL
);

Insert INTO [#RxFactorTypes]
	(
	FactorType
	)
Values
	('D1'),
	('D2'),
	('D3');

-- Version 22

INSERT INTO [dbo].[lkRiskModelsDiagHCC]
(
	 [ICD10CD] 
	,[HCCLabel] 
	,[PaymentYear] 
	,[ModelVersion] 
	,[HCCNumber] 
	,[RAFactorType] 
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
		select distinct 
				PaymentYear, 
				RAFactorType 
			from dbo.[lkRiskModelsMaster]
		where ModelVersion = 22
			  and rafactortype in (select FactorType from #PartCFactorTypes)
	) c
	on a.[Payment Year] = c.PaymentYear
WHERE 
	[CMS-HCC Model Category V22 for current Payment Year] = 'YES'


-- Version 23
INSERT INTO [dbo].[lkRiskModelsDiagHCC]
(
   	 [ICD10CD] 
	,[HCCLabel] 
	,[PaymentYear] 
	,[ModelVersion] 
	,[HCCNumber] 
	,[RAFactorType] 
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
		select distinct 
				PaymentYear, 
				RAFactorType 
			from dbo.[lkRiskModelsMaster]
		where ModelVersion = 23
		and rafactortype in (select FactorType from #PartCFactorTypes)
	) c
	on a.[Payment Year] = c.PaymentYear
WHERE 
	[CMS-HCC Model Category V23 for current Payment Year] = 'YES'

-- Version 24

INSERT INTO [dbo].[lkRiskModelsDiagHCC]
(
	 [ICD10CD] 
	,[HCCLabel] 
	,[PaymentYear] 
	,[ModelVersion] 
	,[HCCNumber] 
	,[RAFactorType] 
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
		select distinct 
				PaymentYear, 
				RAFactorType 
			from dbo.[lkRiskModelsMaster]
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
	,[RAFactorType] 
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
	,[RAFactorType] = c.RAFactorType
	,[HCCIsChronic] = b.HCC_is_Chronic
	,[LoadDate] = 0
	,[LoadDate] = GETDATE()
FROM 
	[ProdSupport].[dbo].[ICD-10-CM Mappings] a
	left join #HCC_Is_Chronic b
		on a.[CMS-HCC ESRD Model Category V21] = b.HCC_Number 
	join (
		select distinct 
				PaymentYear, 
				RAFactorType 
			from dbo.[lkRiskModelsMaster]
		where ModelVersion = 21
		and rafactortype in (select FactorType from #ESRDFactorTypes)
	) c
	on a.[Payment Year] = c.PaymentYear
WHERE 
	[CMS-HCC ESRD Model Category V21 for current Payment Year] = 'YES'

-- Part D
-- Version 05
INSERT INTO [dbo].[lkRiskModelsDiagHCC]
(
	 [ICD10CD] 
	,[HCCLabel] 
	,[PaymentYear] 
	,[ModelVersion] 
	,[HCCNumber] 
	,[RAFactorType] 
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
	,[RAFactorType] = c.RAFactorType
	,[HCCIsChronic] = b.HCC_is_Chronic
	,[LoadDate] = 0
	,[LoadDate] = GETDATE()
FROM 
	[ProdSupport].[dbo].[ICD-10-CM Mappings] a
	left join #HCC_Is_Chronic b
		on a.[RxHCC Model Category V05] = b.HCC_Number 
	join (
		select distinct 
				PaymentYear, 
				RAFactorType 
			from dbo.[lkRiskModelsMaster]
		where ModelVersion = 5
		and rafactortype in (select FactorType from #RxFactorTypes)
	) c
	on a.[Payment Year] = c.PaymentYear
WHERE 
	[RXHCC Model Category V05 for current Payment Year] = 'YES'

 
INSERT INTO [dbo].[lkRiskModelsDiagHCC]
(
	 [ICD10CD] 
	,[HCCLabel] 
	,[PaymentYear] 
	,[ModelVersion] 
	,[HCCNumber] 
	,[RAFactorType] 
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
	dbo.lk_Risk_Models_DiagHCC_ICD10 a
WHERE 
	Payment_Year = 2017;

   
--================================================================================================================================================================================================--

-- Script 5 - Inserting values into [lkRiskModelsInteraction]

if (object_id('[dbo].[lkRiskModelsInteraction]') is not null)
BEGIN
  Truncate table [dbo].[lkRiskModelsInteraction];
End


IF (OBJECT_ID('tempdb.dbo.[#Combination2]') IS NOT NULL)
BEGIN
    DROP TABLE [#Combination2];
END;

CREATE TABLE [#Combination2]
(
    [Id] INT IDENTITY(1, 1) PRIMARY KEY,
    [PaymentYear] [int] NOT NULL,
    [RAFactorType] [varchar](5) NULL,
    [ModelVersion] [smallint] NULL
);

Insert Into [#Combination2]
(
	[PaymentYear], 
	[RAFactorType],
	[ModelVersion] 
)
Select distinct 
	paymentyear, 
	RAFactorType, 
	ModelVersion 
from [dbo].[lkRiskModelsMaster]
where paymentyear > 2016
	and RAFactorType in ('CN','CP','CF','I','C1','C2','I1','I2','D','D1','D2','D3')

INSERT INTO [dbo].[lkRiskModelsInteraction](
	[PaymentYear] ,
	[ModelVersion] ,
	[InteractionLabel] ,
	[HCCLabel1] ,
	[HCCLabel2] ,
	[HCCLabel3] ,
	[HCCNumber1] ,
	[HCCNumber2] ,
	[HCCNumber3] ,
	[RAFactorType] ,
	[LongDescription] ,
	[ShortDescription] , 
    [LoadID] ,
	[LoadDate] 
)
select distinct
	[Payment_Year] = b.payment_year,
	[ModelVersion] = c.[ModelVersion],
	[InteractionLabel] = b.interaction_label,
	[HCCLabel1] = b.hcc_label_1,
	[HCCLabel2] = b.hcc_label_2,
	[HCCLabel3] = b.hcc_label_3,
	[HCCNumber1] = b.hcc_number_1,
	[HCCNumber2] = b.hcc_number_2,
	[HCCNumber3] = b.hcc_number_3,
	[RAFactorType] = b.factor_type,
	[LongDescription] = b.long_description,
	[ShortDescription] = b.short_description, 
	[LoadID] = 0,
	[LoadDate] = getdate()
from dbo.lk_Risk_Models_Interactions b
	join [#Combination2] c
	on b.Payment_Year = c.PaymentYear
	and b.FACTOR_TYPE = c.RAFactorType
where 
	Payment_Year > 2016
	   

IF (OBJECT_ID('tempdb.dbo.#Combination2') IS NOT NULL)
BEGIN
    DROP TABLE [#Combination2];
END;

--================================================================================================================================================================================================--


 