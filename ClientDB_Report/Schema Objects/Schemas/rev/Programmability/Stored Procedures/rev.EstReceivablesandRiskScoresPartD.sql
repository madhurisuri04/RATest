Create PROCEDURE [rev].[EstReceivablesandRiskScoresPartD]
    (
        @Debug BIT = 0
    )
AS /************************************************************************        
* Name			:	[rev.EstReceivablesandRiskScoresPartD]     				*                                                     
* Type 			:	Stored Procedure									*                
* Author       	:	Madhuri Suri     									*
* Date          :	12/10/2017											*	
* Ticket        :   
* Version		:        												*
* Description	:	Estimated Receivables and Risk Scores for Part D                                              *

***************************************************************************/
    /**********************************************************************************************************************************
Ticket   Date          Author           Descrition          
69577    3/19/2018    D. Waddell        Change to iterate through identity column instead of Payment Year
75807    5/1/2019     Madhuri Suri      Part D Corrections for ER 2.0 
76933    10/14/2019   Madhuri Suri      Automate Summary ER Wrapper and History
RRI-229/79617 9/22/2020 Anand           Used log table logic   
*************************************************************************************************************************************/
    --exec rev.EstReceivablesandRiskScoresPartD

    BEGIN
        SET NOCOUNT ON

        SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
		Declare @RowCount_OUT INT;
		Declare @UserID VARCHAR(128) = SYSTEM_USER;
		Declare @EstRecvRskadjActivityID INT;

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



  /***********************************************************
  Execute Deletes before running ER Procs
  *************************************************************/
   
		Begin

        EXEC rev.EstRecvPartDDeleteHCC; 

		End

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
         
           /***********************************************************
  Execute refresh Payment year Proc to get PY to be refreshed
  *************************************************************/
      
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
                EXEC [dbo].[PerfLogMonitor] '002' ,
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
                EXEC [dbo].[PerfLogMonitor] '003
			1'  ,
@ProcessNameIn  ,
@ET             ,
@MasterET       ,
@ET OUT         ,
0               ,
0
            END


        DECLARE @I INT
        DECLARE @ID INT = (   SELECT COUNT([ID]) --TFS 69577  modified by D. Waddell 03/18/18
                              FROM   [#EstRecevRefreshPY]
                          )


        SET @I = 1

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


        WHILE ( @I <= @ID )
            BEGIN

                DECLARE @Payment_Year VARCHAR(4)
                DECLARE @MYU VARCHAR(1)

                SELECT @Payment_Year = Payment_Year ,
                       @MYU = MYU
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
    SELECT [Part_C_D_Flag] = 'Part D',
           [Process] = 'EstRecevMemberDetailPartD',
		   [Payment_Year] = @Payment_Year, 
		   [MYU]=@MYU,
           [BDate] = GETDATE(),
           [EDate] = NULL,
           [AdditionalRows] = NULL,
           [RunBy] = @UserID;

		    SET @EstRecvRskadjActivityID = SCOPE_IDENTITY();
			SET @RowCount_OUT = 0;

                BEGIN
                    EXEC [rev].[EstRecevMemberDetailPartD] @Payment_Year ,
                                                           @MYU,
													       @RowCount = @RowCount_OUT OUTPUT;
                    PRINT 'EstRecevMemberDetailPartD complete'
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
    SELECT [Part_C_D_Flag] = 'Part D',
           [Process] = 'EstRecevDemoCalcPartD',
		   [Payment_Year] = @Payment_Year, 
		   [MYU]=NULL,
           [BDate] = GETDATE(),
           [EDate] = NULL,
           [AdditionalRows] = NULL,
           [RunBy] = @UserID;

		    SET @EstRecvRskadjActivityID = SCOPE_IDENTITY();
			SET @RowCount_OUT = 0;

                BEGIN
                    EXEC [rev].[EstRecevDemoCalcPartD] @RowCount = @RowCount_OUT OUTPUT;
                    PRINT 'EstRecevDemoCalcPartD complete'
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
    SELECT [Part_C_D_Flag] = 'Part D',
           [Process] = 'EstRecevRAPSCalcPartD',
		   [Payment_Year] = @Payment_Year, 
		   [MYU]=@MYU,
           [BDate] = GETDATE(),
           [EDate] = NULL,
           [AdditionalRows] = NULL,
           [RunBy] = @UserID;

		    SET @EstRecvRskadjActivityID = SCOPE_IDENTITY();
			SET @RowCount_OUT = 0;

                BEGIN
                    EXEC [rev].[EstRecevRAPSCalcPartD] @Payment_Year ,
                                                       @MYU,
													   @RowCount = @RowCount_OUT OUTPUT;
                    PRINT 'EstRecevRAPSCalcPartD complete'
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
    SELECT [Part_C_D_Flag] = 'Part D',
           [Process] = 'EstRecevEDSCalcPartD',
		   [Payment_Year] = @Payment_Year, 
		   [MYU]=@MYU,
           [BDate] = GETDATE(),
           [EDate] = NULL,
           [AdditionalRows] = NULL,
           [RunBy] = @UserID;

		    SET @EstRecvRskadjActivityID = SCOPE_IDENTITY();
			SET @RowCount_OUT = 0;
			
                BEGIN
                    EXEC [rev].[EstRecevEDSCalcPartD] @Payment_Year ,
                                                 @MYU,
												 @RowCount = @RowCount_OUT OUTPUT;
                    PRINT 'EstRecevEDSCalcPartD complete'
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
    SELECT [Part_C_D_Flag] = 'Part D',
           [Process] = 'EstRecevMORCalcPartD',
		   [Payment_Year] = @Payment_Year, 
		   [MYU]=NULL,
           [BDate] = GETDATE(),
           [EDate] = NULL,
           [AdditionalRows] = NULL,
           [RunBy] = @UserID;

		    SET @EstRecvRskadjActivityID = SCOPE_IDENTITY();
			SET @RowCount_OUT = 0;

                BEGIN
                    EXEC [rev].[EstRecevMORCalcPartD] @Payment_Year,@RowCount = @RowCount_OUT OUTPUT;
                    PRINT 'EstRecevMORCalcPartD complete'
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
    SELECT [Part_C_D_Flag] = 'Part D',
           [Process] = 'EstRecevDELHIERPartD',
		   [Payment_Year] = @Payment_Year, 
		   [MYU]=NULL,
           [BDate] = GETDATE(),
           [EDate] = NULL,
           [AdditionalRows] = NULL,
           [RunBy] = @UserID;

		    SET @EstRecvRskadjActivityID = SCOPE_IDENTITY();
			SET @RowCount_OUT = 0;

                BEGIN
                    EXEC [rev].[EstRecevDELHIERPartD] @RowCount = @RowCount_OUT OUTPUT;
                    PRINT 'EstRecevDELHIERPartD complete'
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
    SELECT [Part_C_D_Flag] = 'Part D',
           [Process] = 'EstRecevRiskScoreCalcPartD',
		   [Payment_Year] = @Payment_Year, 
		   [MYU]=NULL,
           [BDate] = GETDATE(),
           [EDate] = NULL,
           [AdditionalRows] = NULL,
           [RunBy] = @UserID;

		    SET @EstRecvRskadjActivityID = SCOPE_IDENTITY();
			SET @RowCount_OUT = 0;

                BEGIN
                    EXEC [rev].[EstRecevRiskScoreCalcPartD] @Payment_Year,@RowCount = @RowCount_OUT OUTPUT;
                    PRINT 'EstRecevRiskScoreCalcPartD complete'
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
    SELECT [Part_C_D_Flag] = 'Part D',
           [Process] = 'EstRecevERCalcPartD',
		   [Payment_Year] = @Payment_Year, 
		   [MYU]=NULL,
           [BDate] = GETDATE(),
           [EDate] = NULL,
           [AdditionalRows] = NULL,
           [RunBy] = @UserID;

		    SET @EstRecvRskadjActivityID = SCOPE_IDENTITY();
			SET @RowCount_OUT = 0;

                BEGIN
                    EXEC [rev].[EstRecevERCalcPartD] @Payment_Year,@RowCount = @RowCount_OUT OUTPUT;
                    PRINT 'EstRecevERCalcPartD complete'
                END

			UPDATE [m]
                SET [m].[EDate] = GETDATE(),
                    [m].[AdditionalRows] = Isnull(@RowCount_OUT,0)
                FROM [rev].[EstRecvRskadjActivity] [m]
                WHERE [m].[EstRecvRskadjActivityID]  = @EstRecvRskadjActivityID;



				BEGIN 
				  EXEC [rev].[EstRecevHistoryLoadPartD] @Payment_Year ,
                                                        @MYU
				   PRINT 'EstRecevHistoryLoadPartD complete'
                 END

                /******PARTITION SWITCHES*/

                IF OBJECT_ID('[TEMPDB].[DBO].[#Partition]', 'U') IS NOT NULL
                    DROP TABLE [dbo].[#Partition]

                CREATE TABLE [dbo].[#Partition]
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


                        IF (   (   SELECT ISNULL(MAX([LoadDate]), '1.1.1900')
                                   FROM   [etl].[EstRecvDetailPartD]
                                   WHERE  [PARTITIONkey] = @PartitionKey
                               ) > (   SELECT ISNULL(
                                                        MAX([LoadDate]) ,
                                                        '1.1.1900'
                                                    )
                                       FROM   [rev].[EstRecvDetailPartD]
                                       WHERE  [PartitionKey] = @PartitionKey
                                   )
                               OR  (   SELECT ISNULL(
                                                        MAX([LoadDate]) ,
                                                        '1.1.1900'
                                                    )
                                       FROM   [etl].[RiskScoreFactorsPartD]
                                       WHERE  [PARTITIONkey] = @PartitionKey
                                   ) > (   SELECT ISNULL(
                                                            MAX([Loaddate]) ,
                                                            '1.1.1900'
                                                        )
                                           FROM   [rev].[RiskScoreFactorsPartD]
                                           WHERE  [PartitionKey] = @PartitionKey
                                       )
                               OR  (   SELECT ISNULL(
                                                        MAX(LoadDate) ,
                                                        '1.1.1900'
                                                    )
                                       FROM   [etl].[RiskScoresPartD]
                                       WHERE  [PARTITIONkey] = @PartitionKey
                                   ) > (   SELECT ISNULL(
                                                            MAX([LoadDate]) ,
                                                            '1.1.1900'
                                                        )
                                           FROM   [rev].[RiskScoresPartD]
                                           WHERE  [PartitionKey] = @PartitionKey
                                       )
                           )
                            BEGIN
                                PRINT 'Run EstRecvDetailPartD'
                                IF EXISTS (   SELECT 1
                                              FROM   [etl].[EstRecvDetailPartD]
                                              WHERE  [PartitionKey] = @PartitionKey
                                          )
                                    BEGIN
                                        TRUNCATE TABLE [out].[EstRecvDetailPartD]
                                        ALTER TABLE [rev].[EstRecvDetailPartD] SWITCH PARTITION @PartitionKey TO [out].[EstRecvDetailPartD] PARTITION @PartitionKey
                                        ALTER TABLE etl.[EstRecvDetailPartD] SWITCH PARTITION @PartitionKey TO rev.[EstRecvDetailPartD] PARTITION @PartitionKey
                                    END
                                ELSE
                                    BEGIN
                                        PRINT ' No New data in EstRecvDetailPartD'
                                    END


                                PRINT 'Run RiskScoreFactorsPartD'
                                IF EXISTS (   SELECT 1
                                              FROM   [etl].[RiskScoreFactorsPartD]
                                              WHERE  [PartitionKey] = @PartitionKey
                                          )
                                    BEGIN
                                        TRUNCATE TABLE [out].[RiskScoreFactorsPartD]
                                        ALTER TABLE [rev].[RiskScoreFactorsPartD] SWITCH PARTITION @PartitionKey TO [out].[RiskScoreFactorsPartD] PARTITION @PartitionKey
                                        ALTER TABLE [etl].[RiskScoreFactorsPartD] SWITCH PARTITION @PartitionKey TO [rev].[RiskScoreFactorsPartD] PARTITION @PartitionKey
                                    END
                                ELSE
                                    BEGIN
                                        PRINT ' No New data in RiskScoreFactorsPartD'
                                    END



                                PRINT 'Run RiskScoresPartD'
                                IF EXISTS (   SELECT 1
                                              FROM   [etl].[RiskScoresPartD]
                                              WHERE  [PartitionKey] = @PartitionKey
                                          )
                                    BEGIN
                                        TRUNCATE TABLE [out].[RiskScoresPartD]
                                        ALTER TABLE [rev].[RiskScoresPartD] SWITCH PARTITION @PartitionKey TO [out].[RiskScoresPartD] PARTITION @PartitionKey
                                        ALTER TABLE [etl].[RiskScoresPartD] SWITCH PARTITION @PartitionKey TO [rev].[RiskScoresPartD] PARTITION @PartitionKey
                                    END
                                ELSE
                                    BEGIN
                                        PRINT ' No New data in RiskScoresPartD'
                                    END


                            END

                        SET @I1 = @I1 + 1
                    END

                SET @I = @I + 1
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
  /* Run the wrapper to load the summary tables */
    BEGIN
        EXEC rev.WrapperLoadEstRecvSummaryPartD
    END

    END