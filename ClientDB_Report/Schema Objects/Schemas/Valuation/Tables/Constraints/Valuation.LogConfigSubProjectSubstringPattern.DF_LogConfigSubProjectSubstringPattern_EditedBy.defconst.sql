ALTER TABLE Valuation.LogConfigSubProjectSubstringPattern ADD  CONSTRAINT [DF_LogConfigSubProjectSubstringPattern_EditedBy]  DEFAULT (USER_NAME()) FOR [EditedBy]
