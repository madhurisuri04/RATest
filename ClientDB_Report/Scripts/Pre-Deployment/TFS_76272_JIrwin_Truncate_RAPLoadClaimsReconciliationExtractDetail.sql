-- Truncate etl.RAPSLoadClaimsReconciliationExtractDetail table
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'etl.RAPSLoadClaimsReconciliationExtractDetail') AND type in (N'U'))
TRUNCATE TABLE etl.RAPSLoadClaimsReconciliationExtractDetail
GO