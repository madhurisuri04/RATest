ALTER TABLE Valuation.LogConfigStaticParameters ADD  CONSTRAINT [DF_LogConfigStaticParameters_Edited]  DEFAULT (GETDATE()) FOR [Edited]
