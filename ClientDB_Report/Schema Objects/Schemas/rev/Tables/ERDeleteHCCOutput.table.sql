﻿CREATE TABLE [rev].[ERDeleteHCCOutput]
(
	
	[ERDeleteHCCOutputID] [bigint] IDENTITY(1,1) NOT NULL,
	[Paymentyear] [int] NULL,
	[Modelyear] [int] NULL,
	[ProcessedbyStart] [datetime] NULL,
	[ProcessedbyEnd] [datetime] NULL,
	[ProcessedbyFlag] [varchar](1) NULL,
	[InMOR] [varchar](1) NULL,
	[PlanID] [varchar](5) NULL,
	[HICN] [varchar](15) NULL,
	[RAFactorType] [varchar](2) NULL,
	[HCC] [varchar](20) NULL,
	[HCCDescription] [varchar](255) NULL,
	[Factor] [decimal](20, 4) NULL,
	[HIERHCCOld] [varchar](20) NULL,
	[HIERFactorOld] [decimal](20, 4) NULL,
	[MemberMonths] [int] NULL,
	[BID] [money] NULL,
	[EstimatedValue] [money] NULL,
	[RollforwardMonths] [int] NULL,
	[AnnualizedEstimatedValue] [money] NULL,
	[MonthsinDCP] [int] NULL,
	[ESRD] [varchar](1) NULL,
	[HOSP] [varchar](1) NULL,
	[PBP] [varchar](3) NULL,
	[SCC] [varchar](5) NULL,
	[ProcessedPriorityProcessedby] [datetime] NULL,
	[ProcessedPriorityThrudate] [datetime] NULL,
	[ProcessedPriorityPCN] [varchar](50) NULL,
	[ProcessedPriorityDiag] [varchar](20) NULL,
	[ThruPriorityProcessedby] [datetime] NULL,
	[ThruPriorityThruDate] [datetime] NULL,
	[ThruPriorityPCN] [varchar](50) NULL,
	[ThruPriorityDiag] [varchar](20) NULL,
	[RAPSSource] [varchar](50) NULL,
	[ProviderID] [varchar](40) NULL,
	[ProviderLast] [varchar](55) NULL,
	[ProviderFirst] [varchar](55) NULL,
	[ProviderGroup] [varchar](80) NULL,
	[ProviderAddress] [varchar](100) NULL,
	[ProviderCity] [varchar](30) NULL,
	[ProviderState] [varchar](2) NULL,
	[ProviderZip] [varchar](15) NULL,
	[ProviderPhone] [varchar](15) NULL,
	[ProviderFax] [varchar](15) NULL,
	[TaxID] [varchar](55) NULL,
	[NPI] [varchar](20) NULL,
	[SweepDate] [datetime] NULL,
	[PopulatedDate] [datetime] NULL,
	[AgedStatus] [varchar] (20) NULL
)