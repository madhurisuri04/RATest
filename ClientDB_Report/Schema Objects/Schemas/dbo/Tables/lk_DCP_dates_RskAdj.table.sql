CREATE TABLE [dbo].[lk_DCP_dates_RskAdj](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[PayMonth] [varchar](6) NOT NULL,
	[MOR_DCP] [varchar](50) NOT NULL,
	[Full_Year] [varchar](1) NOT NULL,
	[Description] [varchar](50) NOT NULL,
	[Group_Year] [int] NOT NULL,
	[Order] [int] NOT NULL,
	[DCP_Start] [datetime] NOT NULL,
	[DCP_End] [datetime] NOT NULL,
	[Initial_Sweep_Date] [datetime] NULL,
	[Final_Sweep_Date] [datetime] NULL,
	[Mid_Year_Update] [varchar](1) NULL,
	[MOR_Mid_Year_Update] [varchar](1) NULL
) 

