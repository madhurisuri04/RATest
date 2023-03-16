CREATE TABLE [dbo].[tbl_Clients](
	[Client_ID] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[Client_Name] [varchar](100) NOT NULL,
	[FTP_Folder] [varchar](100) NOT NULL,
	[Default_User_ID] [int] NULL,
	[Run_Import_Pickup] [bit] NOT NULL,
	[Logo] [image] NULL,
	[Email_Compliance_Officer] [varchar](100) NULL,
	[SharePointRoot] [nvarchar](50) NULL,
	[SharePointDocumentLibrary] [nvarchar](50) NULL,
	[Client_DB] [varchar](128) NULL,
	[DB_Server] [nvarchar](30) NULL,
	[MergeRAPSsubmissions] [bit] NULL,
	[MergeRAPSOutputFolder] [varchar](256) NULL,
	[MergeRAPSFileNameFormat] [varchar](128) NULL,
	[MergeRAPSFileMaxLines] [int] NULL,
	[MergeRAPSFileMaxDiagsPerLine] [int] NULL,
	[Client_DB_CN] [varchar](128) NULL,
	[Client_DB_CN_Server] [varchar](128) NULL,
	[Report_DB] [varchar](128) NULL,
	[Report_DB_Server] [varchar](128) NULL,
 CONSTRAINT [PK_tbl_Clients] PRIMARY KEY CLUSTERED 
(
	[Client_ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 97) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO

ALTER TABLE [dbo].[tbl_Clients] ADD  CONSTRAINT [DF_tbl_Clients_Run_Import_Pickup]  DEFAULT (0) FOR [Run_Import_Pickup]
GO

ALTER TABLE [dbo].[tbl_Clients] ADD  CONSTRAINT [DF_tbl_Clients_MergeRAPSFileMaxLines]  DEFAULT ((1000000)) FOR [MergeRAPSFileMaxLines]
GO

ALTER TABLE [dbo].[tbl_Clients] ADD  CONSTRAINT [DF_tbl_Clients_MergeRAPSFileMaxDiagsPerLine]  DEFAULT ((10)) FOR [MergeRAPSFileMaxDiagsPerLine]
GO


