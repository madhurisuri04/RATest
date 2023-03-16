ALTER TABLE Valuation.LogConfigStaticParameters ADD  CONSTRAINT [DF_LogConfigStaticParameters_EditedBy]  DEFAULT (USER_NAME()) FOR [EditedBy]
