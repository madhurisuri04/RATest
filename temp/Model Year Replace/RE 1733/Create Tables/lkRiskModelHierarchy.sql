use HRPReporting

CREATE TABLE [dbo].[lkRiskModelsHierarchy](
	[lkRiskModelsHierarchyID] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[PartCDFlag] [varchar](2) NOT NULL,
	[FACTORTYPE] [varchar](2) NOT NULL,
	[PaymentYear] [INT] NOT NULL,
	[ModelVersion] [smallint] NULL,
	[HCCKEEP] [varchar](50) NOT NULL,
	[HCCDROP] [varchar](50) NOT NULL,
	[HCCKEEPNUMBER] [varchar](50) NOT NULL,
	[HCCDROPNUMBER] [varchar](50) NOT NULL, 
    [LoadID] [bigint] NOT NULL,
	[LoadDate] [datetime] NOT NULL,
 CONSTRAINT [PK_lkRiskModelsHierarchyID] PRIMARY KEY CLUSTERED 
(
	[lkRiskModelsHierarchyID] ASC
)
) 

