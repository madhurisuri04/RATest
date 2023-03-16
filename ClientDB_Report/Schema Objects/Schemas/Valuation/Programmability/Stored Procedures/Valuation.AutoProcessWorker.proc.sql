CREATE PROC [Valuation].[AutoProcessWorker] (@AutoProcessRunId INT = NULL
                                           , @AutoProcessWorkerId SMALLINT = NULL
                                           , @Debug BIT = 0)
AS
    --
    /********************************************************************************************************
* Name			:	Valuation.AutoProcessWorker   															*
* Type 			:	Stored Procedure																		*
* Author       	:	Mitch Casto																				*
* Date			:	2016-09-20																				*
* Version		:	1.0																						*
* Description	:	Used to cycle through work in AutoProcessWorkList table.  Generally run through			*
*					a job.																					*
* Notes: @AutoProcessRunId - runs a specific row singularly from the AutoProcessWorkList table				*
*			If @AutoProcessWorkListId is used, then a value is not required for @AutoProcessRunid			*
*		@AutoProcessWorkListId - runs for a specific row singularly from the AutoProcessWorkList			*
*			table																							*
*																											*
* Version History :																							*
* =================																							*
* Author			Date			Version#    TFS Ticket#		Description									*
* -----------------	----------		--------    -----------		------------								*
* MCasto			2016-09-20		1.0			US54399			Initial										*
* MCasto			2016-10-18		1.1			58445 / US57192												*
* MCasto			2017-04-17		1.2			61356 / US59323	Added code to use							*
*																[Valuation].[AutoProcessActiveWorkList]		*
*																if @AutoProcessRunId is null				*
*																											*
************************************************************************************************************/

    DECLARE @Command NVARCHAR(4000)
    DECLARE @AutoProcessWorkListId INT

    SET STATISTICS IO OFF
    SET NOCOUNT ON

    IF @Debug = 1
        BEGIN
            SET STATISTICS IO ON
            DECLARE @ET DATETIME
            DECLARE @MasterET DATETIME
            SET @ET = GETDATE()
            SET @MasterET = @ET
        END

    IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' | ' + CONVERT(CHAR(23), GETDATE(), 121)
            SET @ET = GETDATE()
            RAISERROR('000', 0, 1) WITH NOWAIT
        END

    IF @AutoProcessRunId IS NULL
        BEGIN


            SELECT @AutoProcessRunId = MAX([apw].[AutoProcessRunId])
              FROM [Valuation].[AutoProcessActiveWorkList] [apw]

        END

    IF @AutoProcessRunId IS NULL
        BEGIN

            DECLARE @Msg VARCHAR(4000)

            SET @Msg
                = '@AutoProcessRunId parameter is NULL and [Valuation].[AutoProcessActiveWorkList] table is empty. Process halted.'
            RAISERROR(@Msg, 15, 15) WITH NOWAIT
            RETURN

        END


    IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' | ' + CONVERT(CHAR(23), GETDATE(), 121)
            SET @ET = GETDATE()
            RAISERROR('001', 0, 1) WITH NOWAIT
        END

    IF @AutoProcessRunId IS NOT NULL
        BEGIN

            IF @Debug = 1
                BEGIN
                    PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                          + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' | ' + CONVERT(CHAR(23), GETDATE(), 121)
                    SET @ET = GETDATE()
                    RAISERROR('002', 0, 1) WITH NOWAIT
                END

            WHILE EXISTS (SELECT
                              1
                            FROM
                              [Valuation].[AutoProcessWorkList] [pwl]
                           WHERE
                                 [pwl].[AutoProcessRunId] = @AutoProcessRunId
                             AND [pwl].[BDate] IS NULL
                             AND [pwl].[EDate] IS NULL
            )
                BEGIN

                    IF @Debug = 1
                        BEGIN
                            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                                  + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' | ' + CONVERT(CHAR(23), GETDATE(), 121)
                            SET @ET = GETDATE()
                            RAISERROR('003', 0, 1) WITH NOWAIT
                        END

                    SET @AutoProcessWorkListId = NULL

                    SELECT TOP 1 @AutoProcessWorkListId = [pwl].[AutoProcessWorkListId]
                      FROM [Valuation].[AutoProcessWorkList] [pwl] WITH (XLOCK, ROWLOCK)
                     WHERE [pwl].[AutoProcessRunId]                          = @AutoProcessRunId
                       AND [pwl].[BDate] IS NULL
                       AND [pwl].[EDate] IS NULL
                       AND [pwl].[Phase] IN (SELECT MIN([pwl].[Phase])
                                               FROM [Valuation].[AutoProcessWorkList] [pwl] WITH (XLOCK, ROWLOCK)
                                              WHERE [pwl].[AutoProcessRunId] = @AutoProcessRunId
                                                AND [pwl].[EDate] IS NULL)
                     ORDER BY [pwl].[Phase]
                            , [pwl].[Priority]
                            , [pwl].[PreRunSecs] DESC
                            , [pwl].[DbName]
                            , [pwl].[CommandDb]
                            , [pwl].[CommandSchema]
                            , [pwl].[CommandSTP]


                    IF @Debug = 1
                        BEGIN
                            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                                  + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' | ' + CONVERT(CHAR(23), GETDATE(), 121)
                            SET @ET = GETDATE()
                            RAISERROR('004', 0, 1) WITH NOWAIT
                        END

                    IF @AutoProcessWorkListId IS NOT NULL
                        BEGIN

                            IF @Debug = 1
                                BEGIN
                                    PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                                          + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' | '
                                          + CONVERT(CHAR(23), GETDATE(), 121)
                                    SET @ET = GETDATE()
                                    RAISERROR('005', 0, 1) WITH NOWAIT
                                END

                            SELECT @Command
                                = '[' + REPLACE(REPLACE([pwl].[CommandDb], ']', ''), '[', '') + '].['
                                  + REPLACE(REPLACE([pwl].[CommandSchema], ']', ''), '[', '') + '].['
                                  + REPLACE(REPLACE([pwl].[CommandSTP], ']', ''), '[', '') + '] ' + [pwl].[Parameter]
                              FROM [Valuation].[AutoProcessWorkList] [pwl]
                             WHERE [pwl].[AutoProcessWorkListId] = @AutoProcessWorkListId

                            IF @Debug = 1
                                BEGIN
                                    PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                                          + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' | '
                                          + CONVERT(CHAR(23), GETDATE(), 121)
                                    SET @ET = GETDATE()
                                    RAISERROR('006', 0, 1) WITH NOWAIT
                                END

                            UPDATE [m]
                               SET [m].[BDate] = GETDATE()
                                 , [m].[AutoProcessWorkerId] = @AutoProcessWorkerId
                                 , [m].[SPID] = @@SPID
                                 , [m].[Status] = 'Started'
                              FROM [Valuation].[AutoProcessWorkList] [m]
                             WHERE [m].[AutoProcessWorkListId] = @AutoProcessWorkListId

                            PRINT '--===================='
                            PRINT @Command
                            PRINT '--===================='
                            RAISERROR('', 0, 1) WITH NOWAIT

                            IF @Debug = 1
                                BEGIN
                                    PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                                          + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' | '
                                          + CONVERT(CHAR(23), GETDATE(), 121)
                                    SET @ET = GETDATE()
                                    RAISERROR('007', 0, 1) WITH NOWAIT
                                END

                            DECLARE @ERROR_MESSAGE NVARCHAR(4000)
                            DECLARE @ERROR_SEVERITY INT
                            DECLARE @ERROR_STATE INT
                            DECLARE @ERROR_PROCEDURE VARCHAR(128)
                            DECLARE @ERROR_LINE INT
                            DECLARE @ERROR_NUMBER INT

                            BEGIN TRY

                                IF @Debug = 1
                                    BEGIN
                                        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                                              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' | '
                                              + CONVERT(CHAR(23), GETDATE(), 121)
                                        SET @ET = GETDATE()
                                        RAISERROR('008', 0, 1) WITH NOWAIT
                                    END

                                EXEC [sys].[sp_executesql] @Command

                                WAITFOR DELAY '00:00:00.25'
                                DECLARE @t CHAR(10) = '00:00:00.' + CAST(CAST(RAND() * 10 AS INT) AS CHAR(1))
                                SET @t = '00:00:0' + CAST(CAST(RAND() * 10 AS INT) AS CHAR(1))
                                WAITFOR DELAY @t

                                IF @Debug = 1
                                    BEGIN
                                        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                                              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' | '
                                              + CONVERT(CHAR(23), GETDATE(), 121)
                                        SET @ET = GETDATE()
                                        RAISERROR('009', 0, 1) WITH NOWAIT
                                    END

                            END TRY
                            BEGIN CATCH

                                SET @ERROR_MESSAGE = ERROR_MESSAGE()
                                SET @ERROR_SEVERITY = ERROR_SEVERITY()
                                SET @ERROR_STATE = ERROR_STATE()
                                SET @ERROR_PROCEDURE = ERROR_PROCEDURE()
                                SET @ERROR_LINE = ERROR_LINE()
                                SET @ERROR_NUMBER = ERROR_NUMBER()

                                UPDATE [m]
                                   SET [m].[ErrorInfo] = CASE
                                                              WHEN @ERROR_MESSAGE LIKE 'Info: %'
                                                                  THEN @ERROR_MESSAGE
                                                              ELSE
                                                                  'Error Message: ' + ISNULL(@ERROR_MESSAGE, 'N/a')
                                                                  + ' | Error State: '
                                                                  + CAST(ISNULL(@ERROR_STATE, '') AS VARCHAR(11))
                                                                  + ' | Error Procedure: '
                                                                  + ISNULL(@ERROR_PROCEDURE, 'N/a')
                                                                  + ' | Error Severity: '
                                                                  + CAST(ISNULL(@ERROR_SEVERITY, '') AS VARCHAR(11))
                                                                  + ' | Error Line: '
                                                                  + CAST(ISNULL(@ERROR_LINE, '') AS VARCHAR(11))
                                                                  + ' | Error Number: '
                                                                  + CAST(ISNULL(@ERROR_NUMBER, '') AS VARCHAR(11))
                                                         END
                                     , [m].[Status] = 'Error'
                                     , [m].[EDate] = GETDATE()
                                  FROM [Valuation].[AutoProcessWorkList] [m]
                                 WHERE [m].[AutoProcessWorkListId] = @AutoProcessWorkListId

                                /*B If specific error numbers, retry code */

                                IF @ERROR_NUMBER IN (1205)
                                    BEGIN
                                        DECLARE @RetryCount INT

                                        SET @RetryCount = 0

                                        SELECT @RetryCount = COUNT(*)
                                          FROM [Valuation].[AutoProcessWorkList] [apw01] WITH (NOLOCK)
                                          LEFT JOIN [Valuation].[AutoProcessWorkList] [apw02] WITH (NOLOCK)
                                            ON [apw01].[DbName]           = [apw02].[DbName]
                                           AND [apw01].[CommandDb]        = [apw02].[CommandDb]
                                           AND [apw01].[CommandSchema]    = [apw02].[CommandSchema]
                                           AND [apw01].[CommandSTP]       = [apw02].[CommandSTP]
                                           AND [apw01].[Parameter]        = [apw02].[Parameter]
                                           AND [apw01].[AutoProcessRunId] = [apw02].[AutoProcessRunId]

                                         WHERE [apw01].[AutoProcessRunId]      = @AutoProcessRunId
                                           AND [apw01].[AutoProcessWorkListId] = @AutoProcessWorkListId


                                        IF @RetryCount < 3
                                            BEGIN
                                                INSERT INTO [Valuation].[AutoProcessWorkList] ([GlobalProcessRunId]
                                                                                             , [ClientId]
                                                                                             , [AutoProcessRunId]
                                                                                             , [AutoProcessId]
                                                                                             , [AutoProcessActionId]
                                                                                             , [Phase]
                                                                                             , [Priority]
                                                                                             , [PreRunSecs]
                                                                                             , [DbName]
                                                                                             , [CommandDb]
                                                                                             , [CommandSchema]
                                                                                             , [CommandSTP]
                                                                                             , [Parameter]
                                                                                             , [BDate]
                                                                                             , [EDate]
                                                                                             , [AutoProcessWorkerId]
                                                                                             , [RowCount]
                                                                                             , [SPID]
                                                                                             , [ErrorInfo]
                                                                                             , [Result]
                                                                                             , [Retry]
                                                                                             , [Status]
                                                                                             , [AutoProcessActionCatalogId]
                                                                                             , [DependAutoProcessActionCatalogId]
                                                                                             , [ByPlan]
                                                                                             , [StopAll])

                                                SELECT [GlobalProcessRunId] = [apw01].[GlobalProcessRunId]
                                                     , [ClientId] = [apw01].[ClientId]
                                                     , [AutoProcessRunId] = [apw01].[AutoProcessRunId]
                                                     , [AutoProcessId] = [apw01].[AutoProcessId]
                                                     , [AutoProcessActionId] = [apw01].[AutoProcessActionId]
                                                     , [Phase] = [apw01].[Phase]
                                                     , [Priority] = [apw01].[Priority]
                                                     , [PreRunSecs] = [apw01].[PreRunSecs]
                                                     , [DbName] = [apw01].[DbName]
                                                     , [CommandDb] = [apw01].[CommandDb]
                                                     , [CommandSchema] = [apw01].[CommandSchema]
                                                     , [CommandSTP] = [apw01].[CommandSTP]
                                                     , [Parameter] = [apw01].[Parameter]
                                                     , [BDate] = NULL
                                                     , [EDate] = NULL
                                                     , [AutoProcessWorkerId] = NULL
                                                     , [RowCount] = NULL
                                                     , [SPID] = NULL
                                                     , [ErrorInfo] = NULL
                                                     , [Result] = NULL
                                                     , [Retry] = @RetryCount
                                                     , [Status] = NULL
                                                     , [AutoProcessActionCatalogId] = [apw01].[AutoProcessActionCatalogId]
                                                     , [DependAutoProcessActionCatalogId] = [apw01].[DependAutoProcessActionCatalogId]
                                                     , [ByPlan] = [apw01].[ByPlan]
                                                     , [StopAll] = [apw01].[StopAll]
                                                  FROM [Valuation].[AutoProcessWorkList] [apw01]
                                                 WHERE [apw01].[AutoProcessWorkListId] = @AutoProcessWorkListId

                                                WAITFOR DELAY '00:00:03'
                                            END

                                    END

                                /*E If specific error numbers, retry code */

                                GOTO NextLoop

                            END CATCH



                            IF @Debug = 1
                                BEGIN
                                    PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                                          + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' | '
                                          + CONVERT(CHAR(23), GETDATE(), 121)
                                    SET @ET = GETDATE()
                                    RAISERROR('010', 0, 1) WITH NOWAIT
                                END


                            UPDATE [m]
                               SET [m].[EDate] = GETDATE()
                                 , [m].[Status] = 'Completed'
                                 , [m].[SPID] = NULL
                              FROM [Valuation].[AutoProcessWorkList] [m]
                             WHERE [m].[AutoProcessWorkListId] = @AutoProcessWorkListId

                            IF @Debug = 1
                                BEGIN
                                    PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                                          + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' | '
                                          + CONVERT(CHAR(23), GETDATE(), 121)
                                    SET @ET = GETDATE()
                                    RAISERROR('011', 0, 1) WITH NOWAIT
                                END
                            NextLoop:
                        END

                    IF @AutoProcessWorkListId IS NULL
                        BEGIN
                            RAISERROR('--=====================================--', 0, 1) WITH NOWAIT
                            RAISERROR('Waiting for available work.', 0, 1) WITH NOWAIT
                            RAISERROR('--=====================================--', 0, 1) WITH NOWAIT
                            WAITFOR DELAY '00:00:05'
                        END

                END
        END

    IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' | ' + CONVERT(CHAR(23), GETDATE(), 121)
            RAISERROR('012', 0, 1) WITH NOWAIT
            PRINT 'Total ET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' | ' + CONVERT(CHAR(23), GETDATE(), 121)
            RAISERROR('Done.|', 0, 1) WITH NOWAIT
        END
