CREATE TABLE [Valuation].[NewHCCPartD](
	[NewHCCPartDId] [bigint] IDENTITY(1,1) NOT NULL,
	[ProcessRunId] [int] NULL,
	[DbName] [varchar](128) NULL,
	[Payment_Year] [char](4) NULL,
	[PROCESSED_BY_START] [smalldatetime] NULL,
	[PROCESSED_BY_END] [smalldatetime] NULL,
	[PlanId] [varchar](5) NULL,
	[HICN] [varchar](15) NULL,
	[HCC_PROCESSED_PCN] [varchar](50) NULL,
	[HCC_DESCRIPTION] [varchar](200) NULL,
	[TYPE] [varchar](6) NULL,
	[Processed_By_Flag] [Varchar] (1) NULL,
	[RxHCC_FACTOR] [money] NULL,
	[RxHCC] [varchar](20) NULL,
	[HIER_RxHCC] [varchar](20) NULL,
	[HIER_RxHCC_FACTOR] [money] NULL,
	[MEMBER_MONTHS] [int] NULL,
	[ROLLFORWARD_MONTHS] [int] NULL,
	[ESRD] [char](3) NULL,
	[HOSP] [char](3) NULL,
	[PBP] [char](3) NULL,
	[SCC] [varchar](5) NULL,
	[BID_AMOUNT] [money] NULL,
	[ESTIMATED_VALUE] [money] NULL,
	[PROCESSED_PRIORITY_DIAG] [varchar](20) NULL,
	[PROCESSED_PRIORITY_PROCESSED_BY] [datetime] NULL,
	[PROCESSED_PRIORITY_THRU_DATE] [datetime] NULL,
	[RA_FACTOR_TYPE] [varchar](5) NULL,
	[PRIORITY] [varchar](17) NULL,
	[PCN_SubprojectId] [varchar](32) NULL,
	[PCN_Coding_Entity] [varchar](32) NULL,
	[PCN_ProviderId] [varchar](32) NULL,
	[Populated_Date] [datetime] NULL,
	[FailureReason] [varchar](20) NULL,
	[MODEL_YEAR]	[CHAR](4)	 NULL,
	[PRE_ADJSTD_FACTOR]	[DECIMAL](20,4)	 NULL,
	[ADJSTD_FINAL_FACTOR]	[DECIMAL](20,4)	 NULL,
	[HIER_HCC_PROCESSED_PCN]	[VARCHAR](50)	 NULL,
	[UNQ_CONDITIONS]	[BIT]	 NULL,
	[MONTHS_IN_DCP]	[INT]	 NULL,
	[ANNUALIZED_ESTIMATED_VALUE]	[MONEY]	 NULL,
	[PROCESSED_PRIORITY_FILEID]	[VARCHAR](18)	 NULL,
	[PROCESSED_PRIORITY_RAC]	[CHAR](1)	 NULL,
	[PROCESSED_PRIORITY_RAPS_SOURCE_ID]	[VARCHAR](50)	 NULL,
	[DOS_PRIORITY_PROCESSED_BY]	[DATETIME]	 NULL,
	[DOS_PRIORITY_THRU_DATE]	[DATETIME]	 NULL,
	[DOS_PRIORITY_PCN]	[VARCHAR](50)	 NULL,
	[DOS_PRIORITY_DIAG]	[VARCHAR](20)	 NULL,
	[DOS_PRIORITY_FILEID]	[VARCHAR](18)	 NULL,
	[DOS_PRIORITY_RAC]	[CHAR](1)	 NULL,
	[DOS_PRIORITY_RAPS_SOURCE]	[VARCHAR](50)	 NULL,
	[PROVIDER_LAST]	[VARCHAR](55)	 NULL,
	[PROVIDER_FIRST]	[VARCHAR](55)	 NULL,
	[PROVIDER_GROUP]	[VARCHAR](80)	 NULL,
	[PROVIDER_ADDRESS]	[VARCHAR](100)	 NULL,
	[PROVIDER_CITY] [VARCHAR](30)	 NULL,
	[PROVIDER_STATE]	[CHAR](2)	 NULL,
	[PROVIDER_ZIP] [VARCHAR](13)	 NULL,
	[PROVIDER_PHONE]	[VARCHAR](15)	 NULL,
	[PROVIDER_FAX]	[VARCHAR](15)	 NULL,
	[TAX_ID]	[VARCHAR](55)	 NULL,
	[NPI]	[VARCHAR](20)	 NULL,
	[SWEEP_DATE] [DATE]	 NULL,
	[EncounterSource] [VARCHAR](4) NULL,
	[ProcessedPriorityRecordID] [VARCHAR](80) NULL,
 CONSTRAINT [PK_ValuationNewHCCPartD] PRIMARY KEY CLUSTERED 
(
	[NewHCCPartDId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON ) 
) 