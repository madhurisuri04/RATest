CREATE PROCEDURE [dbo].[spr_dbo_tbl_Plan_Claims_rollup_Sync_ClaimstatusID] @ClientID INT

/********************************************************************************************************************** 
  * Name			:	[dbo].[spr_dbo_tbl_Plan_Claims_rollup_Sync_ClaimstatusID]																			*
  * Type 			:	Stored Procedure																				*
  * Author       	:	Anand																						*
  * Date			:	2020-04-22																						*
  * Version			:	1.0																								*
  * Description		:	This stored procedure will update the ClaimsStatusID in tbl_Plan_Claims_rollup table
						based on plan level table 
  *Notes:																										*
  * Version History :																									*
  * =================																									*
  * Author			Date			Version#    TFS Ticket#		Description												*
  * ---------------	----------		--------    -----------		------------											*
  * Anand			2019-01-07		1.0							Initial	
  * Anand			2020-08-17      1.1			RRI-163/79359	Used RolluptableID to filter
  * Anand			2022-02-22	    1.2         RRI-2171		Optimized Update Logic
  **********************************************************************************************************************/
AS
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;


BEGIN TRY
BEGIN TRANSACTION Update_tbl_Plan_Claims

IF (OBJECT_ID('tempdb.dbo.#WorkList') IS NOT NULL)
BEGIN
    DROP TABLE [#WorkList];
END;

CREATE TABLE [#WorkList]
(
    [DatabaseName] VARCHAR(128),
    [PlanIdentifier] SMALLINT,
    [ClientName] VARCHAR(100),
    [RollupTableConfigID] INT
);

RAISERROR('000', 0, 1) WITH NOWAIT;

DECLARE @DatabaseName VARCHAR(128);
DECLARE @PlanIdentifier SMALLINT;
DECLARE @UploadedDate DATETIME;
DECLARE @FiledateSQL VARCHAR(8000);
DECLARE @MinValue BIGINT;
DECLARE @MaxValue BIGINT;
DECLARE @batchSize BIGINT;
DECLARE @RollupLoad DATETIME 

SET @batchSize = 2000000;

;WITH [CTE_a1]
AS (SELECT [Client_ID] = ISNULL([mg].[MergedClientID], [x].[Client_ID]),
           [x].[Connection_ID]
    FROM [$(HRPReporting)].[dbo].[xref_Client_Connections] [x] WITH (NOLOCK)
        LEFT JOIN [$(HRPReporting)].[dbo].[MergedClients] [mg] WITH (NOLOCK)
            ON [x].[Client_ID] = [mg].[ClientID]
               AND [mg].[Product] = 'RAPS'
               AND [mg].[ClientID] <> 11)


INSERT INTO [#WorkList]
(
    [DatabaseName],
    [PlanIdentifier],
    [ClientName],
    [RollupTableConfigID]
)
SELECT DISTINCT
       [DatabaseName] = [conn].[Connection_Name],
       [PlanIdentifier] = [p].[PlanIdentifier],
       [ClientName] = [rc].[ClientName],
       [RollupTableConfigID] = [rtc].[RollupTableConfigID]
FROM [$(HRPReporting)].[dbo].[tbl_Clients] [c] WITH (NOLOCK)
    JOIN [CTE_a1] [xref]
        ON [c].[Client_ID] = [xref].[Client_ID]
    JOIN [$(HRPReporting)].[dbo].[tbl_Connection] [conn] WITH (NOLOCK)
        ON [xref].[Connection_ID] = [conn].[Connection_ID]
	JOIN [$(HRPReporting)].[dbo].[tbl_uploads] [U] WITH (NOLOCK)
        ON [U].[Connection_ID] = [conn].[Connection_ID]
	JOIN [$(HRPReporting)].[dbo].[lk_FileTypes] FT WITH (NOLOCK)
		on [FT].[FileTypeID] = [U].[FileTypeID]
		AND [FT].[FileTypeID] =17
    JOIN [$(HRPInternalReportsDB)].[dbo].[RollupPlan] [p] WITH (NOLOCK)
        ON [conn].[Plan_ID] = [p].[PlanID]
           AND [p].[Active] = 1
           AND [p].[UseForRollup] = 1
    JOIN [$(HRPInternalReportsDB)].[dbo].[RollupClient] [rc] WITH (NOLOCK)
        ON [p].[ClientIdentifier] = [rc].[ClientIdentifier]
           AND [rc].[Active] = 1
           AND [rc].[UseForRollup] = 1
           AND [rc].[ClientIdentifier] = @ClientID
           AND
           (
               ([c].[Client_Name] = [rc].[ClientName])
               OR ([rc].[ClientName] = 'Innovation Health')
           )
    JOIN [$(HRPInternalReportsDB)].[dbo].[RollupTableConfig] [rtc] WITH (NOLOCK)
        ON [rc].[ClientIdentifier] = [rtc].[ClientIdentifier]
           AND [rtc].[TruncateTable] = 0
           AND [rtc].[Active] = 1
	JOIN [$(HRPInternalReportsDB)].[dbo].RollupTableStatus rts with (nolock)
		ON [rtc].[RollupTableConfigID] = [rts].[RollupTableConfigID]
    JOIN [$(HRPInternalReportsDB)].[dbo].[RollupTable] [rt] WITH (NOLOCK)
        ON [rtc].[RollupTableID] = [rt].[RollupTableID]
           AND [rt].[Rungroup] = '03'
           AND [rt].[RolluptableID] = 15
Where [U].[ImportedDate] > [rts].[RollupStart]
	And [U].[ImportedDate]  < getdate()

ORDER BY [p].[PlanIdentifier] ASC;


RAISERROR('001', 0, 1) WITH NOWAIT;

--To Check for any update file processed for ClaimStatusID

SELECT @UploadedDate = MAX(rts.[RollupStart])
FROM [#WorkList] [W]
    JOIN [$(HRPInternalReportsDB)].[dbo].[RollupTableConfig] [rtc] WITH (NOLOCK)
        ON [rtc].[RollupTableConfigID] = [W].[RollupTableConfigID]
    JOIN [$(HRPInternalReportsDB)].[dbo].RollupTableStatus rts WITH (NOLOCK)
        ON [rtc].[RollupTableConfigID] = [rts].[RollupTableConfigID];

IF (OBJECT_ID('tempdb.dbo.#PLANLIST') IS NOT NULL)
BEGIN
    DROP TABLE [#PLANLIST];
END;


CREATE TABLE [#PLANLIST]
(
    [DatabaseName] VARCHAR(128),
    [PlanIdentifier] SMALLINT
);

WHILE EXISTS (SELECT TOP 1 * FROM [#WorkList])
BEGIN

    SELECT TOP 1
           @DatabaseName = [wl].[DatabaseName],
           @PlanIdentifier = [wl].[PlanIdentifier]
    FROM [#WorkList] wl
    ORDER BY [wl].[DatabaseName];

    SET @FiledateSQL
        = '

	INSERT INTO [#PLANLIST]
	(
		 [DatabaseName]
   	   , [PlanIdentifier]

	)
	Select 
		Distinct 
	 ''' + @DatabaseName + ''' As [DatabaseName] ,
	 ' + CAST(@PlanIdentifier AS VARCHAR(32)) + ' As Planidentifier 
	 FROM
	 (
	 SELECT TOP 1 LOADDATE
	 	FROM  [' + @DatabaseName
          + '].[dbo].[tbl_plan_claims_validation] [CN]
		ORDER BY CN.PLANCLAIMSVALIDATIONID DESC
	 )D
	Where D.[LoadDate] >=  ''' + CONVERT(VARCHAR(20), @UploadedDate, 120) + '''

   ';

    SET NOCOUNT ON;

    EXEC (@FiledateSQL);

    DELETE a1
    FROM [#WorkList] [a1]
    WHERE [a1].[DatabaseName] = @DatabaseName
          AND [a1].[PlanIdentifier] = @PlanIdentifier;
END;

IF (OBJECT_ID('tempdb.dbo.#PlanClaimStatus') IS NOT NULL)
BEGIN
    DROP TABLE [#PlanClaimStatus];
END;


CREATE TABLE [#PlanClaimStatus]
(
    [ClaimTempID] BIGINT IDENTITY(1, 1) PRIMARY KEY,
    [PlanIdentifier] SMALLINT,
    [Claim_ID] BIGINT,
    [ClaimStatusID] TINYINT
);

IF EXISTS
(
    SELECT *
    FROM tempdb.sys.indexes
    WHERE name = 'IX_#PlanClaimStatus_Claim_StatusID'
          AND OBJECT_ID = OBJECT_ID('tempdb..#PlanClaimStatus')
)
BEGIN

    DROP INDEX IX_#PlanClaimStatus_Claim_StatusID ON #PlanClaimStatus;

    CREATE NONCLUSTERED INDEX [IX_#PlanClaimStatus_Claim_StatusID]
    ON [#PlanClaimStatus] (
                              [Claim_ID],
                              [ClaimStatusID],
                              [PlanIdentifier]
                          );
END;



WHILE EXISTS (SELECT TOP 1 * FROM [#PLANLIST])
BEGIN

    SELECT TOP 1
           @DatabaseName = [wl].[DatabaseName],
           @PlanIdentifier = [wl].[PlanIdentifier]
    FROM [#PLANLIST] wl
    ORDER BY [wl].[DatabaseName];

    IF (OBJECT_ID('tempdb.dbo.#PlanClaimStatus') IS NOT NULL)
    BEGIN
        TRUNCATE TABLE [#PlanClaimStatus];
    END;

    SET @FiledateSQL
        = '
	INSERT INTO [#PlanClaimStatus]
	(
		[PlanIdentifier],
		[Claim_ID],
		[ClaimStatusID]
	)
	SELECT DISTINCT 
	  ' + CAST(@PlanIdentifier AS VARCHAR(32)) + ' AS Planidentifier,	
	   A.claim_id,
       A.claimstatusid
	FROM [' + @DatabaseName + '].[dbo].tbl_plan_claims_validation A
    INNER JOIN
    (
        SELECT Claim_id,
               MAX(planclaimsvalidationID) AS MaxplanclaimsvalidationID
        FROM [' + @DatabaseName + '].[dbo].tbl_plan_claims_validation CN
        Where [CN].[LoadDate] >= ''' + CONVERT(VARCHAR(20), @UploadedDate, 120) + ''' 
        GROUP BY claim_id
    ) b
        ON A.planclaimsvalidationID = b.MaxplanclaimsvalidationID
           AND A.claim_id = b.claim_id;
   ';

    SET NOCOUNT ON;

    EXEC (@FiledateSQL);

    RAISERROR('003', 0, 1) WITH NOWAIT;

	WHILE EXISTS (SELECT TOP 1 * FROM [#PlanClaimStatus])
    BEGIN

        PRINT 'Running process for ' + @DatabaseName + ' | [PlanIdentifier] = ' + CAST(@PlanIdentifier AS VARCHAR(21))
              + '.';
        PRINT '-B----DT: ' + CONVERT(CHAR(23), GETDATE(), 121);

		Select  @Minvalue =Min(a1.[ClaimTempID]),
				@Maxvalue =Max(a1.[ClaimTempID])
			From [#PlanClaimStatus]  [a1] (Nolock)
			Where A1.PlanIdentifier=@PlanIdentifier;

        RAISERROR('005', 0, 1) WITH NOWAIT;

        Set @RollupLoad = GETDATE();



	 WHILE (@Minvalue <= @Maxvalue)
      BEGIN

	    UPDATE [a1]
            SET [a1].[ClaimStatusID] = [a2].[ClaimStatusID],
                [a1].[RollupLoad] = @RollupLoad
            FROM [dbo].[tbl_Plan_Claims_rollup] (NOLOCK) [a1]
                JOIN [#PlanClaimStatus] [a2]
                    ON [a1].[Claim_ID] = [a2].[Claim_ID]
                       AND [a1].[PlanIdentifier] = [a2].[PlanIdentifier]
				Where [a1].PlanIdentifier = @PlanIdentifier
				  AND [a2].[ClaimTempID] >= @Minvalue
                  AND [a2].[ClaimTempID] < @Minvalue + @batchSize;

           SET @Minvalue = @Minvalue + @batchSize;

		END

        RAISERROR('006', 0, 1) WITH NOWAIT;

			IF (OBJECT_ID('tempdb.dbo.#PlanClaimStatus') IS NOT NULL)
			BEGIN
					TRUNCATE TABLE [#PlanClaimStatus];
			END;

	END;

    DELETE a1
    FROM [#PLANLIST] [a1]
    WHERE [a1].[DatabaseName] = @DatabaseName
          AND [a1].[PlanIdentifier] = @PlanIdentifier;
		

END;

Commit Transaction Update_tbl_Plan_Claims		
End Try

-------------------------------------------------------------------------
-- Error handling
-------------------------------------------------------------------------	
Begin Catch
	If (XACT_STATE() = 1 Or XACT_STATE() = -1)
		Rollback Transaction Update_tbl_Plan_Claims

	Declare @ErrorMsg varchar(2000)
	Set @ErrorMsg = 'Error: ' + IsNull(Error_Procedure(),'script') + ': ' +  Error_Message() +
				    ', Error Number: ' + cast(Error_Number() as varchar(10)) + ' Line: ' + 
				    cast(Error_Line() as varchar(50))
	
	Raiserror (@ErrorMsg, 16, 1)	

End Catch