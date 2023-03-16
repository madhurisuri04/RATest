use HRPReporting

--CREATE TABLE [dbo].[lkRiskModelsMaster](
CREATE TABLE ProdSupport.[dbo].[lkRiskModelsMaster](
	[lkRiskModelsMasterID] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[PaymentYear] [int] NOT NULL,
	[SplitSegmentNumber] [int] NULL,
	[SplitSegmentWeight] [decimal](20, 4) NULL,
	[PaymStart] [datetime] NULL,
	[PaymEnd] [datetime] NULL,
	[RecordType] [char](1) NULL,
	[Part_C_D_Flag] [char](1) NULL,
	[RAFactorType] [varchar](5) NULL,
	[NormalizationFactor] [decimal](20, 4) NULL,
	[CodingIntensity] [decimal](20, 4) NULL,
	[MSP_Reduction] [decimal](20, 4) NULL,
	[ESRD_MSP_Reduction] [decimal](20, 4) NULL,
	[Segment] [varchar](50) NULL,
	[CMSModel] [varchar](50) NULL,
	[ModelVersion] [smallint] NULL,
	[BidRate] [varchar](50) NULL,
	[SubmissionModel] [varchar](5) NOT NULL,
	[SubmissionModelNumber] [tinyint] NOT NULL,
	[UserID] [varchar](128) NOT NULL,
	[LoadDate] [datetime] NOT NULL,
	[APCCFlag] [char](1) NULL,
 CONSTRAINT [PK_lkRiskModelsMasterID] PRIMARY KEY CLUSTERED 
(
	[lkRiskModelsMasterID] ASC
)
)


Truncate table ProdSupport.dbo.[lkRiskModelsMaster]

INSERT INTO ProdSupport.dbo.[lkRiskModelsMaster](
	[PaymentYear] 
	,[SplitSegmentNumber] 
	,[SplitSegmentWeight] 
	,[PaymStart] 
	,[PaymEnd] 
	,[RecordType] 
	,[Part_C_D_Flag] 
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
	,[Part_C_D_Flag] = 'C'
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
from HRPReporting.[dbo].[lk_Risk_Score_Factors_PartC] a,
	 HRPReporting.[dbo].[lk_normalization_factors] b
where 
	a.PaymentYear = b.year 
	and a.PaymentYear in (2017, 2018, 2019, 2020, 2021)

union all

select 
	[PaymentYear] = b.Year
	,[SplitSegmentNumber] = 1
	,[SplitSegmentWeight] = 1.0000
	,[PaymStart] = b.Year+'-01-01 00:00:00.000'
	,[PaymEnd] = b.Year+'-12-31 00:00:00.000'
	,[RecordType] = '2'
	,[Part_C_D_Flag] = 'D'
	,[RAFactorType] = c.[RAFactorType] 
	,[NormalizationFactor] = b.[PartD_Factor] 
	,[CodingIntensity] = b.[CodingIntensity] 
	,[MSP_Reduction] = NULL 
	,[ESRD_MSP_Reduction] = NULL 
	,[Segment] = 'CMS-RxHCC' 
	,[CMSModel] = 'CMS-RxHCC'
	,[ModelVersion] = 5
	,[BidRate] = 'PD County bid rate' 
	,[SubmissionModel] = 'RAPS'
	,[SubmissionModelNumber] = 1
	,[UserID] = 'Manual' 
	,[LoadDate] = getdate()
	,[APCCFlag] = 'N'
from HRPReporting.[dbo].[lk_normalization_factors] b
cross join (
	select 'D1' RAFactorType union select 'D2' RAFactorType union select 'D3' RAFactorType 
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
	,[Part_C_D_Flag] = 'D'
	,[RAFactorType] = c.[RAFactorType] 
	,[NormalizationFactor] = b.[PartD_Factor] 
	,[CodingIntensity] = b.[CodingIntensity] 
	,[MSP_Reduction] = NULL 
	,[ESRD_MSP_Reduction] = NULL 
	,[Segment] = 'CMS-RxHCC' 
	,[CMSModel] = 'CMS-RxHCC'
	,[ModelVersion] = 5
	,[BidRate] = 'PD County bid rate' 
	,[SubmissionModel] = 'EDS'
	,[SubmissionModelNumber] = 2
	,[UserID] = 'Manual' 
	,[LoadDate] = getdate()
	,[APCCFlag] = 'N'
from HRPReporting.[dbo].[lk_normalization_factors] b
cross join (
	select 'D1' RAFactorType union select 'D2' RAFactorType union select 'D3' RAFactorType 
) c
where b.year in (2017, 2018, 2019, 2020, 2021)


/*

select * from ProdSupport.dbo.[lkRiskModelsMaster]

select * from ProdSupport.dbo.[lkRiskModelsMaster]
where paymentyear = 2018

*/
