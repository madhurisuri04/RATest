ALTER TABLE Valuation.ConfigSubProjectReviewName ADD  CONSTRAINT [DF_ConfigSubProjectReviewName_AddedBy]  DEFAULT (USER_NAME()) FOR [AddedBy]
