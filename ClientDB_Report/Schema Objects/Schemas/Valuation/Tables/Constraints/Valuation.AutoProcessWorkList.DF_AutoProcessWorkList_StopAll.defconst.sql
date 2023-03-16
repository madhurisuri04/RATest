ALTER TABLE [Valuation].[AutoProcessWorkList]
ADD CONSTRAINT [DF_AutoProcessWorkList_StopAll]
DEFAULT ((0)) FOR [StopAll]