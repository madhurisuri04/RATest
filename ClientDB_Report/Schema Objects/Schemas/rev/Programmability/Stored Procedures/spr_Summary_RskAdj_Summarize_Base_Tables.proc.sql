CREATE PROCEDURE [rev].[spr_Summary_RskAdj_Summarize_Base_Tables]
    @YearRefresh INT = NULL,
    @ForceAltHICN BIT = 0,
    @ForceMMR BIT = 0,
    @ForceMOR BIT = 0,
    @ForceRAPS BIT = 0,
    @ForceEDS BIT = 0,
    @Debug BIT = 0
AS --
/************************************************************************************************************/
/* Name				:	[rev].[spr_Summary_RskAdj_Summarize_Base_Tables]     	    						*/
/* Type 			:	Stored Procedure																	*/
/* Author       	:	David Waddell    																	*/
/* Date				:	02/02/2017																			*/
/* Version			:																						*/
/* Description		:	Wrapper procedure invokes the Summary 2.0 modules   								*/
/*																											*/
/* Version History :																						*/
/* =================																						*/
/* Author				Date		Version#    TFS Ticket#		Description								    */
/* -----------------	----------  --------    -----------		------------								*/
/* David Waddell		02/12/2017	1.1			58112			Set Flags for ALT_HICN, MMR, MOR and		*/
/*																RAPS to be refereshed based on rollup		*/
/*																tables refresh								*/
/* Mitch Casto			2017-03-27	1.2			63302/US63790	-Added @YearRefresh parameter. This will	*/
/*																allow the stp to be run outside of the job	*/
/*																for a specific payment year. If set to null	*/
/*																then the stp will run for all years.		*/
/*																-Added @Force... parameters. This will allow*/
/*																for running of specific process outside the */
/*																of the rollup driven processes.  Note: When */
/*																used all the rollup driven processes will	*/
/*																not run.									*/
/*																											*/
/* D.Waddell          2017-09-18  1.3         66947/ RE-1111    Update to include EDS process to Summary Run*/
/* D.Waddell		  10/29/2019  1.4		  RE-6981			Set Transaction Isolation Level Read to    */
/*                                                              Uncommitted                                */
/************************************************************************************************************/
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

    /*B Initialize Activity Logging */
    DECLARE @tbl_Summary_RskAdj_ActivityIdMain INT;
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
           [Process] = 'Summary Process' + CASE
                                               WHEN @YearRefresh IS NOT NULL THEN
                                                   ' (PY ' + LTRIM(RTRIM(CAST(@YearRefresh AS VARCHAR(11)))) + ' Only)'
                                               ELSE
                                                   ''
                                           END,
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

    /* B Initialize Performance Logging  */
    IF @Debug = 1
    BEGIN
        SET STATISTICS IO ON;

        DECLARE @ET DATETIME;
        DECLARE @MasterET DATETIME;
        DECLARE @ProcessNameIn VARCHAR(128);
        DECLARE @MOR_LastUpdated DATETIME = NULL;
        DECLARE @MMR_LastUpdated DATETIME = NULL;
        DECLARE @AltHICN_LastUpdated DATETIME = NULL;
        DECLARE @RAPS_LastUpdated DATETIME = NULL;
        DECLARE @EDS_LastUpdated DATETIME = NULL;
        DECLARE @EDSloaddateSQL VARCHAR(MAX);
        DECLARE @EDSloaddate DATETIME;

        SET @ET = GETDATE();
        SET @MasterET = @ET;
        SET @ProcessNameIn = OBJECT_NAME(@@PROCID);

        EXEC [dbo].[PerfLogMonitor] @Section = '000',
                                    @ProcessName = @ProcessNameIn,
                                    @ET = @ET,
                                    @MasterET = @MasterET,
                                    @ET_Out = @ET OUT,
                                    @TableOutput = 0,
                                    @End = 0;
    END;

    /* E Initialize Performance Logging   */

    /*B Get table driven configuration variables */
    DECLARE @Mode TINYINT;
    DECLARE @BBusinessHours TINYINT;
    DECLARE @EBusinessHours TINYINT;

    DECLARE @DeleteBatchAltHICN INT;
    DECLARE @DeleteBatchMMR INT;
    DECLARE @DeleteBatchMOR INT;
    DECLARE @DeleteBatchRAPS_Preliminary INT;
    DECLARE @DeleteBatchRAPS INT;
    DECLARE @DeleteBatchRAPS_MOR_Combined INT;
    DECLARE @DeleteBatchEDS_Preliminary INT; --MSTest
    DECLARE @DeleteBatchEDS INT; --MSTest


    DECLARE @RowCount_OUT INT = 0;
    DECLARE @AltHICN_RowCount INT = 0;
    DECLARE @MMR_RowCount INT = 0;
    DECLARE @MOR_RowCount INT = 0;
    DECLARE @RAPS_RowCount INT = 0;
    DECLARE @EDS_RowCount INT = 0; -- MSTEST
    DECLARE @Curr_DB VARCHAR(128) = NULL;
    DECLARE @Clnt_DB VARCHAR(128) = NULL;

    SET @Curr_DB =
    (
        SELECT [Current Database] = DB_NAME()
    );
    SET @Clnt_DB = SUBSTRING(@Curr_DB, 0, CHARINDEX('_Report', @Curr_DB));

    SET @MMR_LastUpdated =
    (
        SELECT MAX([EDate])
        FROM [rev].[tbl_Summary_RskAdj_Activity]
        WHERE [Process] = '[rev].[spr_Summary_RskAdj_MMR]'
    );

    SET @MMR_LastUpdated = ISNULL((@MMR_LastUpdated), DATEADD(dd, -1, GETDATE()));

    SET @MOR_LastUpdated =
    (
        SELECT MAX([EDate])
        FROM [rev].[tbl_Summary_RskAdj_Activity]
        WHERE [Process] = '[rev].[spr_Summary_RskAdj_MOR]'
    );

    SET @MOR_LastUpdated = ISNULL((@MOR_LastUpdated), DATEADD(dd, -1, GETDATE()));


    SET @AltHICN_LastUpdated =
    (
        SELECT MAX([EDate])
        FROM [rev].[tbl_Summary_RskAdj_Activity]
        WHERE [Process] = '[rev].[spr_Summary_RskAdj_AltHICN]'
    );

    SET @AltHICN_LastUpdated = ISNULL((@AltHICN_LastUpdated), DATEADD(dd, -1, GETDATE()));


    SET @RAPS_LastUpdated =
    (
        SELECT MAX([EDate])
        FROM [rev].[tbl_Summary_RskAdj_Activity]
        WHERE [Process] = '[rev].[spr_Summary_RskAdj_RAPS]'
    );

    SET @RAPS_LastUpdated = ISNULL((@RAPS_LastUpdated), DATEADD(dd, -1, GETDATE()));

    --EDS 
    SET @EDS_LastUpdated =
    (
        SELECT MAX([EDate])
        FROM [rev].[tbl_Summary_RskAdj_Activity]
        WHERE [Process] = '[rev].[spr_Summary_RskAdj_EDS]'
    );

    SET @EDS_LastUpdated = ISNULL((@EDS_LastUpdated), DATEADD(dd, -1, GETDATE())); -- MSTest


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

    /*
      Step 01
      Populates [rev].[tbl_Summary_RskAdj_RefreshPY]
      */

    EXEC [rev].[spr_Summary_RskAdj_RefreshPY] @FullRefresh = 0,
                                              @YearRefresh = @YearRefresh,
                                              @Debug = 0;

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

    SELECT TOP 1
           @DeleteBatchAltHICN = CAST([a1].[Value] AS INT)
    FROM [rev].[tbl_Summary_RskAdj_Config] [a1] WITH (NOLOCK)
    WHERE [a1].[Variable] = '@DeleteBatchAltHICN';

    SELECT TOP 1
           @DeleteBatchMMR = CAST([a1].[Value] AS INT)
    FROM [rev].[tbl_Summary_RskAdj_Config] [a1] WITH (NOLOCK)
    WHERE [a1].[Variable] = '@DeleteBatchMMR';

    SELECT TOP 1
           @DeleteBatchMOR = CAST([a1].[Value] AS INT)
    FROM [rev].[tbl_Summary_RskAdj_Config] [a1] WITH (NOLOCK)
    WHERE [a1].[Variable] = '@DeleteBatchMOR';

    SELECT TOP 1
           @DeleteBatchRAPS_Preliminary = CAST([a1].[Value] AS INT)
    FROM [rev].[tbl_Summary_RskAdj_Config] [a1] WITH (NOLOCK)
    WHERE [a1].[Variable] = '@DeleteBatchRAPS_Preliminary';

    SELECT TOP 1
           @DeleteBatchRAPS = CAST([a1].[Value] AS INT)
    FROM [rev].[tbl_Summary_RskAdj_Config] [a1] WITH (NOLOCK)
    WHERE [a1].[Variable] = '@DeleteBatchRAPS';

    SELECT TOP 1
           @DeleteBatchRAPS_MOR_Combined = CAST([a1].[Value] AS INT)
    FROM [rev].[tbl_Summary_RskAdj_Config] [a1] WITH (NOLOCK)
    WHERE [a1].[Variable] = '@DeleteBatchRAPS_MOR_Combined';

    --EDS 

    SELECT TOP 1
           @DeleteBatchEDS_Preliminary = CAST([a1].[Value] AS INT)
    FROM [rev].[tbl_Summary_RskAdj_Config] [a1] WITH (NOLOCK)
    WHERE [a1].[Variable] = '@DeleteBatchEDS_Preliminary';

    SELECT TOP 1
           @DeleteBatchEDS = CAST([a1].[Value] AS INT)
    FROM [rev].[tbl_Summary_RskAdj_Config] [a1] WITH (NOLOCK)
    WHERE [a1].[Variable] = '@DeleteBatchEDS'; --MSTest


    /*E Get table driven configuration variables */

    /*B Set Defaults if configuration values are not available */

    SET @Mode = ISNULL(@Mode, 0);
    SET @BBusinessHours = ISNULL(@BBusinessHours, 7);
    SET @EBusinessHours = ISNULL(@EBusinessHours, 20);


    IF @Debug = 1
    BEGIN
        PRINT '/*B Configuration Settings */';
        PRINT '@Mode = ' + ISNULL(CAST(@Mode AS VARCHAR(11)), 'NULL');
        PRINT '@BBusinessHours = ' + ISNULL(CAST(@BBusinessHours AS VARCHAR(11)), 'NULL');
        PRINT '@EBusinessHours = ' + ISNULL(CAST(@EBusinessHours AS VARCHAR(11)), 'NULL');
        PRINT '@DeleteBatchAltHICN = ' + ISNULL(CAST(@DeleteBatchAltHICN AS VARCHAR(11)), 'NULL --Default Value Used');
        PRINT '@DeleteBatchMMR = ' + ISNULL(CAST(@DeleteBatchMMR AS VARCHAR(11)), 'NULL --Default Value Used');
        PRINT '@DeleteBatchMOR = ' + ISNULL(CAST(@DeleteBatchMOR AS VARCHAR(11)), 'NULL --Default Value Used');
        PRINT '@DeleteBatchRAPS_Preliminary = '
              + ISNULL(CAST(@DeleteBatchRAPS_Preliminary AS VARCHAR(11)), 'NULL --Default Value Used');
        PRINT '@DeleteBatchRAPS = ' + ISNULL(CAST(@DeleteBatchRAPS AS VARCHAR(11)), 'NULL --Default Value Used');
        PRINT '@DeleteBatchRAPS_MOR_Combined =  '
              + ISNULL(CAST(@DeleteBatchRAPS_MOR_Combined AS VARCHAR(11)), 'NULL --Default Value Used');
        PRINT '@DeleteBatchEDS_Preliminary = '
              + ISNULL(CAST(@DeleteBatchEDS_Preliminary AS VARCHAR(11)), 'NULL --Default Value Used');
        PRINT '@DeleteBatchEDS = ' + ISNULL(CAST(@DeleteBatchEDS AS VARCHAR(11)), 'NULL --Default Value Used');
        PRINT '/*E Configuration Settings */';
        RAISERROR('', 0, 1) WITH NOWAIT;
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

    /*E Set Defaults if configuration values are not available */

    /*B Identify tables to be changed*/
    DECLARE @MMR_FLAG BIT = 0,
            @ALT_HICN BIT = 0,
            @MOR_FLAG BIT = 0,
            @RAPS_FLAG BIT = 0,
            @EDS_FLAG BIT = 0; --MSTest

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

    IF EXISTS
    (
        SELECT 1
        FROM [$(HRPInternalReportsDB)].[dbo].[RollupTableConfig] [conf]
            JOIN [$(HRPInternalReportsDB)].[dbo].[RollupTable] [tbl]
                ON [conf].[RollupTableID] = [tbl].[RollupTableID]
            JOIN [$(HRPInternalReportsDB)].[dbo].[RollupClient] [clnt]
                ON [conf].[ClientIdentifier] = [clnt].[ClientIdentifier]
            JOIN [$(HRPInternalReportsDB)].[dbo].[RollupTableStatus] [stat]
                ON [stat].[RollupTableConfigID] = [conf].[RollupTableConfigID]
            JOIN [$(HRPReporting)].[dbo].[tbl_Clients] [rptclnt]
                ON [rptclnt].[Client_Name] = [clnt].[ClientName]
        WHERE [rptclnt].[Report_DB] = DB_NAME()
              AND [tbl].[RollupTableName] IN ( 'tbl_Member_Months_rollup' )
              AND [stat].[RollupStatus] = 'Stable'
              AND [stat].[IndexBuildEnd] > @MMR_LastUpdated
    )
    BEGIN

        SET @MMR_FLAG = 1;
        SET @RAPS_FLAG = 1;
        SET @EDS_FLAG = 1;

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

    IF EXISTS
    (
        SELECT 1
        FROM [$(HRPInternalReportsDB)].[dbo].[RollupTableConfig] [conf]
            JOIN [$(HRPInternalReportsDB)].[dbo].[RollupTable] [tbl]
                ON [conf].[RollupTableID] = [tbl].[RollupTableID]
            JOIN [$(HRPInternalReportsDB)].[dbo].[RollupClient] [clnt]
                ON [conf].[ClientIdentifier] = [clnt].[ClientIdentifier]
            JOIN [$(HRPInternalReportsDB)].[dbo].[RollupTableStatus] [stat]
                ON [stat].[RollupTableConfigID] = [conf].[RollupTableConfigID]
            JOIN [$(HRPReporting)].[dbo].[tbl_Clients] [rptclnt]
                ON [rptclnt].[Client_Name] = [clnt].[ClientName]
        WHERE [rptclnt].[Report_DB] = DB_NAME()
              AND [tbl].[RollupTableName] IN ( 'tbl_ALTHICN_rollup' )
              AND [stat].[RollupStatus] = 'Stable'
              AND [stat].[IndexBuildEnd] > @AltHICN_LastUpdated
    )
    BEGIN

        SET @ALT_HICN = 1;
        SET @MMR_FLAG = 1;
        SET @RAPS_FLAG = 1;
        SET @EDS_FLAG = 1;

        IF @Debug = 1
        BEGIN
            EXEC [dbo].[PerfLogMonitor] @Section = '006',
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
        EXEC [dbo].[PerfLogMonitor] @Section = '007',
                                    @ProcessName = @ProcessNameIn,
                                    @ET = @ET,
                                    @MasterET = @MasterET,
                                    @ET_Out = @ET OUT,
                                    @TableOutput = 0,
                                    @End = 0;
    END;

    IF EXISTS
    (
        SELECT 1
        FROM [$(HRPInternalReportsDB)].[dbo].[RollupTableConfig] [conf]
            JOIN [$(HRPInternalReportsDB)].[dbo].[RollupTable] [tbl]
                ON [conf].[RollupTableID] = [tbl].[RollupTableID]
            JOIN [$(HRPInternalReportsDB)].[dbo].[RollupClient] [clnt]
                ON [conf].[ClientIdentifier] = [clnt].[ClientIdentifier]
            JOIN [$(HRPInternalReportsDB)].[dbo].[RollupTableStatus] [stat]
                ON [stat].[RollupTableConfigID] = [conf].[RollupTableConfigID]
            JOIN [$(HRPReporting)].[dbo].[tbl_Clients] [rptclnt]
                ON [rptclnt].[Client_Name] = [clnt].[ClientName]
        WHERE [rptclnt].[Report_DB] = DB_NAME()
              AND [tbl].[RollupTableName] IN ( 'Converted_MOR_Data_rollup' )
              AND [stat].[RollupStatus] = 'Stable'
              AND [stat].[IndexBuildEnd] > @MOR_LastUpdated
    )
    BEGIN

        SET @MOR_FLAG = 1;
        SET @RAPS_FLAG = 1;
        SET @EDS_FLAG = 1;

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

    IF EXISTS
    (
        SELECT 1
        FROM [$(HRPInternalReportsDB)].[dbo].[RollupTableConfig] [conf]
            JOIN [$(HRPInternalReportsDB)].[dbo].[RollupTable] [tbl]
                ON [conf].[RollupTableID] = [tbl].[RollupTableID]
            JOIN [$(HRPInternalReportsDB)].[dbo].[RollupClient] [clnt]
                ON [conf].[ClientIdentifier] = [clnt].[ClientIdentifier]
            JOIN [$(HRPInternalReportsDB)].[dbo].[RollupTableStatus] [stat]
                ON [stat].[RollupTableConfigID] = [conf].[RollupTableConfigID]
            JOIN [$(HRPReporting)].[dbo].[tbl_Clients] [rptclnt]
                ON [rptclnt].[Client_Name] = [clnt].[ClientName]
        WHERE [rptclnt].[Report_DB] = DB_NAME()
              AND [tbl].[RollupTableName] IN ( 'Raps_Accepted_rollup' )
              AND [stat].[RollupStatus] = 'Stable'
              AND [stat].[IndexBuildEnd] > @RAPS_LastUpdated
    )
    BEGIN

        SET @RAPS_FLAG = 1;

        IF @Debug = 1
        BEGIN
            EXEC [dbo].[PerfLogMonitor] @Section = '010',
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
        EXEC [dbo].[PerfLogMonitor] @Section = '010.1',
                                    @ProcessName = @ProcessNameIn,
                                    @ET = @ET,
                                    @MasterET = @MasterET,
                                    @ET_Out = @ET OUT,
                                    @TableOutput = 0,
                                    @End = 0;
    END;



    IF (OBJECT_ID('tempdb.dbo.[#EDSLoadDate]') IS NOT NULL)
        DROP TABLE [#EDSLoadDate];

    CREATE TABLE [#EDSLoadDate]
    (
        [Id] INT IDENTITY(1, 1) PRIMARY KEY,
        [LoadDate] DATETIME NULL
    );


    SET @EDSloaddateSQL
        = '
			 
					INSERT INTO #EDSLoadDate
					(LoadDate)
					SELECT top 1 LoadDate
						
					from ' + @Clnt_DB + '.dbo.MAO004Response m 
					ORDER BY m.LoadDate DESC';



    EXEC (@EDSloaddateSQL);

    IF @Debug = 1
    BEGIN
        EXEC [dbo].[PerfLogMonitor] @Section = '010.11',
                                    @ProcessName = @ProcessNameIn,
                                    @ET = @ET,
                                    @MasterET = @MasterET,
                                    @ET_Out = @ET OUT,
                                    @TableOutput = 0,
                                    @End = 0;
        PRINT '@EDSloaddateSQL : ';
        PRINT (@EDSloaddateSQL);
    END;

    SET @EDSloaddate =
    (
        SELECT LoadDate FROM [#EDSLoadDate]
    );

    IF @Debug = 1
    BEGIN
        EXEC [dbo].[PerfLogMonitor] @Section = '010.12',
                                    @ProcessName = @ProcessNameIn,
                                    @ET = @ET,
                                    @MasterET = @MasterET,
                                    @ET_Out = @ET OUT,
                                    @TableOutput = 0,
                                    @End = 0;
        PRINT '@EDSloaddate : ';
        PRINT CAST(@EDSloaddate AS VARCHAR);
    END;

    IF ((SELECT @EDSloaddate) > (SELECT @EDS_LastUpdated))
    BEGIN

        SET @EDS_FLAG = 1;

        IF @Debug = 1
        BEGIN
            EXEC [dbo].[PerfLogMonitor] @Section = '010.2',
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
        EXEC [dbo].[PerfLogMonitor] @Section = '011',
                                    @ProcessName = @ProcessNameIn,
                                    @ET = @ET,
                                    @MasterET = @MasterET,
                                    @ET_Out = @ET OUT,
                                    @TableOutput = 0,
                                    @End = 0;
    END;

    /* B If any @Force... flags are set to 1, then run only for the force flags */

    IF @ForceAltHICN = 1
       OR @ForceMMR = 1
       OR @ForceMOR = 1
       OR @ForceRAPS = 1
       OR @ForceEDS = 1
    BEGIN

        SET @ALT_HICN = @ForceAltHICN;
        SET @MMR_FLAG = @ForceMMR;
        SET @MOR_FLAG = @ForceMOR;
        SET @RAPS_FLAG = @ForceRAPS;
        SET @EDS_FLAG = @ForceEDS;

    END;

    /* E If any @Force... flags are set to 1, then run only for the force flags */

    IF @Debug = 1
    BEGIN
        EXEC [dbo].[PerfLogMonitor] @Section = '011.1',
                                    @ProcessName = @ProcessNameIn,
                                    @ET = @ET,
                                    @MasterET = @MasterET,
                                    @ET_Out = @ET OUT,
                                    @TableOutput = 0,
                                    @End = 0;
    END;

    /*E Identify tables to be changed*/

    IF @Mode IN ( 0, 1 )
    BEGIN
        /*B EXEC [rev].[spr_Summary_RskAdj_AltHICN_MMR_MOR_RAPS] */
        IF @MMR_FLAG = 0
           AND @ALT_HICN = 0
           AND @MOR_FLAG = 0
           AND @RAPS_FLAG = 0
           AND @EDS_FLAG = 0
        BEGIN

            IF @Debug = 1
            BEGIN
                EXEC [dbo].[PerfLogMonitor] @Section = '011.2',
                                            @ProcessName = @ProcessNameIn,
                                            @ET = @ET,
                                            @MasterET = @MasterET,
                                            @ET_Out = @ET OUT,
                                            @TableOutput = 0,
                                            @End = 0;
            END;

            GOTO SkipEXECspr_Summary_RskAdj_AltHICN_MMR_MOR_RAPS;

        END;
        ELSE
        BEGIN
            /***********************************************************************/
            /*Step 02 Populates [rev].[tbl_Summary_RskAdj_AltHICN]                */
            /**********************************************************************/
            IF @ALT_HICN = 1
            BEGIN
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

                UPDATE [m]
                SET [m].[EDate] = GETDATE(),
                    [m].[AdditionalRows] = @AltHICN_RowCount
                FROM [rev].[tbl_Summary_RskAdj_Activity] [m]
                WHERE [m].[tbl_Summary_RskAdj_ActivityId] = @tbl_Summary_RskAdj_ActivityIdSecondary;

                SET @tbl_Summary_RskAdj_ActivityIdSecondary = NULL;

                IF @Debug = 1
                BEGIN
                    SELECT [spr_Summary_RskAdj_AltHICN] = @RowCount_OUT;
                END;

                IF @Debug = 1
                BEGIN
                    EXEC [dbo].[PerfLogMonitor] @Section = '013',
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
                EXEC [dbo].[PerfLogMonitor] @Section = '014',
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
                    EXEC [dbo].[PerfLogMonitor] @Section = '015',
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

                UPDATE [m]
                SET [m].[EDate] = GETDATE(),
                    [m].[AdditionalRows] = @MMR_RowCount
                FROM [rev].[tbl_Summary_RskAdj_Activity] [m]
                WHERE [m].[tbl_Summary_RskAdj_ActivityId] = @tbl_Summary_RskAdj_ActivityIdSecondary;

                SET @tbl_Summary_RskAdj_ActivityIdSecondary = NULL;

                IF @Debug = 1
                BEGIN
                    SELECT [spr_Summary_RskAdj_MMR] = @RowCount_OUT;
                END;

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
                       [Process] = '[rev].[spr_Summary_RskAdj_MOR]',
                       [BDate] = GETDATE(),
                       [EDate] = NULL,
                       [AdditionalRows] = 0,
                       [RunBy] = USER_NAME();

                SET @tbl_Summary_RskAdj_ActivityIdSecondary = SCOPE_IDENTITY();

                EXEC [rev].[spr_Summary_RskAdj_MOR] @LoadDateTime = @ET,
                                                    @DeleteBatch = @DeleteBatchMOR,
                                                    @RowCount = @RowCount_OUT OUTPUT,
                                                    @Debug = 0;

                SET @MOR_RowCount = @RowCount_OUT;

                UPDATE [m]
                SET [m].[EDate] = GETDATE(),
                    [m].[AdditionalRows] = @MOR_RowCount
                FROM [rev].[tbl_Summary_RskAdj_Activity] [m]
                WHERE [m].[tbl_Summary_RskAdj_ActivityId] = @tbl_Summary_RskAdj_ActivityIdSecondary;

                SET @tbl_Summary_RskAdj_ActivityIdSecondary = NULL;

                IF @Debug = 1
                BEGIN
                    SELECT [spr_Summary_RskAdj_MOR] = @RowCount_OUT;
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

            END;

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

            /*****************************************************************************************************************************************************************************************/
            /* Step 04 Formally [rev].[spr_Summary_RskAdj_RAPS] Uses [rev].[spr_Summary_RskAdj_RefreshPY], [rev].[tbl_Summary_RskAdj_AltHICN] and [rev].[tbl_Summary_RskAdj_MMR]                    */
            /* Populates [rev].[tbl_Summary_RskAdj_RAPS_Preliminary]                                                                                                                                */
            /***************************************************************************************************************************************************************************************/
            IF @RAPS_FLAG = 1
            BEGIN
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
                       [Process] = '[rev].[spr_Summary_RskAdj_RAPS_Preliminary]',
                       [BDate] = GETDATE(),
                       [EDate] = NULL,
                       [AdditionalRows] = NULL,
                       [RunBy] = USER_NAME();

                SET @tbl_Summary_RskAdj_ActivityIdSecondary = SCOPE_IDENTITY();

                SET @RowCount_OUT = 0;

                EXEC [rev].[spr_Summary_RskAdj_RAPS_Preliminary] @FullRefresh = 0,
                                                                 @YearRefresh = NULL,
                                                                 @LoadDateTime = @ET,
                                                                 @DeleteBatch = @DeleteBatchRAPS_Preliminary,
                                                                 @RowCount = @RowCount_OUT OUTPUT,
                                                                 @Debug = 0;

                SET @RAPS_RowCount = @RowCount_OUT;

                UPDATE [m]
                SET [m].[EDate] = GETDATE(),
                    [m].[AdditionalRows] = @RowCount_OUT
                FROM [rev].[tbl_Summary_RskAdj_Activity] [m]
                WHERE [m].[tbl_Summary_RskAdj_ActivityId] = @tbl_Summary_RskAdj_ActivityIdSecondary;

                SET @tbl_Summary_RskAdj_ActivityIdSecondary = NULL;

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

                IF @Debug = 1
                BEGIN
                    SELECT [spr_Summary_RskAdj_RAPS_Preliminary] = @RowCount_OUT;

                    EXEC [dbo].[PerfLogMonitor] @Section = '023',
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
                       [Process] = '[rev].[spr_Summary_RskAdj_RAPS]',
                       [BDate] = GETDATE(),
                       [EDate] = NULL,
                       [AdditionalRows] = NULL,
                       [RunBy] = USER_NAME();

                SET @tbl_Summary_RskAdj_ActivityIdSecondary = SCOPE_IDENTITY();

                SET @RowCount_OUT = 0;

                EXEC [rev].[spr_Summary_RskAdj_RAPS] @LoadDateTime = @ET,
                                                     @DeleteBatch = @DeleteBatchRAPS,
                                                     @RowCount = @RowCount_OUT OUTPUT,
                                                     @Debug = 0;


                UPDATE [m]
                SET [m].[EDate] = GETDATE(),
                    [m].[AdditionalRows] = @RowCount_OUT
                FROM [rev].[tbl_Summary_RskAdj_Activity] [m]
                WHERE [m].[tbl_Summary_RskAdj_ActivityId] = @tbl_Summary_RskAdj_ActivityIdSecondary;

                SET @tbl_Summary_RskAdj_ActivityIdSecondary = NULL;

                IF @Debug = 1
                BEGIN
                    SELECT [spr_Summary_RskAdj_RAPS] = @RowCount_OUT;

                    EXEC [dbo].[PerfLogMonitor] @Section = '024',
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
                       [Process] = '[rev].[spr_Summary_RskAdj_RAPS_MOR_Combined]',
                       [BDate] = GETDATE(),
                       [EDate] = NULL,
                       [AdditionalRows] = NULL,
                       [RunBy] = USER_NAME();

                SET @tbl_Summary_RskAdj_ActivityIdSecondary = SCOPE_IDENTITY();

                SET @RowCount_OUT = 0;

                EXEC [rev].[spr_Summary_RskAdj_RAPS_MOR_Combined] @LoadDateTime = @ET,
                                                                  @DeleteBatch = @DeleteBatchRAPS_MOR_Combined,
                                                                  @RowCount = @RowCount_OUT OUTPUT,
                                                                  @Debug = 0;

                UPDATE [m]
                SET [m].[EDate] = GETDATE(),
                    [m].[AdditionalRows] = @RowCount_OUT
                FROM [rev].[tbl_Summary_RskAdj_Activity] [m]
                WHERE [m].[tbl_Summary_RskAdj_ActivityId] = @tbl_Summary_RskAdj_ActivityIdSecondary;

                SET @tbl_Summary_RskAdj_ActivityIdSecondary = NULL;

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
            END;
            ----EDS START 
            IF @EDS_FLAG = 1
            BEGIN
                IF @Debug = 1
                BEGIN
                    EXEC [dbo].[PerfLogMonitor] @Section = '025.1',
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
                       [Process] = '[rev].[spr_Summary_RskAdj_EDS_Preliminary]',
                       [BDate] = GETDATE(),
                       [EDate] = NULL,
                       [AdditionalRows] = NULL,
                       [RunBy] = USER_NAME();

                SET @tbl_Summary_RskAdj_ActivityIdSecondary = SCOPE_IDENTITY();

                SET @RowCount_OUT = 0;

                EXEC [rev].[spr_Summary_RskAdj_EDS_Preliminary] @FullRefresh = 0,
                                                                @YearRefresh = NULL,
                                                                @LoadDateTime = @ET,
                                                                @DeleteBatch = @DeleteBatchEDS_Preliminary,
                                                                @RowCount = @RowCount_OUT OUTPUT,
                                                                @Debug = 0;

                SET @EDS_RowCount = @RowCount_OUT;

                UPDATE [m]
                SET [m].[EDate] = GETDATE(),
                    [m].[AdditionalRows] = @RowCount_OUT
                FROM [rev].[tbl_Summary_RskAdj_Activity] [m]
                WHERE [m].[tbl_Summary_RskAdj_ActivityId] = @tbl_Summary_RskAdj_ActivityIdSecondary;

                SET @tbl_Summary_RskAdj_ActivityIdSecondary = NULL;

                IF @Debug = 1
                BEGIN
                    EXEC [dbo].[PerfLogMonitor] @Section = '025.2',
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

                    EXEC [dbo].[PerfLogMonitor] @Section = '025.3',
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
                       [Process] = '[rev].[spr_Summary_RskAdj_EDS]',
                       [BDate] = GETDATE(),
                       [EDate] = NULL,
                       [AdditionalRows] = NULL,
                       [RunBy] = USER_NAME();

                SET @tbl_Summary_RskAdj_ActivityIdSecondary = SCOPE_IDENTITY();

                SET @RowCount_OUT = 0;

                EXEC [rev].[spr_Summary_RskAdj_EDS] @LoadDateTime = @ET,
                                                    @DeleteBatch = @DeleteBatchEDS,
                                                    @RowCount = @RowCount_OUT OUTPUT,
                                                    @Debug = 0;


                UPDATE [m]
                SET [m].[EDate] = GETDATE(),
                    [m].[AdditionalRows] = @RowCount_OUT
                FROM [rev].[tbl_Summary_RskAdj_Activity] [m]
                WHERE [m].[tbl_Summary_RskAdj_ActivityId] = @tbl_Summary_RskAdj_ActivityIdSecondary;

                SET @tbl_Summary_RskAdj_ActivityIdSecondary = NULL;

                IF @Debug = 1
                BEGIN
                    SELECT [spr_Summary_RskAdj_EDS] = @RowCount_OUT;

                    EXEC [dbo].[PerfLogMonitor] @Section = '025.4',
                                                @ProcessName = @ProcessNameIn,
                                                @ET = @ET,
                                                @MasterET = @MasterET,
                                                @ET_Out = @ET OUT,
                                                @TableOutput = 0,
                                                @End = 0;
                END;

            END;

            ---EDS END 
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

        END;
    END;

    SKIPEXECSPR_SUMMARY_RSKADJ_ALTHICN_MMR_MOR_RAPS:

    IF @Mode IN ( 0, 2 )
    BEGIN
        IF @Mode = 2
        BEGIN
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

            SET @ALT_HICN = 1;
            SET @MMR_FLAG = 1;
            SET @MOR_FLAG = 1;
            SET @RAPS_FLAG = 1;
            SET @EDS_FLAG = 1;

        END;

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

        /*B IX Rebuild */
        DECLARE @ParaSortInTemp BIT = 0;
        DECLARE @ParaOnline BIT = 0;

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
        /*-B Rebuild/Defrag IX for rev.tbl_Summary_RskAdj_MOR */

        IF @MOR_FLAG = 1
        BEGIN

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
                   [BDate] = GETDATE(),
                   [EDate] = NULL,
                   [AdditionalRows] = NULL,
                   [RunBy] = USER_NAME();

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
                                                   @TableName = 'tbl_Summary_RskAdj_MOR',
                                                   @SortInTemp = @ParaSortInTemp,
                                                   @Online = @ParaOnline;

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

            UPDATE [m]
            SET [m].[EDate] = GETDATE()
            FROM [rev].[tbl_Summary_RskAdj_Activity] [m]
            WHERE [m].[tbl_Summary_RskAdj_ActivityId] = @tbl_Summary_RskAdj_ActivityIdSecondary;

            SET @tbl_Summary_RskAdj_ActivityIdSecondary = NULL;

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

        END;

        /*-E Rebuild/Defrag IX for rev.tbl_Summary_RskAdj_MOR */

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

        /*-B Rebuild/Defrag IX for rev.tbl_Summary_RskAdj_RAPS */

        IF @RAPS_FLAG = 1
        BEGIN
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
                   [Process] = '[dbo].[spr_RebuildIndexesByTable] @TableName=[rev].[tbl_Summary_RskAdj_RAPS_Preliminary]',
                   [BDate] = GETDATE(),
                   [EDate] = NULL,
                   [AdditionalRows] = NULL,
                   [RunBy] = USER_NAME();

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

            SET @tbl_Summary_RskAdj_ActivityIdSecondary = SCOPE_IDENTITY();

            IF @Debug = 1
            BEGIN
                EXEC [dbo].[PerfLogMonitor] @Section = '047',
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
            SET [m].[EDate] = GETDATE()
            FROM [rev].[tbl_Summary_RskAdj_Activity] [m]
            WHERE [m].[tbl_Summary_RskAdj_ActivityId] = @tbl_Summary_RskAdj_ActivityIdSecondary;

            SET @tbl_Summary_RskAdj_ActivityIdSecondary = NULL;

            IF @Debug = 1
            BEGIN
                EXEC [dbo].[PerfLogMonitor] @Section = '048',
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
                   [Process] = '[dbo].[spr_RebuildIndexesByTable] @TableName=[rev].[tbl_Summary_RskAdj_RAPS]',
                   [BDate] = GETDATE(),
                   [EDate] = NULL,
                   [AdditionalRows] = NULL,
                   [RunBy] = USER_NAME();

            IF @Debug = 1
            BEGIN
                EXEC [dbo].[PerfLogMonitor] @Section = '049',
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
                EXEC [dbo].[PerfLogMonitor] @Section = '050',
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
            SET [m].[EDate] = GETDATE()
            FROM [rev].[tbl_Summary_RskAdj_Activity] [m]
            WHERE [m].[tbl_Summary_RskAdj_ActivityId] = @tbl_Summary_RskAdj_ActivityIdSecondary;

            SET @tbl_Summary_RskAdj_ActivityIdSecondary = NULL;

            IF @Debug = 1
            BEGIN
                EXEC [dbo].[PerfLogMonitor] @Section = '051',
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
                   [Process] = '[dbo].[spr_RebuildIndexesByTable] @TableName=[rev].[tbl_Summary_RskAdj_RAPS_MOR_Combined]',
                   [BDate] = GETDATE(),
                   [EDate] = NULL,
                   [AdditionalRows] = NULL,
                   [RunBy] = USER_NAME();

            IF @Debug = 1
            BEGIN
                EXEC [dbo].[PerfLogMonitor] @Section = '052',
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
                EXEC [dbo].[PerfLogMonitor] @Section = '053',
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
                EXEC [dbo].[PerfLogMonitor] @Section = '054',
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
                EXEC [dbo].[PerfLogMonitor] @Section = '055',
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
                EXEC [dbo].[PerfLogMonitor] @Section = '055.1',
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
                   [Process] = '[dbo].[spr_RebuildIndexesByTable] @TableName=[rev].[tbl_Summary_RskAdj_EDS_Preliminary]',
                   [BDate] = GETDATE(),
                   [EDate] = NULL,
                   [AdditionalRows] = NULL,
                   [RunBy] = USER_NAME();

            IF @Debug = 1
            BEGIN
                EXEC [dbo].[PerfLogMonitor] @Section = '055.2',
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
                EXEC [dbo].[PerfLogMonitor] @Section = '055.3',
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
            SET [m].[EDate] = GETDATE()
            FROM [rev].[tbl_Summary_RskAdj_Activity] [m]
            WHERE [m].[tbl_Summary_RskAdj_ActivityId] = @tbl_Summary_RskAdj_ActivityIdSecondary;

            SET @tbl_Summary_RskAdj_ActivityIdSecondary = NULL;

            IF @Debug = 1
            BEGIN
                EXEC [dbo].[PerfLogMonitor] @Section = '055.4',
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
                   [Process] = '[dbo].[spr_RebuildIndexesByTable] @TableName=[rev].[tbl_Summary_RskAdj_EDS]',
                   [BDate] = GETDATE(),
                   [EDate] = NULL,
                   [AdditionalRows] = NULL,
                   [RunBy] = USER_NAME();

            IF @Debug = 1
            BEGIN
                EXEC [dbo].[PerfLogMonitor] @Section = '055.5',
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
                EXEC [dbo].[PerfLogMonitor] @Section = '055.6',
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
            SET [m].[EDate] = GETDATE()
            FROM [rev].[tbl_Summary_RskAdj_Activity] [m]
            WHERE [m].[tbl_Summary_RskAdj_ActivityId] = @tbl_Summary_RskAdj_ActivityIdSecondary;

            SET @tbl_Summary_RskAdj_ActivityIdSecondary = NULL;

            IF @Debug = 1
            BEGIN
                EXEC [dbo].[PerfLogMonitor] @Section = '055.7',
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
            EXEC [dbo].[PerfLogMonitor] @Section = '056',
                                        @ProcessName = @ProcessNameIn,
                                        @ET = @ET,
                                        @MasterET = @MasterET,
                                        @ET_Out = @ET OUT,
                                        @TableOutput = 0,
                                        @End = 0;
        END;
    /*E IX Rebuild */
    END;

    IF @Debug = 1
    BEGIN
        EXEC [dbo].[PerfLogMonitor] @Section = '057',
                                    @ProcessName = @ProcessNameIn,
                                    @ET = @ET,
                                    @MasterET = @MasterET,
                                    @ET_Out = @ET OUT,
                                    @TableOutput = 0,
                                    @End = 0;
    END;

    /* Populate the [dbo].[tbl_Summary_TskAdj_LoadStats] table */

    INSERT INTO [rev].[tbl_Summary_RskAdj_LoadStats]
    (
        [ServerName],
        [DbName],
        [TableName],
        [PaymentYear],
        [Model_Year],
        [LoadDateTime],
        [Count],
        [CaptureDateTime],
        [RunBy]
    )
    SELECT [ServerName] = @@SERVERNAME,
           [DbName] = DB_NAME(),
           [TableName] = '[rev].[tbl_Summary_RskAdj_AltHICN]',
           [PaymentYear] = NULL,
           [Model_Year] = NULL,
           [LoadDateTime] = [a1].[LoadDateTime],
           [Count] = COUNT(*),
           [CaptureDateTime] = GETDATE(),
           [RunBy] = USER_NAME()
    FROM [rev].[tbl_Summary_RskAdj_AltHICN] [a1] WITH (NOLOCK)
    GROUP BY [a1].[LoadDateTime]
    UNION ALL
    SELECT [ServerName] = @@SERVERNAME,
           [DbName] = DB_NAME(),
           [TableName] = '[rev].[tbl_Summary_RskAdj_MMR]',
           [PaymentYear] = [a1].[PaymentYear],
           [Model_Year] = NULL,
           [LoadDateTime] = [a1].[LoadDateTime],
           [Count] = COUNT(*),
           [CaptureDateTime] = GETDATE(),
           [RunBy] = USER_NAME()
    FROM [rev].[tbl_Summary_RskAdj_MMR] [a1] WITH (NOLOCK)
    GROUP BY [a1].[PaymentYear],
             [a1].[LoadDateTime]
    UNION ALL
    SELECT [ServerName] = @@SERVERNAME,
           [DbName] = DB_NAME(),
           [TableName] = '[rev].[tbl_Summary_RskAdj_MOR]',
           [PaymentYear] = [a1].[PaymentYear],
           [Model_Year] = [a1].[Model_Year],
           [LoadDateTime] = [a1].[LoadDateTime],
           [Count] = COUNT(*),
           [CaptureDateTime] = GETDATE(),
           [RunBy] = USER_NAME()
    FROM [rev].[tbl_Summary_RskAdj_MOR] [a1] WITH (NOLOCK)
    GROUP BY [a1].[PaymentYear],
             [a1].[Model_Year],
             [a1].[LoadDateTime]
    UNION ALL
    SELECT [ServerName] = @@SERVERNAME,
           [DbName] = DB_NAME(),
           [TableName] = '[rev].[tbl_Summary_RskAdj_RAPS_Preliminary]',
           [PaymentYear] = [a1].[PaymentYear],
           [Model_Year] = [a1].[ModelYear],
           [LoadDateTime] = [a1].[LoadDateTime],
           [Count] = COUNT(*),
           [CaptureDateTime] = GETDATE(),
           [RunBy] = USER_NAME()
    FROM [rev].[tbl_Summary_RskAdj_RAPS_Preliminary] [a1] WITH (NOLOCK)
    GROUP BY [a1].[PaymentYear],
             [a1].[ModelYear],
             [a1].[LoadDateTime]
    UNION ALL
    SELECT [ServerName] = @@SERVERNAME,
           [DbName] = DB_NAME(),
           [TableName] = '[rev].[tbl_Summary_RskAdj_RAPS]',
           [PaymentYear] = [a1].[PaymentYear],
           [Model_Year] = [a1].[ModelYear],
           [LoadDateTime] = [a1].[LoadDateTime],
           [Count] = COUNT(*),
           [CaptureDateTime] = GETDATE(),
           [RunBy] = USER_NAME()
    FROM [rev].[tbl_Summary_RskAdj_RAPS] [a1] WITH (NOLOCK)
    GROUP BY [a1].[PaymentYear],
             [a1].[ModelYear],
             [a1].[LoadDateTime]
    UNION ALL
    SELECT [ServerName] = @@SERVERNAME,
           [DbName] = DB_NAME(),
           [TableName] = '[rev].[tbl_Summary_RskAdj_RAPS_MOR_Combined]',
           [PaymentYear] = [a1].[PaymentYear],
           [Model_Year] = [a1].[ModelYear],
           [LoadDateTime] = [a1].[LoadDateTime],
           [Count] = COUNT(*),
           [CaptureDateTime] = GETDATE(),
           [RunBy] = USER_NAME()
    FROM [rev].[tbl_Summary_RskAdj_RAPS_MOR_Combined] [a1] WITH (NOLOCK)
    GROUP BY [a1].[PaymentYear],
             [a1].[ModelYear],
             [a1].[LoadDateTime]
    UNION ALL
    SELECT [ServerName] = @@SERVERNAME,
           [DbName] = DB_NAME(),
           [TableName] = '[rev].[tbl_Summary_RskAdj_EDS_Preliminary]',
           [PaymentYear] = [a1].[PaymentYear],
           [Model_Year] = [a1].[ModelYear],
           [LoadDateTime] = [a1].[LoadDateTime],
           [Count] = COUNT(*),
           [CaptureDateTime] = GETDATE(),
           [RunBy] = USER_NAME()
    FROM [rev].[tbl_Summary_RskAdj_EDS_Preliminary] [a1] WITH (NOLOCK)
    GROUP BY [a1].[PaymentYear],
             [a1].[ModelYear],
             [a1].[LoadDateTime]
    UNION ALL
    SELECT [ServerName] = @@SERVERNAME,
           [DbName] = DB_NAME(),
           [TableName] = '[rev].[tbl_Summary_RskAdj_EDS]',
           [PaymentYear] = [a1].[PaymentYear],
           [Model_Year] = [a1].[Model_Year],
           [LoadDateTime] = [a1].[LoadDateTime],
           [Count] = COUNT(*),
           [CaptureDateTime] = GETDATE(),
           [RunBy] = USER_NAME()
    FROM [rev].[tbl_Summary_RskAdj_EDS] [a1] WITH (NOLOCK)
    GROUP BY [a1].[PaymentYear],
             [a1].[Model_Year],
             [a1].[LoadDateTime];

    IF @Debug = 1
    BEGIN
        EXEC [dbo].[PerfLogMonitor] @Section = '058',
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
    WHERE [m].[tbl_Summary_RskAdj_ActivityId] = @tbl_Summary_RskAdj_ActivityIdMain;

    IF @Debug = 1
    BEGIN
        EXEC [dbo].[PerfLogMonitor] @Section = '059',
                                    @ProcessName = @ProcessNameIn,
                                    @ET = @ET,
                                    @MasterET = @MasterET,
                                    @ET_Out = @ET OUT,
                                    @TableOutput = 0,
                                    @End = 0;
    END;
END;


