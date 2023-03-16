ALTER TABLE [dbo].[ETLValidationLOBState]
	ADD CONSTRAINT [fk_StateCodeID] 
	FOREIGN KEY (StateCodeID)
	REFERENCES ref.StateCode (StateCodeID)	

