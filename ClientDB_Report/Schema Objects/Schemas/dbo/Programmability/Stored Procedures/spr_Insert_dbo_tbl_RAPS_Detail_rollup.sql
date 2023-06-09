CREATE PROCEDURE [dbo].[spr_Insert_dbo_tbl_RAPS_Detail_rollup]
    @SourceDatabase sysname,
    @PlanIdentifier SMALLINT,
    @Incre_load_Count BIGINT OUTPUT

/********************************************************************************************************************** 
  * Name			:	[dbo].[spr_Insert_dbo_tbl_RAPS_Detail_rollup]																			*
  * Type 			:	Stored Procedure																				*
  * Author       	:	Mitch Casto																						*
  * Date			:	2019-01-03																						*
  * Version			:	1.0																								*
  * Description		:	This stored procedure will check for incremental records based on tbl_Raps_Detail_Id 
						and insert it in batches
  *Notes:																										*
  * Version History :																									*
  * =================																									*
  * Author			Date			Version#    TFS Ticket#		Description												*
  * ---------------	----------		--------    -----------		------------											*
  * MCasto			2019-01-03		1.0							Initial	
  * Anand           2019-01-06		1.1	        RE-7431/77587   
  * Anand 			2022-23-02		1.2			RRI-2171		Optimized Insert Process			     				*	

  **********************************************************************************************************************/
AS
DECLARE @InsertSQL VARCHAR(8000);
DECLARE @UpdateDT DATETIME = GETDATE();
DECLARE @SourceMinValue BIGINT;
DECLARE @SourceMinValueD BIGINT;
DECLARE @SourceMaxValue BIGINT;
DECLARE @SourceMaxValueD BIGINT;
DECLARE @TargetMaxValue BIGINT;
DECLARE @batchsize BIGINT = 4000000;
DECLARE @SourceSQL NVARCHAR(4000);
DECLARE @TableName VARCHAR(128) = 'tbl_RAPS_Detail_Rollup';

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

BEGIN TRY
BEGIN TRANSACTION Insert_update_tbl_Raps;

    IF NOT EXISTS
    (
        SELECT 1
        FROM dbo.RollupMinMaxValues
        WHERE [SourceDatabase] = @SourceDatabase
              AND [TableName] = @TableName
              AND [PLANIDENTIFIER] = @PlanIdentifier
    )
    BEGIN

        SET @SourceSQL
            = N'
SELECT @SourceMinValueD =Min([tbl_RAPS_Detail_ID]),
	   @SourceMaxValueD =Max([tbl_RAPS_Detail_ID])	
FROM ' + @SourceDatabase + N'.[dbo].[tbl_RAPS_Detail] rd WITH (NOLOCK)
		  ';

        EXECUTE sp_executesql @SourceSQL,
                              N'@SourceMinValueD BIGINT OUTPUT, @SourceMaxValueD BIGINT OUTPUT',
                              @SourceMinValueD = @SourceMinValue OUTPUT,
                              @SourceMaxValueD = @SourceMaxValue OUTPUT;


        SELECT @TargetMaxValue = ISNULL(MAX([tbl_RAPS_Detail_ID]), -9223372036854775808)
        FROM [dbo].[tbl_RAPS_Detail_Rollup] rd WITH (NOLOCK)
        WHERE rd.planidentifier = @PlanIdentifier;

        INSERT INTO dbo.RollupMinMaxValues
        (
            [TableName],
            [SourceDatabase],
            [PlanIdentifier],
            [SourceMinValue],
            [SourceMaxValue],
            [TargetMaxValue],
            [LastUpdateDateTime]
        )
        VALUES
        (  
			@TableName, 
			@SourceDatabase, 
			@PlanIdentifier, 
			@SourceMinValue, 
			@SourceMaxValue,
            CASE
                WHEN @TargetMaxValue = '-9223372036854775808' THEN
                    @SourceMinValue - 1
                ELSE
                    @TargetMaxValue
            END, 
			@UpdateDT
		);

    END;

    ELSE
    BEGIN

        SET @SourceSQL
            = N'
SELECT @SourceMinValueD =Min([tbl_RAPS_Detail_ID]),
	   @SourceMaxValueD =Max([tbl_RAPS_Detail_ID])	
FROM ' + @SourceDatabase + N'.[dbo].[tbl_RAPS_Detail] rd WITH (NOLOCK)
		  ';

        EXECUTE sp_executesql @SourceSQL,
                              N'@SourceMinValueD BIGINT OUTPUT, @SourceMaxValueD BIGINT OUTPUT',
                              @SourceMinValueD = @SourceMinValue OUTPUT,
                              @SourceMaxValueD = @SourceMaxValue OUTPUT;

        UPDATE t
        SET SourceMinValue = @SourceMinValue,
            SourceMaxValue = @SourceMaxValue,
            LastUpdateDateTime = @UpdateDT
        FROM dbo.RollupMinMaxValues t
        WHERE [SourceDatabase] = @SourceDatabase
              AND TableName = @TableName
              AND PlanIdentifier = @PlanIdentifier;

    END;

    SELECT @SourceMaxValue = SourceMaxValue,
           @TargetMaxValue = TargetMaxValue
    FROM dbo.RollupMinMaxValues
    WHERE [SourceDatabase] = @SourceDatabase
          AND [TableName] = @TableName
          AND [PlanIdentifier] = @PlanIdentifier;

    PRINT 'Checking Database: ' + @SourceDatabase + ' | PlanIdentifier: ' + CAST(@PlanIdentifier AS VARCHAR(32));

    IF @SourceMaxValue = @TargetMaxValue
    BEGIN
        RAISERROR('-----------------------------------------------------------------------', 0, 1) WITH NOWAIT;
        RAISERROR('Target and Source Data match. No action needed.', 0, 1) WITH NOWAIT;
        RAISERROR('=======================================================================', 0, 1) WITH NOWAIT;

        GOTO ExitProcess;
    END;

    IF @SourceMaxValue < @TargetMaxValue
    BEGIN
        RAISERROR('-----------------------------------------------------------------------', 0, 1) WITH NOWAIT;
        PRINT 'Target: ' + CAST(FORMAT(@TargetMaxValue, '##,##0', 'en-US') AS VARCHAR(32)) + ' | Source: '
              + CAST(FORMAT(@SourceMaxValue, '##,##0', 'en-US') AS VARCHAR(32));
        RAISERROR('Warning Target row count is higher than Source count. Exiting process.', 0, 1) WITH NOWAIT;
        RAISERROR('=======================================================================', 0, 1) WITH NOWAIT;

        GOTO ExitProcess;
    END;

    IF @SourceMaxValue > @TargetMaxValue
    BEGIN
        RAISERROR('-----------------------------------------------------------------------', 0, 1) WITH NOWAIT;
        PRINT 'Target: ' + CAST(FORMAT(@TargetMaxValue, '##,##0', 'en-US') AS VARCHAR(32)) + ' | Source: '
              + CAST(FORMAT(@SourceMaxValue, '##,##0', 'en-US') AS VARCHAR(32));
        RAISERROR('Initiating loading of new data from Source to Target.', 0, 1) WITH NOWAIT;
        PRINT 'Loading: ' + CAST(FORMAT(@SourceMaxValue - @TargetMaxValue, '##,##0', 'en-US') AS VARCHAR(32)) + ' rows';
        RAISERROR('=======================================================================', 0, 1) WITH NOWAIT;
    END;

    SET @Incre_load_Count = @SourceMaxValue - @TargetMaxValue;

    WHILE (@TargetMaxValue <= @SourceMaxValue)
    BEGIN

        SET @InsertSQL
            = '
SELECT 
        [PlanIdentifier] = ' + CAST(@PlanIdentifier AS CHAR(6))
              + '
	  , [Record_id]
      , [Seq_num1]
      , [Seq_Error]
      , [Pat_Control]
      , [HICN]
      , [Hic_Error]
      , [DOB]
      , [DOB_Error]
      , [Provd_Type1]
      , [From_Date1]
      , [Thru_date1]
      , [Delete_Ind1]
      , [Diag1]
      , [DC_Filler1]
      , [Diag1_Err1]
      , [Diag1_Err2]
      , [Provd_Type2]
      , [From_Date2]
      , [Thru_Date2]
      , [Delete_Ind_2]
      , [Diag2]
      , [DC_Filler2]
      , [Diag2_Err1]
      , [Diag2_Err2]
      , [Provd_Type3]
      , [From_Date3]
      , [Thru_Date3]
      , [Delete_Ind3]
      , [Diag3]
      , [DC_Filler3]
      , [Diag3_Err1]
      , [Diag3_Err2]
      , [Provd_Type4]
      , [From_Date4]
      , [Thru_Date4]
      , [Delete_Ind4]
      , [Diag4]
      , [DC_Filler4]
      , [Diag4_Err1]
      , [Diag4_Err2]
      , [Provd_Type5]
      , [From_Date5]
      , [Thru_Date5]
      , [Delete_Ind5]
      , [Diag5]
      , [DC_Filler5]
      , [Diag5_Err1]
      , [Diag5_Err2]
      , [Provd_Type6]
      , [From_Date6]
      , [Thru_Date6]
      , [Delete_Ind6]
      , [Diag6]
      , [DC_Filler6]
      , [Diag6_Err1]
      , [Diag6_Err2]
      , [Provd_Type7]
      , [From_Date7]
      , [Thru_date7]
      , [Delete_Ind_7]
      , [Diag7]
      , [DC_Filler7]
      , [Diag7_Err1]
      , [Diag7_Err2]
      , [Provd_Type8]
      , [From_Date8]
      , [Thru_Date8]
      , [Delete_Ind8]
      , [Diag8]
      , [DC_Filler8]
      , [Diag8_Err1]
      , [Diag8_Err2]
      , [Provd_Type9]
      , [From_Date9]
      , [Thru_date9]
      , [Delete_Ind_9]
      , [Diag9]
      , [DC_Filler9]
      , [Diag9_Err1]
      , [Diag9_Err2]
      , [Provd_Type10]
      , [From_Date10]
      , [Thru_Date10]
      , [Delete_Ind10]
      , [Diag10]
      , [DC_Filler10]
      , [Diag10_Err1]
      , [Diag10_Err2]
      , [Corrected_HICN]
      , [Filler]
      , [EXPORTED_DATE]
      , [EXPORTED_FILEID]
      , [ICD]
      , [RAC1]
      , [RAC2]
      , [RAC3]
      , [RAC4]
      , [RAC5]
      , [RAC6]
      , [RAC7]
      , [RAC8]
      , [RAC9]
      , [RAC10]
      , [RAPSDetailOverpaymentID]
      , [MemberIDReceived]
      , [RAPS_Detail_ID]
      , [Claim_ID]
      , [RAPSStatusID]
      , [RAPSSourceTypeID]
      , [OutboundFileID]
	  , [tbl_RAPS_Detail_ID]
	  , [RollupLoad] = ''' + CONVERT(CHAR(23), @UpdateDT, 121) + '''
FROM [' + @SourceDatabase + '].[dbo].[tbl_RAPS_Detail] WITH (NOLOCK)
WHERE [tbl_RAPS_Detail_ID] > CONVERT(BIGINT,' + CAST(@TargetMaxValue AS VARCHAR(MAX))
              + ')
  AND [tbl_RAPS_Detail_ID] <=  CONVERT(BIGINT,' + CAST(@TargetMaxValue AS VARCHAR(MAX)) + ')' + '+'
              + ' CONVERT(BIGINT,' + CAST(@batchsize AS VARCHAR(MAX))
              + ')
  AND [EXPORTED_DATE]>= DATEADD(year,-4,getdate())
'       ;

        INSERT INTO [dbo].[tbl_RAPS_Detail_rollup]
        (
            [PlanIdentifier],
            [Record_id],
            [Seq_num1],
            [Seq_Error],
            [Pat_Control],
            [HICN],
            [Hic_Error],
            [DOB],
            [DOB_Error],
            [Provd_Type1],
            [From_Date1],
            [Thru_date1],
            [Delete_Ind1],
            [Diag1],
            [DC_Filler1],
            [Diag1_Err1],
            [Diag1_Err2],
            [Provd_Type2],
            [From_Date2],
            [Thru_Date2],
            [Delete_Ind_2],
            [Diag2],
            [DC_Filler2],
            [Diag2_Err1],
            [Diag2_Err2],
            [Provd_Type3],
            [From_Date3],
            [Thru_Date3],
            [Delete_Ind3],
            [Diag3],
            [DC_Filler3],
            [Diag3_Err1],
            [Diag3_Err2],
            [Provd_Type4],
            [From_Date4],
            [Thru_Date4],
            [Delete_Ind4],
            [Diag4],
            [DC_Filler4],
            [Diag4_Err1],
            [Diag4_Err2],
            [Provd_Type5],
            [From_Date5],
            [Thru_Date5],
            [Delete_Ind5],
            [Diag5],
            [DC_Filler5],
            [Diag5_Err1],
            [Diag5_Err2],
            [Provd_Type6],
            [From_Date6],
            [Thru_Date6],
            [Delete_Ind6],
            [Diag6],
            [DC_Filler6],
            [Diag6_Err1],
            [Diag6_Err2],
            [Provd_Type7],
            [From_Date7],
            [Thru_date7],
            [Delete_Ind_7],
            [Diag7],
            [DC_Filler7],
            [Diag7_Err1],
            [Diag7_Err2],
            [Provd_Type8],
            [From_Date8],
            [Thru_Date8],
            [Delete_Ind8],
            [Diag8],
            [DC_Filler8],
            [Diag8_Err1],
            [Diag8_Err2],
            [Provd_Type9],
            [From_Date9],
            [Thru_date9],
            [Delete_Ind_9],
            [Diag9],
            [DC_Filler9],
            [Diag9_Err1],
            [Diag9_Err2],
            [Provd_Type10],
            [From_Date10],
            [Thru_Date10],
            [Delete_Ind10],
            [Diag10],
            [DC_Filler10],
            [Diag10_Err1],
            [Diag10_Err2],
            [Corrected_HICN],
            [Filler],
            [EXPORTED_DATE],
            [EXPORTED_FILEID],
            [ICD],
            [RAC1],
            [RAC2],
            [RAC3],
            [RAC4],
            [RAC5],
            [RAC6],
            [RAC7],
            [RAC8],
            [RAC9],
            [RAC10],
            [RAPSDetailOverpaymentID],
            [MemberIDReceived],
            [RAPS_Detail_ID],
            [Claim_ID],
            [RAPSStatusID],
            [RAPSSourceTypeID],
            [OutboundFileID],
            [tbl_RAPS_Detail_ID],
            [RollupLoad]
        )
        EXEC (@InsertSQL);

        SET @TargetMaxValue = @TargetMaxValue + @batchsize;

    END;

    UPDATE t
    SET [TargetMaxValue] = @SourceMaxValue
    FROM dbo.RollupMinMaxValues t
    WHERE [SourceDatabase] = @SourceDatabase
          AND TableName = @TableName
          AND PlanIdentifier = @PlanIdentifier;
 
   ExitProcess:;
	
	COMMIT TRANSACTION Insert_update_tbl_Raps;

	RETURN ISNULL(@Incre_load_Count, 0);


END TRY
BEGIN CATCH
    DECLARE @error INT,
            @message VARCHAR(4000);
    SELECT @error = ERROR_NUMBER(),
           @message = ERROR_MESSAGE();
	ROLLBACK Transaction Insert_update_tbl_Raps;
    RAISERROR('%d: %s', 16, 1, @error, @message);

END CATCH;
