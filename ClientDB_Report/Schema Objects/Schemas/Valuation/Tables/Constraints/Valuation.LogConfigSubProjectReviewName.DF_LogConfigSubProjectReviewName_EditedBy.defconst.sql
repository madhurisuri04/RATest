ALTER TABLE Valuation.LogConfigSubProjectReviewName ADD  CONSTRAINT [DF_LogConfigSubProjectReviewName_EditedBy]  DEFAULT (USER_NAME()) FOR [EditedBy]
