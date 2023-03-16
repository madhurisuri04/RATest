/****** Object:  Index [IDX_RAPS_DiagHCC_rollup_thrudate_diagcode]    Script Date: 01/14/2016 08:45:20 ******/
CREATE NONCLUSTERED INDEX [IDX_RAPS_DiagHCC_rollup_thrudate_diagcode]
  ON [dbo].[RAPS_DiagHCC_rollup] ( [ThruDate] ASC, [DiagnosisCode] ASC )
  INCLUDE ( [Voided_by_RAPSID]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80) ON [PRIMARY]
