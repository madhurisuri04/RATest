ALTER TABLE Valuation.LogConfigClientMain ADD  CONSTRAINT [DF_LogConfigClientMain_EditedBy]  DEFAULT (USER_NAME()) FOR [EditedBy]
