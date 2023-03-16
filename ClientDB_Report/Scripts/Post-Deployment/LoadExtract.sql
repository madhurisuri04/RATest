/*******************************************************************************************************************************       
* Author       		:	Rakshit Lall
* Date          	:	08/04/2017
* Version			:	1.0
* Project			:	REV R&A Extracts
* Version History	:   66210
* Purpose			:	Add types of extracts
  Author			Date		Version#	TFS Ticket#		Description
* -----------------	----------	--------	-----------		------------ 
	Rakshit Lall	4/9/2018	1.1			70510			Added new extract entries for ER detail and Part D New HCC
	Rohit Ambala	04/25/2018	1.2			69456			Added New Extract for MBI HICN Crosswalk.
	Josh Irwin		10/5/2018	1.3			73563			Added new extracts for RAPS Claims Reconciliation report
	Rakshit Lall	11/2/2018	1.4			73973			Added new entry for Part C HCC EDS And RAPS reconciliation
	Josh Irwin		10/11/2019	1.5			77017			Added new extracts for QRAPS Reconciliation report
*********************************************************************************************************************************/

DECLARE
	@Today DATETIME = GETDATE(),
	@User VARCHAR(500) = SYSTEM_USER

MERGE [dbo].[Extract] AS TARGET
USING
(
SELECT
    1 AS ExtractID
   ,'RE' AS AppCode
   ,'EstimatedReceivableExtract' AS ExtractName
   ,'RiskAdjustment' AS ExtractGroup
   ,1 AS ActiveFlag
   ,@Today AS CreatedDate
   ,@User AS CreatedUser
   ,@Today AS UpdatedDate
   ,@User AS UpdatedUser

UNION ALL

SELECT
    2 AS ExtractID
   ,'RE' AS AppCode
   ,'EstimatedReceivablePartDExtract' AS ExtractName
   ,'RiskAdjustment' AS ExtractGroup
   ,1 AS ActiveFlag
   ,@Today AS CreatedDate
   ,@User AS CreatedUser
   ,@Today AS UpdatedDate
   ,@User AS UpdatedUser

UNION ALL

SELECT
    3 AS ExtractID
   ,'RE' AS AppCode
   ,'PartDNewHCCEDSAndRAPSExtract' AS ExtractName
   ,'RiskAdjustment' AS ExtractGroup
   ,1 AS ActiveFlag
   ,@Today AS CreatedDate
   ,@User AS CreatedUser
   ,@Today AS UpdatedDate
   ,@User AS UpdatedUser

UNION ALL

SELECT
    4 AS ExtractID
   ,'REC' AS AppCode
   ,'MBIHICNCrosswalkExtract' AS ExtractName
   ,'Operational' AS ExtractGroup
   ,1 AS ActiveFlag
   ,@Today AS CreatedDate
   ,@User AS CreatedUser
   ,@Today AS UpdatedDate
   ,@User AS UpdatedUser

UNION ALL

SELECT
    5 AS ExtractID
   ,'RAPS' AS AppCode
   ,'RAPSReconciliationClaimsDetailExtract' AS ExtractName
   ,'Operational' AS ExtractGroup
   ,1 AS ActiveFlag
   ,@Today AS CreatedDate
   ,@User AS CreatedUser
   ,@Today AS UpdatedDate
   ,@User AS UpdatedUser

UNION ALL

SELECT
    6 AS ExtractID
   ,'RE' AS AppCode
   ,'PartCNewHCCRAPSEDSReconciliationExtract' AS ExtractName
   ,'RiskAdjustment' AS ExtractGroup
   ,1 AS ActiveFlag
   ,@Today AS CreatedDate
   ,@User AS CreatedUser
   ,@Today AS UpdatedDate
   ,@User AS UpdatedUser

UNION ALL

SELECT
    7 AS ExtractID
   ,'RAPS' AS AppCode
   ,'QRAPSReconciliationDetailExtract' AS ExtractName
   ,'Operational' AS ExtractGroup
   ,1 AS ActiveFlag
   ,@Today AS CreatedDate
   ,@User AS CreatedUser
   ,@Today AS UpdatedDate
   ,@User AS UpdatedUser
)
AS SOURCE
ON (TARGET.ExtractID = SOURCE.ExtractID)
WHEN MATCHED THEN
	UPDATE SET
	TARGET.ExtractID	= SOURCE.ExtractID,
	TARGET.AppCode		= SOURCE.AppCode,
	TARGET.ExtractName	= SOURCE.ExtractName,
	TARGET.ExtractGroup = SOURCE.ExtractGroup,
	TARGET.ActiveFlag	= SOURCE.ActiveFlag,
	TARGET.CreatedDate	= SOURCE.CreatedDate,
	TARGET.CreatedUser	= SOURCE.CreatedUser,
	TARGET.UpdatedDate	= SOURCE.UpdatedDate,
	TARGET.UpdatedUser	= SOURCE.UpdatedUser
WHEN NOT MATCHED THEN
	INSERT
	(
		ExtractID,
		AppCode,
		ExtractName,
		ExtractGroup,
		ActiveFlag,
		CreatedDate,
		CreatedUser,
		UpdatedDate,
		UpdatedUser	
	)
	VALUES
	(
		SOURCE.ExtractID,
		SOURCE.AppCode,
		SOURCE.ExtractName,
		SOURCE.ExtractGroup,
		SOURCE.ActiveFlag,
		SOURCE.CreatedDate,
		SOURCE.CreatedUser,
		SOURCE.UpdatedDate,
		SOURCE.UpdatedUser
	);