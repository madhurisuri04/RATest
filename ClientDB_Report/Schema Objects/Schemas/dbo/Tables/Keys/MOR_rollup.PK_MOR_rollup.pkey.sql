﻿ALTER TABLE [dbo].[MOR_rollup]
ADD CONSTRAINT [PK_MOR_rollup]
    PRIMARY KEY CLUSTERED ([MOR_rollupID] ASC) 
	WITH (ALLOW_PAGE_LOCKS = ON, ALLOW_ROW_LOCKS = ON, PAD_INDEX = OFF, 
		  IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF
	     )
