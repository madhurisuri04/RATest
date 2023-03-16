CREATE TABLE [log].[Package_Debug](
[Package_DebugID] int identity(1,1),
	[load_id] [bigint] NULL,
	[load_date] [datetime] NULL,
	[package_name] [varchar](50) NULL,
	[execution_guid] [uniqueidentifier] NOT NULL,
	[message] [varchar](2048) NULL,
	[message_date] [datetime] NULL
) 