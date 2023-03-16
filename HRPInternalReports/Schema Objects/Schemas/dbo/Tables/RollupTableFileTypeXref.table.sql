CREATE TABLE [dbo].[RollupTableFileTypeXref](
	[RollupTableFileTypeXrefID] [int] IDENTITY(1,1) NOT NULL,
	[RollupTableID] [int] NOT NULL,
	[FileTypeID] [int] NOT NULL,
	[Active] [bit] NOT NULL,
	[CreateDate] [smalldatetime] NOT NULL,
	[ModifiedDate] [smalldatetime] NOT NULL
)