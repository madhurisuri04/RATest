ALTER TABLE [Valuation].[AutoProcessWorkList]
ADD CONSTRAINT [DF_AutoProcessWorkList_Retry]
DEFAULT ((0)) FOR [Retry]