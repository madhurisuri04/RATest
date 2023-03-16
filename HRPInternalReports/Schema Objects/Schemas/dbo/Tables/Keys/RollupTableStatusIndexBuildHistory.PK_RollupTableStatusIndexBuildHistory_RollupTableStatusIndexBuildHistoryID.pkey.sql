ALTER TABLE [dbo].[RollupTableStatusIndexBuildHistory] ADD  CONSTRAINT [PK_RollupTableStatusIndexBuildHistory_RollupTableStatusIndexBuildHistoryID] PRIMARY KEY CLUSTERED 
(
	[RollupTableStatusIndexBuildHistoryID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
