﻿ALTER TABLE [dbo].[RollupTableStatusHistory] ADD  CONSTRAINT [PK_RollupTableStatusHistory_RollupTableStatusHistoryID] PRIMARY KEY CLUSTERED 
(
	[RollupTableStatusHistoryID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
