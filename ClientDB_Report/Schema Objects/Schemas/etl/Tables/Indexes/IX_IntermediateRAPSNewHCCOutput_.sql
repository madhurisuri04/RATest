CREATE NONCLUSTERED INDEX [IX_IntermediateRAPSNewHCCOutput__payment_year__paymstart]
ON [etl].[IntermediateRAPSNewHCCOutput] (
                                      [PaymentYear],
                                      [PaymStart]
                                  )
WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF,
      ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80
     )
ON [PRIMARY];
GO
