﻿ALTER TABLE [dbo].[tbl_PDE_rollup] ADD  CONSTRAINT [PK_tbl_PDE_rollup_tbl_PDE_rollupID] PRIMARY KEY CLUSTERED 
(
	[tbl_PDE_rollupID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
