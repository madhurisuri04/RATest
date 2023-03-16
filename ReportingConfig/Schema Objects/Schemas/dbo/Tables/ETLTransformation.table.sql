CREATE TABLE [dbo].[ETLTransformation](
	[ETLTransformationID] [int] IDENTITY(1,1) NOT NULL,
	[DomainCD] [varchar](10) NULL,
	[TransformationDescription] [varchar](1000) NULL,
	[TableName] [varchar](128) NULL,
	[ColumnName] [varchar](128) NULL,
	[GlobalLOBState] [bit] NOT NULL,
	[GlobalClientVendor] [bit] NOT NULL,
	[DisabledDateTime] [datetime2](7) NOT NULL
	)