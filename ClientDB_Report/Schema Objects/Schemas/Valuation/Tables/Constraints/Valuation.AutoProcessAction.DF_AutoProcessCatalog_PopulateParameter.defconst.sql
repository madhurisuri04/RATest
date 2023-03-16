ALTER TABLE [Valuation].[AutoProcessAction]
ADD CONSTRAINT [DF_AutoProcessCatalog_PopulateParameter]
DEFAULT ((0)) FOR [PopulateParameter]