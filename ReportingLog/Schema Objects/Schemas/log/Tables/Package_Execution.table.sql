CREATE TABLE [log].[Package_Execution](
	[package_log_id] [bigint] IDENTITY(-2147483600,1) NOT NULL, 
	[parent_package_log_key] [bigint] NULL,
	[package_guid] [uniqueidentifier] NOT NULL,
	[package_name] [varchar](50) NULL,
	[execution_guid] [uniqueidentifier] NOT NULL,
	[start_time] [datetime] NOT NULL,
	[end_time] [datetime] NULL,
	[duration_sec]  AS (datediff(second,[start_time],[end_time])) PERSISTED,
	[status] [varchar](10) NOT NULL,
	[error_source] [varchar](1024) NULL,
	[error_description] [varchar](2048) NULL,
	[load_id] [bigint] NULL
) 