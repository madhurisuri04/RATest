CREATE TABLE [dbo].[RollupTableStatusIndexBuildHistory](
	[RollupTableStatusIndexBuildHistoryID] [int] IDENTITY(1,1) NOT NULL,
	[RollupTableStatusID] [int] NOT NULL,
	[IndexBuildStart] [datetime] NOT NULL,
	[IndexBuildEnd] [datetime] NOT NULL,
	[HistoryCreateDate] [smalldatetime] NOT NULL,
	[HistoryModifiedDate] [smalldatetime] NOT NULL
) 