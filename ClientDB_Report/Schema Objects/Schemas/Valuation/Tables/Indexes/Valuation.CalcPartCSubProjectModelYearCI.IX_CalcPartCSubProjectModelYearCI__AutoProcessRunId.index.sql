CREATE NONCLUSTERED INDEX [IX_CalcPartCSubProjectModelYearCI__AutoProcessRunId] ON [Valuation].[CalcPartCSubProjectModelYearCI] 
(
	[AutoProcessRunId] ASC,
	[ClientId] ASC,
	[PMH_Attestation] ASC,
	[Model_Year] ASC
)
INCLUDE ( [HCCTotal],
[AnnualizedEstimatedValue]) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF
, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON
, ALLOW_PAGE_LOCKS  = ON ) 
