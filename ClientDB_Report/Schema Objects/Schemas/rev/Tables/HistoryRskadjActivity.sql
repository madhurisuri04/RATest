CREATE TABLE [rev].[HistoryRskadjActivity](
	[HistoryRskadjActivityID] [INT] IDENTITY(1,1) NOT NULL,
	[GroupingID] [INT] NULL,
	[PartCDFlag] [VARCHAR](10) NULL,
	[Process] [VARCHAR](130) NULL,
	[TableName] [VARCHAR](100) NULL,
	[PaymentYear] [INT] NULL,
	[MYUFlag] [VARCHAR](2) NULL,
	[LastUpdatedDate] [DATETIME] NULL,
	[BDate] [DATETIME] NULL,
	[EDate] [DATETIME] NULL,
	[AdditionalRows] [INT] NULL,
	[RunBy] [VARCHAR](257) NULL
)