ALTER TABLE [Valuation].[AutoProcess]
ADD CONSTRAINT [DF_AutoProcess_AddedBy]
DEFAULT (USER_NAME()) FOR [AddedBy]