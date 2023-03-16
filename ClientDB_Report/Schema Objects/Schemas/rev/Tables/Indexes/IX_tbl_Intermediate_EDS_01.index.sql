CREATE NONCLUSTERED INDEX [IX_tbl_Intermediate_EDS_01]
    ON [rev].[tbl_Intermediate_EDS]
(
    [HICN] ASC
  , [RAFT] ASC
  , [HCC] ASC
  , [HCC_Number] ASC
  , [Deleted] ASC
  , [PaymentYear] ASC
  , [ModelYear] ASC)
    WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF
        , ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON )


