CREATE NONCLUSTERED INDEX IDX_tbl_RAPS_Detail_rollup_OutboundFileID
ON [dbo].[tbl_RAPS_Detail_rollup] ([OutboundFileID])
WITH (  FILLFACTOR = 80)