﻿ALTER TABLE [dbo].[ETLDerivedValue]
    ADD CONSTRAINT [PK_ETLDerivedValue] PRIMARY KEY CLUSTERED ([ETLDerivedValueID] ASC) WITH (ALLOW_PAGE_LOCKS = ON, ALLOW_ROW_LOCKS = ON, PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF);
