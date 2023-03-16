CREATE PROCEDURE [dbo].[spr_dbo_tbl_RAPS_Detail_rollup_Sync_RAPSStatusID]

@ClientID Int

  /********************************************************************************************************************** 
  * Name			:	[dbo].[spr_dbo_tbl_RAPS_Detail_rollup_Sync_RAPSStatusID]										*
  * Type 			:	Stored Procedure																				*
  * Author       	:	Mitch Casto																						*
  * Date			:	2019-01-07																						*
  * Version			:	1.0																								*
  * Description		:	This stored procedure will update the Raps_status_ID in tbl_Raps_Detail_rollup table
						based on plan level table 
  *Notes:																										*
  * Version History :																									*
  * =================																									*
  * Author			Date			Version#    TFS Ticket#		Description												*
  * ---------------	----------		--------    -----------		------------											*
  * MCasto			2019-01-07		1.0							Initial	
  * Anand           2019-01-07		1.1	        RE-7431/77587   ClientID Changes
  *	Anand			2020-01-24		1.2			RE-7649/77747	Split Update Statements	
  * Anand		    2020-02-14		1.3			RE-7767/77942   Batch Update
  * Anand			2020-03-02		1.4			RE-7840/78054   Added the filter for Rungroup - 04 & Run the Update
																based on tbl_uploads & CNRapsImportdetail
  * Anand			2020-08-17      1.5 		RRI-163/79359	Used RolluptabeID to filter
  * Anand			2022-02-23      1.6 		RRI-2171		Optimized Update logic
  **********************************************************************************************************************/
 
AS

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;


BEGIN TRY
BEGIN TRANSACTION Udpate_tbl_Raps_detail

IF (OBJECT_ID('tempdb.dbo.#WorkList') IS NOT NULL)
BEGIN
    DROP TABLE [#WorkList]
END


CREATE TABLE [#WorkList]
(
    [DatabaseName] VARCHAR(128)
  , [PlanIdentifier] SMALLINT
  , [ClientName] VARCHAR(100)
  , [RollupTableConfigID] Int
)

RAISERROR('000', 0, 1) WITH NOWAIT

DECLARE @DatabaseName VARCHAR(128)
DECLARE @PlanIdentifier SMALLINT
DECLARE @InsertSQL VARCHAR(8000)

/**/
;
WITH [CTE_a1]
AS (SELECT [Client_ID] = ISNULL([mg].[MergedClientID], [x].[Client_ID])
         , [x].[Connection_ID]
    FROM [$(HRPReporting)].[dbo].[xref_Client_Connections] [x] WITH (NOLOCK)
        LEFT JOIN [$(HRPReporting)].[dbo].[MergedClients] [mg] WITH (NOLOCK)
            ON [x].[Client_ID] = [mg].[ClientID]
               AND [mg].[Product] = 'RAPS'
               AND [mg].[ClientID] <> 11)


INSERT INTO [#WorkList]
(
    [DatabaseName]
  , [PlanIdentifier]
  , [ClientName]
  , [RollupTableConfigID]

)
SELECT DISTINCT
       [DatabaseName] = [conn].[Connection_Name]
     , [PlanIdentifier] = [p].[PlanIdentifier]
     , [ClientName] = [rc].[ClientName]
	 , [RollupTableConfigID]=[rtc].[RollupTableConfigID]
FROM [$(HRPReporting)].[dbo].[tbl_Clients] [c] WITH (NOLOCK)
    JOIN [CTE_a1] [xref]
        ON [c].[Client_ID] = [xref].[Client_ID]
    JOIN [$(HRPReporting)].[dbo].[tbl_Connection] [conn] WITH (NOLOCK)
        ON [xref].[Connection_ID] = [conn].[Connection_ID]
	JOIN [$(HRPReporting)].[dbo].[TBL_UPLOADS] U WITH (NOLOCK) 
		ON [U].[Connection_ID]=[conn].[Connection_ID]
	JOIN [$(HRPReporting)].[dbo].[lk_FileTypes] FT WITH (NOLOCK)
		on [FT].[FileTypeID] = [U].[FileTypeID]
		AND [FT].[FileTypeID] IN (16,29,17,3)
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
	 	AND [RTC].[TruncateTable]=0
		AND [RTC].[Active]=1
	JOIN [$(HRPInternalReportsDB)].[dbo].RollupTableStatus rts with (nolock)
		ON [rtc].[RollupTableConfigID] = [rts].[RollupTableConfigID]
    JOIN [$(HRPInternalReportsDB)].[dbo].[RollupTable] [rt] WITH (NOLOCK)
        ON [rtc].[RollupTableID] = [rt].[RollupTableID]
		 AND [RT].[Rungroup]='04'
		 AND [RT].[RolluptableID]=21
Where [U].[ImportedDate] > [rts].[RollupStart]
	And [U].[ImportedDate]  < getdate()
 
ORDER BY [p].[PlanIdentifier] ASC


RAISERROR('001', 0, 1) WITH NOWAIT
 
 
DECLARE @Maxvalue BIGINT
DECLARE @Minvalue BIGINT 
DECLARE @Raps_id BIGINT
DECLARE @batchSize BIGINT
DECLARE @Count BIGINT
Declare @RollupLoad Datetime
DECLARE @Raps_idmax BIGINT
SET @batchSize = 4000000
 
IF OBJECT_ID('tempdb..#RapsStatus') IS NOT NULL DROP TABLE #RapsStatus
Begin

CREATE TABLE #RapsStatus
    (
		[RAPSTempID] BIGINT IDENTITY(1, 1) PRIMARY KEY,
		[tbl_RAPS_Detail_RollupID] BIGINT,
		[RAPSStatusID] TINYINT,
		[PlanIdentifier] SMALLINT
    );
 
End

WHILE EXISTS (SELECT TOP 1* FROM [#WorkList])
BEGIN

    SELECT TOP 1
           @DatabaseName = [wl].[DatabaseName]
         , @PlanIdentifier = [wl].[PlanIdentifier]
    FROM [#WorkList] wl
    ORDER BY [wl].[DatabaseName]
	 
		SELECT 
		    @Minvalue =	Min(tbl_RAPS_Detail_rollupID),
			@Maxvalue = Max(tbl_RAPS_Detail_rollupID)
		FROM [dbo].[tbl_RAPS_Detail_rollup](NOLOCK) 
		WHERE [PlanIdentifier]=@PlanIdentifier
		 
    RAISERROR('004', 0, 1) WITH NOWAIT

    PRINT 'Running process for ' + @DatabaseName + ' | [PlanIdentifier] = ' + CAST(@PlanIdentifier AS VARCHAR(21))
          + '.'
    PRINT '-B----DT: ' + CONVERT(CHAR(23), GETDATE(), 121)

	IF OBJECT_ID('tempdb..#RapsStatus') IS NOT NULL

	Begin

	Truncate Table #RapsStatus
	 
	End
	 
WHILE (@Minvalue <= @Maxvalue)

Begin
 

	Set @Count = 
	(
	 Select Top 1 ([tbl_RAPS_Detail_rollupID])
	 From [dbo].[tbl_RAPS_Detail_rollup](NOLOCK) [a1] 
	 Where [a1].[tbl_RAPS_Detail_rollupID] > = @Minvalue
	 AND [a1].[tbl_RAPS_Detail_rollupID] < @Minvalue + @batchSize
	 AND [A1].PlanIdentifier = @PlanIdentifier
	 )


If @Count is not null

Begin

	Set  @InsertSQL=
	 '

	INSERT INTO #RapsStatus
	(
	[tbl_RAPS_Detail_rollupID],
	[RAPSStatusID],
	[PlanIdentifier] 
	)
	 Select 
	 [a1].tbl_RAPS_Detail_rollupID,
	 [a2].RAPSstatusID,
	 ' + CAST(@PlanIdentifier AS VARCHAR(32)) + ' As Planidentifier 
	FROM [dbo].[tbl_RAPS_Detail_rollup](NOLOCK) [a1] 
		  JOIN [' + @DatabaseName + '].[dbo].[tbl_RAPS_Detail] [a2]
            ON [a1].[tbl_RAPS_Detail_ID] = [a2].[tbl_RAPS_Detail_ID] 
      	WHERE [a1].[PlanIdentifier] = ' + CAST(@PlanIdentifier AS VARCHAR(32)) + '
		AND [a1].[tbl_RAPS_Detail_rollupID] > = CONVERT(BIGINT,' + CAST(@Minvalue AS VARCHAR(MAX)) + ')
		AND [a1].[tbl_RAPS_Detail_rollupID] <  CONVERT(BIGINT,' + CAST(@Minvalue AS VARCHAR(Max)) + ')' + '+' + CAST(@batchSize AS VARCHAR(Max)) + '
	Group by [a1].tbl_RAPS_Detail_rollupID,[a2].RAPSstatusID

	Except

	SELECT 
	 [a1].tbl_RAPS_Detail_rollupID,	 	 
	 [A1].RAPSStatusID AS [RAPSStatusID],
	 ' + CAST(@PlanIdentifier AS VARCHAR(32)) + ' As Planidentifier 
	 FROM [dbo].[tbl_RAPS_Detail_rollup](NOLOCK) [a1]
  	 WHERE [a1].[PlanIdentifier] = ' + CAST(@PlanIdentifier AS VARCHAR(32)) + '
	 AND [a1].[tbl_RAPS_Detail_rollupID] > = CONVERT(BIGINT,' + CAST(@Minvalue AS VARCHAR(MAX)) + ')
	 AND [a1].[tbl_RAPS_Detail_rollupID] <  CONVERT(BIGINT,' + CAST(@Minvalue AS VARCHAR(Max)) + ')' + '+' + CAST(@batchSize AS VARCHAR(Max)) + '
	 Group by [a1].tbl_RAPS_Detail_rollupID,[a1].RAPSstatusID

   '
  
    SET NOCOUNT ON

    EXEC (@InsertSQL)
 
End

SET @Minvalue = @Minvalue + @batchSize

End
 
 RAISERROR('005', 0, 1) WITH NOWAIT

 IF EXISTS(SELECT * FROM tempdb.sys.indexes WHERE name = 'IX_#RapsStatus_Raps_Detail'
		AND OBJECT_ID = object_id('tempdb..#RapsStatus')) 
		BEGIN

			DROP INDEX IX_#RapsStatus_Raps_Detail on #RapsStatus

			CREATE NONCLUSTERED INDEX [IX_#RapsStatus_Raps_Detail]
				ON [#RapsStatus] ([tbl_RAPS_Detail_rollupID],[RAPSStatusID])

		END 

SET @Raps_id = 0

SET @Raps_idmax = (SELECT Max([RAPSTempID]) FROM #RapsStatus [a1])
 
Set @RollupLoad = GETDATE();						

WHILE (@Raps_id <= @Raps_idmax)
	BEGIN

	UPDATE [a1]
    SET [a1].[RAPSStatusID] = [a2].[RAPSStatusID]
		, [a1].[RollupLoad] =  @RollupLoad 
    FROM [dbo].[tbl_RAPS_Detail_rollup](NOLOCK) [a1]
        JOIN #RapsStatus [a2]
			ON  [a1].[PlanIdentifier] = [a2].[PlanIdentifier]
			AND [a1].[tbl_RAPS_Detail_rollupID] = [a2].[tbl_RAPS_Detail_rollupID]
    WHERE [a1].[PlanIdentifier] = @PlanIdentifier
				AND [a2].[RAPSTempID] >=  @Raps_id
				AND [a2].[RAPSTempID] <  @Raps_id + @batchSize
		 
		SET @Raps_id = @Raps_id + @batchSize

	END
 
    PRINT '-E----DT: ' + CONVERT(CHAR(23), GETDATE(), 121)
			
    DELETE a1
    FROM [#WorkList] [a1]
    WHERE [a1].[DatabaseName] = @DatabaseName
          AND [a1].[PlanIdentifier] = @PlanIdentifier

END

Commit Transaction Udpate_tbl_Raps_detail

End Try

-------------------------------------------------------------------------
-- Error handling
-------------------------------------------------------------------------	
BEGIN CATCH
    DECLARE @error INT,
            @message VARCHAR(4000);
    SELECT @error = ERROR_NUMBER(),
           @message = ERROR_MESSAGE();
	ROLLBACK Transaction Udpate_tbl_Raps_detail;
    RAISERROR('%d: %s', 16, 1, @error, @message);

END CATCH