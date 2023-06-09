CREATE PROCEDURE [dbo].[spr_Insert_dbo_RAPS_Detail_rollup]
    @SourceDatabase sysname,
    @PlanIdentifier SMALLINT, --= -999
    @Incre_load_Count INT OUTPUT

/********************************************************************************************************************** 
  * Name			:	[dbo].[spr_Insert_dbo_RAPS_Detail_rollup]														*
  * Type 			:	Stored Procedure																				*
  * Author       	:	Mitch Casto																						*
  * Date			:	2019-01-03																						*
  * Version			:	1.0																								*
  * Description		:	This stored procedure will check for incremental records based on Raps_Detail_Id 
						and insert it in batches
  *Notes:																										        *
  * Version History :																									*
  * =================																									*
  * Author			Date			Version#    TFS Ticket#		Description												*
  * ---------------	----------		--------    -----------		------------											*
  * MCasto			2019-01-03		1.0							Initial	
  * Anand           2019-01-06		1.1	        RE-7431/77587
  *	Anand			2022-02-24		1.3			RRI-2171		Optimized Insert Process								*
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
DECLARE @TableName VARCHAR(128) = 'RAPS_Detail_Rollup';

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

RAISERROR('000', 0, 1) WITH NOWAIT;

BEGIN TRY
BEGIN TRANSACTION Insert_update_Raps;

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
SELECT @SourceMinValueD =Min([RAPS_Detail_ID]),
	   @SourceMaxValueD =Max([RAPS_Detail_ID])	
FROM ' + @SourceDatabase + N'.[dbo].[RAPS_Detail] rd WITH (NOLOCK)
		  ';

        EXECUTE sp_executesql @SourceSQL,
                              N'@SourceMinValueD BIGINT OUTPUT, @SourceMaxValueD BIGINT OUTPUT',
                              @SourceMinValueD = @SourceMinValue OUTPUT,
                              @SourceMaxValueD = @SourceMaxValue OUTPUT;

        SELECT @TargetMaxValue = ISNULL(MAX([RAPS_Detail_ID]), -9223372036854775808)
        FROM [dbo].[RAPS_Detail_Rollup] rd WITH (NOLOCK)
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
SELECT @SourceMinValueD =Min([RAPS_Detail_ID]),
	   @SourceMaxValueD =Max([RAPS_Detail_ID])	
FROM ' + @SourceDatabase + N'.[dbo].[RAPS_Detail] rd WITH (NOLOCK)
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

    RAISERROR('003', 0, 1) WITH NOWAIT;

    PRINT 'Checking Database: ' + @SourceDatabase + ' | @PlanIdentifier: ' + CAST(@PlanIdentifier AS VARCHAR(32));

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
       [PLAN_ID]
     , [PlanIdentifier] = ' + CAST(@PlanIdentifier AS CHAR(6))
              + '
     , [CLAIM_CONTROL_NUMBER]
     , [HICN]
     , [DATE_OF_SERVICE_START]
     , [DATE_OF_SERVICE_END]
     , [PROVIDER_TYPE]
     , [DIAG1]
     , [DIAG2]
     , [DIAG3]
     , [DIAG4]
     , [DIAG5]
     , [DIAG6]
     , [DIAG7]
     , [DIAG8]
     , [DIAG9]
     , [DIAG10]
     , [DELDIAG1]
     , [DELDIAG2]
     , [DELDIAG3]
     , [DELDIAG4]
     , [DELDIAG5]
     , [DELDIAG6]
     , [DELDIAG7]
     , [DELDIAG8]
     , [DELDIAG9]
     , [DELDIAG10]
     , [USER_UPLOADED_BY]
     , [SOURCE]
     , [IMPORTED_DATE]
     , [EXPORTED_FILEID]
     , [Source_ID]
     , [Provider_ID]
     , [Image_ID]
     , [Date_Of_Notification]
     , [In_Cluster]
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
     , [RAPS_Detail_ID]
     , [MemberIDReceived]
     , [Claim_ID]
     , [RAPSDetailImportID]
     , [RAPSSourceTypeID]
     , [SPMRID]
     , [CNRAPSImportDetailID]
	 , [RollupLoad] = ''' + CONVERT(CHAR(23), @UpdateDT, 121) + '''
FROM [' + @SourceDatabase + '].[dbo].[RAPS_Detail] WITH (NOLOCK)
WHERE [RAPS_Detail_ID] > CONVERT(BIGINT,' + CAST(@TargetMaxValue AS VARCHAR(MAX))
              + ')
  AND [RAPS_Detail_ID] <=  CONVERT(BIGINT,' + CAST(@TargetMaxValue AS VARCHAR(MAX)) + ')' + '+' + ' CONVERT(BIGINT,'
              + CAST(@batchsize AS VARCHAR(MAX)) + ')
  AND [IMPORTED_DATE]>= DATEADD(year,-4,getdate())
'       ;

        INSERT INTO [dbo].[RAPS_Detail_rollup]
        (
            [PLAN_ID],
            [PlanIdentifier],
            [CLAIM_CONTROL_NUMBER],
            [HICN],
            [DATE_OF_SERVICE_START],
            [DATE_OF_SERVICE_END],
            [PROVIDER_TYPE],
            [DIAG1],
            [DIAG2],
            [DIAG3],
            [DIAG4],
            [DIAG5],
            [DIAG6],
            [DIAG7],
            [DIAG8],
            [DIAG9],
            [DIAG10],
            [DELDIAG1],
            [DELDIAG2],
            [DELDIAG3],
            [DELDIAG4],
            [DELDIAG5],
            [DELDIAG6],
            [DELDIAG7],
            [DELDIAG8],
            [DELDIAG9],
            [DELDIAG10],
            [USER_UPLOADED_BY],
            [SOURCE],
            [IMPORTED_DATE],
            [EXPORTED_FILEID],
            [Source_ID],
            [Provider_ID],
            [Image_ID],
            [Date_Of_Notification],
            [In_Cluster],
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
            [RAPS_Detail_ID],
            [MemberIDReceived],
            [Claim_ID],
            [RAPSDetailImportID],
            [RAPSSourceTypeID],
            [SPMRID],
            [CNRAPSImportDetailID],
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
	
	COMMIT TRANSACTION Insert_update_Raps;

RETURN ISNULL(@Incre_load_Count, 0);

END TRY
BEGIN CATCH
    DECLARE @error INT,
            @message VARCHAR(4000);
    SELECT @error = ERROR_NUMBER(),
           @message = ERROR_MESSAGE();
	ROLLBACK Transaction Insert_update_Raps;
    RAISERROR('%d: %s', 16, 1, @error, @message);

END CATCH;
