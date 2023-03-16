/*******************************************************************************************************************************
* Name			:	rev.WrapperLoadPartDNewHCCOutputMParameter       
* Author       	:	Rakshit Lall
* TFS#          :   
* Date          :	1/10/2018
* Version		:	1.0
* Project		:	Wrapper SP used for deleting data from "PartDNewHCCOutputMParameter" table for the active payment year in the <Client>_Report Db 
					and then load the data in the permanent table
* SP call		:	Exec rev.WrapperLoadPartDNewHCCOutputMParameter
* Version History :
  Author			Date		Version#	TFS Ticket#		Description
* -----------------	----------	--------	-----------		------------ 
	Rakshit Lall	1/18/2018	1.1			68897			Commented out the DELETE from the table
	Rakshit Lall	2/15/2018	1.2			69583			Uncommented the EDS SP call
	David Waddell   3/29/2018   1.3         70339           Updated Print statements to include Start and End Process By Dates 
	Anand			3/06/2020	1.4			78034			Removing reference - History PartD table.
	Anand			4/03/2021	1.5			80908			Removed Raps/File String Parameters
    D. Waddell		5/29/2021	1.6			RRI-348/908		Add insert into New HCC Activity Log (RAPS New HCC)
    D. Waddell      6/25/21     1.7         RRI-1258        Add insert into New HCC Activity Log (EDS New HCC)
*********************************************************************************************************************************/

CREATE PROCEDURE [rev].[WrapperLoadPartDNewHCCOutputMParameter]
AS
    BEGIN

        SET NOCOUNT ON

        DECLARE @Error_Message VARCHAR (8000)
        DECLARE @NewHCCActivityIdMain INT; 
		DECLARE @NewHCCActivityIdSecondary INT;
		DECLARE @Today DATETIME;
		DECLARE @RAPSRowCount INT;
		DECLARE @EDSRowCount INT;
        DECLARE @TableName VARCHAR(100);
        DECLARE @ReportOutputByMonth CHAR(1);
		DECLARE @RefreshDate  DATETIME;
        DECLARE @TableName_OUT VARCHAR(100);
        DECLARE @ReportOutputByMonth_OUT CHAR(1);
		Declare @RowCount_OUT INT;
		DECLARE @UserID Varchar(20);

        BEGIN TRY

            IF OBJECT_ID( 'TempDB..#ActiveYearPlans' ) IS NOT NULL
                DROP TABLE #ActiveYearPlans

            CREATE TABLE #ActiveYearPlans
                (
                    ActiveYearPlanID SMALLINT IDENTITY (1, 1) PRIMARY KEY NOT NULL ,
                    PaymentYear INT NOT NULL ,
                    ProcessedByStartDate SMALLDATETIME NOT NULL ,
                    ProcessedByEndDate SMALLDATETIME NOT NULL
                )

            INSERT INTO #ActiveYearPlans (   PaymentYear ,
                                             ProcessedByStartDate ,
                                             ProcessedByEndDate
                                         )
                        SELECT   RPY.Payment_Year ,
                                 RPY.From_Date AS ProcessedByStartDate ,
                                 GETDATE() AS ProcessedByEndDate
                        FROM     rev.tbl_Summary_RskAdj_RefreshPY RPY WITH ( NOLOCK )
                        GROUP BY RPY.Payment_Year ,
                                 RPY.From_Date

            /* Commenting this portion out to test the partition switch approach */

            --DELETE FROM rev.PartDNewHCCOutputMParameter
            --WHERE PaymentYear IN
            --	(
            --		SELECT DISTINCT PaymentYear
            --		FROM #ActiveYearPlans
            --	)

            IF EXISTS (   SELECT TOP 1 PartDNewHCCOutputMParameterID
                          FROM   etl.PartDNewHCCOutputMParameter
                      )
                BEGIN
                    TRUNCATE TABLE etl.PartDNewHCCOutputMParameter
                END

            /* Loop for plan and year */

            DECLARE @Counter INT ,
                    @I       INT = 1

            SET @Counter = (   SELECT MAX( ActiveYearPlanID )
                               FROM   #ActiveYearPlans
                           )

            WHILE ( @I <= @Counter )
                BEGIN

                    DECLARE @PaymentYear INT = (   SELECT PaymentYear
                                                   FROM   #ActiveYearPlans
                                                   WHERE  ActiveYearPlanID = @I
                                               )
                    DECLARE @ProcessedByStartDate SMALLDATETIME = (   SELECT ProcessedByStartDate
                                                                      FROM   #ActiveYearPlans
                                                                      WHERE  ActiveYearPlanID = @I
                                                                  )
                    DECLARE @ProcessedByEndDate SMALLDATETIME = (   SELECT ProcessedByEndDate
                                                                    FROM   #ActiveYearPlans
                                                                    WHERE  ActiveYearPlanID = @I
                                                                )

                    SELECT @PaymentYear ,
                           @ProcessedByStartDate ,
                           @ProcessedByEndDate

                    DECLARE @SPPath VARCHAR (300) = 'rev.LoadSummaryPartDRAPSNewHCC'

                    PRINT ( @SPPath )

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
					   [Process] = 'rev.LoadSummaryPartDRAPSNewHCC',
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


                    EXEC @SPPath @PaymentYear ,
                                 @ProcessedByStartDate ,
                                 @ProcessedByEndDate ,
                                 'M' ,
                                 -1 ,
                                  @RowCount = @RowCount_OUT OUTPUT,
                                  @TableName = @TableName_OUT OUTPUT,
                                  @ReportOutputByMonthID = @ReportOutputByMonth_OUT OUTPUT
                                  
                                  ;
                    
                    /* Update NewHCCActivitiy table with number of RAPS New HCC records inserted     */
					SET @RefreshDate = GETDATE();
					SET  @RAPSRowCount = Isnull(@RowCount_OUT,0);
                    SET @TableName = IsNull(@TableName_OUT,0);
                    SET @ReportOutputByMonth = ISNull(@ReportOutputByMonth_Out,0);

					UPDATE [m]
					SET [m].[EDate] = @RefreshDate,
                        [m].[ReportOutputByMonthID] = @ReportOutputByMonth,
                        [m].[TableName] = @TableName,
                        [m].[PartCDFlag]= 'Part D',
						[m].[AdditionalRows] = @RAPSRowCount,
                        [m].[LastUpdatedDate] = GETDATE()
					FROM [rev].[NewHCCActivity] [m]
					WHERE [m]. [NewHCCActivityId]  = @NewHCCActivityIdMain;


					SET @NewHCCActivityIdSecondary = @NewHCCActivityIdMain;


                    PRINT 'RAPS Load completed for :'
                          + CONVERT( VARCHAR (4), @PaymentYear )
                          + ' processed from '
                          + CONVERT( VARCHAR (10), @ProcessedByStartDate, 101 )
                          + ' to '
                          + CONVERT( VARCHAR (10), @ProcessedByEndDate, 101 )
                          + ' .'

                    -----

                    DECLARE @EDSSPPath VARCHAR (300) = 'rev.LoadSummaryPartDEDSNewHCC'

                    PRINT ( @EDSSPPath )

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
					   [Process] = 'rev.LoadSummaryPartDEDSNewHCC',
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



                    EXEC @EDSSPPath @PaymentYear ,
                                    @ProcessedByStartDate ,
                                    @ProcessedByEndDate ,
                                    'M' ,
                                    -1 ,
                                     @RowCount = @RowCount_OUT OUTPUT,
                                  @TableName = @TableName_OUT OUTPUT,
                                  @ReportOutputByMonthID = @ReportOutputByMonth_OUT OUTPUT                                  
                                  ;


                    /* Update NewHCCActivitiy table with number of RAPS New HCC records inserted     */
					SET @RefreshDate = GETDATE();
					SET  @RAPSRowCount = Isnull(@RowCount_OUT,0);
                    SET @TableName = IsNull(@TableName_OUT,0);
                    SET @ReportOutputByMonth = ISNull(@ReportOutputByMonth_Out,0);

					UPDATE [m]
					SET [m].[EDate] = @RefreshDate,
                        [m].[ReportOutputByMonthID] = @ReportOutputByMonth,
                        [m].[TableName] = @TableName,
                        [m].[PartCDFlag]= 'Part D',
						[m].[AdditionalRows] = @RAPSRowCount,
                        [m].[LastUpdatedDate] = GETDATE()
					FROM [rev].[NewHCCActivity] [m]
					WHERE [m]. [NewHCCActivityId]  = @NewHCCActivityIdMain;


					SET @NewHCCActivityIdSecondary = NULL;


                    PRINT 'EDS Load completed for :'
                          + CONVERT( VARCHAR (4), @PaymentYear )
                          + ' processed from '
                          + CONVERT( VARCHAR (10), @ProcessedByStartDate, 101 )
                          + ' to '
                          + CONVERT( VARCHAR (10), @ProcessedByEndDate, 101 )
                          + ' .'

                    /* Switch Partitions */

                    IF EXISTS (   SELECT TOP 1 1
                                  FROM   etl.PartDNewHCCOutputMParameter
                              )
                        BEGIN

                            PRINT 'Starting Partition Switch For PaymentYear : '
                                  + CONVERT( VARCHAR (4), @PaymentYear )

                            BEGIN TRANSACTION SwitchPartitions;

                            TRUNCATE TABLE [out].PartDNewHCCOutputMParameter

                            -- Switch Partition for History PartDNewHCCOutputMParameter 
                            --ALTER TABLE hst.PartDNewHCCOutputMParameter SWITCH PARTITION $Partition.[pfn_SummPY](@PaymentYear)TO [out].PartDNewHCCOutputMParameter PARTITION $Partition.[pfn_SummPY](@PaymentYear)

                            -- Switch Partition for DBO PartDNewHCCOutputMParameter 
                            ALTER TABLE rev.PartDNewHCCOutputMParameter SWITCH PARTITION $Partition.[pfn_SummPY](@PaymentYear)TO [out].PartDNewHCCOutputMParameter PARTITION $Partition.[pfn_SummPY](@PaymentYear)

                            -- Switch Partition for ETL PartDNewHCCOutputMParameter	
                            ALTER TABLE etl.PartDNewHCCOutputMParameter SWITCH PARTITION $Partition.[pfn_SummPY](@PaymentYear)TO rev.PartDNewHCCOutputMParameter PARTITION $Partition.[pfn_SummPY](@PaymentYear)

                            COMMIT TRANSACTION SwitchPartitions;

                            PRINT 'Partition Switch Completed For PaymentYear : '
                                  + CONVERT( VARCHAR (4), @PaymentYear )

                        END
                    ELSE
                        PRINT 'Partition switching did not run because there was no data was loaded in the ETL table For PaymentYear'
                              + CONVERT( VARCHAR (4), @PaymentYear )

                    SET @I = @I + 1

                END

        END TRY
        BEGIN CATCH
            DECLARE @ErrorMsg VARCHAR (2000)
            SET @ErrorMsg = 'Error: ' + ISNULL( ERROR_PROCEDURE(), 'script' )
                            + ': ' + ERROR_MESSAGE() + ', Error Number: '
                            + CAST(ERROR_NUMBER() AS VARCHAR (10))
                            + ' Line: ' + CAST(ERROR_LINE() AS VARCHAR (50))

            RAISERROR( @ErrorMsg, 16, 1 )
        END CATCH

    END