ALTER TABLE [Valuation].[AutoProcessWorkList]
ADD CONSTRAINT [DF_AutoProcessWorkList_Phase]
DEFAULT ((1)) FOR [Phase]