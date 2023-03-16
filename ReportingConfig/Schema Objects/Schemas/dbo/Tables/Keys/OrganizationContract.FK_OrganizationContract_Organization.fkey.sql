ALTER TABLE [dbo].[OrganizationContract]
	ADD CONSTRAINT [FK_OrganizationContract_Organization] 
	FOREIGN KEY ([OrganizationID])
	REFERENCES [Organization] ([OrganizationID])  ON DELETE NO ACTION ON UPDATE NO ACTION;	


