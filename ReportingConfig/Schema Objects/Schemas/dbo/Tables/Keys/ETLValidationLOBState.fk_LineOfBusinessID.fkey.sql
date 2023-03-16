ALTER TABLE [dbo].[ETLValidationLOBState]
	ADD CONSTRAINT [fk_LineOfBusinessID] 
	FOREIGN KEY (LineOfBusinessID)
	REFERENCES ref.LineOfBusiness (LineOfBusinessID)	

