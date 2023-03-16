CREATE TABLE [dbo].[tbl_ClientSettingTypes](
	[ClientSettingTypeID] [int] NOT NULL,
	[SettingType] [varchar](50) NOT NULL,
	[Description] [varchar](500) NULL,
	[DefaultSettingValue] [varchar](256) NULL
) ON [PRIMARY]
