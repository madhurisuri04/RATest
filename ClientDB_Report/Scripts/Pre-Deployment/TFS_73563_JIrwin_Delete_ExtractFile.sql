IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ExtractFile]') AND type in (N'U'))
TRUNCATE TABLE [dbo].[ExtractFile]
GO