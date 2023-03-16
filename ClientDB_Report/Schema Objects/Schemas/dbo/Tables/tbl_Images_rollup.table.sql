CREATE TABLE [dbo].[tbl_Images_rollup](
	tbl_Images_rollupID	int Identity NOT NULL,
	PlanIdentifier				smallint Not Null,
	[ImageID] [int] NOT NULL,
	[ImageName] [varchar](255) NOT NULL,
	[DateImageReceived] [smalldatetime] NULL,
	[HICN] [varchar](50) NULL,
	[ProviderID] [varchar](50) NULL
	)