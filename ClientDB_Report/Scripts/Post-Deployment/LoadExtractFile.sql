/*******************************************************************************************************************************       
* Author       		:	Rakshit Lall
* Date          	:	08/04/2017
* Version			:	1.0
* Project			:	REV R&A ExtractEngine 
* TFS				:   66210
* Purpose			:	Load ExtractFile
  Author			Date		Version#	TFS Ticket#		Description
* -----------------	----------	--------	-----------		------------
	Rakshit Lall	4/9/2018	1.1			70510			Added new extract entries for ER detail and Part D New HCC
	Rohit Ambala	04/25/2018	1.2			69456			Added MBI HICN Crosswalk Entry.
	Josh Irwin		10/5/2018	1.3			73563			Added new extract for RAPS Claims Reconciliation report
	Rakshit Lall	11/2/2018	1.4			73973			Added new entry for Part C HCC EDS And RAPS reconciliation
	Josh Irwin		2/19/2019	1.5			74723			Added logic for UseClientDB for RAPS Claims Reconciliation extract
	Josh Irwin		10/11/2019	1.6			77017			Added new extract for QRAPS Reconciliation report
*********************************************************************************************************************************/

SET IDENTITY_INSERT dbo.ExtractFile ON;

DECLARE
	@Today DATETIME = GETDATE(),
	@User VARCHAR(500) = SYSTEM_USER,
	@EstimatedReceivableExtract BIGINT = (SELECT ExtractID FROM dbo.Extract WHERE ExtractName = 'EstimatedReceivableExtract'),
	@EstimatedReceivablePartDExtract BIGINT = (SELECT ExtractID FROM dbo.Extract WHERE ExtractName = 'EstimatedReceivablePartDExtract'),
	@PartDNewHCCEDSAndRAPSExtract BIGINT = (SELECT ExtractID FROM dbo.Extract WHERE ExtractName = 'PartDNewHCCEDSAndRAPSExtract'),
	@MBIHICNCrosswalkExtract BIGINT = (SELECT ExtractID FROM dbo.Extract WHERE ExtractName = 'MBIHICNCrosswalkExtract'),
	@RAPSReconciliationClaimsDetailExtract BIGINT = (SELECT ExtractID FROM dbo.Extract WHERE ExtractName = 'RAPSReconciliationClaimsDetailExtract'),
	@PartCNewHCCRAPSEDSReconciliationExtract BIGINT = (SELECT ExtractID FROM dbo.Extract WHERE ExtractName = 'PartCNewHCCRAPSEDSReconciliationExtract'),
	@QRAPSReconciliationDetailExtract BIGINT = (SELECT ExtractID FROM dbo.Extract WHERE ExtractName = 'QRAPSReconciliationDetailExtract')

--SELECT
--	@EstimatedReceivableExtract,
--	@EstimatedReceivablePartDExtract,
--	@PartDNewHCCEDSAndRAPSExtract,
--	@MBIHICNCrosswalkExtract,
--	@RAPSReconciliationClaimsDetailExtract,
--	@PartCNewHCCRAPSEDSReconciliationExtract,
--	@QRAPSReconciliationDetailExtract

MERGE dbo.ExtractFile AS TARGET
USING
( 
SELECT 
	1 AS ExtractFileID,
	@EstimatedReceivableExtract AS ExtractID,
	'EstimatedReceivable-Detail' AS ExtractFileName,
	'StoredProcedure' AS ExtractCodeType,
	'ExtractEstRecvDetailPartC' AS ExtractCodeName,
	@Today AS CreatedDate,
	@User AS CreatedUser,
	@Today AS UpdatedDate,
	@User AS UpdatedUser,
	0 AS UseClientDB

UNION ALL
	
SELECT 
	2 AS ExtractFileID,
	@EstimatedReceivablePartDExtract AS ExtractID,
	'EstimatedReceivablePartD-Detail' AS ExtractFileName,
	'StoredProcedure' AS ExtractCodeType,
	'ExtractEstRecvDetailPartD' AS ExtractCodeName,
	@Today AS CreatedDate,
	@User AS CreatedUser,
	@Today AS UpdatedDate,
	@User AS UpdatedUser,
	0 AS UseClientDB

UNION ALL

SELECT 
	3 AS ExtractFileID,
	@PartDNewHCCEDSAndRAPSExtract AS ExtractID,
	'PartDNewHCCEDSAndRAPS-Detail' AS ExtractFileName,
	'StoredProcedure' AS ExtractCodeType,
	'ExtractPartDNewHCCEDSAndRAPS' AS ExtractCodeName,
	@Today AS CreatedDate,
	@User AS CreatedUser,
	@Today AS UpdatedDate,
	@User AS UpdatedUser,
	0 AS UseClientDB

UNION ALL

SELECT 
	4 AS ExtractFileID,
	@MBIHICNCrosswalkExtract AS ExtractID,
	'MBIHICNCrosswalk-Detail' AS ExtractFileName,
	'StoredProcedure' AS ExtractCodeType,
	'MBIHICNCrosswalkExtract' AS ExtractCodeName,
	@Today AS CreatedDate,
	@User AS CreatedUser,
	@Today AS UpdatedDate,
	@User AS UpdatedUser,
	0 AS UseClientDB

UNION ALL

SELECT 
	5 AS ExtractFileID,
	@RAPSReconciliationClaimsDetailExtract AS ExtractID,
	'RAPSReconciliationClaimsDetail' AS ExtractFileName,
	'StoredProcedure' AS ExtractCodeType,
	'ExtractRAPSReconciliationClaimsDetail' AS ExtractCodeName,
	@Today AS CreatedDate,
	@User AS CreatedUser,
	@Today AS UpdatedDate,
	@User AS UpdatedUser,
	1 AS UseClientDB

UNION ALL

SELECT 
	6 AS ExtractFileID,
	@PartCNewHCCRAPSEDSReconciliationExtract AS ExtractID,
	'PartCHCCRAPSEDSReconciliation-Detail' AS ExtractFileName,
	'StoredProcedure' AS ExtractCodeType,
	'ExtractPartCHCCRAPSEDSReconciliation' AS ExtractCodeName,
	@Today AS CreatedDate,
	@User AS CreatedUser,
	@Today AS UpdatedDate,
	@User AS UpdatedUser,
	0 AS UseClientDB

UNION ALL

SELECT 
	7 AS ExtractFileID,
	@QRAPSReconciliationDetailExtract AS ExtractID,
	'QRAPSReconciliationDetail' AS ExtractFileName,
	'StoredProcedure' AS ExtractCodeType,
	'ExtractQRAPSReconciliationDetail' AS ExtractCodeName,
	@Today AS CreatedDate,
	@User AS CreatedUser,
	@Today AS UpdatedDate,
	@User AS UpdatedUser,
	1 AS UseClientDB
)
AS SOURCE
ON (TARGET.ExtractFileID = SOURCE.ExtractFileID)
WHEN MATCHED THEN
	UPDATE SET
	TARGET.ExtractID		= SOURCE.ExtractID,
	TARGET.ExtractFileName	= SOURCE.ExtractFileName,
	TARGET.ExtractCodeType	= SOURCE.ExtractCodeType,
	TARGET.ExtractCodeName	= SOURCE.ExtractCodeName,
	TARGET.UpdatedDate		= SOURCE.UpdatedDate,
	TARGET.UpdatedUser		= SOURCE.UpdatedUser,
	TARGET.UseClientDB		= SOURCE.UseClientDB
WHEN NOT MATCHED THEN
	INSERT
	(
		ExtractFileID
		,ExtractID
		,ExtractFileName
		,ExtractCodeType
		,ExtractCodeName
		,CreatedDate
		,CreatedUser
		,UpdatedDate
		,UpdatedUser
		,UseClientDB
)
	VALUES
	(
		SOURCE.ExtractFileID,
		SOURCE.ExtractID,
		SOURCE.ExtractFileName,
		SOURCE.ExtractCodeType,
		SOURCE.ExtractCodeName,
		SOURCE.CreatedDate,
		SOURCE.CreatedUser,
		SOURCE.UpdatedDate,
		SOURCE.UpdatedUser,
		SOURCE.UseClientDB
	);
	
SET IDENTITY_INSERT dbo.ExtractFile OFF;