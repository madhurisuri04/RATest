ALTER TABLE Valuation.LogConfigProjectIdList ADD  CONSTRAINT [DF_LogConfigProjectIdList_Edited]  DEFAULT (GETDATE()) FOR [Edited]
