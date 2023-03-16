CREATE NONCLUSTERED INDEX [IX_tbl_Intermediate_RAP_01] ON [rev].[tbl_Intermediate_RAPS]
    (
    [HICN],
    [RAFT],
    [HCC],
    [HCC_Number],
    [Deleted],
    [PaymentYear],
    [ModelYear]
    )WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = ON, DROP_EXISTING = OFF
    , ONLINE = ON, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON )

