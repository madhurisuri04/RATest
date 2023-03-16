CREATE PROCEDURE [Valuation].[ConfigLoadAutoProcessWorkList]
    @iClientId INT ,
    @iAutoProcessRunId INT = NULL , ---2016100509  /*Note: If null, then new AutoProcessRunId will be assigned */
    @iFilteredAuditAutoProcessRunId INT ,
    @iCTRLoadDate DATE ,
    @iDeliveredDate DATE ,
                                    /*B Parameters that are changed less frequently */
    @iModelYearA INT ,
    @iModelYearB INT ,
    @iBlendedPaymentDetailHeaderA VARCHAR(128) ,
    @iBlendedPaymentDetailHeaderB VARCHAR(128) ,
    @iBlendedPaymentDetailHeaderESRD VARCHAR(128) ,
    @iTotalsDetailHeaderA VARCHAR(128) ,
    @iTotalsDetailHeaderB VARCHAR(128) ,
    @iTotalsDetailHeaderESRD VARCHAR(128) ,
    @iTotalsSummaryHeader VARCHAR(128) ,
    @iYearToYearSummaryRowDisplay VARCHAR(128) ,
    @iRetrospectiveValuationDetailDOSPaymentYearHeader VARCHAR(128) ,
    @iPAYMENT_YEAR VARCHAR(4) ,
    @iPROCESSBY_START SMALLDATETIME ,
    @iPROCESSBY_END SMALLDATETIME ,
    @iSERVERNAME VARCHAR(130) = @@SERVERNAME ,
    @CTRSummaryServer VARCHAR(130) = 'RQIRPTDBS900' ,
    @CTRSummaryDb VARCHAR(130) = 'HRPClientGlobal_Report' ,
                                    /*E Parameters that are changed less frequently */
    @Debug BIT = 0
AS --

    /************************************************************************************************************************************ 
* Name			:	[Valuation].[ConfigLoadAutoProcessWorkList]																			*
* Type 			:	Stored Procedure																									*
* Author       	:	Mitch Casto																											*
* Date			:	2016-10-18																											*
* Version		:																														*
* Description	:	Used to load Valuation.AutoProcessWorkList																			*
*																																		*
* Version History :																														*
* =================																														*
* Author			Date			Version#    TFS Ticket#			Description															*
* -----------------	----------		--------    -----------			------------														*
* MCasto			2016-10-18		1.0			58445 / US57192																			*
* MCasto			2017-04-21		1.1			61356 / US59323		Update to use new [Valuation].[UpdateEDateAutoProcessRun] modes		*
* MCasto			2017-07-27		1.2			RE1039/US67184		Corrected Section 003 with @iClientId replacing hardcoded 19 and 	*
*												TFS66078			allow parameters to handle NULL as literal							*
*																																		*
*****************************************************************************************************************************************/
    /*Typical Parameters 

EXEC [Valuation].[ConfigLoadAutoProcessWorkList]
    @iClientId INT = 11
    , @iAutoProcessRunId INT = NULL---2016100509  /*Note: If null, then new AutoProcessRunId will be assigned */
    , @iFilteredAuditAutoProcessRunId INT = 513
    , @iCTRLoadDate DATE = '2016-09-28'
    , @iDeliveredDate DATE = '2016-10-11'

    , @iModelYearA INT = 2013
    , @iModelYearB INT = 2014

    , @iBlendedPaymentDetailHeaderA VARCHAR(128) = 'REMOVE' --'2014 DOS/2015 Payment Year - 2013 Model (67%)'
    , @iBlendedPaymentDetailHeaderB VARCHAR(128) = '2015 DOS/2016 Payment Year - 2014 Model (100%)'
    , @iBlendedPaymentDetailHeaderESRD VARCHAR(128) = '2015 DOS/2016 Payment Year - 2014 Model (100% ESRD)'
    , @iTotalsDetailHeaderA VARCHAR(128) = 'REMOVE' --2014 DOS/2015 Payment Year - 2013 Model (67%)'
    , @iTotalsDetailHeaderB VARCHAR(128) = '2014 DOS/2015 Payment Year - 2014 Model (100%)'
    , @iTotalsDetailHeaderESRD VARCHAR(128) = '2014 DOS/2015 Payment Year - 2014 Model (100% - ESRD)'
    , @iTotalsSummaryHeader VARCHAR(128) = 'RAPS SUBMISSIONS - REALIZED for 2016 Payment Year'
    , @iYearToYearSummaryRowDisplay VARCHAR(128) = '2015 Retro Projects (2015 DOS / 2016 PY)'
    , @iRetrospectiveValuationDetailDOSPaymentYearHeader VARCHAR(128) = '2015 DOS / 2016 Payment Year'

    , @iPAYMENT_YEAR VARCHAR(4) = '2016'
    , @iPROCESSBY_START SMALLDATETIME = '2015-01-01'
    , @iPROCESSBY_END SMALLDATETIME = '2016-12-31'

    , @iSERVERNAME VARCHAR(130) = @@SERVERNAME
    , @CTRSummaryServer VARCHAR(130) = 'RQIRPTDBS900'
    , @CTRSummaryDb VARCHAR(130) = 'HRPClientGlobal_Report'
	, @Debug = 1
*/

    SET NOCOUNT ON

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

    /*B Quick Parameter Check */

    IF @iFilteredAuditAutoProcessRunId IS NULL
        BEGIN

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


            DECLARE @Msg VARCHAR(4000)

            SET @Msg = '    Parameter @iFilteredAuditAutoProcessRunId is set to NULL. Process halted.
	To find FilteredAudit values query: 
	SELECT * FROM [Valuation].[AutoProcessRun] a1 WITH(NOLOCK) WHERE a1.[ClientId] = '
                       + CAST(@iClientId AS VARCHAR(11)) + ''
            RAISERROR(@Msg, 15, 15) WITH NOWAIT

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

            RETURN
        END

    /*E Quick Parameter Check */

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


    /*B Set ProjectIdList */

    DECLARE @ProjectIdList VARCHAR(2048)
    SELECT @ProjectIdList = COALESCE(@ProjectIdList + ', ', '')
                            + CAST([cp].[ProjectId] AS VARCHAR(11))
    FROM   [Valuation].[ConfigProjectIdList] [cp]
    WHERE  [cp].[ClientId] = @iClientId
           AND [cp].[ActiveBDate] <= CAST(GETDATE() AS DATE)
           AND ISNULL([cp].[ActiveEDate], DATEADD(dd, 1, GETDATE())) >= CAST(GETDATE() AS DATE)


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


    /*E Set ProjectIdList */

    /*B Get ClientName based on current database */

    DECLARE @ClientName VARCHAR(128) = LEFT(DB_NAME(), PATINDEX(
                                                                   '%[_]%' ,
                                                                   DB_NAME()
                                                               ) - 1)

    /*E Get ClientName based on current database */

    IF @Debug = 1
        BEGIN
            EXEC [dbo].[PerfLogMonitor] '005' ,
                                        @ProcessNameIn ,
                                        @ET ,
                                        @MasterET ,
                                        @ET OUT ,
                                        0 ,
                                        0
        END

    DECLARE @OriginalInputAutoProcessRunId INT = @iAutoProcessRunId

    /*B Get new AutoProcessRunId*/

    IF @iAutoProcessRunId IS NULL
        BEGIN

            IF @Debug = 1
                BEGIN
                    EXEC [dbo].[PerfLogMonitor] '006' ,
                                                @ProcessNameIn ,
                                                @ET ,
                                                @MasterET ,
                                                @ET OUT ,
                                                0 ,
                                                0
                END

            INSERT INTO [Valuation].[AutoProcessRun] (   [ClientId] ,
                                                         [ConfigClientMainId] ,
                                                         [BDate] ,
                                                         [EDate] ,
                                                         [FriendlyDescription] ,
                                                         [ClientVisibleBDate] ,
                                                         [ClientVisibleEDate] ,
                                                         [GlobalProcessRunId]
                                                     )
                        SELECT [ClientId] = @iClientId ,
                               [ConfigClientMainId] = 1 ,
                               [BDate] = GETDATE() ,
                               [EDate] = NULL ,
                               [FriendlyDescription] = @ClientName
                                                       + ' - Retrospective Valuation ('
                                                       + CONVERT(
                                                                    CHAR(10) ,
                                                                    @iDeliveredDate ,
                                                                    121
                                                                ) + ') PY'
                                                       + @iPAYMENT_YEAR
                                                       + ' [@@iAutoProcessRunId@@]' ,
                               [ClientVisibleBDate] = NULL , --CAST(GETDATE() AS DATE)
                               [ClientVisibleEDate] = NULL ,
                               [GlobalProcessRunId] = NULL

            SET @iAutoProcessRunId = SCOPE_IDENTITY()

            IF @Debug = 1
                BEGIN
                    EXEC [dbo].[PerfLogMonitor] '007' ,
                                                @ProcessNameIn ,
                                                @ET ,
                                                @MasterET ,
                                                @ET OUT ,
                                                0 ,
                                                0
                END

            UPDATE [m]
            SET    [m].[FriendlyDescription] = REPLACE(
                                                          [m].[FriendlyDescription] ,
                                                          '@@iAutoProcessRunId@@' ,
                                                          CAST(@iAutoProcessRunId AS VARCHAR(11))
                                                      )
            FROM   [Valuation].[AutoProcessRun] [m]
            WHERE  [m].[AutoProcessRunId] = @iAutoProcessRunId

            IF @Debug = 1
                BEGIN
                    EXEC [dbo].[PerfLogMonitor] '008' ,
                                                @ProcessNameIn ,
                                                @ET ,
                                                @MasterET ,
                                                @ET OUT ,
                                                0 ,
                                                0
                END

        END

    /*E Get new AutoProcessRunId*/

    /*B Set [Valuation].[AutoProcessActiveWorkList] */

    IF @Debug = 1
        BEGIN
            EXEC [dbo].[PerfLogMonitor] '008.1' ,
                                        @ProcessNameIn ,
                                        @ET ,
                                        @MasterET ,
                                        @ET OUT ,
                                        0 ,
                                        0
        END

    DELETE FROM [Valuation].[AutoProcessActiveWorkList]

    IF @Debug = 1
        BEGIN
            EXEC [dbo].[PerfLogMonitor] '008.2' ,
                                        @ProcessNameIn ,
                                        @ET ,
                                        @MasterET ,
                                        @ET OUT ,
                                        0 ,
                                        0
        END

    INSERT INTO [Valuation].[AutoProcessActiveWorkList]
        ( [AutoProcessRunId] )
                SELECT [AutoProcessRunId] = @iAutoProcessRunId

    /*E Set [Valuation].[AutoProcessActiveWorkList] */

    IF @Debug = 1
        BEGIN
            EXEC [dbo].[PerfLogMonitor] '009' ,
                                        @ProcessNameIn ,
                                        @ET ,
                                        @MasterET ,
                                        @ET OUT ,
                                        0 ,
                                        0
        END

    IF @Debug = 1
        BEGIN
            SELECT [New: AutoProcessRunId] = @iAutoProcessRunId
        END

    IF @Debug = 1
        BEGIN
            EXEC [dbo].[PerfLogMonitor] '010' ,
                                        @ProcessNameIn ,
                                        @ET ,
                                        @MasterET ,
                                        @ET OUT ,
                                        0 ,
                                        0
        END

    DECLARE @PlanDbList TABLE
        (
            [PlanDb] VARCHAR(130) PRIMARY KEY ,
            [Priority] INT
        )

    DECLARE @WorkList TABLE
        (
            [Id] INT IDENTITY(1, 1) PRIMARY KEY ,
            [PlanDb] VARCHAR(130) ,
            [Priority] INT ,
            [Schema] VARCHAR(130) ,
            [Stp] VARCHAR(130) ,
            [Parameters] VARCHAR(2048)
        )

    IF @Debug = 1
        BEGIN
            EXEC [dbo].[PerfLogMonitor] '011' ,
                                        @ProcessNameIn ,
                                        @ET ,
                                        @MasterET ,
                                        @ET OUT ,
                                        0 ,
                                        0
        END

    /*B Load NewHCC PartC & PartD workload */

    DECLARE @PlanDb VARCHAR(130)
    DECLARE @Priority INT

    IF @Debug = 1
        BEGIN
            EXEC [dbo].[PerfLogMonitor] '012' ,
                                        @ProcessNameIn ,
                                        @ET ,
                                        @MasterET ,
                                        @ET OUT ,
                                        0 ,
                                        0
        END

    INSERT INTO @PlanDbList (   [PlanDb] ,
                                [Priority]
                            )
                SELECT [ccp].[PlanDb] ,
                       [ccp].[Priority]
                FROM   [Valuation].[ConfigClientPlan] [ccp]
                WHERE  [ccp].[ClientId] = @iClientId
                       AND [ccp].[ActiveBDate] <= GETDATE()
                       AND ISNULL(
                                     [ccp].[ActiveEDate] ,
                                     DATEADD(dd, 1, GETDATE())
                                 ) >= GETDATE()
                       AND SUBSTRING(REVERSE([ccp].[PlanDb]), 5, 1) = 'H'

    IF @Debug = 1
        BEGIN
            EXEC [dbo].[PerfLogMonitor] '013' ,
                                        @ProcessNameIn ,
                                        @ET ,
                                        @MasterET ,
                                        @ET OUT ,
                                        0 ,
                                        0
        END

    WHILE EXISTS (   SELECT *
                     FROM   @PlanDbList
                 )
        BEGIN

            IF @Debug = 1
                BEGIN
                    EXEC [dbo].[PerfLogMonitor] '014WL' ,
                                                @ProcessNameIn ,
                                                @ET ,
                                                @MasterET ,
                                                @ET OUT ,
                                                0 ,
                                                0
                END

            SELECT   TOP 1 @PlanDb = [PlanDb] ,
                     @Priority = [Priority]
            FROM     @PlanDbList
            ORDER BY [PlanDb]

            IF @Debug = 1
                BEGIN
                    EXEC [dbo].[PerfLogMonitor] '015WL' ,
                                                @ProcessNameIn ,
                                                @ET ,
                                                @MasterET ,
                                                @ET OUT ,
                                                0 ,
                                                0
                END

            INSERT INTO @WorkList (   [PlanDb] ,
                                      [Priority] ,
                                      [Schema] ,
                                      [Stp] ,
                                      [Parameters]
                                  )
                        SELECT [PlanDb] = @PlanDb ,
                               [Priority] = @Priority ,
                               [Schema] = '[Valuation]' ,
                               [Stp] = '[GetNewHCCPartD]' ,
                               [Parameters] = '@PAYMENT_YEAR = '''
                                              + @iPAYMENT_YEAR
                                              + ''', @PROCESSBY_START = '''
                                              + CONVERT(
                                                           CHAR(10) ,
                                                           @iPROCESSBY_START ,
                                                           120
                                                       )
                                              + ''', @PROCESSBY_END = '''
                                              + CONVERT(
                                                           CHAR(10) ,
                                                           @iPROCESSBY_END ,
                                                           120
                                                       )
                                              + ''' , @PRIORITY = ''P'', @Valuation = 1, @ProcessRunId = '
                                              + CAST(@iAutoProcessRunId AS VARCHAR(11))
                                              + ', @$EnumDbName = '''
                                              + @PlanDb + ''', @Debug = 0'
                        UNION
                        SELECT [PlanDb] = @PlanDb ,
                               [Priority] = @Priority ,
                               [Schema] = '[dbo]' ,
                               [Stp] = '[spr_EstRecv_New_HCC]' ,
                               [Parameters] = '@Payment_Year_NewDeleteHCC = '''
                                              + @iPAYMENT_YEAR
                                              + ''', @PROCESSBY_START = '''
                                              + CONVERT(
                                                           CHAR(10) ,
                                                           @iPROCESSBY_START ,
                                                           120
                                                       )
                                              + ''' , @PROCESSBY_END = '''
                                              + CONVERT(
                                                           CHAR(10) ,
                                                           @iPROCESSBY_END ,
                                                           120
                                                       )
                                              + ''' , @ReportOutputByMonth = ''V'', @RAPS_STRING_ALL = ''ALL'' , @File_STRING_ALL = ''ALL'', @SERVERNAME = '''
                                              + @iSERVERNAME
                                              + ''' , @$EnumDbName = '''
                                              + @PlanDb
                                              + ''', @ProcessRunId = '
                                              + CAST(@iAutoProcessRunId AS VARCHAR(11))
                                              + ', @Debug = 0'

            IF @Debug = 1
                BEGIN
                    EXEC [dbo].[PerfLogMonitor] '016WL' ,
                                                @ProcessNameIn ,
                                                @ET ,
                                                @MasterET ,
                                                @ET OUT ,
                                                0 ,
                                                0
                END

            DELETE [m]
            FROM  @PlanDbList [m]
            WHERE [m].[PlanDb] = @PlanDb

            IF @Debug = 1
                BEGIN
                    EXEC [dbo].[PerfLogMonitor] '017WL' ,
                                                @ProcessNameIn ,
                                                @ET ,
                                                @MasterET ,
                                                @ET OUT ,
                                                0 ,
                                                0
                END

        END

    IF @Debug = 1
        BEGIN
            EXEC [dbo].[PerfLogMonitor] '018' ,
                                        @ProcessNameIn ,
                                        @ET ,
                                        @MasterET ,
                                        @ET OUT ,
                                        0 ,
                                        0
        END

    DELETE [m]
    FROM  [Valuation].[AutoProcessWorkList] [m]
    WHERE [m].[AutoProcessRunId] = @iAutoProcessRunId

    IF @Debug = 1
        BEGIN
            EXEC [dbo].[PerfLogMonitor] '019' ,
                                        @ProcessNameIn ,
                                        @ET ,
                                        @MasterET ,
                                        @ET OUT ,
                                        0 ,
                                        0
        END

    INSERT INTO [Valuation].[AutoProcessWorkList] (   [GlobalProcessRunId] ,
                                                      [ClientId] ,
                                                      [AutoProcessRunId] ,
                                                      [AutoProcessId] ,
                                                      [AutoProcessActionId] ,
                                                      [Phase] ,
                                                      [Priority] ,
                                                      [PreRunSecs] ,
                                                      [DbName] ,
                                                      [CommandDb] ,
                                                      [CommandSchema] ,
                                                      [CommandSTP] ,
                                                      [Parameter] ,
                                                      [BDate] ,
                                                      [EDate] ,
                                                      [AutoProcessWorkerId] ,
                                                      [RowCount] ,
                                                      [SPID] ,
                                                      [ErrorInfo] ,
                                                      [Result] ,
                                                      [Retry] ,
                                                      [Status] ,
                                                      [AutoProcessActionCatalogId] ,
                                                      [DependAutoProcessActionCatalogId] ,
                                                      [ByPlan] ,
                                                      [StopAll]
                                                  )
                SELECT [GlobalProcessRunId] = -1 ,
                       [ClientId] = @iClientId ,
                       [AutoProcessRunId] = @iAutoProcessRunId ,
                       [AutoProcessId] = -1 ,
                       [AutoProcessActionId] = NULL ,
                       [Phase] = 5 ,
                       [Priority] = [Priority] ,
                       [PreRunSecs] = 99999 ,
                       [DbName] = [PlanDb] ,
                       [CommandDb] = DB_NAME() ,
                       [CommandSchema] = [Schema] ,
                       [CommandSTP] = [Stp] ,
                       [Parameter] = [Parameters] ,
                       [BDate] = NULL ,
                       [EDate] = NULL ,
                       [AutoProcessWorkerId] = NULL ,
                       [RowCount] = NULL ,
                       [SPID] = NULL ,
                       [ErrorInfo] = NULL ,
                       [Result] = NULL ,
                       [Retry] = NULL ,
                       [Status] = NULL ,
                       [AutoProcessActionCatalogId] = NULL ,
                       [DependAutoProcessActionCatalogId] = NULL ,
                       [ByPlan] = 1 ,
                       [StopAll] = 0
                FROM   @WorkList

    /*E Load NewHCC PartC & PartD to worklist */

    IF @Debug = 1
        BEGIN
            EXEC [dbo].[PerfLogMonitor] '020' ,
                                        @ProcessNameIn ,
                                        @ET ,
                                        @MasterET ,
                                        @ET OUT ,
                                        0 ,
                                        0
        END

    /*B Get new client level databases */

    INSERT INTO [Valuation].[AutoProcessWorkList] (   [GlobalProcessRunId] ,
                                                      [ClientId] ,
                                                      [AutoProcessRunId] ,
                                                      [AutoProcessId] ,
                                                      [AutoProcessActionId] ,
                                                      [Phase] ,
                                                      [Priority] ,
                                                      [PreRunSecs] ,
                                                      [DbName] ,
                                                      [CommandDb] ,
                                                      [CommandSchema] ,
                                                      [CommandSTP] ,
                                                      [Parameter] ,
                                                      [BDate] ,
                                                      [EDate] ,
                                                      [AutoProcessWorkerId] ,
                                                      [RowCount] ,
                                                      [SPID] ,
                                                      [ErrorInfo] ,
                                                      [Result] ,
                                                      [Retry] ,
                                                      [Status] ,
                                                      [AutoProcessActionCatalogId] ,
                                                      [DependAutoProcessActionCatalogId] ,
                                                      [ByPlan] ,
                                                      [StopAll]
                                                  )
                SELECT [GlobalProcessRunId] = -1 ,
                       [ClientId] = @iClientId ,
                       [AutoProcessRunId] = @iAutoProcessRunId ,
                       [AutoProcessId] = -1 ,
                       [AutoProcessActionId] = NULL ,
                       [Phase] = 1 ,
                       [Priority] = 2 ,
                       [PreRunSecs] = 99999 ,
                       [DbName] = DB_NAME() ,
                       [CommandDb] = DB_NAME() ,
                       [CommandSchema] = '[Valuation]' ,
                       [CommandSTP] = '[ConfigInsertConfigClientPlan]' ,
                       [Parameter] = '' ,
                       [BDate] = NULL ,
                       [EDate] = NULL ,
                       [AutoProcessWorkerId] = NULL ,
                       [RowCount] = NULL ,
                       [SPID] = NULL ,
                       [ErrorInfo] = NULL ,
                       [Result] = NULL ,
                       [Retry] = NULL ,
                       [Status] = NULL ,
                       [AutoProcessActionCatalogId] = NULL ,
                       [DependAutoProcessActionCatalogId] = NULL ,
                       [ByPlan] = 0 ,
                       [StopAll] = 0

    /*E Get new client level databases */

    IF @Debug = 1
        BEGIN
            EXEC [dbo].[PerfLogMonitor] '021' ,
                                        @ProcessNameIn ,
                                        @ET ,
                                        @MasterET ,
                                        @ET OUT ,
                                        0 ,
                                        0
        END

    /*B Load [Valuation].[ConfigGetNewProjectSubProjectReviewName] into worklist */

    INSERT INTO [Valuation].[AutoProcessWorkList] (   [GlobalProcessRunId] ,
                                                      [ClientId] ,
                                                      [AutoProcessRunId] ,
                                                      [AutoProcessId] ,
                                                      [AutoProcessActionId] ,
                                                      [Phase] ,
                                                      [Priority] ,
                                                      [PreRunSecs] ,
                                                      [DbName] ,
                                                      [CommandDb] ,
                                                      [CommandSchema] ,
                                                      [CommandSTP] ,
                                                      [Parameter] ,
                                                      [BDate] ,
                                                      [EDate] ,
                                                      [AutoProcessWorkerId] ,
                                                      [RowCount] ,
                                                      [SPID] ,
                                                      [ErrorInfo] ,
                                                      [Result] ,
                                                      [Retry] ,
                                                      [Status] ,
                                                      [AutoProcessActionCatalogId] ,
                                                      [DependAutoProcessActionCatalogId] ,
                                                      [ByPlan] ,
                                                      [StopAll]
                                                  )
                SELECT [GlobalProcessRunId] = -1 ,
                       [ClientId] = @iClientId ,
                       [AutoProcessRunId] = @iAutoProcessRunId ,
                       [AutoProcessId] = -1 ,
                       [AutoProcessActionId] = NULL ,
                       [Phase] = 1 ,
                       [Priority] = 1 ,
                       [PreRunSecs] = 99999 ,
                       [DbName] = DB_NAME() ,
                       [CommandDb] = DB_NAME() ,
                       [CommandSchema] = '[Valuation]' ,
                       [CommandSTP] = '[ConfigGetNewProjectSubProjectReviewName]' ,
                       [Parameter] = '@ClientLevelDb = ''' + @ClientName
                                     + '_CN_ClientLevel'', @Debug = 0' ,
                       [BDate] = NULL ,
                       [EDate] = NULL ,
                       [AutoProcessWorkerId] = NULL ,
                       [RowCount] = NULL ,
                       [SPID] = NULL ,
                       [ErrorInfo] = NULL ,
                       [Result] = NULL ,
                       [Retry] = NULL ,
                       [Status] = NULL ,
                       [AutoProcessActionCatalogId] = NULL ,
                       [DependAutoProcessActionCatalogId] = NULL ,
                       [ByPlan] = 0 ,
                       [StopAll] = 0

    /*E Load [Valuation].[ConfigGetNewProjectSubProjectReviewName] into worklist */

    IF @Debug = 1
        BEGIN
            EXEC [dbo].[PerfLogMonitor] '022' ,
                                        @ProcessNameIn ,
                                        @ET ,
                                        @MasterET ,
                                        @ET OUT ,
                                        0 ,
                                        0
        END

    /*B Load [Valuation].[ConfigGetCTRSummary] into worklist */

    INSERT INTO [Valuation].[AutoProcessWorkList] (   [GlobalProcessRunId] ,
                                                      [ClientId] ,
                                                      [AutoProcessRunId] ,
                                                      [AutoProcessId] ,
                                                      [AutoProcessActionId] ,
                                                      [Phase] ,
                                                      [Priority] ,
                                                      [PreRunSecs] ,
                                                      [DbName] ,
                                                      [CommandDb] ,
                                                      [CommandSchema] ,
                                                      [CommandSTP] ,
                                                      [Parameter] ,
                                                      [BDate] ,
                                                      [EDate] ,
                                                      [AutoProcessWorkerId] ,
                                                      [RowCount] ,
                                                      [SPID] ,
                                                      [ErrorInfo] ,
                                                      [Result] ,
                                                      [Retry] ,
                                                      [Status] ,
                                                      [AutoProcessActionCatalogId] ,
                                                      [DependAutoProcessActionCatalogId] ,
                                                      [ByPlan] ,
                                                      [StopAll]
                                                  )
                SELECT [GlobalProcessRunId] = -1 ,
                       [ClientId] = @iClientId ,
                       [AutoProcessRunId] = @iAutoProcessRunId ,
                       [AutoProcessId] = -1 ,
                       [AutoProcessActionId] = NULL ,
                       [Phase] = 2 ,
                       [Priority] = 1 ,
                       [PreRunSecs] = 99999 ,
                       [DbName] = DB_NAME() ,
                       [CommandDb] = DB_NAME() ,
                       [CommandSchema] = '[Valuation]' ,
                       [CommandSTP] = '[ConfigGetCTRSummary]' ,
                       [Parameter] = '@CTRSummaryServer = '''
                                     + @CTRSummaryServer
                                     + ''', @CTRSummaryDb = '''
                                     + @CTRSummaryDb + ''', @LoadDate = '''
                                     + CONVERT(CHAR(10), @iCTRLoadDate, 120)
                                     + ''', @AutoProcessRunId = '
                                     + CAST(@iAutoProcessRunId AS VARCHAR(11))
                                     + ', @ClientId = '
                                     + CAST(@iClientId AS VARCHAR(11))
                                     + ', @Debug = 0' ,
                       [BDate] = NULL ,
                       [EDate] = NULL ,
                       [AutoProcessWorkerId] = NULL ,
                       [RowCount] = NULL ,
                       [SPID] = NULL ,
                       [ErrorInfo] = NULL ,
                       [Result] = NULL ,
                       [Retry] = NULL ,
                       [Status] = NULL ,
                       [AutoProcessActionCatalogId] = NULL ,
                       [DependAutoProcessActionCatalogId] = NULL ,
                       [ByPlan] = 0 ,
                       [StopAll] = 0

    /*E Load [Valuation].[ConfigGetCTRSummary] into worklist */

    IF @Debug = 1
        BEGIN
            EXEC [dbo].[PerfLogMonitor] '023' ,
                                        @ProcessNameIn ,
                                        @ET ,
                                        @MasterET ,
                                        @ET OUT ,
                                        0 ,
                                        0
        END

    /*B Load [Valuation].[ConfigUpdateSubProjectIdAndFailureReason] into worklist */

    INSERT INTO [Valuation].[AutoProcessWorkList] (   [GlobalProcessRunId] ,
                                                      [ClientId] ,
                                                      [AutoProcessRunId] ,
                                                      [AutoProcessId] ,
                                                      [AutoProcessActionId] ,
                                                      [Phase] ,
                                                      [Priority] ,
                                                      [PreRunSecs] ,
                                                      [DbName] ,
                                                      [CommandDb] ,
                                                      [CommandSchema] ,
                                                      [CommandSTP] ,
                                                      [Parameter] ,
                                                      [BDate] ,
                                                      [EDate] ,
                                                      [AutoProcessWorkerId] ,
                                                      [RowCount] ,
                                                      [SPID] ,
                                                      [ErrorInfo] ,
                                                      [Result] ,
                                                      [Retry] ,
                                                      [Status] ,
                                                      [AutoProcessActionCatalogId] ,
                                                      [DependAutoProcessActionCatalogId] ,
                                                      [ByPlan] ,
                                                      [StopAll]
                                                  )
                SELECT [GlobalProcessRunId] = -1 ,
                       [ClientId] = @iClientId ,
                       [AutoProcessRunId] = @iAutoProcessRunId ,
                       [AutoProcessId] = -1 ,
                       [AutoProcessActionId] = NULL ,
                       [Phase] = 98 ,
                       [Priority] = 1 ,
                       [PreRunSecs] = 99999 ,
                       [DbName] = DB_NAME() ,
                       [CommandDb] = DB_NAME() ,
                       [CommandSchema] = '[Valuation]' ,
                       [CommandSTP] = '[ConfigUpdateSubProjectIdAndFailureReason]' ,
                       [Parameter] = '@ClientId = '
                                     + CAST(@iClientId AS VARCHAR(11))
                                     + ', @AutoProcessRunId = '
                                     + CAST(@iAutoProcessRunId AS VARCHAR(11))
                                     + ', @ProjectIdList = '''
                                     + ISNULL(@ProjectIdList, 'NULL')
                                     + ''', @Debug = 0' ,
                       [BDate] = NULL ,
                       [EDate] = NULL ,
                       [AutoProcessWorkerId] = NULL ,
                       [RowCount] = NULL ,
                       [SPID] = NULL ,
                       [ErrorInfo] = NULL ,
                       [Result] = NULL ,
                       [Retry] = NULL ,
                       [Status] = NULL ,
                       [AutoProcessActionCatalogId] = NULL ,
                       [DependAutoProcessActionCatalogId] = NULL ,
                       [ByPlan] = 0 ,
                       [StopAll] = 0

    /*E Load [Valuation].[ConfigUpdateSubProjectIdAndFailureReason] into worklist */

    IF @Debug = 1
        BEGIN
            EXEC [dbo].[PerfLogMonitor] '024' ,
                                        @ProcessNameIn ,
                                        @ET ,
                                        @MasterET ,
                                        @ET OUT ,
                                        0 ,
                                        0
        END

    /*B Add [Valuation].[ConfigGetCalc] */

    INSERT INTO [Valuation].[AutoProcessWorkList] (   [GlobalProcessRunId] ,
                                                      [ClientId] ,
                                                      [AutoProcessRunId] ,
                                                      [AutoProcessId] ,
                                                      [AutoProcessActionId] ,
                                                      [Phase] ,
                                                      [Priority] ,
                                                      [PreRunSecs] ,
                                                      [DbName] ,
                                                      [CommandDb] ,
                                                      [CommandSchema] ,
                                                      [CommandSTP] ,
                                                      [Parameter] ,
                                                      [BDate] ,
                                                      [EDate] ,
                                                      [AutoProcessWorkerId] ,
                                                      [RowCount] ,
                                                      [SPID] ,
                                                      [ErrorInfo] ,
                                                      [Result] ,
                                                      [Retry] ,
                                                      [Status] ,
                                                      [AutoProcessActionCatalogId] ,
                                                      [DependAutoProcessActionCatalogId] ,
                                                      [ByPlan] ,
                                                      [StopAll]
                                                  )
                SELECT [GlobalProcessRunId] = -1 ,
                       [ClientId] = @iClientId ,
                       [AutoProcessRunId] = @iAutoProcessRunId ,
                       [AutoProcessId] = -1 ,
                       [AutoProcessActionId] = NULL ,
                       [Phase] = 99 ,
                       [Priority] = 1 ,
                       [PreRunSecs] = 99999 ,
                       [DbName] = DB_NAME() ,
                       [CommandDb] = DB_NAME() ,
                       [CommandSchema] = '[Valuation]' ,
                       [CommandSTP] = '[ConfigGetCalc]' ,
                       [Parameter] = '@ClientId = '
                                     + CAST(@iClientId AS VARCHAR(11))
                                     + ', @AutoProcessRunId = '
                                     + CAST(@iAutoProcessRunId AS VARCHAR(11))
                                     + ', @AutoProcessRunIdFA = '
                                     + CAST(@iFilteredAuditAutoProcessRunId AS VARCHAR(11))
                                     + ', @CTRLoadDate = '''
                                     + CONVERT(CHAR(10), @iCTRLoadDate, 121)
                                     + '''' + ', @ModelYearA = '
                                     + ISNULL(
                                                 CAST(@iModelYearA AS VARCHAR(11)) ,
                                                 'NULL'
                                             ) + ', @ModelYearB = '
                                     + ISNULL(
                                                 CAST(@iModelYearB AS VARCHAR(11)) ,
                                                 'NULL'
                                             )
                                     + ', @BlendedPaymentDetailHeaderA = '''
                                     + @iBlendedPaymentDetailHeaderA
                                     + ''', @BlendedPaymentDetailHeaderB = '''
                                     + @iBlendedPaymentDetailHeaderB
                                     + ''', @BlendedPaymentDetailHeaderESRD = '''
                                     + @iBlendedPaymentDetailHeaderESRD
                                     + ''', @TotalsDetailHeaderA = '''
                                     + @iTotalsDetailHeaderA
                                     + ''', @TotalsDetailHeaderB = '''
                                     + @iTotalsDetailHeaderB
                                     + ''', @TotalsDetailHeaderESRD = '''
                                     + @iTotalsDetailHeaderESRD
                                     + ''', @TotalsSummaryHeader = '''
                                     + @iTotalsSummaryHeader
                                     + ''', @YearToYearSummaryRowDisplay = '''
                                     + @iYearToYearSummaryRowDisplay
                                     + ''', @RetrospectiveValuationDetailDOSPaymentYearHeader = '''
                                     + @iRetrospectiveValuationDetailDOSPaymentYearHeader
                                     + ''', @DeliveredDate = '''
                                     + CONVERT(CHAR(10), @iDeliveredDate, 121)
                                     + '''
		, @Debug = 0' ,
                       [BDate] = NULL ,
                       [EDate] = NULL ,
                       [AutoProcessWorkerId] = NULL ,
                       [RowCount] = NULL ,
                       [SPID] = NULL ,
                       [ErrorInfo] = NULL ,
                       [Result] = NULL ,
                       [Retry] = NULL ,
                       [Status] = NULL ,
                       [AutoProcessActionCatalogId] = NULL ,
                       [DependAutoProcessActionCatalogId] = NULL ,
                       [ByPlan] = 0 ,
                       [StopAll] = 0

    /*E Add [Valuation].[ConfigGetCalc] */

    IF @Debug = 1
        BEGIN
            EXEC [dbo].[PerfLogMonitor] '025' ,
                                        @ProcessNameIn ,
                                        @ET ,
                                        @MasterET ,
                                        @ET OUT ,
                                        0 ,
                                        0
        END

    /*B Add [Valuation].[UpdateEDateAutoProcessRun] */

    INSERT INTO [Valuation].[AutoProcessWorkList] (   [GlobalProcessRunId] ,
                                                      [ClientId] ,
                                                      [AutoProcessRunId] ,
                                                      [AutoProcessId] ,
                                                      [AutoProcessActionId] ,
                                                      [Phase] ,
                                                      [Priority] ,
                                                      [PreRunSecs] ,
                                                      [DbName] ,
                                                      [CommandDb] ,
                                                      [CommandSchema] ,
                                                      [CommandSTP] ,
                                                      [Parameter] ,
                                                      [BDate] ,
                                                      [EDate] ,
                                                      [AutoProcessWorkerId] ,
                                                      [RowCount] ,
                                                      [SPID] ,
                                                      [ErrorInfo] ,
                                                      [Result] ,
                                                      [Retry] ,
                                                      [Status] ,
                                                      [AutoProcessActionCatalogId] ,
                                                      [DependAutoProcessActionCatalogId] ,
                                                      [ByPlan] ,
                                                      [StopAll]
                                                  )
                SELECT [GlobalProcessRunId] = -1 ,
                       [ClientId] = @iClientId ,
                       [AutoProcessRunId] = @iAutoProcessRunId ,
                       [AutoProcessId] = -1 ,
                       [AutoProcessActionId] = NULL ,
                       [Phase] = -9999999 ,
                       [Priority] = 1 ,
                       [PreRunSecs] = 99999 ,
                       [DbName] = DB_NAME() ,
                       [CommandDb] = DB_NAME() ,
                       [CommandSchema] = '[Valuation]' ,
                       [CommandSTP] = '[UpdateEDateAutoProcessRun]' ,
                       [Parameter] = '@Mode = 1, @AutoProcessRunId = '
                                     + CAST(@iAutoProcessRunId AS VARCHAR(11)) ,
                       [BDate] = NULL ,
                       [EDate] = NULL ,
                       [AutoProcessWorkerId] = NULL ,
                       [RowCount] = NULL ,
                       [SPID] = NULL ,
                       [ErrorInfo] = NULL ,
                       [Result] = NULL ,
                       [Retry] = NULL ,
                       [Status] = NULL ,
                       [AutoProcessActionCatalogId] = NULL ,
                       [DependAutoProcessActionCatalogId] = NULL ,
                       [ByPlan] = 0 ,
                       [StopAll] = 0
                UNION ALL
                SELECT [GlobalProcessRunId] = -1 ,
                       [ClientId] = @iClientId ,
                       [AutoProcessRunId] = @iAutoProcessRunId ,
                       [AutoProcessId] = -1 ,
                       [AutoProcessActionId] = NULL ,
                       [Phase] = -9999999 ,
                       [Priority] = -1 ,
                       [PreRunSecs] = 0 ,
                       [DbName] = DB_NAME() ,
                       [CommandDb] = DB_NAME() ,
                       [CommandSchema] = '[Valuation]' ,
                       [CommandSTP] = '[ConfigLoadAutoProcessWorkList]' ,
                       [Parameter] = '@iClientId = '
                                     + CAST(@iClientId AS VARCHAR(11))
                                     + ', @iAutoProcessRunId = '
                                     + ISNULL(
                                                 CAST(@OriginalInputAutoProcessRunId AS VARCHAR(11)) ,
                                                 'NULL'
                                             )
                                     + ' /*Note: If null, then new AutoProcessRunId will be assigned */'
                                     + ', @iFilteredAuditAutoProcessRunId = '
                                     + +ISNULL(
                                                  CAST(@iFilteredAuditAutoProcessRunId AS VARCHAR(11)) ,
                                                  'NULL'
                                              ) + ', @iCTRLoadDate = '''
                                     + CONVERT(CHAR(10), @iCTRLoadDate, 121)
                                     + ''''
                                     + '  /*B Parameters that are changed less frequently */'
                                     + ', @iDeliveredDate = '''
                                     + CONVERT(CHAR(10), @iDeliveredDate, 121)
                                     + '''' + ', @iModelYearA = '
                                     + ISNULL(
                                                 CAST(@iModelYearA AS VARCHAR(11)) ,
                                                 'NULL'
                                             ) + ', @iModelYearB = '
                                     + ISNULL(
                                                 CAST(@iModelYearB AS VARCHAR(11)) ,
                                                 'NULL'
                                             )
                                     + ', @iBlendedPaymentDetailHeaderA = '''
                                     + @iBlendedPaymentDetailHeaderA
                                     + ''', @iBlendedPaymentDetailHeaderB = '''
                                     + @iBlendedPaymentDetailHeaderB
                                     + ''', @iBlendedPaymentDetailHeaderESRD = '''
                                     + @iBlendedPaymentDetailHeaderESRD
                                     + ''', @iTotalsDetailHeaderA = '''
                                     + @iTotalsDetailHeaderA
                                     + ''', @iTotalsDetailHeaderB = '''
                                     + @iTotalsDetailHeaderB
                                     + ''', @iTotalsDetailHeaderESRD = '''
                                     + @iTotalsDetailHeaderESRD
                                     + ''', @iTotalsSummaryHeader = '''
                                     + @iTotalsSummaryHeader
                                     + ''', @iYearToYearSummaryRowDisplay = '''
                                     + @iYearToYearSummaryRowDisplay
                                     + ''', @iRetrospectiveValuationDetailDOSPaymentYearHeader = '''
                                     + @iRetrospectiveValuationDetailDOSPaymentYearHeader
                                     + ''' , @iPAYMENT_YEAR = '''
                                     + @iPAYMENT_YEAR + ''
                                     + ''', @iPROCESSBY_START = '''
                                     + CONVERT(
                                                  CHAR(10) ,
                                                  @iPROCESSBY_START ,
                                                  121
                                              ) + ''
                                     + ''', @iPROCESSBY_END = '''
                                     + CONVERT(CHAR(10), @iPROCESSBY_END, 121)
                                     + '' + ''', @iSERVERNAME = '''
                                     + @iSERVERNAME + ''
                                     + ''', @CTRSummaryServer  = '''
                                     + @CTRSummaryServer + ''
                                     + ''', @CTRSummaryDb  = '''
                                     + @CTRSummaryDb + ''''
                                     + +' /*E Parameters that are changed less frequently */'
                                     + ', @Debug = '
                                     + CAST(@Debug AS CHAR(1)) ,
                       [BDate] = GETDATE() ,
                       [EDate] = GETDATE() ,
                       [AutoProcessWorkerId] = -1 ,
                       [RowCount] = NULL ,
                       [SPID] = NULL ,
                       [ErrorInfo] = NULL ,
                       [Result] = NULL ,
                       [Retry] = NULL ,
                       [Status] = 'Completed' ,
                       [AutoProcessActionCatalogId] = NULL ,
                       [DependAutoProcessActionCatalogId] = NULL ,
                       [ByPlan] = 0 ,
                       [StopAll] = 0
                UNION ALL
                SELECT [GlobalProcessRunId] = -1 ,
                       [ClientId] = @iClientId ,
                       [AutoProcessRunId] = @iAutoProcessRunId ,
                       [AutoProcessId] = -1 ,
                       [AutoProcessActionId] = NULL ,
                       [Phase] = 9999999 ,
                       [Priority] = 1 ,
                       [PreRunSecs] = 99999 ,
                       [DbName] = DB_NAME() ,
                       [CommandDb] = DB_NAME() ,
                       [CommandSchema] = '[Valuation]' ,
                       [CommandSTP] = '[UpdateEDateAutoProcessRun]' ,
                       [Parameter] = '@Mode = 2, @AutoProcessRunId = '
                                     + CAST(@iAutoProcessRunId AS VARCHAR(11)) ,
                       [BDate] = NULL ,
                       [EDate] = NULL ,
                       [AutoProcessWorkerId] = NULL ,
                       [RowCount] = NULL ,
                       [SPID] = NULL ,
                       [ErrorInfo] = NULL ,
                       [Result] = NULL ,
                       [Retry] = NULL ,
                       [Status] = NULL ,
                       [AutoProcessActionCatalogId] = NULL ,
                       [DependAutoProcessActionCatalogId] = NULL ,
                       [ByPlan] = 0 ,
                       [StopAll] = 0
                UNION ALL
                SELECT [GlobalProcessRunId] = -1 ,
                       [ClientId] = @iClientId ,
                       [AutoProcessRunId] = @iAutoProcessRunId ,
                       [AutoProcessId] = -1 ,
                       [AutoProcessActionId] = NULL ,
                       [Phase] = 9999999 ,
                       [Priority] = 2 ,
                       [PreRunSecs] = 99999 ,
                       [DbName] = DB_NAME() ,
                       [CommandDb] = DB_NAME() ,
                       [CommandSchema] = '[Valuation]' ,
                       [CommandSTP] = '[UpdateEDateAutoProcessRun]' ,
                       [Parameter] = '@Mode = 3, @AutoProcessRunId = '
                                     + CAST(@iAutoProcessRunId AS VARCHAR(11)) ,
                       [BDate] = NULL ,
                       [EDate] = NULL ,
                       [AutoProcessWorkerId] = NULL ,
                       [RowCount] = NULL ,
                       [SPID] = NULL ,
                       [ErrorInfo] = NULL ,
                       [Result] = NULL ,
                       [Retry] = NULL ,
                       [Status] = NULL ,
                       [AutoProcessActionCatalogId] = NULL ,
                       [DependAutoProcessActionCatalogId] = NULL ,
                       [ByPlan] = 0 ,
                       [StopAll] = 0

    /*E Add [Valuation].[UpdateEDateAutoProcessRun] */

    IF @Debug = 1
        BEGIN
            EXEC [dbo].[PerfLogMonitor] '026' ,
                                        @ProcessNameIn ,
                                        @ET ,
                                        @MasterET ,
                                        @ET OUT ,
                                        0 ,
                                        0
        END

        /*B Add PreRunSecs */

        --
        /**/;
    WITH [CTE_PreviousRunSub]
    AS ( /*B Get the last [AutoProcessWorkListId] for DbName, Schema & STP */ SELECT   [AutoProcessWorkListId] = MAX([pwl].[AutoProcessWorkListId]) ,
                                                                                       [DbName] = [pwl].[DbName] ,
                                                                                       [CommandDb] = [pwl].[CommandDb] ,
                                                                                       [CommandSchema] = [pwl].[CommandSchema] ,
                                                                                       [CommandSTP] = [pwl].[CommandSTP]
                                                                              FROM     [Valuation].[AutoProcessWorkList] [pwl]
                                                                              WHERE    [pwl].[BDate] IS NOT NULL
                                                                                       AND [pwl].[EDate] IS NOT NULL
                                                                              GROUP BY [pwl].[DbName] ,
                                                                                       [pwl].[CommandDb] ,
                                                                                       [pwl].[CommandSchema] ,
                                                                                       [pwl].[CommandSTP]

    /*E Get the last [AutoProcessWorkListId] for DbName, Schema & STP */
       ) ,
         [CTE_PreviousRun]
    AS ( /*B Get the last ET for DbName, Schema & STP */ SELECT   [DbName] = [pwl].[DbName] ,
                                                                  [CommandDb] = [pwl].[CommandDb] ,
                                                                  [CommandSchema] = [pwl].[CommandSchema] ,
                                                                  [CommandSTP] = [pwl].[CommandSTP] ,
                                                                  [ET(secs)] = DATEDIFF(
                                                                                           ss ,
                                                                                           [pwl].[BDate],
                                                                                           [pwl].[EDate]
                                                                                       )
                                                         FROM     [Valuation].[AutoProcessWorkList] [pwl]
                                                                  JOIN [CTE_PreviousRunSub] [a1] ON [pwl].[AutoProcessWorkListId] = [a1].[AutoProcessWorkListId]
                                                         WHERE    [pwl].[BDate] IS NOT NULL
                                                                  AND [pwl].[EDate] IS NOT NULL
                                                         GROUP BY [pwl].[DbName] ,
                                                                  [pwl].[CommandDb] ,
                                                                  [pwl].[CommandSchema] ,
                                                                  [pwl].[CommandSTP] ,
                                                                  [pwl].[BDate] ,
                                                                  [pwl].[EDate]

         /*E Get the last ET for DbName, Schema & STP */
       ) ,
         [CTE_Avg]
    AS ( SELECT   [DbName] = [pwl].[DbName] ,
                  [CommandDb] = [pwl].[CommandDb] ,
                  [CommandSchema] = [pwl].[CommandSchema] ,
                  [CommandSTP] = [pwl].[CommandSTP] ,
                  [ET(secs)] = AVG(DATEDIFF(ss, [pwl].[BDate], [pwl].[EDate]))
         FROM     [Valuation].[AutoProcessWorkList] [pwl]
         WHERE    [pwl].[BDate] IS NOT NULL
                  AND [pwl].[EDate] IS NOT NULL
         GROUP BY [pwl].[DbName] ,
                  [pwl].[CommandDb] ,
                  [pwl].[CommandSchema] ,
                  [pwl].[CommandSTP]
       ) ,
         [CTE_Results]
    AS ( SELECT   [b].[DbName] ,
                  [b].[CommandDb] ,
                  [b].[CommandSchema] ,
                  [b].[CommandSTP] ,
                  [ET(secs)] = AVG([b].[ET(secs)])
         FROM     (   SELECT [a].[DbName] ,
                             [a].[CommandDb] ,
                             [a].[CommandSchema] ,
                             [a].[CommandSTP] ,
                             [a].[ET(secs)]
                      FROM   [CTE_PreviousRun] [a]
                      UNION ALL
                      SELECT [a].[DbName] ,
                             [a].[CommandDb] ,
                             [a].[CommandSchema] ,
                             [a].[CommandSTP] ,
                             [a].[ET(secs)]
                      FROM   [CTE_Avg] [a]
                  ) [b]
         GROUP BY [b].[DbName] ,
                  [b].[CommandDb] ,
                  [b].[CommandSchema] ,
                  [b].[CommandSTP]
       )
    UPDATE [pwl]
    SET    [pwl].[PreRunSecs] = [r1].[ET(secs)]
    FROM   [Valuation].[AutoProcessWorkList] [pwl]
           JOIN [CTE_Results] [r1] ON ISNULL([pwl].[DbName], 'x') = ISNULL(
                                                                              [r1].[DbName] ,
                                                                              'x'
                                                                          )
                                      AND ISNULL([pwl].[CommandDb], 'x') = ISNULL(
                                                                                     [r1].[CommandDb] ,
                                                                                     'x'
                                                                                 )
                                      AND ISNULL([pwl].[CommandSchema], 'x') = ISNULL(
                                                                                         [r1].[CommandSchema] ,
                                                                                         'x'
                                                                                     )
                                      AND [pwl].[CommandSTP] = [r1].[CommandSTP]
    WHERE  [pwl].[AutoProcessRunId] = @iAutoProcessRunId
           AND (   [pwl].[ErrorInfo] IS NULL
                   OR [pwl].[ErrorInfo] = ''
               )
           AND [r1].[ET(secs)] > 0

    /*E Add PreRunSecs */

    IF @Debug = 1
        BEGIN
            EXEC [dbo].[PerfLogMonitor] '027' ,
                                        @ProcessNameIn ,
                                        @ET ,
                                        @MasterET ,
                                        @ET OUT ,
                                        0 ,
                                        1
        END
