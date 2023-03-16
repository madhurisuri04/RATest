ALTER TABLE [dbo].[tbl_Member_Months_rollup]
ADD CONSTRAINT [PK_tbl_Member_Months_rollup]
    PRIMARY KEY CLUSTERED ([tbl_Member_Months_rollupID] ASC) 
	WITH (ALLOW_PAGE_LOCKS = ON, ALLOW_ROW_LOCKS = ON, PAD_INDEX = OFF, 
		  IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF
	     )



		 