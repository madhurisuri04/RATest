CREATE TABLE [etl].[EstRecvSummaryPartD](
	[EstRecvSummaryPartDID] [bigint] IDENTITY(1,1) NOT NULL,
	[PaymentYear] [int] NOT NULL,
	[MYUFlag] [char](1) NOT NULL,
	[PBP] [varchar](10) NULL,
	[Members] [int] NULL,
	[MemberMonths] [int] NULL,
	[MonthsInDCP] [int] NULL,
	[EstimatedReceivable] [decimal](16, 4) NULL,
	[EstimatedReceivableAfterDelete] [decimal](16, 4) NULL,
	[AmountDeleted] [decimal](16, 4) NULL,
	[TotalPremiumYTD] [decimal](20, 3) NULL,
	[RAFactorType] [varchar](5) NULL,
	[LastPaymentMonth] [smalldatetime] NULL,
	[AgedStatus] [varchar](15) NULL,
	[DBPlanID] [varchar](5) NULL,
	[RAPSProjectedRiskScore] [decimal](10, 3) NULL,
	[EDSProjectedRiskScore] [decimal](10, 3) NULL,
	[ProjectedRiskScore] [decimal](10, 3) NULL,
	[RAPSProjectedRiskScoreAfterDelete] [decimal](10, 3) NULL,
	[EDSProjectedRiskScoreAfterDelete] [decimal](10, 3) NULL,
	[ProjectedRiskScoreAfterDelete] [decimal](10, 3) NULL,
	[CurrentScore] [decimal](10, 3) NULL,
	[LoadDate] [datetime] NOT NULL,
	[UserID] [varchar](128) NOT NULL,
	[Category] [varchar](30) NULL)
GO


