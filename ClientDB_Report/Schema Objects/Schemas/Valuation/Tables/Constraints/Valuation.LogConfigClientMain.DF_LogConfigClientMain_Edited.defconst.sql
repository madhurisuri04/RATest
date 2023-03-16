ALTER TABLE Valuation.LogConfigClientMain ADD  CONSTRAINT [DF_LogConfigClientMain_Edited]  DEFAULT (GETDATE()) FOR [Edited]
