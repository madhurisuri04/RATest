CREATE TABLE [dbo].[ETLValidationLOBState]
(
	ETLValidationLOBStateID [int] IDENTITY(1,1) NOT NULL,
	ETLValidationID [int] NOT NULL,
	LineOfBusinessID [tinyint] NOT NULL,
	StateCodeID [tinyint] NOT NULL
)
