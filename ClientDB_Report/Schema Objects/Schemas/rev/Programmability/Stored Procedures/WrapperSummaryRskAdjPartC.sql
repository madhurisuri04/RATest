CREATE PROCEDURE [rev].[WrapperSummaryRskAdjPartC] @Debug BIT = 0
AS
/************************************************************************************************************
Name			:	[rev].[WrapperSummaryRskAdjPartC]                   	    				
Type 			:	Stored Procedure																
Author       	:   Madhuri Suri    																
Date			:	2/26/2018																	
Version			:																				
Description		:	Wrapper procedure invokes the Summary PartC          						
																								
Version History :																					
=================																					
Author				Date		Version#    TFS Ticket#		Description								
-----------------	----------  --------    -----------		------------							
D. Waddell          6/07/2018	1.1			71385           Add Activity Log Entry called "Boot Up Summary Process". (Section 001,005)
Rakshit Lall		9/18/2018	1.2			73164			Added code to run the [rev].[spr_Summary_RskAdj_EDS_MOR_Combined] SP
D.Waddell			5/3/2019	1.3			75914 (RE-4080) Fix summary log time (EDate)
D.Waddell			6/17/2019   1.4         76216 (RE-5461) Fix summary log time (BegDate)
Anand				2019-07-06  1.5			RE - 5112 Added EDS Src Flag Part
Madhuri Suri        2018-09-24    2.0         76879           Summary 2.5 Changes  
D.Waddell           9/30/2019   2.1         76913 (RE-6557) Remove all reference to update statistics in Summary Stored Procedures 
Madhuri Suri		2021-01-21  2.2         RRI-290/80000   Remove EDS Src Reference/Store Proc     
	*************************************************************************************************************/
BEGIN

    DECLARE @ET DATETIME,
            @MasterET DATETIME,
            @ProcessNameIn VARCHAR(128),
            @RowCount_OUT INT = 0,
            @AltHICN_RowCount INT = 0,
            @MMR_RowCount INT = 0,
            @MOR_RowCount INT = 0,
            @RAPS_RowCount INT = 0,
            @EDS_RowCount INT = 0,
            @Curr_DB VARCHAR(128) = NULL,
            @Clnt_DB VARCHAR(128) = NULL,
            @DeleteBatchAltHICN INT,
            @DeleteBatchMMR INT,
            @DeleteBatchMOR INT,
            @DeleteBatchRAPS_Preliminary INT,
            @DeleteBatchRAPS INT,
            @DeleteBatchRAPS_MOR_Combined INT,
            --@DeleteBatchEDS_Source INT, -- RE - 5112
            @DeleteBatchEDS_Preliminary INT,
            @DeleteBatchEDS INT,
            @Mode TINYINT,
            @BBusinessHours TINYINT,
            @EBusinessHours TINYINT,
            @Today DATETIME = GETDATE(),
            @UserID VARCHAR(128) = SYSTEM_USER;
    DECLARE @RefreshDate DATETIME; -- Summary 2.5  

    IF @Debug = 1
    BEGIN
        EXEC [dbo].[PerfLogMonitor] @Section = '000',
                                    @ProcessName = @ProcessNameIn,
                                    @ET = @ET,
                                    @MasterET = @MasterET,
                                    @ET_Out = @ET OUT,
                                    @TableOutput = 0,
                                    @End = 0;
    END;


    /*B Initialize Activity Logging */
    DECLARE @tbl_Summary_RskAdj_ActivityIdMain INT =
            (
                SELECT MAX([GroupingId]) FROM [rev].[tbl_Summary_RskAdj_Activity]
            );
    DECLARE @tbl_Summary_RskAdj_ActivityIdSecondary INT;

    INSERT INTO [rev].[tbl_Summary_RskAdj_Activity]
    (
        [GroupingId],
        [Process],
        [BDate],
        [EDate],
        [AdditionalRows],
        [RunBy]
    )
    SELECT [GroupingId] = NULL,
           [Process] = 'Part C Summary Process',
           [BDate] = @Today,
           [EDate] = NULL,
           [AdditionalRows] = NULL,
           [RunBy] = @UserID;

    SET @tbl_Summary_RskAdj_ActivityIdMain = SCOPE_IDENTITY();

    UPDATE [m]
    SET [m].[GroupingId] = @tbl_Summary_RskAdj_ActivityIdMain
    FROM [rev].[tbl_Summary_RskAdj_Activity] [m]
    WHERE [m].[tbl_Summary_RskAdj_ActivityId] = @tbl_Summary_RskAdj_ActivityIdMain;

    /*E Initialize Activity Logging */

    IF @Debug = 1
    BEGIN
        EXEC [dbo].[PerfLogMonitor] @Section = '001',
                                    @ProcessName = @ProcessNameIn,
                                    @ET = @ET,
                                    @MasterET = @MasterET,
                                    @ET_Out = @ET OUT,
                                    @TableOutput = 0,
                                    @End = 0;
    END;



    SELECT TOP 1
           @Mode = CAST([a1].[Value] AS TINYINT)
    FROM [rev].[tbl_Summary_RskAdj_Config] [a1] WITH (NOLOCK)
    WHERE [a1].[Variable] = '@Mode';

    SELECT TOP 1
           @BBusinessHours = CAST([a1].[Value] AS TINYINT)
    FROM [rev].[tbl_Summary_RskAdj_Config] [a1] WITH (NOLOCK)
    WHERE [a1].[Variable] = '@BBusinessHours';

    SELECT TOP 1
           @EBusinessHours = CAST([a1].[Value] AS TINYINT)
    FROM [rev].[tbl_Summary_RskAdj_Config] [a1] WITH (NOLOCK)
    WHERE [a1].[Variable] = '@EBusinessHours';


    /* Set Defaults if configuration values are not available */

    SET @Mode = ISNULL(@Mode, 0);
    SET @BBusinessHours = ISNULL(@BBusinessHours, 7);
    SET @EBusinessHours = ISNULL(@EBusinessHours, 20);

    SET @tbl_Summary_RskAdj_ActivityIdMain =
    (
        SELECT MAX([GroupingId]) FROM [rev].[tbl_Summary_RskAdj_Activity]
    );


    SET @Curr_DB =
    (
        SELECT [Current Database] = DB_NAME()
    );
    SET @Clnt_DB = SUBSTRING(@Curr_DB, 0, CHARINDEX('_Report', @Curr_DB));


    DECLARE @MOR_FLAG BIT =
            (
                SELECT [Runflag]
                FROM [rev].[SummaryProcessRunFlag]
                WHERE [Process] = 'MOR'
            );

    DECLARE @RAPS_FLAG BIT =
            (
                SELECT [Runflag]
                FROM [rev].[SummaryProcessRunFlag]
                WHERE [Process] = 'RAPS'
            );

    DECLARE @EDS_FLAG BIT =
            (
                SELECT [Runflag]
                FROM [rev].[SummaryProcessRunFlag]
                WHERE [Process] = 'EDS'
            );

    ----RE - 5112
    --DECLARE @EDSSrc_FLAG BIT =
    --        (
    --            SELECT [Runflag]
    --            FROM [rev].[SummaryProcessRunFlag]
    --            WHERE [Process] = 'EDSSrc'
    --        );


    IF @Mode IN ( 0, 1 )
    BEGIN
        /*B  */
        IF @MOR_FLAG = 0
           AND @RAPS_FLAG = 0
           AND @EDS_FLAG = 0
           --AND @EDSSrc_FLAG = 0 --RE - 5112

        BEGIN

            GOTO SkipEXECspr_Summary_RskAdj_AltHICN_MMR_MOR_RAPS;

        END;
        ELSE
        BEGIN

            /*Update Statistics for MOR RAPS and EDS Before */
            --         update statistics [rev].[tbl_Summary_RskAdj_MOR]

            --         update statistics [rev].[tbl_Summary_RskAdj_RAPS_Preliminary]

            --update statistics [rev].[tbl_Summary_RskAdj_RAPS]

            --         update statistics [rev].[tbl_Summary_RskAdj_EDS_Preliminary]

            --         update statistics [rev].[tbl_Summary_RskAdj_EDS]

            --         update statistics [rev].[tbl_Summary_RskAdj_RAPS_MOR_Combined]

            --         update statistics [rev].[tbl_Summary_RskAdj_EDS_MOR_Combined]

            IF @MOR_FLAG = 1
            BEGIN
                IF @Debug = 1
                BEGIN
                    EXEC [dbo].[PerfLogMonitor] @Section = '002',
                                                @ProcessName = @ProcessNameIn,
                                                @ET = @ET,
                                                @MasterET = @MasterET,
                                                @ET_Out = @ET OUT,
                                                @TableOutput = 0,
                                                @End = 0;
                END;

                SET @RowCount_OUT = NULL;
                SET @Today = GETDATE();

                INSERT INTO [rev].[tbl_Summary_RskAdj_Activity]
                (
                    [GroupingId],
                    [Process],
                    [BDate],
                    [EDate],
                    [AdditionalRows],
                    [RunBy]
                )
                SELECT [GroupingId] = @tbl_Summary_RskAdj_ActivityIdMain,
                       [Process] = '[rev].[spr_Summary_RskAdj_MOR]',
                       [BDate] = @Today,
                       [EDate] = NULL,
                       [AdditionalRows] = 0,
                       [RunBy] = @UserID;

                SET @tbl_Summary_RskAdj_ActivityIdSecondary = SCOPE_IDENTITY();

                EXEC [rev].[spr_Summary_RskAdj_MOR] @LoadDateTime = @ET,
                                                    @DeleteBatch = @DeleteBatchMOR,
                                                    @RowCount = @RowCount_OUT OUTPUT,
                                                    @Debug = 0;

                SET @MOR_RowCount = @RowCount_OUT;

                SET @RefreshDate = GETDATE();
                UPDATE [m]
                SET [m].[EDate] = @RefreshDate,
                    [m].[AdditionalRows] = @MOR_RowCount
                FROM [rev].[tbl_Summary_RskAdj_Activity] [m]
                WHERE [m].[tbl_Summary_RskAdj_ActivityId] = @tbl_Summary_RskAdj_ActivityIdSecondary;

                UPDATE [m]
                SET [m].[LastRefreshDate] = @RefreshDate
                FROM [rev].[SummaryProcessRunFlag] [m]
                WHERE [m].[Process] = 'MOR'; -- Summary 2.5

                --update [m]
                --set [m].[EDate] = getdate() --RE 4080
                --  , [m].[AdditionalRows] = @MOR_RowCount
                --from [rev].[tbl_Summary_RskAdj_Activity] [m]
                --where [m].[tbl_Summary_RskAdj_ActivityId] = @tbl_Summary_RskAdj_ActivityIdSecondary

                SET @tbl_Summary_RskAdj_ActivityIdSecondary = NULL;

                IF @Debug = 1
                BEGIN
                    SELECT [spr_Summary_RskAdj_MOR] = @RowCount_OUT;
                END;

                IF @Debug = 1
                BEGIN
                    EXEC [dbo].[PerfLogMonitor] @Section = '003',
                                                @ProcessName = @ProcessNameIn,
                                                @ET = @ET,
                                                @MasterET = @MasterET,
                                                @ET_Out = @ET OUT,
                                                @TableOutput = 0,
                                                @End = 0;
                END;

            END;



            /*****************************************************************************************************************************************************************************************/
            /* Step 04 Formally [rev].[spr_Summary_RskAdj_RAPS] Uses [rev].[spr_Summary_RskAdj_RefreshPY], [rev].[tbl_Summary_RskAdj_AltHICN] and [rev].[tbl_Summary_RskAdj_MMR]                    */
            /* Populates [rev].[tbl_Summary_RskAdj_RAPS_Preliminary]                                                                                                                                */
            /***************************************************************************************************************************************************************************************/
            IF @RAPS_FLAG = 1
            BEGIN
                IF @Debug = 1
                BEGIN
                    EXEC [dbo].[PerfLogMonitor] @Section = '004',
                                                @ProcessName = @ProcessNameIn,
                                                @ET = @ET,
                                                @MasterET = @MasterET,
                                                @ET_Out = @ET OUT,
                                                @TableOutput = 0,
                                                @End = 0;
                END;

                SET @RowCount_OUT = NULL;
                SET @Today = GETDATE();
                INSERT INTO [rev].[tbl_Summary_RskAdj_Activity]
                (
                    [GroupingId],
                    [Process],
                    [BDate],
                    [EDate],
                    [AdditionalRows],
                    [RunBy]
                )
                SELECT [GroupingId] = @tbl_Summary_RskAdj_ActivityIdMain,
                       [Process] = '[rev].[spr_Summary_RskAdj_RAPS_Preliminary]',
                       [BDate] = @Today,
                       [EDate] = NULL,
                       [AdditionalRows] = NULL,
                       [RunBy] = @UserID;

                SET @tbl_Summary_RskAdj_ActivityIdSecondary = SCOPE_IDENTITY();

                SET @RowCount_OUT = 0;

                EXEC [rev].[spr_Summary_RskAdj_RAPS_Preliminary] @FullRefresh = 0,
                                                                 @YearRefresh = NULL,
                                                                 @LoadDateTime = @ET,
                                                                 @DeleteBatch = @DeleteBatchRAPS_Preliminary,
                                                                 @RowCount = @RowCount_OUT OUTPUT,
                                                                 @Debug = 0;

                SET @RAPS_RowCount = @RowCount_OUT;

                SET @RefreshDate = GETDATE();
                UPDATE [m]
                SET [m].[EDate] = @RefreshDate,
                    [m].[AdditionalRows] = @RAPS_RowCount
                FROM [rev].[tbl_Summary_RskAdj_Activity] [m]
                WHERE [m].[tbl_Summary_RskAdj_ActivityId] = @tbl_Summary_RskAdj_ActivityIdSecondary;

                --update [m]
                --set [m].[EDate] = getdate() --RE 4080
                --  , [m].[AdditionalRows] = @RowCount_OUT
                --from [rev].[tbl_Summary_RskAdj_Activity] [m]
                --where [m].[tbl_Summary_RskAdj_ActivityId] = @tbl_Summary_RskAdj_ActivityIdSecondary

                SET @tbl_Summary_RskAdj_ActivityIdSecondary = NULL;

                IF @Debug = 1
                BEGIN
                    EXEC [dbo].[PerfLogMonitor] @Section = '005',
                                                @ProcessName = @ProcessNameIn,
                                                @ET = @ET,
                                                @MasterET = @MasterET,
                                                @ET_Out = @ET OUT,
                                                @TableOutput = 0,
                                                @End = 0;
                END;

                IF @Debug = 1
                BEGIN
                    SELECT [spr_Summary_RskAdj_RAPS_Preliminary] = @RowCount_OUT;

                    EXEC [dbo].[PerfLogMonitor] @Section = '006',
                                                @ProcessName = @ProcessNameIn,
                                                @ET = @ET,
                                                @MasterET = @MasterET,
                                                @ET_Out = @ET OUT,
                                                @TableOutput = 0,
                                                @End = 0;
                END;
                SET @Today = GETDATE();
                INSERT INTO [rev].[tbl_Summary_RskAdj_Activity]
                (
                    [GroupingId],
                    [Process],
                    [BDate],
                    [EDate],
                    [AdditionalRows],
                    [RunBy]
                )
                SELECT [GroupingId] = @tbl_Summary_RskAdj_ActivityIdMain,
                       [Process] = '[rev].[spr_Summary_RskAdj_RAPS]',
                       [BDate] = @Today,
                       [EDate] = NULL,
                       [AdditionalRows] = NULL,
                       [RunBy] = @UserID;

                SET @tbl_Summary_RskAdj_ActivityIdSecondary = SCOPE_IDENTITY();

                SET @RowCount_OUT = 0;

                EXEC [rev].[spr_Summary_RskAdj_RAPS] @LoadDateTime = @ET,
                                                     @DeleteBatch = @DeleteBatchRAPS,
                                                     @RowCount = @RowCount_OUT OUTPUT,
                                                     @Debug = 0;

                -- set @RAPS_RowCount = @RowCount_OUT

                SET @RefreshDate = GETDATE();
                UPDATE [m]
                SET [m].[EDate] = @RefreshDate,
                    [m].[AdditionalRows] = @RowCount_OUT
                FROM [rev].[tbl_Summary_RskAdj_Activity] [m]
                WHERE [m].[tbl_Summary_RskAdj_ActivityId] = @tbl_Summary_RskAdj_ActivityIdSecondary;



                --update [m]
                --set [m].[EDate] = getdate() --RE 5461
                --  , [m].[AdditionalRows] = @RowCount_OUT
                --from [rev].[tbl_Summary_RskAdj_Activity] [m]
                --where [m].[tbl_Summary_RskAdj_ActivityId] = @tbl_Summary_RskAdj_ActivityIdSecondary

                SET @tbl_Summary_RskAdj_ActivityIdSecondary = NULL;

                IF @Debug = 1
                BEGIN
                    SELECT [spr_Summary_RskAdj_RAPS] = @RowCount_OUT;

                    EXEC [dbo].[PerfLogMonitor] @Section = '007',
                                                @ProcessName = @ProcessNameIn,
                                                @ET = @ET,
                                                @MasterET = @MasterET,
                                                @ET_Out = @ET OUT,
                                                @TableOutput = 0,
                                                @End = 0;
                END;


                /************************************************************************************************************************************************************************************************/
                /* Step 05 Formally [rev].[spr_Summary_RskAdj_RAPS_MOR_Combined] Uses [rev].[spr_Summary_RskAdj_RefreshPY], [rev].[tbl_Summary_RskAdj_RAPS_Preliminary] and [rev].[tbl_Summary_RskAdj_MMR]      */
                /* Populates  [rev].[tbl_Intermediate_RAPS], [rev].[tbl_Intermediate_RAPS_INT], [rev].[tbl_Intermediate_RAPS_INTRank] and [rev].[tbl_Summary_RskAdj_RAPS]                                       */
                /**********************************************************************************************************************************************************************************************	*/
                SET @Today = GETDATE();
                INSERT INTO [rev].[tbl_Summary_RskAdj_Activity]
                (
                    [GroupingId],
                    [Process],
                    [BDate],
                    [EDate],
                    [AdditionalRows],
                    [RunBy]
                )
                SELECT [GroupingId] = @tbl_Summary_RskAdj_ActivityIdMain,
                       [Process] = '[rev].[spr_Summary_RskAdj_RAPS_MOR_Combined]',
                       [BDate] = @Today,
                       [EDate] = NULL,
                       [AdditionalRows] = NULL,
                       [RunBy] = @UserID;

                SET @tbl_Summary_RskAdj_ActivityIdSecondary = SCOPE_IDENTITY();

                SET @RowCount_OUT = 0;

                EXEC [rev].[spr_Summary_RskAdj_RAPS_MOR_Combined] @LoadDateTime = @ET,
                                                                  @DeleteBatch = @DeleteBatchRAPS_MOR_Combined,
                                                                  @RowCount = @RowCount_OUT OUTPUT,
                                                                  @Debug = 0;


                SET @RefreshDate = GETDATE();
                UPDATE [m]
                SET [m].[EDate] = @RefreshDate,
                    [m].[AdditionalRows] = @RowCount_OUT
                FROM [rev].[tbl_Summary_RskAdj_Activity] [m]
                WHERE [m].[tbl_Summary_RskAdj_ActivityId] = @tbl_Summary_RskAdj_ActivityIdSecondary;


                UPDATE [m]
                SET [m].[LastRefreshDate] = @RefreshDate
                FROM [rev].[SummaryProcessRunFlag] [m]
                WHERE [m].[Process] = 'RAPS'; -- Summary 2.5

                --update [m]
                --set [m].[EDate] = getdate() --RE 4080
                --  , [m].[AdditionalRows] = @RowCount_OUT
                --from [rev].[tbl_Summary_RskAdj_Activity] [m]
                --where [m].[tbl_Summary_RskAdj_ActivityId] = @tbl_Summary_RskAdj_ActivityIdSecondary

                SET @tbl_Summary_RskAdj_ActivityIdSecondary = NULL;

                IF @Debug = 1
                BEGIN
                    EXEC [dbo].[PerfLogMonitor] @Section = '008',
                                                @ProcessName = @ProcessNameIn,
                                                @ET = @ET,
                                                @MasterET = @MasterET,
                                                @ET_Out = @ET OUT,
                                                @TableOutput = 0,
                                                @End = 0;
                END;
            END;


            ------------------------------------------------EDS Start--------------------------------------

            ----RE - 5112
            --IF @EDSSrc_FLAG = 1
            --BEGIN
            --    IF @Debug = 1
            --    BEGIN
            --        EXEC [dbo].[PerfLogMonitor] @Section = '009',
            --                                    @ProcessName = @ProcessNameIn,
            --                                    @ET = @ET,
            --                                    @MasterET = @MasterET,
            --                                    @ET_Out = @ET OUT,
            --                                    @TableOutput = 0,
            --                                    @End = 0;
            --    END;

            --    SET @RowCount_OUT = NULL;
            --    SET @Today = GETDATE();
            --    INSERT INTO [rev].[tbl_Summary_RskAdj_Activity]
            --    (
            --        [GroupingId],
            --        [Process],
            --        [BDate],
            --        [EDate],
            --        [AdditionalRows],
            --        [RunBy]
            --    )
            --    SELECT [GroupingId] = @tbl_Summary_RskAdj_ActivityIdMain,
            --           [Process] = '[rev].[spr_Summary_RskAdj_EDS_Source]',
            --           [BDate] = @Today,
            --           [EDate] = NULL,
            --           [AdditionalRows] = NULL,
            --           [RunBy] = @UserID;

            --    SET @tbl_Summary_RskAdj_ActivityIdSecondary = SCOPE_IDENTITY();

            --    SET @RowCount_OUT = 0;

            --    EXEC [rev].[spr_Summary_RskAdj_EDS_Source] @FullRefresh = 0,
            --                                               @YearRefresh = NULL,
            --                                               @LoadDateTime = @ET,
            --                                               @DeleteBatch = @DeleteBatchEDS_Source, -- RE - 5112
            --                                               @RowCount = @RowCount_OUT OUTPUT,
            --                                               @Debug = 0;

            --    SET @EDS_RowCount = @RowCount_OUT;

            --    SET @RefreshDate = GETDATE();
            --    UPDATE [m]
            --    SET [m].[EDate] = @RefreshDate,
            --        [m].[AdditionalRows] = @EDS_RowCount
            --    FROM [rev].[tbl_Summary_RskAdj_Activity] [m]
            --    WHERE [m].[tbl_Summary_RskAdj_ActivityId] = @tbl_Summary_RskAdj_ActivityIdSecondary;

            --    UPDATE [m]
            --    SET [m].[LastRefreshDate] = @RefreshDate
            --    FROM [rev].[SummaryProcessRunFlag] [m]
            --    WHERE [m].[Process] = 'EDSSrc'; -- Summary 2.5

            --    --update [m]
            --    --set [m].[EDate] = getdate() --RE4080
            --    --  , [m].[AdditionalRows] = @RowCount_OUT
            --    --from [rev].[tbl_Summary_RskAdj_Activity] [m]
            --    --where [m].[tbl_Summary_RskAdj_ActivityId] = @tbl_Summary_RskAdj_ActivityIdSecondary


            --    SET @tbl_Summary_RskAdj_ActivityIdSecondary = NULL;

            --    IF @Debug = 1
            --    BEGIN
            --        SELECT [spr_Summary_RskAdj_EDS] = @RowCount_OUT;

            --        EXEC [dbo].[PerfLogMonitor] @Section = '010',
            --                                    @ProcessName = @ProcessNameIn,
            --                                    @ET = @ET,
            --                                    @MasterET = @MasterET,
            --                                    @ET_Out = @ET OUT,
            --                                    @TableOutput = 0,
            --                                    @End = 0;
            --    END;

            --END;




            ----EDS START 
            IF @EDS_FLAG = 1
            BEGIN
                IF @Debug = 1
                BEGIN
                    EXEC [dbo].[PerfLogMonitor] @Section = '011',
                                                @ProcessName = @ProcessNameIn,
                                                @ET = @ET,
                                                @MasterET = @MasterET,
                                                @ET_Out = @ET OUT,
                                                @TableOutput = 0,
                                                @End = 0;
                END;

                SET @RowCount_OUT = NULL;
                SET @Today = GETDATE();
                INSERT INTO [rev].[tbl_Summary_RskAdj_Activity]
                (
                    [GroupingId],
                    [Process],
                    [BDate],
                    [EDate],
                    [AdditionalRows],
                    [RunBy]
                )
                SELECT [GroupingId] = @tbl_Summary_RskAdj_ActivityIdMain,
                       [Process] = '[rev].[spr_Summary_RskAdj_EDS_Preliminary]',
                       [BDate] = @Today,
                       [EDate] = NULL,
                       [AdditionalRows] = NULL,
                       [RunBy] = @UserID;

                SET @tbl_Summary_RskAdj_ActivityIdSecondary = SCOPE_IDENTITY();

                SET @RowCount_OUT = 0;

                EXEC [rev].[spr_Summary_RskAdj_EDS_Preliminary] @FullRefresh = 0,
                                                                @YearRefresh = NULL,
                                                                @LoadDateTime = @ET,
                                                                @DeleteBatch = @DeleteBatchEDS_Preliminary,
                                                                @RowCount = @RowCount_OUT OUTPUT,
                                                                @Debug = 0;

                SET @EDS_RowCount = @RowCount_OUT;

                --update [m]
                --set [m].[EDate] = getdate() --RE4080
                --  , [m].[AdditionalRows] = @RowCount_OUT
                --from [rev].[tbl_Summary_RskAdj_Activity] [m]
                --where [m].[tbl_Summary_RskAdj_ActivityId] = @tbl_Summary_RskAdj_ActivityIdSecondary

                SET @EDS_RowCount = @RowCount_OUT;

                SET @RefreshDate = GETDATE();
                UPDATE [m]
                SET [m].[EDate] = @RefreshDate,
                    [m].[AdditionalRows] = @EDS_RowCount
                FROM [rev].[tbl_Summary_RskAdj_Activity] [m]
                WHERE [m].[tbl_Summary_RskAdj_ActivityId] = @tbl_Summary_RskAdj_ActivityIdSecondary; -- Summary 2.5


                SET @tbl_Summary_RskAdj_ActivityIdSecondary = NULL;

                IF @Debug = 1
                BEGIN
                    EXEC [dbo].[PerfLogMonitor] @Section = '012',
                                                @ProcessName = @ProcessNameIn,
                                                @ET = @ET,
                                                @MasterET = @MasterET,
                                                @ET_Out = @ET OUT,
                                                @TableOutput = 0,
                                                @End = 0;
                END;

                IF @Debug = 1
                BEGIN
                    SELECT [spr_Summary_RskAdj_EDS_Preliminary] = @RowCount_OUT;

                    EXEC [dbo].[PerfLogMonitor] @Section = '013',
                                                @ProcessName = @ProcessNameIn,
                                                @ET = @ET,
                                                @MasterET = @MasterET,
                                                @ET_Out = @ET OUT,
                                                @TableOutput = 0,
                                                @End = 0;
                END;

                SET @Today = GETDATE();
                INSERT INTO [rev].[tbl_Summary_RskAdj_Activity]
                (
                    [GroupingId],
                    [Process],
                    [BDate],
                    [EDate],
                    [AdditionalRows],
                    [RunBy]
                )
                SELECT [GroupingId] = @tbl_Summary_RskAdj_ActivityIdMain,
                       [Process] = '[rev].[spr_Summary_RskAdj_EDS]',
                       [BDate] = @Today,
                       [EDate] = NULL,
                       [AdditionalRows] = NULL,
                       [RunBy] = @UserID;

                SET @tbl_Summary_RskAdj_ActivityIdSecondary = SCOPE_IDENTITY();

                SET @RowCount_OUT = 0;

                EXEC [rev].[spr_Summary_RskAdj_EDS] @LoadDateTime = @ET,
                                                    @DeleteBatch = @DeleteBatchEDS,
                                                    @RowCount = @RowCount_OUT OUTPUT,
                                                    @Debug = 0;

                SET @RefreshDate = GETDATE();
                UPDATE [m]
                SET [m].[EDate] = @RefreshDate,
                    [m].[AdditionalRows] = @RowCount_OUT
                FROM [rev].[tbl_Summary_RskAdj_Activity] [m]
                WHERE [m].[tbl_Summary_RskAdj_ActivityId] = @tbl_Summary_RskAdj_ActivityIdSecondary; --Summary 2.5


                --update [m]
                --set [m].[EDate] = getdate() --RE 4080
                --  , [m].[AdditionalRows] = @RowCount_OUT
                --from [rev].[tbl_Summary_RskAdj_Activity] [m]
                --where [m].[tbl_Summary_RskAdj_ActivityId] = @tbl_Summary_RskAdj_ActivityIdSecondary

                SET @tbl_Summary_RskAdj_ActivityIdSecondary = NULL;

                IF @Debug = 1
                BEGIN
                    SELECT [spr_Summary_RskAdj_EDS] = @RowCount_OUT;

                    EXEC [dbo].[PerfLogMonitor] @Section = '014',
                                                @ProcessName = @ProcessNameIn,
                                                @ET = @ET,
                                                @MasterET = @MasterET,
                                                @ET_Out = @ET OUT,
                                                @TableOutput = 0,
                                                @End = 0;
                END;

                IF @Debug = 1
                BEGIN
                    SELECT [spr_Summary_RskAdj_EDS_Preliminary] = @RowCount_OUT;

                    EXEC [dbo].[PerfLogMonitor] @Section = '015',
                                                @ProcessName = @ProcessNameIn,
                                                @ET = @ET,
                                                @MasterET = @MasterET,
                                                @ET_Out = @ET OUT,
                                                @TableOutput = 0,
                                                @End = 0;
                END;
                SET @Today = GETDATE();
                INSERT INTO [rev].[tbl_Summary_RskAdj_Activity]
                (
                    [GroupingId],
                    [Process],
                    [BDate],
                    [EDate],
                    [AdditionalRows],
                    [RunBy]
                )
                SELECT [GroupingId] = @tbl_Summary_RskAdj_ActivityIdMain,
                       [Process] = '[rev].[spr_Summary_RskAdj_EDS_MOR_Combined]',
                       [BDate] = @Today,
                       [EDate] = NULL,
                       [AdditionalRows] = NULL,
                       [RunBy] = @UserID;

                SET @tbl_Summary_RskAdj_ActivityIdSecondary = SCOPE_IDENTITY();

                SET @RowCount_OUT = 0;

                EXEC [rev].[spr_Summary_RskAdj_EDS_MOR_Combined] @LoadDateTime = @ET,
                                                                 @DeleteBatch = @DeleteBatchEDS,
                                                                 @RowCount = @RowCount_OUT OUTPUT,
                                                                 @Debug = 0;
                SET @RefreshDate = GETDATE();
                UPDATE [m]
                SET [m].[EDate] = @RefreshDate, -- RE 4080
                    [m].[AdditionalRows] = @RowCount_OUT
                FROM [rev].[tbl_Summary_RskAdj_Activity] [m]
                WHERE [m].[tbl_Summary_RskAdj_ActivityId] = @tbl_Summary_RskAdj_ActivityIdSecondary;


                UPDATE [m]
                SET [m].[LastRefreshDate] = @RefreshDate
                FROM [rev].[SummaryProcessRunFlag] [m]
                WHERE [m].[Process] = 'EDS';

                SET @tbl_Summary_RskAdj_ActivityIdSecondary = NULL;

                IF @Debug = 1
                BEGIN
                    SELECT [spr_Summary_RskAdj_EDS] = @RowCount_OUT;

                    EXEC [dbo].[PerfLogMonitor] @Section = '016',
                                                @ProcessName = @ProcessNameIn,
                                                @ET = @ET,
                                                @MasterET = @MasterET,
                                                @ET_Out = @ET OUT,
                                                @TableOutput = 0,
                                                @End = 0;
                END;

            END;

            ---EDS END 
            ----update [m]
            ----set [m].[EDate] = @Today
            ----from [rev].[tbl_Summary_RskAdj_Activity] [m]
            ----where [m].[tbl_Summary_RskAdj_ActivityId] = @tbl_Summary_RskAdj_ActivityIdSecondary

            SET @tbl_Summary_RskAdj_ActivityIdSecondary = NULL;

            IF @Debug = 1
            BEGIN
                EXEC [dbo].[PerfLogMonitor] @Section = '017',
                                            @ProcessName = @ProcessNameIn,
                                            @ET = @ET,
                                            @MasterET = @MasterET,
                                            @ET_Out = @ET OUT,
                                            @TableOutput = 0,
                                            @End = 0;
            END;

        END;




    /*Update Statistics for MOR RAPS and EDS*/
    --      update statistics [rev].[tbl_Summary_RskAdj_MOR]

    --      update statistics [rev].[tbl_Summary_RskAdj_RAPS_Preliminary]

    --      update statistics [rev].[tbl_Summary_RskAdj_RAPS]

    --      update statistics [rev].[tbl_Summary_RskAdj_EDS_Preliminary]

    --update statistics [rev].[tbl_Summary_RskAdj_EDS]

    --      update statistics [rev].[tbl_Summary_RskAdj_RAPS_MOR_Combined]

    --      update statistics [rev].[tbl_Summary_RskAdj_EDS_MOR_Combined]

    END;

    SKIPEXECSPR_SUMMARY_RSKADJ_ALTHICN_MMR_MOR_RAPS:

    IF @Mode IN ( 2 )
    BEGIN
        IF @Mode = 2
        BEGIN
            IF @Debug = 1
            BEGIN
                EXEC [dbo].[PerfLogMonitor] @Section = '018',
                                            @ProcessName = @ProcessNameIn,
                                            @ET = @ET,
                                            @MasterET = @MasterET,
                                            @ET_Out = @ET OUT,
                                            @TableOutput = 0,
                                            @End = 0;
            END;

            SET @MOR_FLAG = 1;
            SET @RAPS_FLAG = 1;
            SET @EDS_FLAG = 1;
            --SET @EDSSrc_FLAG = 1; --- RE - 5112

        END;

        IF @Debug = 1
        BEGIN
            EXEC [dbo].[PerfLogMonitor] @Section = '019',
                                        @ProcessName = @ProcessNameIn,
                                        @ET = @ET,
                                        @MasterET = @MasterET,
                                        @ET_Out = @ET OUT,
                                        @TableOutput = 0,
                                        @End = 0;
        END;

        /*B IX Rebuild */
        DECLARE @ParaSortInTemp BIT = 0;
        DECLARE @ParaOnline BIT = 0;

        SET @tbl_Summary_RskAdj_ActivityIdSecondary = SCOPE_IDENTITY();
        SET @Today = GETDATE();
        SET @ParaSortInTemp = CASE
                                  WHEN DATEPART(hh, @Today) >= @BBusinessHours
                                       AND DATEPART(hh, @Today) <= @EBusinessHours THEN
                                      1
                                  ELSE
                                      0
                              END;

        SET @ParaOnline = CASE
                              WHEN DATEPART(hh, @Today) >= @BBusinessHours
                                   AND DATEPART(hh, @Today) <= @EBusinessHours THEN
                                  1
                              ELSE
                                  0
                          END;
        /*-B Rebuild/Defrag IX for rev.tbl_Summary_RskAdj_MOR */

        IF @MOR_FLAG = 1
        BEGIN

            IF @Debug = 1
            BEGIN
                EXEC [dbo].[PerfLogMonitor] @Section = '020',
                                            @ProcessName = @ProcessNameIn,
                                            @ET = @ET,
                                            @MasterET = @MasterET,
                                            @ET_Out = @ET OUT,
                                            @TableOutput = 0,
                                            @End = 0;
            END;

            SET @Today = GETDATE();

            INSERT INTO [rev].[tbl_Summary_RskAdj_Activity]
            (
                [GroupingId],
                [Process],
                [BDate],
                [EDate],
                [AdditionalRows],
                [RunBy]
            )
            SELECT [GroupingId] = @tbl_Summary_RskAdj_ActivityIdMain,
                   [Process] = '[dbo].[spr_RebuildIndexesByTable] @TableName=[rev].[tbl_Summary_RskAdj_MOR]',
                   [BDate] = @Today,
                   [EDate] = NULL,
                   [AdditionalRows] = NULL,
                   [RunBy] = @UserID;

            SET @tbl_Summary_RskAdj_ActivityIdSecondary = SCOPE_IDENTITY();

            IF @Debug = 1
            BEGIN
                EXEC [dbo].[PerfLogMonitor] @Section = '021',
                                            @ProcessName = @ProcessNameIn,
                                            @ET = @ET,
                                            @MasterET = @MasterET,
                                            @ET_Out = @ET OUT,
                                            @TableOutput = 0,
                                            @End = 0;
            END;

            EXEC [dbo].[spr_RebuildIndexesByTable] @SchemaName = 'rev',
                                                   @TableName = 'tbl_Summary_RskAdj_MOR',
                                                   @SortInTemp = @ParaSortInTemp,
                                                   @Online = @ParaOnline;

            IF @Debug = 1
            BEGIN
                EXEC [dbo].[PerfLogMonitor] @Section = '022',
                                            @ProcessName = @ProcessNameIn,
                                            @ET = @ET,
                                            @MasterET = @MasterET,
                                            @ET_Out = @ET OUT,
                                            @TableOutput = 0,
                                            @End = 0;
            END;

            UPDATE [m]
            SET [m].[EDate] = GETDATE() --RE 4080
            FROM [rev].[tbl_Summary_RskAdj_Activity] [m]
            WHERE [m].[tbl_Summary_RskAdj_ActivityId] = @tbl_Summary_RskAdj_ActivityIdSecondary;

            SET @tbl_Summary_RskAdj_ActivityIdSecondary = NULL;

            IF @Debug = 1
            BEGIN
                EXEC [dbo].[PerfLogMonitor] @Section = '023',
                                            @ProcessName = @ProcessNameIn,
                                            @ET = @ET,
                                            @MasterET = @MasterET,
                                            @ET_Out = @ET OUT,
                                            @TableOutput = 0,
                                            @End = 0;
            END;

        END;

        /*-E Rebuild/Defrag IX for rev.tbl_Summary_RskAdj_MOR */

        IF @Debug = 1
        BEGIN
            EXEC [dbo].[PerfLogMonitor] @Section = '024',
                                        @ProcessName = @ProcessNameIn,
                                        @ET = @ET,
                                        @MasterET = @MasterET,
                                        @ET_Out = @ET OUT,
                                        @TableOutput = 0,
                                        @End = 0;
        END;

        /*-B Rebuild/Defrag IX for rev.tbl_Summary_RskAdj_RAPS */

        IF @RAPS_FLAG = 1
        BEGIN
            IF @Debug = 1
            BEGIN
                EXEC [dbo].[PerfLogMonitor] @Section = '025',
                                            @ProcessName = @ProcessNameIn,
                                            @ET = @ET,
                                            @MasterET = @MasterET,
                                            @ET_Out = @ET OUT,
                                            @TableOutput = 0,
                                            @End = 0;
            END;

            /*********************************************************************/
            /* ReIndex tbl_Summary Raps  Preliminary                             */
            /*********************************************************************/
            SET @Today = GETDATE();
            INSERT INTO [rev].[tbl_Summary_RskAdj_Activity]
            (
                [GroupingId],
                [Process],
                [BDate],
                [EDate],
                [AdditionalRows],
                [RunBy]
            )
            SELECT [GroupingId] = @tbl_Summary_RskAdj_ActivityIdMain,
                   [Process] = '[dbo].[spr_RebuildIndexesByTable] @TableName=[rev].[tbl_Summary_RskAdj_RAPS_Preliminary]',
                   [BDate] = @Today,
                   [EDate] = NULL,
                   [AdditionalRows] = NULL,
                   [RunBy] = @UserID;

            IF @Debug = 1
            BEGIN
                EXEC [dbo].[PerfLogMonitor] @Section = '026',
                                            @ProcessName = @ProcessNameIn,
                                            @ET = @ET,
                                            @MasterET = @MasterET,
                                            @ET_Out = @ET OUT,
                                            @TableOutput = 0,
                                            @End = 0;
            END;

            SET @tbl_Summary_RskAdj_ActivityIdSecondary = SCOPE_IDENTITY();

            IF @Debug = 1
            BEGIN
                EXEC [dbo].[PerfLogMonitor] @Section = '025',
                                            @ProcessName = @ProcessNameIn,
                                            @ET = @ET,
                                            @MasterET = @MasterET,
                                            @ET_Out = @ET OUT,
                                            @TableOutput = 0,
                                            @End = 0;
            END;

            EXEC [dbo].[spr_RebuildIndexesByTable] @SchemaName = 'rev',
                                                   @TableName = 'tbl_Summary_RskAdj_RAPS_Preliminary',
                                                   @SortInTemp = @ParaSortInTemp,
                                                   @Online = @ParaOnline;

            UPDATE [m]
            SET [m].[EDate] = GETDATE() -- RE 4080
            FROM [rev].[tbl_Summary_RskAdj_Activity] [m]
            WHERE [m].[tbl_Summary_RskAdj_ActivityId] = @tbl_Summary_RskAdj_ActivityIdSecondary;

            SET @tbl_Summary_RskAdj_ActivityIdSecondary = NULL;

            IF @Debug = 1
            BEGIN
                EXEC [dbo].[PerfLogMonitor] @Section = '027',
                                            @ProcessName = @ProcessNameIn,
                                            @ET = @ET,
                                            @MasterET = @MasterET,
                                            @ET_Out = @ET OUT,
                                            @TableOutput = 0,
                                            @End = 0;
            END;

            /*********************************************************************/
            /* ReIndex tbl_Summary Raps                                          */
            /*********************************************************************/
            SET @Today = GETDATE();
            INSERT INTO [rev].[tbl_Summary_RskAdj_Activity]
            (
                [GroupingId],
                [Process],
                [BDate],
                [EDate],
                [AdditionalRows],
                [RunBy]
            )
            SELECT [GroupingId] = @tbl_Summary_RskAdj_ActivityIdMain,
                   [Process] = '[dbo].[spr_RebuildIndexesByTable] @TableName=[rev].[tbl_Summary_RskAdj_RAPS]',
                   [BDate] = @Today,
                   [EDate] = NULL,
                   [AdditionalRows] = NULL,
                   [RunBy] = @UserID;

            IF @Debug = 1
            BEGIN
                EXEC [dbo].[PerfLogMonitor] @Section = '028',
                                            @ProcessName = @ProcessNameIn,
                                            @ET = @ET,
                                            @MasterET = @MasterET,
                                            @ET_Out = @ET OUT,
                                            @TableOutput = 0,
                                            @End = 0;
            END;

            SET @tbl_Summary_RskAdj_ActivityIdSecondary = SCOPE_IDENTITY();

            IF @Debug = 1
            BEGIN
                EXEC [dbo].[PerfLogMonitor] @Section = '029',
                                            @ProcessName = @ProcessNameIn,
                                            @ET = @ET,
                                            @MasterET = @MasterET,
                                            @ET_Out = @ET OUT,
                                            @TableOutput = 0,
                                            @End = 0;
            END;

            EXEC [dbo].[spr_RebuildIndexesByTable] @SchemaName = 'rev',
                                                   @TableName = 'tbl_Summary_RskAdj_RAPS',
                                                   @SortInTemp = @ParaSortInTemp,
                                                   @Online = @ParaOnline;

            UPDATE [m]
            SET [m].[EDate] = GETDATE() -- RE4080
            FROM [rev].[tbl_Summary_RskAdj_Activity] [m]
            WHERE [m].[tbl_Summary_RskAdj_ActivityId] = @tbl_Summary_RskAdj_ActivityIdSecondary;

            SET @tbl_Summary_RskAdj_ActivityIdSecondary = NULL;

            IF @Debug = 1
            BEGIN
                EXEC [dbo].[PerfLogMonitor] @Section = '030',
                                            @ProcessName = @ProcessNameIn,
                                            @ET = @ET,
                                            @MasterET = @MasterET,
                                            @ET_Out = @ET OUT,
                                            @TableOutput = 0,
                                            @End = 0;
            END;

            /****************************************************************************/
            /* ReIndex RAPS MOR Combined                                                */
            /****************************************************************************/
            SET @Today = GETDATE();
            INSERT INTO [rev].[tbl_Summary_RskAdj_Activity]
            (
                [GroupingId],
                [Process],
                [BDate],
                [EDate],
                [AdditionalRows],
                [RunBy]
            )
            SELECT [GroupingId] = @tbl_Summary_RskAdj_ActivityIdMain,
                   [Process] = '[dbo].[spr_RebuildIndexesByTable] @TableName=[rev].[tbl_Summary_RskAdj_RAPS_MOR_Combined]',
                   [BDate] = @Today,
                   [EDate] = NULL,
                   [AdditionalRows] = NULL,
                   [RunBy] = @UserID;

            IF @Debug = 1
            BEGIN
                EXEC [dbo].[PerfLogMonitor] @Section = '031',
                                            @ProcessName = @ProcessNameIn,
                                            @ET = @ET,
                                            @MasterET = @MasterET,
                                            @ET_Out = @ET OUT,
                                            @TableOutput = 0,
                                            @End = 0;
            END;

            SET @tbl_Summary_RskAdj_ActivityIdSecondary = SCOPE_IDENTITY();

            IF @Debug = 1
            BEGIN
                EXEC [dbo].[PerfLogMonitor] @Section = '032',
                                            @ProcessName = @ProcessNameIn,
                                            @ET = @ET,
                                            @MasterET = @MasterET,
                                            @ET_Out = @ET OUT,
                                            @TableOutput = 0,
                                            @End = 0;
            END;

            EXEC [dbo].[spr_RebuildIndexesByTable] @SchemaName = 'rev',
                                                   @TableName = 'tbl_Summary_RskAdj_RAPS_MOR_Combined',
                                                   @SortInTemp = @ParaSortInTemp,
                                                   @Online = @ParaOnline;

            IF @Debug = 1
            BEGIN
                EXEC [dbo].[PerfLogMonitor] @Section = '033',
                                            @ProcessName = @ProcessNameIn,
                                            @ET = @ET,
                                            @MasterET = @MasterET,
                                            @ET_Out = @ET OUT,
                                            @TableOutput = 0,
                                            @End = 0;
            END;

            UPDATE [m]
            SET [m].[EDate] = GETDATE() --RE 4080
            FROM [rev].[tbl_Summary_RskAdj_Activity] [m]
            WHERE [m].[tbl_Summary_RskAdj_ActivityId] = @tbl_Summary_RskAdj_ActivityIdSecondary;

            SET @tbl_Summary_RskAdj_ActivityIdSecondary = NULL;

            IF @Debug = 1
            BEGIN
                EXEC [dbo].[PerfLogMonitor] @Section = '034',
                                            @ProcessName = @ProcessNameIn,
                                            @ET = @ET,
                                            @MasterET = @MasterET,
                                            @ET_Out = @ET OUT,
                                            @TableOutput = 0,
                                            @End = 0;
            END;
        END;

        ----EDS Soruce Flag --RE -5112


        --/*-B Rebuild/Defrag IX for rev.tbl_Summary_RskAdj_EDSSoruce */
        --IF @EDSSrc_FLAG = 1
        --BEGIN
        --    IF @Debug = 1
        --    BEGIN
        --        EXEC [dbo].[PerfLogMonitor] @Section = '035',
        --                                    @ProcessName = @ProcessNameIn,
        --                                    @ET = @ET,
        --                                    @MasterET = @MasterET,
        --                                    @ET_Out = @ET OUT,
        --                                    @TableOutput = 0,
        --                                    @End = 0;
        --    END;

        --    /*********************************************************************/
        --    /* ReIndex tbl_Summary EDS  Preliminary                             */
        --    /*********************************************************************/
        --    SET @Today = GETDATE();
        --    INSERT INTO [rev].[tbl_Summary_RskAdj_Activity]
        --    (
        --        [GroupingId],
        --        [Process],
        --        [BDate],
        --        [EDate],
        --        [AdditionalRows],
        --        [RunBy]
        --    )
        --    SELECT [GroupingId] = @tbl_Summary_RskAdj_ActivityIdMain,
        --           [Process] = '[dbo].[spr_RebuildIndexesByTable] @TableName=[rev].[tbl_Summary_RskAdj_EDS_Source]',
        --           [BDate] = @Today,
        --           [EDate] = NULL,
        --           [AdditionalRows] = NULL,
        --           [RunBy] = @UserID;

        --    IF @Debug = 1
        --    BEGIN
        --        EXEC [dbo].[PerfLogMonitor] @Section = '036',
        --                                    @ProcessName = @ProcessNameIn,
        --                                    @ET = @ET,
        --                                    @MasterET = @MasterET,
        --                                    @ET_Out = @ET OUT,
        --                                    @TableOutput = 0,
        --                                    @End = 0;
        --    END;

        --    SET @tbl_Summary_RskAdj_ActivityIdSecondary = SCOPE_IDENTITY();

        --    IF @Debug = 1
        --    BEGIN
        --        EXEC [dbo].[PerfLogMonitor] @Section = '037',
        --                                    @ProcessName = @ProcessNameIn,
        --                                    @ET = @ET,
        --                                    @MasterET = @MasterET,
        --                                    @ET_Out = @ET OUT,
        --                                    @TableOutput = 0,
        --                                    @End = 0;
        --    END;

        --    EXEC [dbo].[spr_RebuildIndexesByTable] @SchemaName = 'rev',
        --                                           @TableName = 'tbl_Summary_RskAdj_EDS_Source',
        --                                           @SortInTemp = @ParaSortInTemp,
        --                                           @Online = @ParaOnline;

        --    UPDATE [m]
        --    SET [m].[EDate] = GETDATE() --RE 4080
        --    FROM [rev].[tbl_Summary_RskAdj_Activity] [m]
        --    WHERE [m].[tbl_Summary_RskAdj_ActivityId] = @tbl_Summary_RskAdj_ActivityIdSecondary;

        --    SET @tbl_Summary_RskAdj_ActivityIdSecondary = NULL;

        --    IF @Debug = 1
        --    BEGIN
        --        EXEC [dbo].[PerfLogMonitor] @Section = '038',
        --                                    @ProcessName = @ProcessNameIn,
        --                                    @ET = @ET,
        --                                    @MasterET = @MasterET,
        --                                    @ET_Out = @ET OUT,
        --                                    @TableOutput = 0,
        --                                    @End = 0;
        --    END;

        --END;


        /*-E Rebuild/Defrag IX for rev.tbl_Summary_RskAdj_RAPS */

        --EDS Start 

        /*-B Rebuild/Defrag IX for rev.tbl_Summary_RskAdj_EDS */
        IF @EDS_FLAG = 1
        BEGIN
            IF @Debug = 1
            BEGIN
                EXEC [dbo].[PerfLogMonitor] @Section = '039',
                                            @ProcessName = @ProcessNameIn,
                                            @ET = @ET,
                                            @MasterET = @MasterET,
                                            @ET_Out = @ET OUT,
                                            @TableOutput = 0,
                                            @End = 0;
            END;

            /*********************************************************************/
            /* ReIndex tbl_Summary EDS  Preliminary                             */
            /*********************************************************************/
            SET @Today = GETDATE();
            INSERT INTO [rev].[tbl_Summary_RskAdj_Activity]
            (
                [GroupingId],
                [Process],
                [BDate],
                [EDate],
                [AdditionalRows],
                [RunBy]
            )
            SELECT [GroupingId] = @tbl_Summary_RskAdj_ActivityIdMain,
                   [Process] = '[dbo].[spr_RebuildIndexesByTable] @TableName=[rev].[tbl_Summary_RskAdj_EDS_Preliminary]',
                   [BDate] = @Today,
                   [EDate] = NULL,
                   [AdditionalRows] = NULL,
                   [RunBy] = @UserID;

            IF @Debug = 1
            BEGIN
                EXEC [dbo].[PerfLogMonitor] @Section = '040',
                                            @ProcessName = @ProcessNameIn,
                                            @ET = @ET,
                                            @MasterET = @MasterET,
                                            @ET_Out = @ET OUT,
                                            @TableOutput = 0,
                                            @End = 0;
            END;

            SET @tbl_Summary_RskAdj_ActivityIdSecondary = SCOPE_IDENTITY();

            IF @Debug = 1
            BEGIN
                EXEC [dbo].[PerfLogMonitor] @Section = '041',
                                            @ProcessName = @ProcessNameIn,
                                            @ET = @ET,
                                            @MasterET = @MasterET,
                                            @ET_Out = @ET OUT,
                                            @TableOutput = 0,
                                            @End = 0;
            END;

            EXEC [dbo].[spr_RebuildIndexesByTable] @SchemaName = 'rev',
                                                   @TableName = 'tbl_Summary_RskAdj_EDS_Preliminary',
                                                   @SortInTemp = @ParaSortInTemp,
                                                   @Online = @ParaOnline;

            UPDATE [m]
            SET [m].[EDate] = GETDATE() --RE 4080
            FROM [rev].[tbl_Summary_RskAdj_Activity] [m]
            WHERE [m].[tbl_Summary_RskAdj_ActivityId] = @tbl_Summary_RskAdj_ActivityIdSecondary;

            SET @tbl_Summary_RskAdj_ActivityIdSecondary = NULL;

            IF @Debug = 1
            BEGIN
                EXEC [dbo].[PerfLogMonitor] @Section = '042',
                                            @ProcessName = @ProcessNameIn,
                                            @ET = @ET,
                                            @MasterET = @MasterET,
                                            @ET_Out = @ET OUT,
                                            @TableOutput = 0,
                                            @End = 0;
            END;

            /*********************************************************************/
            /* ReIndex tbl_Summary EDS                                          */
            /*********************************************************************/
            SET @Today = GETDATE();
            INSERT INTO [rev].[tbl_Summary_RskAdj_Activity]
            (
                [GroupingId],
                [Process],
                [BDate],
                [EDate],
                [AdditionalRows],
                [RunBy]
            )
            SELECT [GroupingId] = @tbl_Summary_RskAdj_ActivityIdMain,
                   [Process] = '[dbo].[spr_RebuildIndexesByTable] @TableName=[rev].[tbl_Summary_RskAdj_EDS]',
                   [BDate] = @Today,
                   [EDate] = NULL,
                   [AdditionalRows] = NULL,
                   [RunBy] = @UserID;

            IF @Debug = 1
            BEGIN
                EXEC [dbo].[PerfLogMonitor] @Section = '043',
                                            @ProcessName = @ProcessNameIn,
                                            @ET = @ET,
                                            @MasterET = @MasterET,
                                            @ET_Out = @ET OUT,
                                            @TableOutput = 0,
                                            @End = 0;
            END;

            SET @tbl_Summary_RskAdj_ActivityIdSecondary = SCOPE_IDENTITY();

            IF @Debug = 1
            BEGIN
                EXEC [dbo].[PerfLogMonitor] @Section = '044',
                                            @ProcessName = @ProcessNameIn,
                                            @ET = @ET,
                                            @MasterET = @MasterET,
                                            @ET_Out = @ET OUT,
                                            @TableOutput = 0,
                                            @End = 0;
            END;

            EXEC [dbo].[spr_RebuildIndexesByTable] @SchemaName = 'rev',
                                                   @TableName = 'tbl_Summary_RskAdj_EDS',
                                                   @SortInTemp = @ParaSortInTemp,
                                                   @Online = @ParaOnline;

            UPDATE [m]
            SET [m].[EDate] = GETDATE() --RE 4080
            FROM [rev].[tbl_Summary_RskAdj_Activity] [m]
            WHERE [m].[tbl_Summary_RskAdj_ActivityId] = @tbl_Summary_RskAdj_ActivityIdSecondary;

            SET @tbl_Summary_RskAdj_ActivityIdSecondary = NULL;

            IF @Debug = 1
            BEGIN
                EXEC [dbo].[PerfLogMonitor] @Section = '045',
                                            @ProcessName = @ProcessNameIn,
                                            @ET = @ET,
                                            @MasterET = @MasterET,
                                            @ET_Out = @ET OUT,
                                            @TableOutput = 0,
                                            @End = 0;
            END;


        END;

        /*-E Rebuild/Defrag IX for rev.tbl_Summary_RskAdj_EDS */

        --EDS END 


        IF @Debug = 1
        BEGIN
            EXEC [dbo].[PerfLogMonitor] @Section = '046',
                                        @ProcessName = @ProcessNameIn,
                                        @ET = @ET,
                                        @MasterET = @MasterET,
                                        @ET_Out = @ET OUT,
                                        @TableOutput = 0,
                                        @End = 0;
        END;
    /*E IX Rebuild */
    END;




    /*B Update Activity Logging  */

    UPDATE [m]
    SET [m].[EDate] = GETDATE() --RE 4080
    FROM [rev].[tbl_Summary_RskAdj_Activity] [m]
    WHERE [m].[tbl_Summary_RskAdj_ActivityId] = @tbl_Summary_RskAdj_ActivityIdMain
          AND [m].[Process] LIKE 'Part C Summary Process%';




/*E Update Activity Logging */

END;