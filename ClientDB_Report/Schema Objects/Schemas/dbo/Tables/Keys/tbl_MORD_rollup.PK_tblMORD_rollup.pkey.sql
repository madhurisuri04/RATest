﻿ALTER TABLE [dbo].[tbl_MORD_rollup]
ADD CONSTRAINT [PK_tblMORD_rollup]
    PRIMARY KEY CLUSTERED ( [tbl_MORD_rollupID] ASC )
    WITH ( ALLOW_PAGE_LOCKS = ON, ALLOW_ROW_LOCKS = ON, PAD_INDEX = OFF ,
           IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF ,
           FILLFACTOR = 100 
         )
