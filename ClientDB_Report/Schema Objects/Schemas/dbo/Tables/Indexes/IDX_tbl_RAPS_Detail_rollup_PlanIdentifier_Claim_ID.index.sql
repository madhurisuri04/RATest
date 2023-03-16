CREATE NONCLUSTERED INDEX [IDX_tbl_RAPS_Detail_rollup_PlanIdentifier_Claim_ID]
ON [dbo].[tbl_RAPS_Detail_rollup] ([PlanIdentifier],[Claim_ID])
INCLUDE ([HICN],[From_Date1],[Thru_date1],[Delete_Ind1],[EXPORTED_FILEID],[RAPSStatusID],[OutboundFileID])
WITH (PAD_INDEX = ON, FillFactor = 80 ) ON [PRIMARY]