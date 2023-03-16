CREATE PROCEDURE [rev].[WrapperSummaryAltHICNMMR] @Debug BIT = 0
AS
/************************************************************************************************************/
/* Name				:	[rev].[spr_Summary_RskAdj_Summarize_Base_Tables]     	    						*/
/* Type 			:	Stored Procedure																	*/
/* Author       	:	Madhuri Suri    																	*/
/* Date				:																			        	*/
/* Version			:																						*/
/* Description		:	Wrapper procedure invokes the Summary AltHICN and MMR  								*/
/*																											*/
/* Version History :																						*/
/* =================																						*/
/* Author				Date		Version#    TFS Ticket#		Description								    */
/* -----------------	----------  --------    -----------		------------								*/
/* Madhuri Suri      2018-09-24     2.0         76879           Summary 2.5 Changes                         */
/* David Waddell	 2019-09-30     2.1			76913 (RE-6557) Remove all reference to update statistics   */
/*                                                              in Summary Stored Procedure                 */
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
    DECLARE @tbl_Summary_RskAdj_ActivityIdMain INT;
    DECLARE @tbl_Summary_RskAdj_ActivityIdSecondary INT;
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

    SET @Curr_DB =
    (
        SELECT [Current Database] = DB_NAME()
    );
    SET @Clnt_DB = SUBSTRING(@Curr_DB, 0, CHARINDEX('_Report', @Curr_DB));

    SET @tbl_Summary_RskAdj_ActivityIdMain =
    (
        SELECT MAX(GroupingId) FROM rev.[tbl_Summary_RskAdj_Activity]
    );

    DECLARE @MMR_FLAG BIT =
            (
                SELECT Runflag FROM rev.SummaryProcessRunFlag WHERE Process = 'MMR'
            ),
            @ALT_HICN BIT =
            (
                SELECT Runflag FROM rev.SummaryProcessRunFlag WHERE Process = 'AltHICN'
            );



    IF @Mode IN ( 0, 1 )
    BEGIN
        /*B  */
        IF @MMR_FLAG = 0
           AND @ALT_HICN = 0
        BEGIN

            GOTO SkipEXECspr_Summary_RskAdj_AltHICN_MMR_MOR_RAPS;

        END;
        ELSE
        BEGIN

            /*Update Statistics for AltHICN and MMR*/
            --UPDATE STATISTICS [rev].[tbl_Summary_RskAdj_AltHICN]

            --UPDATE STATISTICS [rev].[tbl_Summary_RskAdj_MMR]

            /***********************************************************************/
            /*Step 02 Populates [rev].[tbl_Summary_RskAdj_AltHICN]                */
            /**********************************************************************/

            IF @ALT_HICN = 1
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
                       [Process] = '[rev].[spr_Summary_RskAdj_AltHICN]',
                       [BDate] = GETDATE(),
                       [EDate] = NULL,
                       [AdditionalRows] = 0,
                       [RunBy] = USER_NAME();


                SET @tbl_Summary_RskAdj_ActivityIdSecondary = SCOPE_IDENTITY();

                EXEC [rev].[spr_Summary_RskAdj_AltHICN] @LoadDateTime = @ET,
                                                        @DeleteBatch = @DeleteBatchAltHICN,
                                                        @RowCount = @RowCount_OUT OUTPUT,
                                                        @Debug = 0;

                SET @AltHICN_RowCount = @RowCount_OUT;
                SET @RefreshDate = GETDATE();
                UPDATE [m]
                SET [m].[EDate] = @RefreshDate, --
                    [m].[AdditionalRows] = @AltHICN_RowCount
                FROM [rev].[tbl_Summary_RskAdj_Activity] [m]
                WHERE [m].[tbl_Summary_RskAdj_ActivityId] = @tbl_Summary_RskAdj_ActivityIdSecondary;

                UPDATE [m]
                SET [m].[LastRefreshDate] = @RefreshDate
                FROM [rev].[SummaryProcessRunFlag] [m]
                WHERE [m].[Process] = 'AltHICN';
                ---- Summary 2.5


                SET @tbl_Summary_RskAdj_ActivityIdSecondary = NULL;

                IF @Debug = 1
                BEGIN
                    SELECT [spr_Summary_RskAdj_AltHICN] = @RowCount_OUT;
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

            /***************************************************************************************/
            /* Step 03 Uses [rev].[tbl_Summary_RskAdj_AltHICN] and [rev].[tbl_Summary_RskAdj_MMR]  */
            /* Populates [rev].[tbl_Summary_RskAdj_MOR]                                            */
            /***************************************************************************************/
            IF @MMR_FLAG = 1
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
                       [Process] = '[rev].[spr_Summary_RskAdj_MMR]',
                       [BDate] = GETDATE(),
                       [EDate] = NULL,
                       [AdditionalRows] = 0,
                       [RunBy] = USER_NAME();

                SET @tbl_Summary_RskAdj_ActivityIdSecondary = SCOPE_IDENTITY();

                EXEC [rev].[spr_Summary_RskAdj_MMR] @FullRefresh = NULL,
                                                    @YearRefresh = NULL,
                                                    @LoadDateTime = @ET,
                                                    @DeleteBatch = @DeleteBatchMMR,
                                                    @RowCount = @RowCount_OUT OUTPUT,
                                                    @Debug = 0;

                SET @MMR_RowCount = @RowCount_OUT;
                SET @RefreshDate = GETDATE();
                UPDATE [m]
                SET [m].[EDate] = @RefreshDate,
                    [m].[AdditionalRows] = @MMR_RowCount
                FROM [rev].[tbl_Summary_RskAdj_Activity] [m]
                WHERE [m].[tbl_Summary_RskAdj_ActivityId] = @tbl_Summary_RskAdj_ActivityIdSecondary;

                UPDATE [m]
                SET [m].[LastRefreshDate] = @RefreshDate
                FROM [rev].[SummaryProcessRunFlag] [m]
                WHERE [m].[Process] = 'MMR'; -- Summary 2.5

                SET @tbl_Summary_RskAdj_ActivityIdSecondary = NULL;

                IF @Debug = 1
                BEGIN
                    SELECT [spr_Summary_RskAdj_MMR] = @RowCount_OUT;
                END;

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


            END;


        /*Update Statistics for AltHICN BEGIN and MMR*/
        --UPDATE STATISTICS [rev].[tbl_Summary_RskAdj_AltHICN]

        --UPDATE STATISTICS [rev].[tbl_Summary_RskAdj_MMR]


        END;
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

            SET @ALT_HICN = 1;
            SET @MMR_FLAG = 1;

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



        /*-B Rebuild/Defrag IX for rev.tbl_Summary_RskAdj_AltHICN */
        IF @ALT_HICN = 1
        BEGIN

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
                   [Process] = '[dbo].[spr_RebuildIndexesByTable] @TableName=[rev].[tbl_Summary_RskAdj_AltHICN]',
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
                                                   @TableName = 'tbl_Summary_RskAdj_AltHICN',
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

        /*-E Rebuild/Defrag IX for rev.tbl_Summary_RskAdj_AltHICN */

        /*-B Rebuild/Defrag IX for rev.tbl_Summary_RskAdj_MMR */

        IF @MMR_FLAG = 1
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
                   [Process] = '[dbo].[spr_RebuildIndexesByTable] @TableName=[rev].[tbl_Summary_RskAdj_MMR]',
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
                                                   @TableName = 'tbl_Summary_RskAdj_MMR',
                                                   @SortInTemp = @ParaSortInTemp,
                                                   @Online = @ParaOnline;

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

            UPDATE [m]
            SET [m].[EDate] = GETDATE()
            FROM [rev].[tbl_Summary_RskAdj_Activity] [m]
            WHERE [m].[tbl_Summary_RskAdj_ActivityId] = @tbl_Summary_RskAdj_ActivityIdSecondary;

            SET @tbl_Summary_RskAdj_ActivityIdSecondary = NULL;

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

        END;

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

    /*-E Rebuild/Defrag IX for rev.tbl_Summary_RskAdj_MMR */

    END;


END;