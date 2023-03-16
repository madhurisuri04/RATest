
CREATE NONCLUSTERED INDEX [IX_tbl_Summary_RskAdj_EDS_Alternative02]
    ON [rev].[tbl_Summary_RskAdj_EDS]
(
    [HICN]
  , [PaymStart]
  , [PlanID]
  , [Model_Year]
  , [PaymentYear]
  , [Factor_category])
    INCLUDE
(
    [Factor_Desc]
  , [Factor]
  , [Factor_Desc_ORIG]
  , [HCC_Number]
  , [RAFT])
    WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF
        , ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100 )