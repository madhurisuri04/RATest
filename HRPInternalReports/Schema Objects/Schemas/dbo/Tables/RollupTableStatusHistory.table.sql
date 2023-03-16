CREATE TABLE [dbo].[RollupTableStatusHistory](
	[RollupTableStatusHistoryID] [int] IDENTITY(1,1) NOT NULL,
	[RollupTableStatusID] [int] NOT NULL,
	[RollupStart] [datetime] NOT NULL,
	[RollupEnd] [datetime] NOT NULL,
	[HistoryCreateDate] [smalldatetime] NOT NULL,
	[HistoryModifiedDate] [smalldatetime] NOT NULL
)