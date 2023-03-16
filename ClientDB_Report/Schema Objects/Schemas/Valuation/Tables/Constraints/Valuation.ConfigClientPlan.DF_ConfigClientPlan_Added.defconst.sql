ALTER TABLE Valuation.ConfigClientPlan ADD  CONSTRAINT [DF_ConfigClientPlan_Added]  DEFAULT (GETDATE()) FOR [Added]
