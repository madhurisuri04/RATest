ALTER TABLE Valuation.ConfigClientPlan ADD  CONSTRAINT [DF_ConfigClientPlan_AddedBy]  DEFAULT (USER_NAME()) FOR [AddedBy]
