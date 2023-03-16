ALTER TABLE [Valuation].[AutoProcessActionCatalog]
ADD CONSTRAINT [DF_AutoProcessActionCatalog_Added]
DEFAULT (GETDATE()) FOR [Added]