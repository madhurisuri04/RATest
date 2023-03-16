ALTER TABLE [Valuation].[AutoProcessActionCatalog]
ADD CONSTRAINT [DF_AutoProcessAction_CatalogPopulateParameter]
DEFAULT ((0)) FOR [PopulateParameter]