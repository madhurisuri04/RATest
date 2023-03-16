CREATE TABLE [dbo].[tbl_Existing_Conditions_rollup]
(
	tbl_Existing_Conditions_rollupID	int Identity NOT NULL,
	PlanIdentifier							smallint Not Null,
	[EXISTING_CONDITIONS_ID] [int] NOT NULL,
	[HICN] [varchar](12) NOT NULL,
	[SOURCE_FILE_DATE_STAMP] [varchar](6) NOT NULL,
	[DOS] [varchar](21) NOT NULL,
	[HCC_YEAR] [int] NOT NULL,
	[ICD9] [char](8) NULL,
	[HCC_C] [char](8) NULL,
	[HCC_D] [char](8) NULL,
	[PROVIDER_TYPE] [varchar](20) NULL,
	[DATA_SOURCE] [char](4) NOT NULL,
	[Populated] [datetime] NOT NULL,
	[MemberIDReceived] [varchar](12) NULL
)