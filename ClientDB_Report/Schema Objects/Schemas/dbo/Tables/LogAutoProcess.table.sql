CREATE TABLE [dbo].[LogAutoProcess](
	[LogAutoProcessId] [int] IDENTITY(1,1) NOT NULL,
	[AutoProcessId] [int] NULL,
	[AutoProcessName] [varchar] (512) NULL,
	[AutoProcessName_old] [varchar] (512) NULL,
	[ActiveBDate] [date] NULL,
	[ActiveBDate_old] [date] NULL,
	[ActiveEDate] [date] NULL,
	[ActiveEDate_old] [date] NULL,
	[Added] [datetime] NULL,
	[Added_old] [datetime] NULL,
	[AddedBy] [varchar](257) NULL,
	[AddedBy_old] [varchar](257) NULL,
	[Edited] [datetime] NULL,
    [EditedBy] [varchar](257) NULL,
	[Action] [char](1) NULL

	)