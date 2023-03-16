ALTER TABLE [hst].SummaryPartDRskAdjEDS ADD  CONSTRAINT [PKhstSummaryPartDRskAdjEDS] PRIMARY KEY CLUSTERED 
(
	[SummaryPartDRskAdjEDSID] ASC,
	[PaymentYear] ASC
	
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 100 )
ON [pscheme_SummPY](PaymentYear);

GO 