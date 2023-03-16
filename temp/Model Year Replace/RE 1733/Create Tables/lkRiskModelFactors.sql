use HRPReporting

CREATE TABLE [dbo].[lkRiskModelsFactors](
	[lkRiskModelsFactorsID] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[PaymentYear] [int] NOT NULL,
	[ModelVersion] [smallint] NULL,
	[FactorType] [varchar](10) NULL,
	[PartCDFlag] [varchar](1) NULL,
	[OREC] [int] NULL,
	[LI] [int] NULL,
	[MedicaidFlag] [int] NULL,
	[DemoRiskType] [varchar](10) NULL,
	[FactorDescription] [varchar](50) NULL,
	[HCCNumber] [varchar](4) NULL,
	[Gender] [int] NULL,
	[Factor] [decimal](20, 4) NULL,
	[Aged] [int] NULL,
	[APCCFlag] [char](1) NULL,
	[LoadID] [bigint] NOT NULL,
	[LoadDate] [datetime] NOT NULL,
 CONSTRAINT [PK_lkRiskModelsFactorsID] PRIMARY KEY CLUSTERED 
(
	[lkRiskModelsFactorsID] ASC
)
)

