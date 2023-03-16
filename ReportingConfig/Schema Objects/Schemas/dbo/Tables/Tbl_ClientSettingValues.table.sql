CREATE TABLE [dbo].[tbl_ClientSettingValues](
	[ClientSettingValueID] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[Client_ID] [int] NOT NULL,
	[ClientSettingTypeID] [int] NOT NULL,
	[SettingValue] [varchar](256) NULL,
	[ApplicationCode] [varchar](10) NULL
) ON [PRIMARY]