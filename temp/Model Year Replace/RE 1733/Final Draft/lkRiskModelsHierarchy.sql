CREATE TABLE [dbo].[lkRiskModelsHierarchy]
(
	[lkRiskModelsHierarchyID] [int] IDENTITY(1,1) NOT NULL,
	[PartCDFlag] [varchar](2) NOT NULL,
	[RAFactorType] [varchar](2) NOT NULL,
	[PaymentYear] [INT] NOT NULL,
	[ModelVersion] [smallint] NULL,
	[HCCKeep] [varchar](50) NOT NULL,
	[HCCDrop] [varchar](50) NOT NULL,
	[HCCKeepNumber] [varchar](50) NOT NULL,
	[HCCDropNumber] [varchar](50) NOT NULL, 
    [LoadID] [bigint] NOT NULL,
	[LoadDate] [datetime] NOT NULL
)