
CREATE NONCLUSTERED INDEX [IDXNC_tbl_EstRecv_EDS_DiagHCC_RskMod]
    ON [rev].[tbl_EstRecv_EDS_DiagHCC_RskMod]
(
    [HICN] 
  , [RAFT] 
  , [HCC] 
  , [HCC_Number] 
  , [Deleted] 
  , [Payment_year] )
    WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF
        , ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON ) 