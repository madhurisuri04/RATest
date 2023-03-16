CREATE INDEX [IX_RADVMemberDetail_NaturalKey]
    ON [dbo].RADVMemberDetail
	([RADVMemberID],[ICDCode],[DateCoded])
	INCLUDE ([ID])