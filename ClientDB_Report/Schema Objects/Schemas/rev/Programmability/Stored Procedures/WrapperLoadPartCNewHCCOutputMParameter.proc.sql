
/*******************************************************************************************************************************
* Name			:	rev.WrapperLoadPartCNewHCCOutputMParameter
* Type 			:	Stored Procedure          
* Author       	:	Rakshit Lall
* TFS#          :   65357
* Date          :	6/12/2017
* Version		:	1.0
* Project		:	Wrapper SP used for deleting data from "PartCNewHCCOutputMParameter" table for the active payment year in the <Client>_Report Db 
					and calling Plan level SP's to load the data
* SP call		:	Exec rev.WrapperLoadPartCNewHCCOutputMParameter
* Version History :
  Author			Date		Version#	TFS Ticket#					Description
* -----------------	----------		--------	-----------		------------ 
	Rakshit Lall	10/28/2018	1.1		73695					Added code to populate rev.PartCNewHCCRAPSEDSReconciliation table
	D. Waddell      05/21/2019  1.2 75567						exec statements within the loop modified to point to the report level version of the New HCC scripts.     
	D.Waddell       07/01/2019  1.3 76348 (RE-5574)				Wrapper Part C New HCC - removing Client look up table dependency
	D.Waddell       08/23/19    1.4 76647 (RE-6186)				Incorporating Historical capture logic into Part C RAPS and EDS New HCC Wrapper
	Anand			10/16/19	1.5	77046 (RE - 6821)			Created Partition table for MParameter & RAPSRecon.
    D.Waddell		05/29/21	1.6 RRI-948/908					Insert added row count into NewHCCActivity Table (RAPS New HCC)
    D.Waddell       06/25/2021  1.7 RRI-1258                    Insert added row count into NewHCCActivity Table (EDS New HCC)
*********************************************************************************************************************************/

Create PROCEDURE [rev].[WrapperLoadPartCNewHCCOutputMParameter]
AS
BEGIN

    SET NOCOUNT ON;

    DECLARE @Error_Message VARCHAR(8000);
    DECLARE @NewHCCActivityIdMain INT; 
	DECLARE @NewHCCActivityIdSecondary INT;
	DECLARE @Today DATETIME;
	DECLARE @UserID Varchar(20);
	DECLARE @RAPSRowCount INT;
	DECLARE @EDSRowCount INT;
    DECLARE @TableName VARCHAR(100);
    DECLARE @ReportOutputByMonth CHAR(1);
	DECLARE @RowCount_OUT INT;
    DECLARE @TableName_OUT VARCHAR(100);
    DECLARE @ReportOutputByMonth_OUT CHAR(1);
	DECLARE @RefreshDate  DATETIME;

    BEGIN TRY

        IF OBJECT_ID('TempDB..#ActiveYearPlans') IS NOT NULL
            DROP TABLE #ActiveYearPlans;

        DECLARE @ClientID INT =
                (
                    SELECT Client_ID
                    FROM [$(HRPReporting)].dbo.tbl_Clients
                    WHERE Report_DB = DB_NAME()
                );

        CREATE TABLE #ActiveYearPlans
        (
            ActiveYearPlanID SMALLINT IDENTITY(1, 1) PRIMARY KEY NOT NULL,
            PaymentYear VARCHAR(4) NOT NULL,
            ProcessedByStartDate SMALLDATETIME NOT NULL,
            ProcessedByEndDate SMALLDATETIME NOT NULL
        );

        INSERT INTO #ActiveYearPlans -- TFS 75567  Modified 4/1/19 DW 
        (
            PaymentYear, --TFS76348 removed ClientID 
            ProcessedByStartDate,
            ProcessedByEndDate
        )
        SELECT DISTINCT
               RPY.Payment_Year,
               RPY.From_Date AS ProcessedByStartDate,
               GETDATE() AS ProcessedByEndDate
        FROM rev.tbl_Summary_RskAdj_RefreshPY RPY WITH (NOLOCK) --TFS76348 - removing Client look up table dependency  (D.Waddell)
        GROUP BY RPY.Payment_Year,
                 RPY.From_Date;


-- Commented as part of RE - 6821
        --DELETE FROM rev.PartCNewHCCOutputMParameter
        --WHERE PaymentYear IN
        --      (
        --          SELECT DISTINCT PaymentYear FROM #ActiveYearPlans
        --      );

        --DELETE FROM rev.PartCNewHCCRAPSEDSReconciliation
        --WHERE PaymentYear IN
        --      (
        --          SELECT DISTINCT PaymentYear FROM #ActiveYearPlans
        --      );

-- Commented as part of RE - 6821

--RE - 6821 - Changes - Begin


DECLARE @C INT
DECLARE @ID INT = (SELECT COUNT([ActiveYearPlanID]) FROM  [#ActiveYearPlans])

SET @C = 1


WHILE ( @C <= @ID )
  BEGIN 

	DECLARE @PaymentYearM Int

		SELECT @PaymentYearM = PaymentYear  
        FROM   [#ActiveYearPlans]
		WHERE  [ActiveYearPlanID] = @C


if (object_id('[out].[PartCNewHCCRAPSEDSReconciliation]') is not null)
begin
    Truncate table [out].[PartCNewHCCOutputMParameter];
end

ALTER TABLE [rev].[PartCNewHCCOutputMParameter] SWITCH  PARTITION $Partition.[pfn_SummPY] (@PaymentYearM) TO [out].[PartCNewHCCOutputMParameter] PARTITION $Partition.[pfn_SummPY] (@PaymentYearM)
	
SET @C = @C + 1

END

SET @C = 1


WHILE ( @C <= @ID )
  BEGIN 

	DECLARE @PaymentYearRaps Int

		SELECT @PaymentYearRaps = PaymentYear  
        FROM   [#ActiveYearPlans]
		WHERE  [ActiveYearPlanID] = @C


		
if (object_id('[out].[PartCNewHCCRAPSEDSReconciliation]') is not null)
begin
    Truncate table [out].[PartCNewHCCRAPSEDSReconciliation];
end


ALTER TABLE [rev].[PartCNewHCCRAPSEDSReconciliation] SWITCH  PARTITION $Partition.[pfn_SummPY] (@PaymentYearRaps) TO [out].[PartCNewHCCRAPSEDSReconciliation] PARTITION $Partition.[pfn_SummPY] (@PaymentYearRaps)

SET @C = @C + 1

END


--RE - 6821 - Changes - End


        /* Loop for plan and year */

        DECLARE @Counter INT,
                @I INT = 1;

        SET @Counter =
        (
            SELECT MAX(ActiveYearPlanID) FROM #ActiveYearPlans
        );

        WHILE (@I <= @Counter)
        BEGIN

            DECLARE @PaymentYear VARCHAR(4) =
                    (
                        SELECT PaymentYear FROM #ActiveYearPlans WHERE ActiveYearPlanID = @I
                    );
            DECLARE @DB VARCHAR(128) =
                    (
                        SELECT Report_DB
                        FROM [$(HRPReporting)].dbo.tbl_Clients
                        WHERE [Client_ID] = @ClientID
                    ); -- TFS 75567 Modified 4/1/19 DW 
            DECLARE @ProcessedByStartDate SMALLDATETIME =
                    (
                        SELECT ProcessedByStartDate
                        FROM #ActiveYearPlans
                        WHERE ActiveYearPlanID = @I
                    );
            DECLARE @ProcessedByEndDate SMALLDATETIME =
                    (
                        SELECT ProcessedByEndDate
                        FROM #ActiveYearPlans
                        WHERE ActiveYearPlanID = @I
                    );

            --SELECT @PaymentYear, @DB, @ProcessedByStartDate, @ProcessedByEndDate

            /* Load RAPS New HCC data in table - rev.PartCNewHCCOutputMParameter */

            DECLARE @SPPath VARCHAR(300) = @DB + '.rev.spr_EstRecv_RAPS_New_HCC';

            PRINT (@SPPath);


           /* Update NewHCCActivitiy table with start date/time for insert into New HCC table for rev.spr_EstRecv_RAPS_New_HC  */     --Modified for RRI-34/908 DW 5/12/21

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
        SELECT [GroupingId] = NULL,
           [Process] = 'rev.spr_EstRecv_RAPS_New_HCC',
		   [PaymentYear] = @PaymentYear,
           [BDate] = @Today,
           [EDate] = NULL,
           [AdditionalRows] = NULL,
           [RunBy] = @UserID,
           [ReportOutputByMonthID]= NULL;

        SET @NewHCCActivityIdMain = SCOPE_IDENTITY();
	    SET @RowCount_OUT = 0;
        SET @TableName_OUT = '';
        SET @ReportOutputByMonth_OUT = 'N';

        UPDATE [m]
        SET [m].[GroupingId] = @NewHCCActivityIdMain
        FROM [rev].[NewHCCActivity] [m]
	    WHERE [m].[NewHCCActivityId]  = @NewHCCActivityIdMain;

			

        EXEC @SPPath @PaymentYear,
                     @ProcessedByStartDate,
                     @ProcessedByEndDate,
                    'M',
                     @RowCount = @RowCount_OUT OUTPUT,
                     @TableName = @TableName_OUT OUTPUT,
                     @ReportOutputByMonthID = @ReportOutputByMonth_OUT OUTPUT;



            /* Update NewHCCActivitiy table with number of RAPS New HCC records inserted     */
		    SET @RefreshDate = GETDATE();
		    SET  @RAPSRowCount = Isnull(@RowCount_OUT,0);
            SET @TableName = IsNull(@TableName_OUT,0);
            SET @ReportOutputByMonth = ISNull(@ReportOutputByMonth_Out,0);

            UPDATE [m]
             SET [m].[EDate] = @RefreshDate,
                    [m].[AdditionalRows] = @RAPSRowCount,
                    [m].[ReportOutputByMonthID] = @ReportOutputByMonth,
                    [m].[TableName] = @TableName,
                    [m].[PartCDFlag]= 'Part C',
                    [m].[LastUpdatedDate] = GETDATE()
                  
             FROM [rev].[NewHCCActivity] [m]
                WHERE [m]. [NewHCCActivityId]  = @NewHCCActivityIdMain;


            SET @NewHCCActivityIdSecondary = @NewHCCActivityIdMain;
   

            /* Load EDS New HCC data in table - rev.PartCNewHCCOutputMParameter */

            DECLARE @EDSSPPath VARCHAR(300) = @DB + '.rev.spr_EstRecv_EDS_New_HCC';

            PRINT (@EDSSPPath);




             /* Update NewHCCActivitiy table with start date/time for insert into New HCC table for rev.spr_EstRecv_RAPS_New_HC  */     --Modified for RRI-34/908 DW 5/12/21

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
        SELECT [GroupingId] = @NewHCCActivityIdSecondary,
           [Process] = 'rev.spr_EstRecv_EDS_New_HCC',
		   [PaymentYear] = @PaymentYear,
           [BDate] = @Today,
           [EDate] = NULL,
           [AdditionalRows] = NULL,
           [RunBy] = @UserID,
           [ReportOutputByMonthID]= NULL;

        SET @NewHCCActivityIdMain = SCOPE_IDENTITY();
	    SET @RowCount_OUT = 0;
        SET @TableName_OUT = '';
        SET @ReportOutputByMonth_OUT = 'N';

        UPDATE [m]
        SET [m].[GroupingId] = @NewHCCActivityIdSecondary
        FROM [rev].[NewHCCActivity] [m]
	    WHERE [m].[NewHCCActivityId]  = @NewHCCActivityIdMain;





            EXEC @EDSSPPath @PaymentYear,
                            @ProcessedByStartDate,
                            @ProcessedByEndDate,
                            'M',
                            @RowCount = @RowCount_OUT OUTPUT,
                     @TableName = @TableName_OUT OUTPUT,
                     @ReportOutputByMonthID = @ReportOutputByMonth_OUT OUTPUT;

            /* Update NewHCCActivitiy table with number of EDS New HCC records inserted     */
		    SET @RefreshDate = GETDATE();
		    SET  @RAPSRowCount = Isnull(@RowCount_OUT,0);
            SET @TableName = IsNull(@TableName_OUT,0);
            SET @ReportOutputByMonth = ISNull(@ReportOutputByMonth_Out,0);

            UPDATE [m]
             SET [m].[EDate] = @RefreshDate,
                    [m].[AdditionalRows] = @RAPSRowCount,
                    [m].[ReportOutputByMonthID] = @ReportOutputByMonth,
                    [m].[TableName] = @TableName,
                    [m].[PartCDFlag]= 'Part C',
                    [m].[LastUpdatedDate] = GETDATE()
                  
             FROM [rev].[NewHCCActivity] [m]
                WHERE [m]. [NewHCCActivityId]  = @NewHCCActivityIdMain;


                SET @NewHCCActivityIdSecondary = NULL;



            /* Load table - rev.PartCNewHCCRAPSEDSReconciliation */

            EXEC rev.LoadPartCNewHCCRAPSEDSReconciliation @PaymentYear;


            /* Load table - rev.LoadPartCNewHCCOutputMParameterHistory */

            EXEC rev.LoadPartCNewHCCOutputMParameterHistory @PaymentYear;

			SET @I = @I + 1;

        END;
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMsg VARCHAR(2000);
        SET @ErrorMsg
            = 'Error: ' + ISNULL(ERROR_PROCEDURE(), 'script') + ': ' + ERROR_MESSAGE() + ', Error Number: '
              + CAST(ERROR_NUMBER() AS VARCHAR(10)) + ' Line: ' + CAST(ERROR_LINE() AS VARCHAR(50));

        RAISERROR(@ErrorMsg, 16, 1);
    END CATCH;

END;
GO


