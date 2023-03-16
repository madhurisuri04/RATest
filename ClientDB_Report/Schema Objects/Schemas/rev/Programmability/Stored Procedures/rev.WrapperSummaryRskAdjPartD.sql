CREATE PROCEDURE [rev].[WrapperSummaryRskAdjPartD] @Debug BIT = 0
AS
/*********************************************************************************************************** */
/* Name				:	[rev].[WrapperSummaryRskAdjPartD]                   	    						*/
/* Type 			:	Stored Procedure																	*/
/* Author       	:   Madhuri Suri    																	*/
/* Date				:	2/26/2018																			*/
/* Version			:																						*/
/* Description		:	Wrapper procedure invokes the Summary PartD          								*/
/*																											*/
/* Version History :																						*/
/* =================																						*/
/* Author				Date		Version#    TFS Ticket#		Description								    */
/* -----------------	----------  --------    -----------		------------								*/
/*  D. Waddell           6/07/2018    1.1        71385           Add Activity Log Entry called "Boot        */
/*                                                               Up Summary Process". (Section 001,005)     */
/*  D.Waddell			5/3/2019	1.3			75914 (RE-4080) Fix summary log time (EDate)                */
/* Madhuri Suri         2018-09-24  2.0         76879           Summary 2.5 Changes                         */
/*  D. Waddell          9/30/2019   2.1         76913 (RE-6557) Remove all reference to update statistics in*/
/*                                                              Summary Procedure                           */
/************************************************************************************************************/



BEGIN

    DECLARE @ET DATETIME;
    DECLARE @MasterET DATETIME;
    DECLARE @ProcessNameIn VARCHAR(128);
    DECLARE @RowCount_OUT INT = 0;
    DECLARE @AltHICN_RowCount INT = 0;
    DECLARE @MMR_RowCount INT = 0;
    DECLARE @MOR_RowCount INT = 0;
    DECLARE @RAPS_RowCount INT = 0;
    DECLARE @EDS_RowCount INT = 0;
    DECLARE @Curr_DB VARCHAR(128) = NULL;
    DECLARE @Clnt_DB VARCHAR(128) = NULL;
    DECLARE @DeleteBatchAltHICN INT;
    DECLARE @DeleteBatchMMR INT;
    DECLARE @DeleteBatchMOR INT;
    DECLARE @DeleteBatchRAPS_Preliminary INT;
    DECLARE @DeleteBatchRAPS INT;
    DECLARE @DeleteBatchRAPS_MOR_Combined INT;
    DECLARE @DeleteBatchEDS_Preliminary INT;
    DECLARE @DeleteBatchEDS INT;
    DECLARE @Mode TINYINT;
    DECLARE @BBusinessHours TINYINT;
    DECLARE @EBusinessHours TINYINT;
    DECLARE @RefreshDate DATETIME; -- Summary 2.5   

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



    DECLARE @tbl_Summary_RskAdj_ActivityIdMain INT;
    DECLARE @tbl_Summary_RskAdj_ActivityIdSecondary INT;

    /*B Initialize Activity Logging */
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
           [Process] = 'Part D Summary Process',
           [BDate] = GETDATE(),
           [EDate] = NULL,
           [AdditionalRows] = NULL,
           [RunBy] = USER_NAME();

    SET @tbl_Summary_RskAdj_ActivityIdMain = SCOPE_IDENTITY();

    UPDATE [m]
    SET [m].[GroupingId] = @tbl_Summary_RskAdj_ActivityIdMain
    FROM [rev].[tbl_Summary_RskAdj_Activity] [m]
    WHERE [m].[tbl_Summary_RskAdj_ActivityId] = @tbl_Summary_RskAdj_ActivityIdMain;

    /*E Initialize Activity Logging */


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



    IF @Mode IN ( 0, 1 )
    BEGIN
        /*B  */
        IF @MOR_FLAG = 0
           AND @RAPS_FLAG = 0
           AND @EDS_FLAG = 0
        BEGIN

            GOTO SkipEXECspr_Summary_RskAdj_AltHICN_MMR_MOR_RAPS;

        END;
        ELSE
        BEGIN

            /*Update Statistics for MOR RAPS and EDS Before*/
            --update statistics [rev].[SummaryPartDRskAdjMORD]

            --update statistics [rev].[SummaryPartDRskAdjRAPSPreliminary]

            --update statistics [rev].[SummaryPartDRskAdjRAPS]

            --update statistics [rev].[SummaryPartDRskAdjEDSPreliminary]

            --update statistics [rev].[SummaryPartDRskAdjEDS]

            --update statistics [rev].[SummaryPartDRskAdjRAPSMORDCombined]

            IF @MOR_FLAG = 1
            BEGIN
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

                SET @RowCount_OUT = NULL;

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
                       [Process] = '[rev].[LoadSummaryPartDRskAdjMORD]',
                       [BDate] = GETDATE(),
                       [EDate] = NULL,
                       [AdditionalRows] = 0,
                       [RunBy] = USER_NAME();

                SET @tbl_Summary_RskAdj_ActivityIdSecondary = SCOPE_IDENTITY();

                EXEC [rev].[LoadSummaryPartDRskAdjMORD] @LoadDateTime = @ET,
                                                        @DeleteBatch = @DeleteBatchMOR,
                                                        @RowCount = @RowCount_OUT OUTPUT,
                                                        @Debug = 0;

                SET @MOR_RowCount = @RowCount_OUT;

                --update [m]
                --set [m].[EDate] = getdate()
                --  , [m].[AdditionalRows] = @MOR_RowCount
                --from [rev].[tbl_Summary_RskAdj_Activity] [m]
                --where [m].[tbl_Summary_RskAdj_ActivityId] = @tbl_Summary_RskAdj_ActivityIdSecondary

                SET @RefreshDate = GETDATE();
                UPDATE [m]
                SET [m].[EDate] = @RefreshDate,
                    [m].[AdditionalRows] = @MOR_RowCount
                FROM [rev].[tbl_Summary_RskAdj_Activity] [m]
                WHERE [m].[tbl_Summary_RskAdj_ActivityId] = @tbl_Summary_RskAdj_ActivityIdSecondary; -- Summary 2.5


                SET @tbl_Summary_RskAdj_ActivityIdSecondary = NULL;

                IF @Debug = 1
                BEGIN
                    SELECT [LoadSummaryPartDRskAdjMORD] = @RowCount_OUT;
                END;

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
                       [Process] = '[rev].[LoadSummaryPartDRskAdjRAPSPreliminary]',
                       [BDate] = GETDATE(),
                       [EDate] = NULL,
                       [AdditionalRows] = NULL,
                       [RunBy] = USER_NAME();

                SET @tbl_Summary_RskAdj_ActivityIdSecondary = SCOPE_IDENTITY();

                SET @RowCount_OUT = 0;

                EXEC [rev].[LoadSummaryPartDRskAdjRAPSPreliminary] @Debug = 0;

                SET @RAPS_RowCount = @RowCount_OUT;

                --update [m]
                --set [m].[EDate] = getdate()
                --  , [m].[AdditionalRows] = @RowCount_OUT
                --from [rev].[tbl_Summary_RskAdj_Activity] [m]
                --where [m].[tbl_Summary_RskAdj_ActivityId] = @tbl_Summary_RskAdj_ActivityIdSecondary


                SET @RefreshDate = GETDATE();
                UPDATE [m]
                SET [m].[EDate] = @RefreshDate,
                    [m].[AdditionalRows] = @RAPS_RowCount
                FROM [rev].[tbl_Summary_RskAdj_Activity] [m]
                WHERE [m].[tbl_Summary_RskAdj_ActivityId] = @tbl_Summary_RskAdj_ActivityIdSecondary; -- Summary 2.5

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
                    SELECT [LoadSummaryPartDRskAdjRAPSPreliminary] = @RowCount_OUT;

                    EXEC [dbo].[PerfLogMonitor] @Section = '006',
                                                @ProcessName = @ProcessNameIn,
                                                @ET = @ET,
                                                @MasterET = @MasterET,
                                                @ET_Out = @ET OUT,
                                                @TableOutput = 0,
                                                @End = 0;
                END;

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
                       [Process] = '[rev].[LoadSummaryPartDRskAdjRAPS]',
                       [BDate] = GETDATE(),
                       [EDate] = NULL,
                       [AdditionalRows] = NULL,
                       [RunBy] = USER_NAME();

                SET @tbl_Summary_RskAdj_ActivityIdSecondary = SCOPE_IDENTITY();

                SET @RowCount_OUT = 0;

                EXEC [rev].[LoadSummaryPartDRskAdjRAPS] @Debug = 0;


                --update [m]
                --set [m].[EDate] = getdate()
                --  , [m].[AdditionalRows] = @RowCount_OUT
                --from [rev].[tbl_Summary_RskAdj_Activity] [m]
                --where [m].[tbl_Summary_RskAdj_ActivityId] = @tbl_Summary_RskAdj_ActivityIdSecondary


                SET @RefreshDate = GETDATE();
                UPDATE [m]
                SET [m].[EDate] = @RefreshDate,
                    [m].[AdditionalRows] = @RowCount_OUT
                FROM [rev].[tbl_Summary_RskAdj_Activity] [m]
                WHERE [m].[tbl_Summary_RskAdj_ActivityId] = @tbl_Summary_RskAdj_ActivityIdSecondary; -- Summary 2.5

                SET @tbl_Summary_RskAdj_ActivityIdSecondary = NULL;

                IF @Debug = 1
                BEGIN
                    SELECT [LoadSummaryPartDRskAdjRAPS] = @RowCount_OUT;

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
                       [Process] = '[rev].[LoadSummaryPartDRskAdjRAPSMORDCombined]',
                       [BDate] = GETDATE(),
                       [EDate] = NULL,
                       [AdditionalRows] = NULL,
                       [RunBy] = USER_NAME();

                SET @tbl_Summary_RskAdj_ActivityIdSecondary = SCOPE_IDENTITY();

                SET @RowCount_OUT = 0;

                EXEC [rev].[LoadSummaryPartDRskAdjRAPSMORDCombined] @LoadDateTime = @ET,
                                                                    @DeleteBatch = @DeleteBatchRAPS_MOR_Combined,
                                                                    @RowCount = @RowCount_OUT OUTPUT,
                                                                    @Debug = 0;


                SET @RefreshDate = GETDATE();
                UPDATE [m]
                SET [m].[EDate] = @RefreshDate,
                    [m].[AdditionalRows] = @RowCount_OUT
                FROM [rev].[tbl_Summary_RskAdj_Activity] [m]
                WHERE [m].[tbl_Summary_RskAdj_ActivityId] = @tbl_Summary_RskAdj_ActivityIdSecondary; -- Summary 2.5

                SET @tbl_Summary_RskAdj_ActivityIdSecondary = NULL;

                IF @Debug = 1
                BEGIN

                    SELECT [LoadSummaryPartDRskAdjRAPSMORDCombined] = @RowCount_OUT;

                    EXEC [dbo].[PerfLogMonitor] @Section = '008',
                                                @ProcessName = @ProcessNameIn,
                                                @ET = @ET,
                                                @MasterET = @MasterET,
                                                @ET_Out = @ET OUT,
                                                @TableOutput = 0,
                                                @End = 0;
                END;
            END;
            ----EDS START 
            IF @EDS_FLAG = 1
            BEGIN
                IF @Debug = 1
                BEGIN
                    EXEC [dbo].[PerfLogMonitor] @Section = '009',
                                                @ProcessName = @ProcessNameIn,
                                                @ET = @ET,
                                                @MasterET = @MasterET,
                                                @ET_Out = @ET OUT,
                                                @TableOutput = 0,
                                                @End = 0;
                END;

                SET @RowCount_OUT = NULL;

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
                       [Process] = '[rev].[LoadSummaryPartDRskAdjEDSPreliminary]',
                       [BDate] = GETDATE(),
                       [EDate] = NULL,
                       [AdditionalRows] = NULL,
                       [RunBy] = USER_NAME();

                SET @tbl_Summary_RskAdj_ActivityIdSecondary = SCOPE_IDENTITY();

                SET @RowCount_OUT = 0;

                EXEC [rev].[LoadSummaryPartDRskAdjEDSPreliminary] @FullRefresh = 0,
                                                                  @YearRefresh = NULL,
                                                                  @LoadDateTime = @ET,
                                                                  @RowCount = @RowCount_OUT OUTPUT,
                                                                  @Debug = 0;

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
                    SELECT [LoadSummaryPartDRskAdjEDSPreliminary] = @RowCount_OUT;

                    EXEC [dbo].[PerfLogMonitor] @Section = '011',
                                                @ProcessName = @ProcessNameIn,
                                                @ET = @ET,
                                                @MasterET = @MasterET,
                                                @ET_Out = @ET OUT,
                                                @TableOutput = 0,
                                                @End = 0;
                END;

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
                       [Process] = '[rev].[LoadSummaryPartDRskAdjEDS]',
                       [BDate] = GETDATE(),
                       [EDate] = NULL,
                       [AdditionalRows] = NULL,
                       [RunBy] = USER_NAME();

                SET @tbl_Summary_RskAdj_ActivityIdSecondary = SCOPE_IDENTITY();

                SET @RowCount_OUT = 0;

                EXEC [rev].[LoadSummaryPartDRskAdjEDS] @LoadDateTime = @ET,
                                                       @DeleteBatch = @DeleteBatchEDS,
                                                       @RowCount = @RowCount_OUT OUTPUT,
                                                       @Debug = 0;

                SET @RefreshDate = GETDATE();
                UPDATE [m]
                SET [m].[EDate] = @RefreshDate,
                    [m].[AdditionalRows] = @RowCount_OUT
                FROM [rev].[tbl_Summary_RskAdj_Activity] [m]
                WHERE [m].[tbl_Summary_RskAdj_ActivityId] = @tbl_Summary_RskAdj_ActivityIdSecondary; -- Summary 2.5

                --update [m]
                --set [m].[EDate] = getdate()
                --  , [m].[AdditionalRows] = @RowCount_OUT
                --from [rev].[tbl_Summary_RskAdj_Activity] [m]
                --where [m].[tbl_Summary_RskAdj_ActivityId] = @tbl_Summary_RskAdj_ActivityIdSecondary

                SET @tbl_Summary_RskAdj_ActivityIdSecondary = NULL;

                IF @Debug = 1
                BEGIN
                    SELECT [LoadSummaryPartDRskAdjEDS] = @RowCount_OUT;

                    EXEC [dbo].[PerfLogMonitor] @Section = '012',
                                                @ProcessName = @ProcessNameIn,
                                                @ET = @ET,
                                                @MasterET = @MasterET,
                                                @ET_Out = @ET OUT,
                                                @TableOutput = 0,
                                                @End = 0;
                END;

            END;

            ---EDS END 
            --update [m]
            --set [m].[EDate] = getdate()
            --from [rev].[tbl_Summary_RskAdj_Activity] [m]
            --where [m].[tbl_Summary_RskAdj_ActivityId] = @tbl_Summary_RskAdj_ActivityIdSecondary
            SET @RowCount_OUT = 0;
            SET @RefreshDate = GETDATE();
            UPDATE [m]
            SET [m].[EDate] = @RefreshDate,
                [m].[AdditionalRows] = @RowCount_OUT
            FROM [rev].[tbl_Summary_RskAdj_Activity] [m]
            WHERE [m].[tbl_Summary_RskAdj_ActivityId] = @tbl_Summary_RskAdj_ActivityIdSecondary; -- Summary 2.5


            SET @tbl_Summary_RskAdj_ActivityIdSecondary = NULL;

            IF @Debug = 1
            BEGIN
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
                EXEC [dbo].[PerfLogMonitor] @Section = '015',
                                            @ProcessName = @ProcessNameIn,
                                            @ET = @ET,
                                            @MasterET = @MasterET,
                                            @ET_Out = @ET OUT,
                                            @TableOutput = 0,
                                            @End = 0;
            END;
        END;
    /*Update Statistics for MOR RAPS and EDS*/
    --update statistics [rev].[SummaryPartDRskAdjMORD]

    --update statistics [rev].[SummaryPartDRskAdjRAPSPreliminary]

    --update statistics [rev].[SummaryPartDRskAdjRAPS]

    --update statistics [rev].[SummaryPartDRskAdjEDSPreliminary]

    --update statistics [rev].[SummaryPartDRskAdjEDS]

    --update statistics [rev].[SummaryPartDRskAdjRAPSMORDCombined]
    END;



    SKIPEXECSPR_SUMMARY_RSKADJ_ALTHICN_MMR_MOR_RAPS:

    IF @Mode IN ( 2 )
    BEGIN
        IF @Mode = 2
        BEGIN
            IF @Debug = 1
            BEGIN
                EXEC [dbo].[PerfLogMonitor] @Section = '016',
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

        END;

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

        /*B IX Rebuild */
        DECLARE @ParaSortInTemp BIT = 0;
        DECLARE @ParaOnline BIT = 0;

        SET @tbl_Summary_RskAdj_ActivityIdSecondary = SCOPE_IDENTITY();

        SET @ParaSortInTemp = CASE
                                  WHEN DATEPART(hh, GETDATE()) >= @BBusinessHours
                                       AND DATEPART(hh, GETDATE()) <= @EBusinessHours THEN
                                      1
                                  ELSE
                                      0
                              END;

        SET @ParaOnline = CASE
                              WHEN DATEPART(hh, GETDATE()) >= @BBusinessHours
                                   AND DATEPART(hh, GETDATE()) <= @EBusinessHours THEN
                                  1
                              ELSE
                                  0
                          END;

        /*-B Rebuild/Defrag IX for rev.tbl_Summary_RskAdj_MOR */

        IF @MOR_FLAG = 1
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
                   [Process] = '[dbo].[spr_RebuildIndexesByTable] @TableName=[rev].[SummaryPartDRskAdjMORD]',
                   [BDate] = GETDATE(),
                   [EDate] = NULL,
                   [AdditionalRows] = NULL,
                   [RunBy] = USER_NAME();

            SET @tbl_Summary_RskAdj_ActivityIdSecondary = SCOPE_IDENTITY();

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

            EXEC [dbo].[spr_RebuildIndexesByTable] @SchemaName = 'rev',
                                                   @TableName = 'SummaryPartDRskAdjMORD',
                                                   @SortInTemp = @ParaSortInTemp,
                                                   @Online = @ParaOnline;

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

            UPDATE [m]
            SET [m].[EDate] = GETDATE()
            FROM [rev].[tbl_Summary_RskAdj_Activity] [m]
            WHERE [m].[tbl_Summary_RskAdj_ActivityId] = @tbl_Summary_RskAdj_ActivityIdSecondary;

            SET @tbl_Summary_RskAdj_ActivityIdSecondary = NULL;

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

        END;

        /*-E Rebuild/Defrag IX for rev.tbl_Summary_RskAdj_MOR */

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

        /*-B Rebuild/Defrag IX for rev.tbl_Summary_RskAdj_RAPS */

        IF @RAPS_FLAG = 1
        BEGIN
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

            /*********************************************************************/
            /* ReIndex tbl_Summary Raps  Preliminary                             */
            /*********************************************************************/
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
                   [Process] = '[dbo].[spr_RebuildIndexesByTable] @TableName=[rev].[SummaryPartDRskAdjRAPSPreliminary]',
                   [BDate] = GETDATE(),
                   [EDate] = NULL,
                   [AdditionalRows] = NULL,
                   [RunBy] = USER_NAME();

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
                                                   @TableName = 'SummaryPartDRskAdjRAPSPreliminary',
                                                   @SortInTemp = @ParaSortInTemp,
                                                   @Online = @ParaOnline;

            UPDATE [m]
            SET [m].[EDate] = GETDATE()
            FROM [rev].[tbl_Summary_RskAdj_Activity] [m]
            WHERE [m].[tbl_Summary_RskAdj_ActivityId] = @tbl_Summary_RskAdj_ActivityIdSecondary;

            SET @tbl_Summary_RskAdj_ActivityIdSecondary = NULL;

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

            /*********************************************************************/
            /* ReIndex tbl_Summary Raps                                          */
            /*********************************************************************/

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
                   [Process] = '[dbo].[spr_RebuildIndexesByTable] @TableName=[rev].[SummaryPartDRskAdjRAPS]',
                   [BDate] = GETDATE(),
                   [EDate] = NULL,
                   [AdditionalRows] = NULL,
                   [RunBy] = USER_NAME();

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

            SET @tbl_Summary_RskAdj_ActivityIdSecondary = SCOPE_IDENTITY();

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

            EXEC [dbo].[spr_RebuildIndexesByTable] @SchemaName = 'rev',
                                                   @TableName = 'SummaryPartDRskAdjRAPS',
                                                   @SortInTemp = @ParaSortInTemp,
                                                   @Online = @ParaOnline;

            UPDATE [m]
            SET [m].[EDate] = GETDATE()
            FROM [rev].[tbl_Summary_RskAdj_Activity] [m]
            WHERE [m].[tbl_Summary_RskAdj_ActivityId] = @tbl_Summary_RskAdj_ActivityIdSecondary;

            SET @tbl_Summary_RskAdj_ActivityIdSecondary = NULL;

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

            /****************************************************************************/
            /* ReIndex RAPS MOR Combined                                                */
            /****************************************************************************/

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
                   [Process] = '[dbo].[spr_RebuildIndexesByTable] @TableName=[rev].[SummaryPartDRskAdjRAPSMORDCombined]',
                   [BDate] = GETDATE(),
                   [EDate] = NULL,
                   [AdditionalRows] = NULL,
                   [RunBy] = USER_NAME();

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

            SET @tbl_Summary_RskAdj_ActivityIdSecondary = SCOPE_IDENTITY();

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

            EXEC [dbo].[spr_RebuildIndexesByTable] @SchemaName = 'rev',
                                                   @TableName = 'SummaryPartDRskAdjRAPSMORDCombined',
                                                   @SortInTemp = @ParaSortInTemp,
                                                   @Online = @ParaOnline;

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

            UPDATE [m]
            SET [m].[EDate] = GETDATE()
            FROM [rev].[tbl_Summary_RskAdj_Activity] [m]
            WHERE [m].[tbl_Summary_RskAdj_ActivityId] = @tbl_Summary_RskAdj_ActivityIdSecondary;

            SET @tbl_Summary_RskAdj_ActivityIdSecondary = NULL;

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
        END;


        /*-E Rebuild/Defrag IX for rev.tbl_Summary_RskAdj_RAPS */

        --EDS Start 

        /*-B Rebuild/Defrag IX for rev.tbl_Summary_RskAdj_EDS */
        IF @EDS_FLAG = 1
        BEGIN
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

            /*********************************************************************/
            /* ReIndex tbl_Summary EDS  Preliminary                             */
            /*********************************************************************/
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
                   [Process] = '[dbo].[spr_RebuildIndexesByTable] @TableName=[rev].[SummaryPartDRskAdjEDSPreliminary]',
                   [BDate] = GETDATE(),
                   [EDate] = NULL,
                   [AdditionalRows] = NULL,
                   [RunBy] = USER_NAME();

            IF @Debug = 1
            BEGIN
                EXEC [dbo].[PerfLogMonitor] @Section = '035',
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
                EXEC [dbo].[PerfLogMonitor] @Section = '036',
                                            @ProcessName = @ProcessNameIn,
                                            @ET = @ET,
                                            @MasterET = @MasterET,
                                            @ET_Out = @ET OUT,
                                            @TableOutput = 0,
                                            @End = 0;
            END;

            EXEC [dbo].[spr_RebuildIndexesByTable] @SchemaName = 'rev',
                                                   @TableName = 'SummaryPartDRskAdjEDSPreliminary',
                                                   @SortInTemp = @ParaSortInTemp,
                                                   @Online = @ParaOnline;

            UPDATE [m]
            SET [m].[EDate] = GETDATE()
            FROM [rev].[tbl_Summary_RskAdj_Activity] [m]
            WHERE [m].[tbl_Summary_RskAdj_ActivityId] = @tbl_Summary_RskAdj_ActivityIdSecondary;

            SET @tbl_Summary_RskAdj_ActivityIdSecondary = NULL;

            IF @Debug = 1
            BEGIN
                EXEC [dbo].[PerfLogMonitor] @Section = '037',
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
                   [Process] = '[dbo].[spr_RebuildIndexesByTable] @TableName=[rev].[SummaryPartDRskAdjEDS]',
                   [BDate] = GETDATE(),
                   [EDate] = NULL,
                   [AdditionalRows] = NULL,
                   [RunBy] = USER_NAME();

            IF @Debug = 1
            BEGIN
                EXEC [dbo].[PerfLogMonitor] @Section = '038',
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
                EXEC [dbo].[PerfLogMonitor] @Section = '039',
                                            @ProcessName = @ProcessNameIn,
                                            @ET = @ET,
                                            @MasterET = @MasterET,
                                            @ET_Out = @ET OUT,
                                            @TableOutput = 0,
                                            @End = 0;
            END;

            EXEC [dbo].[spr_RebuildIndexesByTable] @SchemaName = 'rev',
                                                   @TableName = 'SummaryPartDRskAdjEDS',
                                                   @SortInTemp = @ParaSortInTemp,
                                                   @Online = @ParaOnline;

            UPDATE [m]
            SET [m].[EDate] = GETDATE()
            FROM [rev].[tbl_Summary_RskAdj_Activity] [m]
            WHERE [m].[tbl_Summary_RskAdj_ActivityId] = @tbl_Summary_RskAdj_ActivityIdSecondary;

            SET @tbl_Summary_RskAdj_ActivityIdSecondary = NULL;

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


        END;

        /*-E Rebuild/Defrag IX for rev.tbl_Summary_RskAdj_EDS */

        --EDS END 


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
    /*E IX Rebuild */
    END;


    /*B Update Activity Logging  */

    UPDATE [m]
    SET [m].[EDate] = GETDATE()
    FROM [rev].[tbl_Summary_RskAdj_Activity] [m]
    WHERE [m].[tbl_Summary_RskAdj_ActivityId] = @tbl_Summary_RskAdj_ActivityIdMain
          AND [m].[Process] LIKE 'Part D Summary Process%';




/*E Update Activity Logging */


END;