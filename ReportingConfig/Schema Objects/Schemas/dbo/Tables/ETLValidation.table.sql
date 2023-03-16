CREATE TABLE [dbo].[ETLValidation](
	[ETLValidationID] [int] IDENTITY(1,1) NOT NULL,
	[DomainCD] varchar(10) NULL,
	[ValidationDescription] [varchar](1000) NULL,
	[TableName] [varchar](128) NULL,
	[ColumnName] [varchar](128) NULL,
	[TargetStatusID] [int] NULL, 
	[GlobalLOBState] [bit] NOT NULL,
	[DisabledDateTime] [datetime2] NOT NULL,
	[CreatedDateTime] [datetime2]  NULL
) 

