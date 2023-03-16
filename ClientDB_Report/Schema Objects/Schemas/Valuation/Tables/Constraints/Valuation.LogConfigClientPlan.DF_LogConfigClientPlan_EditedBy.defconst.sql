ALTER TABLE Valuation.LogConfigClientPlan ADD  CONSTRAINT [DF_LogConfigClientPlan_EditedBy]  DEFAULT (USER_NAME()) FOR [EditedBy]
