CREATE TABLE [log].[Package_Variable_Change](
[Package_Variable_ChangeID] int identity(1,1),
	[package_name] [varchar](50) NULL,
	[package_log_id] [bigint] NULL,
	[variable_name] [varchar](255) NULL,
	[variable_value] [varchar](max) NULL,
	[variable_change_date] [datetime] NULL,
	[execution_guid] [uniqueidentifier] NULL,
	[load_id] [bigint] NULL
)
