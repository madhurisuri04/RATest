/*******************************************************************************************************************************       
* Author       		:	Rakshit Lall
* Date          	:	08/04/2017
* Version			:	1.0
* Project			:	REV R&A Extracts
* Version History	:   66210
* Purpose			:	Add values for Extract statuses
  Author			Date		Version#	TFS Ticket#		Description
* -----------------	----------	--------	-----------		------------ 

*********************************************************************************************************************************/

SET IDENTITY_INSERT [ref].[ExtractStatus] ON;

DECLARE
	@Today DATETIME = GETDATE(),
	@User VARCHAR(256) = SUSER_NAME()

MERGE [ref].[ExtractStatus] AS TARGET
USING
(
SELECT
	1 AS ExtractStatusID,
	'Delivered' AS ExtractStatusCode,
	'Extract File Delivered' AS ExtractStatusDesc,
	@Today AS CreatedDate,
	@User AS CreatedUser
	
UNION ALL
SELECT
	2 AS ExtractStatusID,
	'New' AS ExtractStatusCode,
	'Extract Request Created' AS ExtractStatusDesc,
	@Today AS CreatedDate,
	@User AS CreatedUser
	
UNION ALL
SELECT
	3 AS ExtractStatusID,
	'QueuedForDataLoad' AS ExtractStatusCode,
	'Extract Data Load Inprogress' AS ExtractStatusDesc,
	@Today AS CreatedDate,
	@User AS CreatedUser
	
UNION ALL
SELECT
	4 AS ExtractStatusID,
	'QueuedForDelivery' AS ExtractStatusCode,
	'Extract File Being Delivered' AS ExtractStatusDesc,
	@Today AS CreatedDate,
	@User AS CreatedUser
	
UNION ALL
SELECT
	5 AS ExtractStatusID,
	'QueuedForFileCreation' AS ExtractStatusCode,
	'Extract File Creation InProgress' AS ExtractStatusDesc,
	@Today AS CreatedDate,
	@User AS CreatedUser
)
AS SOURCE
ON (TARGET.ExtractStatusID = SOURCE.ExtractStatusID)
WHEN MATCHED THEN
	UPDATE SET
	TARGET.ExtractStatusCode	= SOURCE.ExtractStatusCode,
	TARGET.ExtractStatusDesc	= SOURCE.ExtractStatusDesc,
	TARGET.CreatedDate			= SOURCE.CreatedDate,
	TARGET.CreatedUser			= SOURCE.CreatedUser
WHEN NOT MATCHED THEN
	INSERT
	(
		ExtractStatusID,
		ExtractStatusCode,
		ExtractStatusDesc,
		CreatedDate,
		CreatedUser
	)
	VALUES
	(
		SOURCE.ExtractStatusID,
		SOURCE.ExtractStatusCode,
		SOURCE.ExtractStatusDesc,
		SOURCE.CreatedDate,
		SOURCE.CreatedUser
	);
	
SET IDENTITY_INSERT [ref].[ExtractStatus] OFF;