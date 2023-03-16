CREATE NONCLUSTERED INDEX [tbl_Plan_Claims_rollup_ImportFileName]
ON [dbo].[tbl_Plan_Claims_rollup] ([ImportFileName])
WITH (PAD_INDEX = ON, FillFactor = 80 ) ON [PRIMARY]  
