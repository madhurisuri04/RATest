ALTER TABLE [Valuation].[AutoProcessActionCatalog]
ADD CONSTRAINT [DF_AutoProcessActionCatalog_AddedBy]
DEFAULT (USER_NAME()) FOR [AddedBy]