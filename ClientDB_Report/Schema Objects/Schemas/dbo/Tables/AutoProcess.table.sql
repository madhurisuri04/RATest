CREATE TABLE [dbo].[AutoProcess](
	[AutoProcessId] [int] IDENTITY(1,1) NOT NULL,
	[AutoProcessName] [varchar] (512) NULL,
	[ActiveBDate] [date] NOT NULL,
	[ActiveEDate] [date] NULL,
	[Added] [datetime] NULL,
	[AddedBy] [varchar](257) NULL,
 CONSTRAINT [PK_AutoProcess] PRIMARY KEY CLUSTERED 


(
	[AutoProcessId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
