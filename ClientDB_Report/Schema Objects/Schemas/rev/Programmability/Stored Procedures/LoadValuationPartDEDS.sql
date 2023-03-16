/*******************************************************************************************************************************
* Name			:	rev.LoadValuationPartDEDS
* Type 			:	Stored Procedure          
* Author       	:	Anand
* JRIA#          :  RRI-1239
* Date          :	10/12/2021
* Version		:	1.0
* SP call		:	Exec rev.LoadValuationPartDEDS
* Version History :
  Author			Date			Version#	    Ticket#					Description
* -----------------	----------		--------	  -----------				------------ 
	Anand			10/12/2021		  1.0			RRI-1239				Execute EDS NEW HCC Valuation Part D
	Madhuri Suri    2/3/2022          2.0           RRI-2064                      While Loop correction
		
*********************************************************************************************************************************/

CREATE PROCEDURE [rev].[LoadValuationPartDEDS]

    @Payment_Year VARCHAR(4) =NUll,
    @PROCESSBY_START SMALLDATETIME=NUll,
    @PROCESSBY_END SMALLDATETIME=NUll
AS
BEGIN

    SET NOCOUNT ON;

    DECLARE @NewHCCActivityIdMain INT; 
	DECLARE @Today DATETIME;
	DECLARE @UserID Varchar(20);
	DECLARE @EDSRowCount INT;
    DECLARE @TableName VARCHAR(100);
    DECLARE @ReportOutputByMonth CHAR(1);
	DECLARE @RowCount_OUT INT;
    DECLARE @TableName_OUT VARCHAR(100);
    DECLARE @ReportOutputByMonth_OUT CHAR(1);
	DECLARE @RefreshDate  DATETIME;
	DECLARE @EDSSPPath VARCHAR(300) = 'rev.LoadSummaryPartDEDSNewHCC';
    DECLARE @Payment_YearV INT
	DECLARE @ProcessedByStartDate SMALLDATETIME 
	DECLARE @ProcessedByENDDate SMALLDATETIME 
	DECLARE @ProcessRunId INT;
	DECLARE @currentyear VARCHAR(4) = YEAR(GETDATE());

    BEGIN TRY




    IF OBJECT_ID('TempDB..#ActiveYearPlans') IS NOT NULL
        DROP TABLE #ActiveYearPlans;

    CREATE TABLE #ActiveYearPlans
    (
        ActiveYearPlanID SMALLINT IDENTITY(1, 1) PRIMARY KEY NOT NULL,
        PaymentYear VARCHAR(4) NOT NULL,
        ProcessedByStartDate SMALLDATETIME NULL,
        ProcessedByEndDate SMALLDATETIME NULL
    );


IF (@Payment_Year IS NOT NULL) 


BEGIN 
/*Declare Force Run Parameters*/
   INSERT INTO #ActiveYearPlans
        (
            PaymentYear, 
            ProcessedByStartDate,
            ProcessedByEndDate
        )
		Values
		(
			@Payment_Year,
			@PROCESSBY_START,
			@PROCESSBY_END
		);


END

ELSE 

BEGIN
/*Declare Parameters from table Refresh PY*/
       INSERT INTO #ActiveYearPlans
        (
            PaymentYear, 
            ProcessedByStartDate,
            ProcessedByEndDate
        )
        SELECT 
               RPY.Payment_Year,
               RPY.From_Date AS ProcessedByStartDate,
               RPY.Final_Sweep_Date AS ProcessedByEndDate
        FROM rev.tbl_Summary_RskAdj_RefreshPY RPY WITH (NOLOCK)
        GROUP BY RPY.Payment_Year,
                 RPY.From_Date,
				 RPY.Final_Sweep_Date;
END 


----------------------------------------------------------------------------------------------------------
/*Run for declared Parameters */
 ----------------------------------------------------------------------------------------------------------- 
DECLARE @Counter INT,
          @I INT = 1;

        SET @Counter =
        (
            SELECT MAX(ActiveYearPlanID) FROM #ActiveYearPlans
        );

WHILE (@I <= @Counter)
 BEGIN
								
	SELECT
	@Payment_YearV= PaymentYear ,
	@ProcessedByStartDate  = ProcessedByStartDate,
	@ProcessedByENDDate =ProcessedByEndDate
	FROM #ActiveYearPlans 
	WHERE ActiveYearPlanID = @I
	
	
		IF (@currentyear < @Payment_Year) OR (@ProcessedByStartDate IS NULL ) OR (@ProcessedByENDDate IS NULL) 
		BEGIN



	PRINT('Payment Year cannot exceed Current Year for Valuation Process OR Process by dates are NULL');
	Return;
			
			
		END 

ELSE
BEGIN
 IF EXISTS ( SELECT TOP 1 *  FROM rev.tbl_Summary_RskAdj_EDS_MOR_Combined
    WHERE PaymentYear = @Payment_YearV)
	 BEGIN

	
    SELECT 
		@ProcessRunId = AutoProcessRunId 
	FROM [Valuation].[AutoProcessActiveWorkList] WITH(NOLOCK);

   		    SET @Today = GETDATE();
            SET @UserID = CURRENT_USER;

           INSERT INTO [rev].[NewHCCActivity]
            (
                [GroupingId],
                [Process],
		        [PaymentYear],
                [BDate],
                [EDate],
                [AdditionalRows],
                [RunBy],
                [ReportOutputByMonthID]
            )
        SELECT [GroupingId] = Null,
           [Process] = 'rev.LoadSummaryPartDEDSNewHCC',
		   [PaymentYear] = @Payment_YearV,
           [BDate] = @Today,
           [EDate] = NULL,
           [AdditionalRows] = NULL,
           [RunBy] = @UserID,
           [ReportOutputByMonthID]= NULL;

        SET @NewHCCActivityIdMain = SCOPE_IDENTITY();
	    SET @RowCount_OUT = 0;
        SET @TableName_OUT = '';
        SET @ReportOutputByMonth_OUT = 'V';

        UPDATE [m]
        SET [m].[GroupingId] = @NewHCCActivityIdMain
        FROM [rev].[NewHCCActivity] [m]
	    WHERE [m].[NewHCCActivityId]  = @NewHCCActivityIdMain;


            EXEC @EDSSPPath @Payment_YearV,
                            @ProcessedByStartDate,
                            @ProcessedByEndDate,
                            @ReportOutputByMonth ='V',
							@ProcessRunId=@ProcessRunId,
                            @RowCount = @RowCount_OUT OUTPUT,
							@TableName = @TableName_OUT OUTPUT,
							@ReportOutputByMonthID = @ReportOutputByMonth_OUT OUTPUT;

		    SET @RefreshDate = GETDATE();
		    SET @EDSRowCount = Isnull(@RowCount_OUT,0);
            SET @TableName = IsNull(@TableName_OUT,0);
            SET @ReportOutputByMonth = ISNull(@ReportOutputByMonth_Out,0);

            UPDATE [m]
             SET [m].[EDate] = @RefreshDate,
                    [m].[AdditionalRows] = @EDSRowCount,
                    [m].[ReportOutputByMonthID] = @ReportOutputByMonth,
                    [m].[TableName] = @TableName,
                    [m].[PartCDFlag]= 'Part D',
                    [m].[LastUpdatedDate] = GETDATE()
                  
             FROM [rev].[NewHCCActivity] [m]
                WHERE [m]. [NewHCCActivityId]  = @NewHCCActivityIdMain;


END
END	
 	
 		SET @I = @I + 1;

 END
 
	
	END TRY
    BEGIN CATCH
        DECLARE @ErrorMsg VARCHAR(2000);
        SET @ErrorMsg
            = 'Error: ' + ISNULL(ERROR_PROCEDURE(), 'script') + ': ' + ERROR_MESSAGE() + ', Error Number: '
              + CAST(ERROR_NUMBER() AS VARCHAR(10)) + ' Line: ' + CAST(ERROR_LINE() AS VARCHAR(50));

        RAISERROR(@ErrorMsg, 16, 1);
    END CATCH;

END;
