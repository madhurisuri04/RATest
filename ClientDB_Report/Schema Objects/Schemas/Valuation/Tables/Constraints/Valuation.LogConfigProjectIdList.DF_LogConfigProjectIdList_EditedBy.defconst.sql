ALTER TABLE Valuation.LogConfigProjectIdList ADD  CONSTRAINT [DF_LogConfigProjectIdList_EditedBy]  DEFAULT (USER_NAME()) FOR [EditedBy]
