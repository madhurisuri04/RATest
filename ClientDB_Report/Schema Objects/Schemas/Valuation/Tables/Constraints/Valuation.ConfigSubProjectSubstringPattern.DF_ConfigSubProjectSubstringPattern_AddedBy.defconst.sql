ALTER TABLE Valuation.ConfigSubProjectSubstringPattern ADD  CONSTRAINT 
[DF_ConfigSubProjectSubstringPattern_AddedBy]  DEFAULT (USER_NAME()) FOR [AddedBy]
