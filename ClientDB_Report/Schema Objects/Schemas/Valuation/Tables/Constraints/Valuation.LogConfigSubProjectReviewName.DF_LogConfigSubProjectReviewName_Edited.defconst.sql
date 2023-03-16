ALTER TABLE Valuation.LogConfigSubProjectReviewName ADD  CONSTRAINT [DF_LogConfigSubProjectReviewName_Edited]  DEFAULT (GETDATE()) FOR [Edited]
