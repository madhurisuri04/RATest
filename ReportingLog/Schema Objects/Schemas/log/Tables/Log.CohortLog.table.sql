CREATE TABLE [log].[CohortLog](
	[CohortlogID] [int] IDENTITY(1,1) NOT NULL,
	[ClientID] [int] NULL,
	[FileImportID] [Int] NULL,
	[TargetTableName] [varchar](50) NULL,
	[PaymentYear] [varchar](4) NULL,
	[StartDateTime] [datetime] NULL,
	[EndDateTime] [datetime] NULL,
	[RowCountSource] [bigint] NULL,
	[RowCountTarget] [bigint] NULL,
	[Status] [varchar](15) NULL,
	[ErrorMessage] [varchar](2048) NULL,
	[LoadID] [bigint] NULL,
	[CreateDateTime] [datetime] NULL,
	[CreateUserID] [Int] NULL)
	
GO
