ALTER TABLE [Valuation].[AutoProcessWorkList]
ADD CONSTRAINT [DF_AutoProcessWorkList_PreRunSecs]
DEFAULT ((99999)) FOR [PreRunSecs]