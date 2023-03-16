-- Truncate dbo.tbl_Plan_Claims_rollup table
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'dbo.tbl_Plan_Claims_rollup') AND type in (N'U'))
TRUNCATE TABLE dbo.tbl_Plan_Claims_rollup
GO