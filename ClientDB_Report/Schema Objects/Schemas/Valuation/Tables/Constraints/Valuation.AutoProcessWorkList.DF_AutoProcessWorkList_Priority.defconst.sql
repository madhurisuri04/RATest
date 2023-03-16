ALTER TABLE [Valuation].[AutoProcessWorkList]
ADD CONSTRAINT [DF_AutoProcessWorkList_Priority]
DEFAULT ((99)) FOR [Priority]