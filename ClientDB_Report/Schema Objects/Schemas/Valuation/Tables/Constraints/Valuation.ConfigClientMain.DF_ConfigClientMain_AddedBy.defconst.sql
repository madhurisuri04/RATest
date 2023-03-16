ALTER TABLE Valuation.ConfigClientMain ADD  CONSTRAINT [DF_ConfigClientMain_AddedBy]  DEFAULT (USER_NAME()) FOR [AddedBy]
