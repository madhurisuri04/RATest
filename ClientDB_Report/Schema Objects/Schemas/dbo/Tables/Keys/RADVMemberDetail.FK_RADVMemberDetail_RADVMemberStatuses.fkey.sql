ALTER TABLE [dbo].RADVMemberDetail
	ADD CONSTRAINT [FK_RADVMemberDetail_RADVMemberStatuses] 
	FOREIGN KEY (RADVStatusID)
	REFERENCES RADVMemberStatuses (ID)	

