﻿ALTER TABLE [dbo].[MOR2012_rollup]
ADD CONSTRAINT [PK_MOR2012_rollup]
    PRIMARY KEY CLUSTERED ([MOR2012_rollupID] ASC) 
	WITH (ALLOW_PAGE_LOCKS = ON, ALLOW_ROW_LOCKS = ON, PAD_INDEX = OFF, 
		  IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF
	     )
