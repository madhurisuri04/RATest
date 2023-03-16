CREATE PROCEDURE [rev].[EstReceivablesandRiskScores]
    (     @Payment_Year VARCHAR(4) = NULL
        , @MYU VARCHAR(1) = NULL
        , @Debug BIT = 0
    )
AS /************************************************************************        
* Name			:	[rev.EstReceivablesandRiskScores]     				*                                                     
* Type 			:	Stored Procedure									*                
* Author       	:	Madhuri Suri     									*
* Date          :	04/24/2017											*	
* Ticket        :   64005
* Version		:        												*
* Description	:	Estimated Receivables and Risk Scores for Part C                                              *

***************************************************************************/
    /**********************************************************************************************************************************
Ticket		 Date          Author           Descrition 
64919		 6/12/2017    Madhuri Suri               
65509		 6/26/2017    Madhuri Suri      EDS implementation Proc included   
65862		 8/7/2017     Madhuri Suri      Remove RefreshPYProc/Add ER Summary tables Load  Proc            
69577		 3/19/2018    D. Waddell        Change to iterate through identity column instead of Payment Year
75824		 4/25/2019    Madhuri Suri      Part C ER 2.0 Minor Changes 
76451		 7/22/2019    Madhuri Suri      Add History ER Load Stored Proc 
RRI-34/79581 09/15/20     Anand             Add Log process to EstRecvRskadjActivity table     
*************************************************************************************************************************************/
    --exec rev.EstReceivablesandRiskScores

BEGIN
        SET NOCOUNT ON

        SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
		Declare @RowCount_OUT INT;
		Declare @UserID VARCHAR(128) = SYSTEM_USER;
		Declare @EstRecvRskadjActivityID INT;

IF  (@Payment_Year IS NOT NULL and  @MYU IS NOT NULL)

BEGIN 

EXEC  [rev].[EstRecevRefreshPaymentYear] @Payment_Year, @MYU

END

ELSE 

BEGIN 

EXEC  [rev].[EstRecevRefreshPaymentYear] 


END

  /***********************************************************
  Execute Deletes before running ER Procs
  *************************************************************/
  	Begin 

        EXEC rev.EstRecevDeleteHCCLoad;

	End

        IF @Debug = 1
            BEGIN
                SET STATISTICS IO ON
                DECLARE @ET DATETIME
                DECLARE @MasterET DATETIME
                DECLARE @ProcessNameIn VARCHAR(128)
                SET @ET = GETDATE()
                SET @MasterET = @ET
                SET @ProcessNameIn = OBJECT_NAME(@@PROCID)
                EXEC [dbo].[PerfLogMonitor] @Section = '000' ,
                                            @ProcessName = @ProcessNameIn ,
                                            @ET = @ET ,
                                            @MasterET = @MasterET ,
                                            @ET_Out = @ET OUT ,
                                            @TableOutput = 0 ,
                                            @End = 0
            END


        IF OBJECT_ID('[TEMPDB].[DBO].[#EstRecevRefreshPY]', 'U') IS NOT NULL
            DROP TABLE [#EstRecevRefreshPY]



        CREATE TABLE [#EstRecevRefreshPY]
            (
                [ID] INT IDENTITY(1, 1) ,
                [EstRecevRefreshPYID] INT ,
                [Payment_Year] INT ,
                [MYU] VARCHAR(2) ,
                [ProcessedBy] DATETIME ,
                [DCPFromDate] DATETIME ,
                [DCPThrudate] DATETIME
            )



        IF @Debug = 1
            BEGIN
                EXEC [dbo].[PerfLogMonitor] '001' ,
                                            @ProcessNameIn ,
                                            @ET ,
                                            @MasterET ,
                                            @ET OUT ,
                                            0 ,
                                            0
            END



        INSERT INTO [#EstRecevRefreshPY]
                    SELECT [EstRecevRefreshPYID] ,
                           [Payment_Year] ,
                           [MYU] ,
                           [ProcessedBy] ,
                           [DCPFromDate] ,
                           [DCPThrudate]
                    FROM   [rev].[EstRecevRefreshPY]





        IF @Debug = 1
            BEGIN
                EXEC [dbo].[PerfLogMonitor] '002' ,
                                            @ProcessNameIn ,
                                            @ET ,
                                            @MasterET ,
                                            @ET OUT ,
                                            0 ,
                                            0
            END
        DECLARE @I INT
        DECLARE @ID INT = (   SELECT COUNT([ID]) --TFS 69577  modified by D. Waddell 03/18/18
                              FROM   [#EstRecevRefreshPY]
                          )




        /***********************************************************
  Execute refresh Payment year Proc to get PY to be refreshed
  *************************************************************/
        /*Removed Refresh paymentYear step to keep it outside the wrapper 65862*/


        SET @I = 1

        IF @Debug = 1
            BEGIN
                EXEC [dbo].[PerfLogMonitor] '003' ,
                                            @ProcessNameIn ,
                                            @ET ,
                                            @MasterET ,
                                            @ET OUT ,
                                            0 ,
                                            0
            END



        WHILE ( @I <= @ID )
            BEGIN

                --DECLARE @Payment_Year VARCHAR(4)
                --DECLARE @MYU VARCHAR(1)

                SELECT @Payment_Year = [Payment_Year] ,
                       @MYU = [MYU]
                FROM   [#EstRecevRefreshPY]
                WHERE  [ID] = @I

			
    INSERT INTO [rev].[EstRecvRskadjActivity]
    (
        [Part_C_D_Flag],
        [Process],
		[Payment_Year], 
		[MYU],
        [BDate],
        [EDate],
        [AdditionalRows],
        [RunBy]
    )
    SELECT [Part_C_D_Flag] = 'Part C',
           [Process] = 'EstRecevMemberDetail',
		   [Payment_Year] = @Payment_Year, 
		   [MYU]=@MYU,
           [BDate] = GETDATE(),
           [EDate] = NULL,
           [AdditionalRows] = NULL,
           [RunBy] = @UserID;

	           SET @EstRecvRskadjActivityID = SCOPE_IDENTITY();
			   SET @RowCount_OUT = 0;

               BEGIN
                    EXEC [rev].[EstRecevMemberDetail] @Payment_Year ,
                                                      @MYU,
													  @RowCount = @RowCount_OUT OUTPUT;
                    PRINT 'EstRecevMemberDetail complete'
                END


				UPDATE [m]
                SET [m].[EDate] = GETDATE(),
                    [m].[AdditionalRows] = Isnull(@RowCount_OUT,0)
                FROM [rev].[EstRecvRskadjActivity] [m]
                WHERE [m].[EstRecvRskadjActivityID]  = @EstRecvRskadjActivityID;


INSERT INTO [rev].[EstRecvRskadjActivity]
    (
        [Part_C_D_Flag],
        [Process],
		[Payment_Year], 
		[MYU],
        [BDate],
        [EDate],
        [AdditionalRows],
        [RunBy]
    )
    SELECT [Part_C_D_Flag] = 'Part C',
           [Process] = 'EstRecevDemoCalc',
		   [Payment_Year] = @Payment_Year, 
		   [MYU]=NULL,
           [BDate] = GETDATE(),
           [EDate] = NULL,
           [AdditionalRows] = NULL,
           [RunBy] = @UserID;

	           SET @EstRecvRskadjActivityID = SCOPE_IDENTITY();
			   SET @RowCount_OUT = 0;

                BEGIN
                    EXEC [rev].[EstRecevDemoCalc] @RowCount = @RowCount_OUT OUTPUT;
                    PRINT 'EstRecevDemoCalc complete'
                END

	    UPDATE [m]
                SET [m].[EDate] = GETDATE(),
                    [m].[AdditionalRows] = Isnull(@RowCount_OUT,0)
                FROM [rev].[EstRecvRskadjActivity] [m]
                WHERE [m].[EstRecvRskadjActivityID]  = @EstRecvRskadjActivityID;



INSERT INTO [rev].[EstRecvRskadjActivity]
    (
        [Part_C_D_Flag],
        [Process],
		[Payment_Year], 
		[MYU],
        [BDate],
        [EDate],
        [AdditionalRows],
        [RunBy]
    )
    SELECT [Part_C_D_Flag] = 'Part C',
           [Process] = 'EstRecevRAPSCalc',
		   [Payment_Year] = @Payment_Year, 
		   [MYU]=@MYU,
           [BDate] = GETDATE(),
           [EDate] = NULL,
           [AdditionalRows] = NULL,
           [RunBy] = @UserID;

	           SET @EstRecvRskadjActivityID = SCOPE_IDENTITY();
			   SET @RowCount_OUT = 0;

                BEGIN
                    EXEC [rev].[EstRecevRAPSCalc] @Payment_Year ,
                                                  @MYU,
												  @RowCount = @RowCount_OUT OUTPUT;
                    PRINT 'EstRecevRAPSCalc complete'
                END


	    UPDATE [m]
                SET [m].[EDate] = GETDATE(),
                    [m].[AdditionalRows] = Isnull(@RowCount_OUT,0)
                FROM [rev].[EstRecvRskadjActivity] [m]
                WHERE [m].[EstRecvRskadjActivityID]  = @EstRecvRskadjActivityID;


INSERT INTO [rev].[EstRecvRskadjActivity]
    (
        [Part_C_D_Flag],
        [Process],
		[Payment_Year], 
		[MYU],
        [BDate],
        [EDate],
        [AdditionalRows],
        [RunBy]
    )
    SELECT [Part_C_D_Flag] = 'Part C',
           [Process] = 'EstRecevEDSCalc',
		   [Payment_Year] = @Payment_Year, 
		   [MYU]=@MYU,
           [BDate] = GETDATE(),
           [EDate] = NULL,
           [AdditionalRows] = NULL,
           [RunBy] = @UserID;

	           SET @EstRecvRskadjActivityID = SCOPE_IDENTITY();
			   SET @RowCount_OUT = 0;


                BEGIN
                    EXEC [rev].[EstRecevEDSCalc] @Payment_Year ,
                                                 @MYU,
												 @RowCount = @RowCount_OUT OUTPUT;
                    PRINT 'EstRecevEDSCalc complete'
                END

				
	    UPDATE [m]
                SET [m].[EDate] = GETDATE(),
                    [m].[AdditionalRows] = Isnull(@RowCount_OUT,0)
                FROM [rev].[EstRecvRskadjActivity] [m]
                WHERE [m].[EstRecvRskadjActivityID]  = @EstRecvRskadjActivityID;



INSERT INTO [rev].[EstRecvRskadjActivity]
    (
        [Part_C_D_Flag],
        [Process],
		[Payment_Year], 
		[MYU],
        [BDate],
        [EDate],
        [AdditionalRows],
        [RunBy]
    )
    SELECT [Part_C_D_Flag] = 'Part C',
           [Process] = 'EstRecevMORCalc',
		   [Payment_Year] = @Payment_Year, 
		   [MYU]=NULL,
           [BDate] = GETDATE(),
           [EDate] = NULL,
           [AdditionalRows] = NULL,
           [RunBy] = @UserID;

	           SET @EstRecvRskadjActivityID = SCOPE_IDENTITY();
			   SET @RowCount_OUT = 0;


                BEGIN
                    EXEC [rev].[EstRecevMORCalc] @Payment_Year,
												 @RowCount = @RowCount_OUT OUTPUT;
                    PRINT 'EstRecevMORCalc complete'
                END

				
	    UPDATE [m]
                SET [m].[EDate] = GETDATE(),
                    [m].[AdditionalRows] = Isnull(@RowCount_OUT,0)
                FROM [rev].[EstRecvRskadjActivity] [m]
                WHERE [m].[EstRecvRskadjActivityID]  = @EstRecvRskadjActivityID;



INSERT INTO [rev].[EstRecvRskadjActivity]
    (
        [Part_C_D_Flag],
        [Process],
		[Payment_Year], 
		[MYU],
        [BDate],
        [EDate],
        [AdditionalRows],
        [RunBy]
    )
    SELECT [Part_C_D_Flag] = 'Part C',
           [Process] = 'EstRecevHIERINT',
		   [Payment_Year] = @Payment_Year, 
		   [MYU]=NULL,
           [BDate] = GETDATE(),
           [EDate] = NULL,
           [AdditionalRows] = NULL,
           [RunBy] = @UserID;

	           SET @EstRecvRskadjActivityID = SCOPE_IDENTITY();
			   SET @RowCount_OUT = 0;

                BEGIN
                    EXEC [rev].[EstRecevHIERINT] @RowCount = @RowCount_OUT OUTPUT;
                    PRINT 'EstRecevHIERINT complete'
                END

			
	    UPDATE [m]
                SET [m].[EDate] = GETDATE(),
                    [m].[AdditionalRows] = Isnull(@RowCount_OUT,0)
                FROM [rev].[EstRecvRskadjActivity] [m]
                WHERE [m].[EstRecvRskadjActivityID]  = @EstRecvRskadjActivityID;



INSERT INTO [rev].[EstRecvRskadjActivity]
    (
        [Part_C_D_Flag],
        [Process],
		[Payment_Year], 
		[MYU],
        [BDate],
        [EDate],
        [AdditionalRows],
        [RunBy]
    )
    SELECT [Part_C_D_Flag] = 'Part C',
           [Process] = 'EstRecevRiskScoreCalc',
		   [Payment_Year] = @Payment_Year, 
		   [MYU]=NULL,
           [BDate] = GETDATE(),
           [EDate] = NULL,
           [AdditionalRows] = NULL,
           [RunBy] = @UserID;

	           SET @EstRecvRskadjActivityID = SCOPE_IDENTITY();
			   SET @RowCount_OUT = 0;

                BEGIN
                    EXEC [rev].[EstRecevRiskScoreCalc] @Payment_Year,
													   @RowCount = @RowCount_OUT OUTPUT;	
                    PRINT 'EstRecevRiskScoreCalc complete'
                END

				  UPDATE [m]
                SET [m].[EDate] = GETDATE(),
                    [m].[AdditionalRows] = Isnull(@RowCount_OUT,0)
                FROM [rev].[EstRecvRskadjActivity] [m]
                WHERE [m].[EstRecvRskadjActivityID]  = @EstRecvRskadjActivityID;


INSERT INTO [rev].[EstRecvRskadjActivity]
    (
        [Part_C_D_Flag],
        [Process],
		[Payment_Year], 
		[MYU],
        [BDate],
        [EDate],
        [AdditionalRows],
        [RunBy]
    )
    SELECT [Part_C_D_Flag] = 'Part C',
           [Process] = 'EstRecevERCalc',
		   [Payment_Year] = @Payment_Year, 
		   [MYU]=NULL,
           [BDate] = GETDATE(),
           [EDate] = NULL,
           [AdditionalRows] = NULL,
           [RunBy] = @UserID;

	           SET @EstRecvRskadjActivityID = SCOPE_IDENTITY();
			   SET @RowCount_OUT = 0;


                BEGIN
                    EXEC [rev].[EstRecevERCalc] @Payment_Year,
												@RowCount = @RowCount_OUT OUTPUT;
                    PRINT 'EstRecevERCalc complete'
                END

            UPDATE [m]
                SET [m].[EDate] = GETDATE(),
                    [m].[AdditionalRows] = Isnull(@RowCount_OUT,0)
                FROM [rev].[EstRecvRskadjActivity] [m]
                WHERE [m].[EstRecvRskadjActivityID]  = @EstRecvRskadjActivityID;



				BEGIN 
				  EXEC [rev].[EstRecevHistoryLoadPartC] @Payment_Year ,
                                                        @MYU
				   PRINT 'EstRecevHistoryLoadPartC complete'
                 END




                IF @Debug = 1
                    BEGIN
                        EXEC [dbo].[PerfLogMonitor] '004' ,
                                                    @ProcessNameIn ,
                                                    @ET ,
                                                    @MasterET ,
                                                    @ET OUT ,
                                                    0 ,
                                                    0
                    END
                /******PARTITION SWITCHES*/

                IF OBJECT_ID('[TEMPDB].[DBO].[#Partition]', 'U') IS NOT NULL
                    DROP TABLE [#Partition]

                CREATE TABLE [#Partition]
                    (
                        [ID] INT IDENTITY(1, 1) ,
                        [PartitionKey] INT
                    )
                INSERT INTO [#Partition]
                            SELECT DISTINCT [EstRecvPartitionKeyID]
                            FROM   [etl].[EstRecvPartitionKey]
                            WHERE  [PaymentYear] = @Payment_Year
                                   AND [MYU] = @MYU

                DECLARE @I1 INT
                DECLARE @ID1 INT = (   SELECT COUNT(DISTINCT [PartitionKey])
                                       FROM   [#Partition]
                                   )
                SET @I1 = 1
                WHILE ( @I1 <= @ID1 )
                    BEGIN



                        DECLARE @PartitionKey INT
                        SELECT @PartitionKey = [PartitionKey]
                        FROM   [#Partition]
                        WHERE  [ID] = @I1


                        IF (   (   SELECT ISNULL(MAX([populated]), '1.1.1900')
                                   FROM   [etl].[EstRecvDetailPartC]
                                   WHERE  [PARTITIONkey] = @PartitionKey
                               ) > (   SELECT ISNULL(
                                                        MAX([populated]) ,
                                                        '1.1.1900'
                                                    )
                                       FROM   [rev].[EstRecvDetailPartC]
                                       WHERE  [PartitionKey] = @PartitionKey
                                   )
                               OR  (   SELECT ISNULL(
                                                        MAX([populated]) ,
                                                        '1.1.1900'
                                                    )
                                       FROM   [etl].[RiskScoreFactorsPartC]
                                       WHERE  [PARTITIONkey] = @PartitionKey
                                   ) > (   SELECT ISNULL(
                                                            MAX([populated]) ,
                                                            '1.1.1900'
                                                        )
                                           FROM   [rev].[RiskScoreFactorsPartC]
                                           WHERE  [PartitionKey] = @PartitionKey
                                       )
                               OR  (   SELECT ISNULL(
                                                        MAX([populated]) ,
                                                        '1.1.1900'
                                                    )
                                       FROM   [etl].[RiskScoresPartC]
                                       WHERE  [PARTITIONkey] = @PartitionKey
                                   ) > (   SELECT ISNULL(
                                                            MAX([populated]) ,
                                                            '1.1.1900'
                                                        )
                                           FROM   [rev].[RiskScoresPartC]
                                           WHERE  [PartitionKey] = @PartitionKey
                                       )
                           )
                            BEGIN
                                PRINT 'Run EstRecvDetailPartC'
                                IF EXISTS (   SELECT 1
                                              FROM   [etl].[EstRecvDetailPartC]
                                              WHERE  [PartitionKey] = @PartitionKey
                                          )
                                    BEGIN
                                        TRUNCATE TABLE [out].[EstRecvDetailPartC]
                                        ALTER TABLE [rev].[EstRecvDetailPartC] SWITCH PARTITION @PartitionKey TO [out].[EstRecvDetailPartC] PARTITION @PartitionKey
                                        ALTER TABLE [etl].[EstRecvDetailPartC] SWITCH PARTITION @PartitionKey TO [rev].[EstRecvDetailPartC] PARTITION @PartitionKey
                                    END
                                ELSE
                                    BEGIN
                                        PRINT ' No New data in EstRecvDetailPartC'
                                    END


                                PRINT 'Run RiskScoreFactorsPartC'
                                IF EXISTS (   SELECT 1
                                              FROM   [etl].[RiskScoreFactorsPartC]
                                              WHERE  [PartitionKey] = @PartitionKey
                                          )
                                    BEGIN
                                        TRUNCATE TABLE [out].[RiskScoreFactorsPartC]
                                        ALTER TABLE [rev].[RiskScoreFactorsPartC] SWITCH PARTITION @PartitionKey TO [out].[RiskScoreFactorsPartC] PARTITION @PartitionKey
                                        ALTER TABLE [etl].[RiskScoreFactorsPartC] SWITCH PARTITION @PartitionKey TO [rev].[RiskScoreFactorsPartC] PARTITION @PartitionKey
                                    END
                                ELSE
                                    BEGIN
                                        PRINT ' No New data in RiskScoreFactorsPartC'
                                    END



                                PRINT 'Run RiskScoresPartC'
                                IF EXISTS (   SELECT 1
                                              FROM   [etl].[RiskScoresPartC]
                                              WHERE  [PartitionKey] = @PartitionKey
                                          )
                                    BEGIN
                                        TRUNCATE TABLE [out].[RiskScoresPartC]
                                        ALTER TABLE [rev].[RiskScoresPartC] SWITCH PARTITION @PartitionKey TO [out].[RiskScoresPartC] PARTITION @PartitionKey
                                        ALTER TABLE [etl].[RiskScoresPartC] SWITCH PARTITION @PartitionKey TO [rev].[RiskScoresPartC] PARTITION @PartitionKey
                                    END
                                ELSE
                                    BEGIN
                                        PRINT ' No New data in RiskScoresPartC'
                                    END


                            END

                        SET @I1 = @I1 + 1
                    END

                SET @I = @I + 1
            END
    END




    IF @Debug = 1
        BEGIN
            EXEC [dbo].[PerfLogMonitor] '005' ,
                                        @ProcessNameIn ,
                                        @ET ,
                                        @MasterET ,
                                        @ET OUT ,
                                        0 ,
                                        1
        END
    /* Run the wrapper to load the summary tables for 65862*/
    BEGIN
        EXEC rev.WrapperLoadEstRecvSummaryPartC;
    END