/****************************************************************************************************************     
* Name			:	dbo.GetActiveRiskScoreDates                                                 
* Type 			:	Stored Procedure          
* Author       	:	Balaji Dhanabalan
* Date          :	09/03/2015
* Version		:	1.1
* Description	:	Stored  procedure for getting the active risk score dates
* SP call		:	Exec dbo.GetActiveRiskScoreDates
* Version History : 
  Author				Date		Version#	TFS Ticket#		Description
* -----------------		----------	--------	-----------		------------
	Rakshit Lall		12/30/2016	1.2			60555			Removed the hardcode value "RiskModelID = 2" from WHERE clause
	Rakshit Lall		4/10/2018	1.3			66782			Added DISTINCT to avoid duplicate rows
	Will Snodgrass		1/8/2019	1.4			74587			Added RiskModelID to output for use in Risk Score Engine.
******************************************************************************************************************/

CREATE PROCEDURE dbo.GetActiveRiskScoreDates 
AS 
BEGIN

DECLARE 
	@Today DATE ,
	@LastDayOfPreviousMonth DATE,
	@CurrentYear SMALLINT,
	@LastYear SMALLINT

SELECT 
	@Today = CONVERT(DATE,GETDATE()),
	@LastDayOfPreviousMonth = cast((DATEADD(s,-1,DATEADD(mm, DATEDIFF(m,0,GETDATE()),0))) AS DATE),
	@CurrentYear = YEAR(GETDATE()),
	@LastYear = YEAR(GETDATE()) -1 

SELECT DISTINCT
	CAST (RiskModelYear as INT) AS RiskModelYear,
	CONVERT(DATE,StartDOS) 'StartDOS', 
	CASE 
		WHEN RiskScoreAsOfDate = 'Today' AND @Today BETWEEN StartDOS AND EndDOS 
			THEN @Today		
		WHEN RiskScoreAsOfDate = 'Last Day Of Previous Month' AND @LastDayOfPreviousMonth BETWEEN StartDOS AND EndDOS 
			THEN @LastDayOfPreviousMonth
		WHEN ISDATE(RiskScoreAsOfDate) = 1 AND CONVERT(DATE, RiskScoreAsOfDate) BETWEEN StartDOS AND EndDOS 
			THEN CONVERT(DATE, RiskScoreAsOfDate)
		ELSE CONVERT(DATE,EndDOS) 
	END 'EndDOS',
	CONVERT(DATE,StartClaimReceivedDate) 'StartClaimReceivedDate',
	CONVERT(DATE,EndClaimReceivedDate) 'EndClaimReceivedDate',
	RiskModelID
FROM [log].[RiskModelControlDate]
WHERE 
	DATEADD(DD,DaysActiveAfterFreezeDate, RiskScoreFreezeDate) > = @Today

END