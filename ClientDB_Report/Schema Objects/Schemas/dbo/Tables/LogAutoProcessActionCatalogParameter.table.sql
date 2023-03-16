CREATE TABLE [dbo].[LogAutoProcessActionCatalogParameter](
	[LogAutoProcessActionCatalogParameterId] [int] IDENTITY(1,1) NOT NULL,
	[AutoProcessActionCatalogParameterId] [int] NULL,
	[AutoProcessActionCatalogId] [int] NULL,
	[AutoProcessActionCatalogId_old] [int] NULL,
	[ParameterName] [varchar](129) NULL,
	[ParameterName_old] [varchar](129) NULL,
	[OrdPosition] [int] NULL,
	[OrdPosition_old] [int] NULL,
	[DataType] [varchar](128) NULL,
	[DataType_old] [varchar](128) NULL,
	[MaxLength] [int] NULL,
	[MaxLength_old] [int] NULL,
	[Nullable] [bit] NULL,
	[Nullable_old] [bit] NULL,
	[Output] [bit] NULL,
	[Output_old] [bit] NULL,
	[ParameterMap] [varchar](133) NULL,
	[ParameterMap_old] [varchar](133) NULL,
	[Edited] [datetime] NULL,
	[EditedBy] [varchar](257) NULL,
	[Action] [char](1) NULL


	)
 