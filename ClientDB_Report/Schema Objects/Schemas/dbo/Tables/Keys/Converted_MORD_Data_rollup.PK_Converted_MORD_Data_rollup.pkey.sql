ALTER TABLE [dbo].[Converted_MORD_Data_rollup]
ADD CONSTRAINT [PK_Converted_MORD_Data_rollup]
    PRIMARY KEY CLUSTERED ( [Converted_MORD_Data_rollupID] ASC )
    WITH ( ALLOW_PAGE_LOCKS = ON, ALLOW_ROW_LOCKS = ON, PAD_INDEX = OFF ,
           IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF ,
           FILLFACTOR = 100 
         )
