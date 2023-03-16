/*
Author:					Rakshit Lall
Date:					10/31/2017
Version:				1.2
Change Description:		Added entry for 2017 RiskModelYear

* Version History	:
  Author			DATE		Version#	TFS Ticket#		Description
* -----------------	----------	--------	-----------		------------
	Rakshit Lall	4/9/2018	1.3			66782			Added new RiskModelID = 4 entry
	Rakshit Lall	10/30/2018	1.4			72190			Added new RiskModelID = 5 entry for 2018 year
*/

SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE 
	@Today DATETIME = GETDATE(),
	@UserID VARCHAR(128) = SUSER_SNAME()

MERGE [log].[RiskModelControlDate]  AS target
USING (
	SELECT 5 AS RiskModelId, 2018 as RiskModelYear , '2018-01-01 00:00:00.0000000' as StartClaimReceivedDate, '2019-04-30 23:59:59.9999999' as EndClaimReceivedDate , '2019-04-30 23:59:59.9999999' as RiskScoreFreezeDate, 60 'DaysActiveAfterFreezeDate'
UNION ALL
	SELECT 4 AS RiskModelId, 2017 as RiskModelYear , '2017-01-01 00:00:00.0000000' as StartClaimReceivedDate, '2018-04-30 23:59:59.9999999' as EndClaimReceivedDate , '2018-04-30 23:59:59.9999999' as RiskScoreFreezeDate, 60 'DaysActiveAfterFreezeDate'
UNION ALL
	SELECT 3 AS RiskModelId, 2017 as RiskModelYear , '2017-01-01 00:00:00.0000000' as StartClaimReceivedDate, '2018-04-30 23:59:59.9999999' as EndClaimReceivedDate , '2018-04-30 23:59:59.9999999' as RiskScoreFreezeDate, 60 'DaysActiveAfterFreezeDate'
UNION ALL
	SELECT 3 AS RiskModelId, 2016 as RiskModelYear , '2016-01-01 00:00:00.0000000' as StartClaimReceivedDate, '2017-04-30 23:59:59.9999999' as EndClaimReceivedDate , '2017-04-30 23:59:59.9999999' as RiskScoreFreezeDate, 60 'DaysActiveAfterFreezeDate'
UNION ALL
	SELECT 2 AS RiskModelId, 2014 as RiskModelYear , '2014-01-01 00:00:00.0000000' as StartClaimReceivedDate, '2015-04-30 23:59:59.9999999' as EndClaimReceivedDate , '2015-04-30 23:59:59.9999999' as RiskScoreFreezeDate, 200 'DaysActiveAfterFreezeDate'
UNION ALL
	SELECT 2 AS RiskModelId, 2015 as RiskModelYear , '2015-01-01 00:00:00.0000000' as StartClaimReceivedDate, '2016-04-30 23:59:59.9999999' as EndClaimReceivedDate , '2016-04-30 23:59:59.9999999' as RiskScoreFreezeDate, 60 'DaysActiveAfterFreezeDate'
UNION ALL
	SELECT 1 AS RiskModelId, 2014 as RiskModelYear , '2014-01-01 00:00:00.0000000' as StartClaimReceivedDate, '2015-04-30 23:59:59.9999999' as EndClaimReceivedDate , '2015-04-30 23:59:59.9999999' as RiskScoreFreezeDate, 200 'DaysActiveAfterFreezeDate'
UNION ALL
	SELECT 1 AS RiskModelId, 2015 as RiskModelYear , '2015-01-01 00:00:00.0000000' as StartClaimReceivedDate, '2016-04-30 23:59:59.9999999' as EndClaimReceivedDate , '2016-04-30 23:59:59.9999999' as RiskScoreFreezeDate, 60 'DaysActiveAfterFreezeDate'
) AS source
ON 
	(
		target.RiskModelId = source.RiskModelId
	AND 
		target.RiskModelYear = source.RiskModelYear 
	)
WHEN MATCHED 
	AND 
		(
			target.StartClaimReceivedDate <> source.StartClaimReceivedDate OR 
			target.EndClaimReceivedDate <> source.EndClaimReceivedDate OR 
			target.RiskScoreFreezeDate <> source.RiskScoreFreezeDate OR 
			target.DaysActiveAfterFreezeDate <> source.DaysActiveAfterFreezeDate 
		) 
THEN 
    UPDATE SET 
		StartClaimReceivedDate = source.StartClaimReceivedDate,
		EndClaimReceivedDate = source.EndClaimReceivedDate,
		RiskScoreFreezeDate = source.RiskScoreFreezeDate,
		DaysActiveAfterFreezeDate = source.DaysActiveAfterFreezeDate,
		UpdateDateTime = @Today,
		UpdateUserId = @UserID,
		UpdateLoadId = -300
WHEN NOT MATCHED 
THEN	
	INSERT 
		(
			RiskModelId, 
			RiskModelYear, 
			StartClaimReceivedDate, 
			EndClaimReceivedDate,
			RiskScoreFreezeDate,
			CreateDateTime,  
			UpdateDateTime,   
			CreateLoadid,
			UpdateLoadId,
			CreateUserId, 
			UpdateUserId
		)
    VALUES 
		(
			source.RiskModelId, 
			source.RiskModelYear,
			Source.StartClaimReceivedDate,
			Source.EndClaimReceivedDate,
			Source.RiskScoreFreezeDate,
			@Today,
			@Today, 
			-300,
			-300, 
			@UserID,
			@UserID
		);