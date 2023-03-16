CREATE NONCLUSTERED INDEX [IDX_EDS_DiagHCC_rollup_thrudate_diagcode]
    ON [rev].[EDS_DiagHCC_rollup]
(
    [ThruDate]
  , [DiagnosisCode])
    INCLUDE
(
    [Voided_by_EDSID])
    WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF
        , ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80 )

