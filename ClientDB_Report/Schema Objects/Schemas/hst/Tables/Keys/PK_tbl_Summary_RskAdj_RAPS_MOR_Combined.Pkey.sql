﻿ALTER TABLE [hst].[tbl_Summary_RskAdj_RAPS_MOR_Combined]
ADD CONSTRAINT [PK_tbl_Summary_RskAdj_RAPS_MOR_Combined]
    PRIMARY KEY CLUSTERED ([tbl_Summary_RskAdj_RAPS_MOR_CombinedId] ASC)
    WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON,
          ALLOW_PAGE_LOCKS = ON
         );
