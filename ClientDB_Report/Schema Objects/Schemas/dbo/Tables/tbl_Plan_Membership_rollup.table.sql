﻿CREATE TABLE [dbo].[tbl_Plan_Membership_rollup](
	tbl_Plan_Membership_rollupID	int Identity  NOT NULL,
	PlanIdentifier			smallint Not Null,
	[PlanMembershipID] [int] NOT NULL,
	[PLANID] [varchar](8) NULL,
	[HICN] [varchar](15) NULL,
	[LAST] [varchar](50) NULL,
	[FIRST] [varchar](50) NULL,
	[MI] [varchar](3) NULL,
	[DOB] [datetime] NULL,
	[GENDER] [varchar](1) NULL,
	[SSN] [varchar](13) NULL,
	[MEMBERID] [varchar](25) NULL,
	[COUNTY_OF_RESIDENCE] [varchar](50) NULL,
	[MEDICAID_STATUS] [varchar](1) NULL,
	[DISABILITY_STATUS] [varchar](1) NULL,
	[PBP] [varchar](25) NULL,
	[Start_Date] [smalldatetime] NULL,
	[End_Date] [smalldatetime] NULL,
	[EFFECTIVE_DATE] [smalldatetime] NULL,
	[TERM_DATE] [smalldatetime] NULL,
	[TRANS_DATE] [smalldatetime] NULL,
	[WITHHOLD_OPTION] [varchar](1) NULL,
	[Low_Income_Cost_Sharing] [varchar](1) NULL,
	[LIS_SUBSIDY] [varchar](3) NULL,
	[ESRD] [varchar](1) NULL,
	[HOSPICE] [varchar](1) NULL,
	[WORKING_AGED] [varchar](1) NULL,
	[INSTITUTIONAL] [varchar](1) NULL,
	[GROUP_CODE] [varchar](16) NULL,
	[LEP] [varchar](6) NULL,
	[FILLER] [varchar](14) NULL,
	[ADDRESS_1] [varchar](50) NULL,
	[ADDRESS_2] [varchar](50) NULL,
	[CITY] [varchar](30) NULL,
	[STATE] [varchar](2) NULL,
	[ZIP] [varchar](5) NULL,
	[ZIP4] [varchar](4) NULL,
	[RISK_SCORE] [varchar](5) NULL,
	[RA_FACTOR_TYPE] [varchar](2) NULL,
	[PCP_ID] [varchar](50) NULL,
	[PCP_FN] [varchar](50) NULL,
	[PCP_LN] [varchar](50) NULL,
	[DATE_IMPORTED] [smalldatetime] NULL,
	[RISK_SCORE_D] [varchar](5) NULL,
	[MemberIDReceived] [varchar](12) NULL)