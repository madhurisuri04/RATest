ALTER TABLE [dbo].[OrganizationContract]
	ADD CONSTRAINT [FK_OrganizationContract_LineOfBusiness] 
	FOREIGN KEY (LineOfBusinessID)
	REFERENCES [ref].[LineOfBusiness] ([LineOfBusinessID]) ON DELETE NO ACTION ON UPDATE NO ACTION;		

