CREATE PROCEDURE [dbo].[spr_Insert_dbo_tbl_Plan_Claims_rollup]
    @SourceDatabase sysname,
    @PlanIdentifier SMALLINT, --= -999
    @Incre_load_Count INT OUTPUT

/********************************************************************************************************************** 
  * Name			:	[dbo].[spr_Insert_dbo_tbl_Plan_Claims_rollup]													*
  * Type 			:	Stored Procedure																				*
  * Author       	:	Anand																							*
  * Date			:	2020-04-22																						*
  * Version			:	1.0																								*
  * Description		:	This stored procedure will check for incremental records based on Claim_ID 
						and insert it in batches
  *Notes:																										        *
  * Version History :													      												*
  * =================																									*
  * Author			Date			Version#    TFS Ticket#		Description												*
  * ---------------	----------		--------    -----------		------------											*
  * Anand           2020-04-22		1.0	        RRI-4/78423   
  * Anand           2020-08-14		1.1         TFS-79347        Hot fix- Used Rollup End date instead of Rollupstart		
  * Anand			2020-08-18      1.2			RRI-163/79359	 Used Data Diff Logic to pick files for previous business day
  *	Anand			2022-02-24		1.3			RRI-2171		 Optimized Insert Process								*
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
DECLARE @TableName VARCHAR(128) = 'tbl_Plan_Claims_Rollup';
 
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

RAISERROR('000', 0, 1) WITH NOWAIT;

BEGIN TRY
BEGIN TRANSACTION Insert_update_Plan;

   IF NOT EXISTS
    (
        SELECT 1
        FROM dbo.RollupMinMaxValues
        WHERE [SourceDatabase] = @SourceDatabase
              AND [TableName] = @TableName
              AND [PLANIDENTIFIER] = @PlanIdentifier
    )
    BEGIN

        SET @SourceSQL = N'
SELECT @SourceMinValueD =Min([Claim_ID]),
	   @SourceMaxValueD =Max([Claim_ID])	
FROM ' + @SourceDatabase + N'.[dbo].[tbl_plan_claims] rd WITH (NOLOCK)
		  ';

        EXECUTE sp_executesql @SourceSQL,
                              N'@SourceMinValueD BIGINT OUTPUT, @SourceMaxValueD BIGINT OUTPUT',
                              @SourceMinValueD = @SourceMinValue OUTPUT,
                              @SourceMaxValueD = @SourceMaxValue OUTPUT;

        SELECT @TargetMaxValue = ISNULL(MAX([Claim_ID]),-2147483648)
        FROM [dbo].[tbl_plan_claims_Rollup] rd WITH (NOLOCK)
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
                WHEN @TargetMaxValue = '-2147483648' THEN
                    @SourceMinValue - 1
                ELSE
                    @TargetMaxValue
            END, 
			@UpdateDT
		);

    END;

    ELSE
    BEGIN

        SET @SourceSQL = N'
SELECT @SourceMinValueD =Min([Claim_ID]),
	   @SourceMaxValueD =Max([Claim_ID])	
FROM ' + @SourceDatabase + N'.[dbo].[tbl_plan_Claims] rd WITH (NOLOCK)
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
      [PlanIdentifier] = ' + CAST(@PlanIdentifier AS CHAR(6))
              + '
	  ,[Claim_ID]
      ,[Plan_ID]
      ,[Plan_Claim_ID]
      ,[Claim_Line_Number]
      ,[HICN]
      ,[Start_Date]
      ,[End_Date]
      ,[Provider_ID]
      ,[Plan_Provider_ID]
      ,[Bill_Type]
      ,[Revenue_Code]
      ,[Procedure_Code]
      ,[Modifier_Code]
      ,[Place_Of_Service_Code]
      ,[Amount_Billed]
      ,[Amount_Paid]
      ,[Diagnoses_1]
      ,[Diagnoses_2]
      ,[Diagnoses_3]
      ,[Diagnoses_4]
      ,[Diagnoses_5]
      ,[Diagnoses_6]
      ,[Diagnoses_7]
      ,[Diagnoses_8]
      ,[Diagnoses_9]
      ,[Diagnoses_10]
      ,[Provider_LastName]
      ,[Provider_FirstName]
      ,[Physician_Address_1]
      ,[Physician_Address_2]
      ,[Physician_City]
      ,[Physician_State]
      ,[Physician_ZIP]
      ,[Physician_ZIP4]
      ,[Physician_Phone]
      ,[Physician_Group_Name]
      ,[Physician_Group_ID]
      ,[Physician_Office_Contact]
      ,[Adjusted_Claim]
      ,[Received_Date]
      ,[Populated]
      ,[AddDiagKey]
      ,[ClaimSource]
      ,[ICD10Ind]
      ,[ImportFileName]
      ,[Original_Plan_Claim_ID]
      ,[Physician_Assoc_ID]
      ,[Physician_Assoc_Name]
      ,[RAC1]
      ,[RAC2]
      ,[RAC3]
      ,[RAC4]
      ,[RAC5]
      ,[RAC6]
      ,[RAC7]
      ,[RAC8]
      ,[RAC9]
      ,[RAC10]
      ,[Unique_MBR_Identifier]
      ,[MemberIDReceived]
      ,[Claim_Sequence_Number]
      ,[FreeField1]
      ,[EncounterID]
      ,[DQ1]
      ,[DQ2]
      ,[DQ3]
      ,[DQ4]
      ,[DQ5]
      ,[DQ6]
      ,[DQ7]
      ,[DQ8]
      ,[DQ9]
      ,[DQ10]
      ,[ClaimStatusID]
      ,[NPI]
      ,[DerivedTaxonomy]
      ,[DerivedSpecialty]
	  ,[RollupLoad] = ''' + CONVERT(CHAR(23), @UpdateDT, 121) + '''
FROM [' + @SourceDatabase + '].[dbo].[tbl_Plan_Claims] WITH (NOLOCK)
WHERE [Claim_ID] > CONVERT(BIGINT,' + CAST(@TargetMaxValue AS VARCHAR(MAX)) + ')
  AND [Claim_ID] <=  CONVERT(BIGINT,' + CAST(@TargetMaxValue AS VARCHAR(MAX)) + ')' + '+' + ' CONVERT(BIGINT,'
              + CAST(@batchsize AS VARCHAR(MAX)) + ')
  AND [Populated]>= DATEADD(year,-4,getdate())
'       ;

        INSERT INTO [dbo].[tbl_Plan_Claims_rollup]
        (
            [PlanIdentifier],
            [Claim_ID],
            [Plan_ID],
            [Plan_Claim_ID],
            [Claim_Line_Number],
            [HICN],
            [Start_Date],
            [End_Date],
            [Provider_ID],
            [Plan_Provider_ID],
            [Bill_Type],
            [Revenue_Code],
            [Procedure_Code],
            [Modifier_Code],
            [Place_Of_Service_Code],
            [Amount_Billed],
            [Amount_Paid],
            [Diagnoses_1],
            [Diagnoses_2],
            [Diagnoses_3],
            [Diagnoses_4],
            [Diagnoses_5],
            [Diagnoses_6],
            [Diagnoses_7],
            [Diagnoses_8],
            [Diagnoses_9],
            [Diagnoses_10],
            [Provider_LastName],
            [Provider_FirstName],
            [Physician_Address_1],
            [Physician_Address_2],
            [Physician_City],
            [Physician_State],
            [Physician_ZIP],
            [Physician_ZIP4],
            [Physician_Phone],
            [Physician_Group_Name],
            [Physician_Group_ID],
            [Physician_Office_Contact],
            [Adjusted_Claim],
            [Received_Date],
            [Populated],
            [AddDiagKey],
            [ClaimSource],
            [ICD10Ind],
            [ImportFileName],
            [Original_Plan_Claim_ID],
            [Physician_Assoc_ID],
            [Physician_Assoc_Name],
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
            [Unique_MBR_Identifier],
            [MemberIDReceived],
            [Claim_Sequence_Number],
            [FreeField1],
            [EncounterID],
            [DQ1],
            [DQ2],
            [DQ3],
            [DQ4],
            [DQ5],
            [DQ6],
            [DQ7],
            [DQ8],
            [DQ9],
            [DQ10],
            [ClaimStatusID],
            [NPI],
            [DerivedTaxonomy],
            [DerivedSpecialty],
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
	
COMMIT TRANSACTION Insert_update_Plan;

RETURN ISNULL(@Incre_load_Count, 0);


END TRY
------------------------------------------------------------------------
-- Error handling
-------------------------------------------------------------------------	
BEGIN CATCH
    DECLARE @error INT,
            @message VARCHAR(4000);
    SELECT @error = ERROR_NUMBER(),
           @message = ERROR_MESSAGE();
	ROLLBACK Transaction Insert_update_Plan;
    RAISERROR('%d: %s', 16, 1, @error, @message);

END CATCH
