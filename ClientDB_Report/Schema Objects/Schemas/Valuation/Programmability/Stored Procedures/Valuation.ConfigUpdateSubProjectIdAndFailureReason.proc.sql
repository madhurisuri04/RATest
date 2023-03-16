CREATE PROC [Valuation].[ConfigUpdateSubProjectIdAndFailureReason]
    (
        @ClientId INT ,
        @AutoProcessRunId INT ,
        @ProjectIdList VARCHAR(2048) ,
        @Debug BIT = 0
    )
AS

    /************************************************************************************************************************ 
* Name			:	Valuation.ConfigUpdateSubProjectIdAndFailureReason													*
* Type 			:	Stored Procedure																					*
* Author       	:	Mitch Casto																							*
* Date			:	2015-04-21																							*
* Version			:	1.0																								*
* Description		:	Updates the SubprojectId and FailureReason on the Valuation.NewHCCPartC	and						*
*						Valuation.NewHCCPartD tables based on PCN string												*
*																														*
* Version History	:																									*
* ===================																									*
* Author			Date		  Version#    TFS Ticket#	Description													*
* -----------------	----------  --------    -----------	------------													*
* MCasto			2015-04-21  1.0	    39812			Initial															*
* DWaddell			2015-10-15  1.1	    47099			Added debuggging code											*
* MCasto			2015-12-01  1.2	    48152			Added flexibility to handle different types of PCN strings		*
* MCasto			2016-01-06  1.3	    47772			Optimized pattern update (Section 027 thru 033) for performance	*
*																														*
* DWaddell			2016-02-04	1.4		47772			Change the stored procedure to use HCC_PROCESSED_PCN  instead of*
*														ClaimID in determining PCN string								*
*																														*
* MCasto			2016-10-04	1.5		58445			Added PL_Audit 2016 patch (Section 033 thru 036)				*
* MCasto			2017-07-27	1.6		RE1039/US67184	Added filter to PL_Audit 2016 patch (Section 033 thru 034)		*																										*
*										TFS66078																		*
*************************************************************************************************************************/

    SET STATISTICS IO OFF
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


    DECLARE @ActionList TABLE
        (
            [Id] INT IDENTITY(1, 1) PRIMARY KEY ,
            [SubProjectId] INT ,
            [PCNStringPattern] VARCHAR(255) ,
            [UniquePattern] VARCHAR(255) ,
            [FailureReason] VARCHAR(20) ,
            [Priority] TINYINT ,
            [Source01] VARCHAR(255) ,
            [Filler01] CHAR(1) ,
            [Filler02] CHAR(1) ,
            [Payment_Year] CHAR(4) ,
            [SubprojectIdBPosition] INT ,
            [SubprojectIdLength] INT ,
            [ProviderIdBPosition] INT ,
            [ProviderIdLength] INT ,
            [FullPattern] VARCHAR(256) ,
            [UpdateStatement] VARCHAR(4000)
        )

    DECLARE @tblProjectIdList TABLE
        (
            [ProjectId] INT
        )

    IF @Debug = 1
        BEGIN

            EXEC [dbo].[PerfLogMonitor] @Section = '001' ,
                                        @ProcessName = @ProcessNameIn ,
                                        @ET = @ET ,
                                        @MasterET = @MasterET ,
                                        @ET_Out = @ET OUT ,
                                        @TableOutput = 0 ,
                                        @End = 0

        END

        /**/;
    WITH [CTE_parse] ( [Starting_Character], [Ending_Character], [Occurence] )
    AS ( SELECT [Starting_Character] = 1 ,
                [Ending_Character] = CAST(CHARINDEX(',', @ProjectIdList + ',') AS INT) ,
                [Occurence] = 1
         UNION ALL
         SELECT [Starting_Character] = [CTE_parse].[Ending_Character] + 1 ,
                [Ending_Character] = CAST(CHARINDEX(
                                                       ',' ,
                                                       @ProjectIdList + ',',
                                                       [CTE_parse].[Ending_Character]
                                                       + 1
                                                   ) AS INT) ,
                [CTE_parse].[Occurence] + 1
         FROM   [CTE_parse]
         WHERE  CHARINDEX(',', @ProjectIdList + ',', [Ending_Character] + 1) <> 0
       )
    INSERT INTO @tblProjectIdList ( [ProjectId] )
                SELECT [StringValues] = CAST(LTRIM(RTRIM(SUBSTRING(
                                                                      @ProjectIdList ,
                                                                      [CTE_parse].[Starting_Character],
                                                                      [CTE_parse].[Ending_Character]
                                                                      - [CTE_parse].[Starting_Character]
                                                                  )
                                                        )
                                                  ) AS INT)
                FROM   [CTE_parse]


    IF @Debug = 1
        BEGIN

            EXEC [dbo].[PerfLogMonitor] @Section = '002' ,
                                        @ProcessName = @ProcessNameIn ,
                                        @ET = @ET ,
                                        @MasterET = @MasterET ,
                                        @ET_Out = @ET OUT ,
                                        @TableOutput = 0 ,
                                        @End = 0

        END

    INSERT INTO @ActionList (   [SubProjectId] ,
                                [PCNStringPattern] ,
                                [UniquePattern] ,
                                [FailureReason] ,
                                [Priority] ,
                                [Source01] ,
                                [Filler01] ,
                                [Filler02] ,
                                [FullPattern] ,
                                [Payment_Year] ,
                                [SubprojectIdBPosition] ,
                                [SubprojectIdLength] ,
                                [ProviderIdBPosition] ,
                                [ProviderIdLength] ,
                                [UpdateStatement]
                            )
                SELECT [SubProjectId] = [spsp].[SubProjectId] ,
                       [PCNStringPattern] = [spsp].[PCNStringPattern] ,
                       [UniquePattern] = [spsp].[UniquePattern] ,
                       [FailureReason] = ISNULL([spsp].[FailureReason], 'N/a') ,
                       [Priority] = CASE WHEN [spsp].[Filler01] IS NULL
                                              AND [spsp].[Filler02] IS NULL THEN
                                             1
                                         ELSE 2
                                    END ,
                       [Source01] = [spsp].[Source01] ,
                       [Filler01] = [spsp].[Filler01] ,
                       [Filler02] = [spsp].[Filler02] ,
                       [FullPattern] = REPLACE(
                                                  [spsp].[Source01]
                                                  + [spsp].[ProviderType]
                                                  + [spsp].[OnShoreOffShore]
                                                  + [spsp].[ID_VAN]
                                                  + [spsp].[PMH]
                                                  + [spsp].[MissingSignature]
                                                  + [spsp].[Filler01]
                                                  + [spsp].[Filler02] ,
                                                  '_' ,
                                                  '[_]'
                                              )
                                       + REPLACE(
                                                    [spsp].[UniquePattern] ,
                                                    'Z' ,
                                                    '_'
                                                ) ,
                       [Payment_Year] = [spsp].[Payment_Year] ,
                       [spsp].[SubprojectIdBPosition] ,
                       [spsp].[SubprojectIdLength] ,
                       [spsp].[ProviderIdBPosition] ,
                       [spsp].[ProviderIdLength] ,
                       [spsp].[UpdateStatement]
                FROM   [Valuation].[ConfigSubProjectSubstringPattern] [spsp]
                WHERE  [spsp].[ClientId] = @ClientId
                       AND [spsp].[ActiveBDate] <= GETDATE()
                       AND ISNULL(
                                     [spsp].[ActiveEDate] ,
                                     DATEADD(dd, 1, GETDATE())
                                 ) > GETDATE()
                       AND (   [spsp].[PCNStringPattern] IS NOT NULL
                               OR [spsp].[UpdateStatement] IS NOT NULL
                           )
                       AND [spsp].[ProjectId] IN (   SELECT [ProjectId]
                                                     FROM   @tblProjectIdList
                                                 )


    IF @Debug = 1
        BEGIN
            EXEC [dbo].[PerfLogMonitor] @Section = '003' ,
                                        @ProcessName = @ProcessNameIn ,
                                        @ET = @ET ,
                                        @MasterET = @MasterET ,
                                        @ET_Out = @ET OUT ,
                                        @TableOutput = 0 ,
                                        @End = 0

        END

    /*B Reset PCN_SubProjectId and FailureReason */

    UPDATE [pc]
    SET    [pc].[PCN_SubprojectId] = NULL ,
           [pc].[FailureReason] = NULL
    FROM   [Valuation].[NewHCCPartC] [pc]
    WHERE  [pc].[ProcessRunId] = @AutoProcessRunId

    IF @Debug = 1
        BEGIN

            EXEC [dbo].[PerfLogMonitor] @Section = '004' ,
                                        @ProcessName = @ProcessNameIn ,
                                        @ET = @ET ,
                                        @MasterET = @MasterET ,
                                        @ET_Out = @ET OUT ,
                                        @TableOutput = 0 ,
                                        @End = 0

        END

    UPDATE [pc]
    SET    [pc].[PCN_SubprojectId] = NULL ,
           [pc].[FailureReason] = NULL
    FROM   [Valuation].[NewHCCPartD] [pc]
    WHERE  [pc].[ProcessRunId] = @AutoProcessRunId


    /*E Reset PCN_SubProjectId and FailureReason */

    IF @Debug = 1
        BEGIN

            EXEC [dbo].[PerfLogMonitor] @Section = '005' ,
                                        @ProcessName = @ProcessNameIn ,
                                        @ET = @ET ,
                                        @MasterET = @MasterET ,
                                        @ET_Out = @ET OUT ,
                                        @TableOutput = 0 ,
                                        @End = 0

        END

    DECLARE @Source01 VARCHAR(255)
    DECLARE @SubprojectIdBPosition INT
    DECLARE @SubprojectIdLength INT
    DECLARE @ProviderIdBPosition INT
    DECLARE @ProviderIdLength INT
    DECLARE @UpdateStatement VARCHAR(4000)
    DECLARE @UpdateStatement_SQL VARCHAR(8000)
    DECLARE @FullPattern VARCHAR(256)


    /*B Keep list of valid SubprojectId */

    DECLARE @SubProjectIdList TABLE
        (
            [SubProjectId] VARCHAR(32) ,
            [FailureReason] VARCHAR(20)
        )

    IF @Debug = 1
        BEGIN

            EXEC [dbo].[PerfLogMonitor] @Section = '006' ,
                                        @ProcessName = @ProcessNameIn ,
                                        @ET = @ET ,
                                        @MasterET = @MasterET ,
                                        @ET_Out = @ET OUT ,
                                        @TableOutput = 0 ,
                                        @End = 0

        END

    INSERT INTO @SubProjectIdList (   [SubProjectId] ,
                                      [FailureReason]
                                  )
                SELECT DISTINCT [SubProjectId] ,
                       [FailureReason]
                FROM   @ActionList


    /*E Keep list of valid SubprojectId */

    IF @Debug = 1
        BEGIN

            EXEC [dbo].[PerfLogMonitor] @Section = '007' ,
                                        @ProcessName = @ProcessNameIn ,
                                        @ET = @ET ,
                                        @MasterET = @MasterET ,
                                        @ET_Out = @ET OUT ,
                                        @TableOutput = 0 ,
                                        @End = 0

        END

    /*B Update Clause */

    WHILE EXISTS (   SELECT *
                     FROM   @ActionList
                     WHERE  [UpdateStatement] IS NOT NULL
                 )
        BEGIN

            IF @Debug = 1
                BEGIN

                    EXEC [dbo].[PerfLogMonitor] @Section = '008' ,
                                                @ProcessName = @ProcessNameIn ,
                                                @ET = @ET ,
                                                @MasterET = @MasterET ,
                                                @ET_Out = @ET OUT ,
                                                @TableOutput = 0 ,
                                                @End = 0

                END

            SELECT   TOP 1 @UpdateStatement = [a].[UpdateStatement] ,
                     @Source01 = [a].[Source01]
            FROM     @ActionList [a]
            WHERE    [a].[UpdateStatement] IS NOT NULL
            ORDER BY [a].[SubProjectId]

            IF @Debug = 1
                BEGIN

                    EXEC [dbo].[PerfLogMonitor] @Section = '009' ,
                                                @ProcessName = @ProcessNameIn ,
                                                @ET = @ET ,
                                                @MasterET = @MasterET ,
                                                @ET_Out = @ET OUT ,
                                                @TableOutput = 0 ,
                                                @End = 0

                END

            IF @UpdateStatement IS NOT NULL
                BEGIN

                    IF @Debug = 1
                        BEGIN

                            EXEC [dbo].[PerfLogMonitor] @Section = '010' ,
                                                        @ProcessName = @ProcessNameIn ,
                                                        @ET = @ET ,
                                                        @MasterET = @MasterET ,
                                                        @ET_Out = @ET OUT ,
                                                        @TableOutput = 0 ,
                                                        @End = 0

                        END

                    SET @UpdateStatement_SQL = '
UPDATE p
SET ' +             REPLACE(
                               @UpdateStatement ,
                               '[$PCNString_ClaimId$]' ,
                               '[HCC_PROCESSED_PCN]'
                           )                   + '
FROM [Valuation].[NewHCCPartC] [p]
WHERE [p].[ProcessRunId] = ' + CAST(@AutoProcessRunId AS VARCHAR(11))
                                               + '
AND [p].[PCN_SubprojectId] IS NULL
AND [p].[HCC_PROCESSED_PCN] LIKE ''' + @Source01 + '%''

UPDATE p
SET ' +             REPLACE(
                               @UpdateStatement ,
                               '[$PCNString_ClaimId$]' ,
                               '[HCC_PROCESSED_PCN]'
                           )                   + '
FROM [Valuation].[NewHCCPartD] [p]
WHERE [p].[ProcessRunId] = ' + CAST(@AutoProcessRunId AS VARCHAR(11))
                                               + '
AND [p].[PCN_SubprojectId] IS NULL
AND [p].[HCC_PROCESSED_PCN] LIKE ''' + @Source01 + '%''

'
                    IF @Debug = 1
                        BEGIN

                            PRINT @UpdateStatement_SQL
                            EXEC [dbo].[PerfLogMonitor] @Section = '011' ,
                                                        @ProcessName = @ProcessNameIn ,
                                                        @ET = @ET ,
                                                        @MasterET = @MasterET ,
                                                        @ET_Out = @ET OUT ,
                                                        @TableOutput = 0 ,
                                                        @End = 0
                        END

                    EXEC ( @UpdateStatement_SQL )

                    IF @Debug = 1
                        BEGIN

                            EXEC [dbo].[PerfLogMonitor] @Section = '012' ,
                                                        @ProcessName = @ProcessNameIn ,
                                                        @ET = @ET ,
                                                        @MasterET = @MasterET ,
                                                        @ET_Out = @ET OUT ,
                                                        @TableOutput = 0 ,
                                                        @End = 0

                        END

                    SET @UpdateStatement_SQL = NULL

                    IF @Debug = 1
                        BEGIN

                            EXEC [dbo].[PerfLogMonitor] @Section = '013' ,
                                                        @ProcessName = @ProcessNameIn ,
                                                        @ET = @ET ,
                                                        @MasterET = @MasterET ,
                                                        @ET_Out = @ET OUT ,
                                                        @TableOutput = 0 ,
                                                        @End = 0

                        END

                    DELETE [m]
                    FROM  @ActionList [m]
                    WHERE [m].[UpdateStatement] = @UpdateStatement

                    IF @Debug = 1
                        BEGIN

                            EXEC [dbo].[PerfLogMonitor] @Section = '014' ,
                                                        @ProcessName = @ProcessNameIn ,
                                                        @ET = @ET ,
                                                        @MasterET = @MasterET ,
                                                        @ET_Out = @ET OUT ,
                                                        @TableOutput = 0 ,
                                                        @End = 0

                        END

                END

            IF @Debug = 1
                BEGIN

                    EXEC [dbo].[PerfLogMonitor] @Section = '015' ,
                                                @ProcessName = @ProcessNameIn ,
                                                @ET = @ET ,
                                                @MasterET = @MasterET ,
                                                @ET_Out = @ET OUT ,
                                                @TableOutput = 0 ,
                                                @End = 0

                END

            /*-B Remove invalid SubprojectIds */

            UPDATE [p]
            SET    [p].[PCN_SubprojectId] = NULL
            FROM   [Valuation].[NewHCCPartC] [p]
            WHERE  [p].[PCN_SubprojectId] NOT IN (   SELECT [m].[SubProjectId]
                                                     FROM   @SubProjectIdList [m]
                                                 )
                   AND [p].[ProcessRunId] = @AutoProcessRunId

            IF @Debug = 1
                BEGIN

                    EXEC [dbo].[PerfLogMonitor] @Section = '016' ,
                                                @ProcessName = @ProcessNameIn ,
                                                @ET = @ET ,
                                                @MasterET = @MasterET ,
                                                @ET_Out = @ET OUT ,
                                                @TableOutput = 0 ,
                                                @End = 0

                END

            UPDATE [p]
            SET    [p].[PCN_SubprojectId] = NULL
            FROM   [Valuation].[NewHCCPartD] [p]
            WHERE  [p].[PCN_SubprojectId] NOT IN (   SELECT [m].[SubProjectId]
                                                     FROM   @SubProjectIdList [m]
                                                 )
                   AND [p].[ProcessRunId] = @AutoProcessRunId

            /*-E Remove invalid SubprojectIds */

            IF @Debug = 1
                BEGIN

                    EXEC [dbo].[PerfLogMonitor] @Section = '017' ,
                                                @ProcessName = @ProcessNameIn ,
                                                @ET = @ET ,
                                                @MasterET = @MasterET ,
                                                @ET_Out = @ET OUT ,
                                                @TableOutput = 0 ,
                                                @End = 0

                END

        END

    /*E Update Clause */


    IF @Debug = 1
        BEGIN

            EXEC [dbo].[PerfLogMonitor] @Section = '018' ,
                                        @ProcessName = @ProcessNameIn ,
                                        @ET = @ET ,
                                        @MasterET = @MasterET ,
                                        @ET_Out = @ET OUT ,
                                        @TableOutput = 0 ,
                                        @End = 0

        END

    /*B Position */

    WHILE EXISTS (   SELECT 1
                     FROM   @ActionList
                     WHERE  [SubprojectIdBPosition] IS NOT NULL
                 )
        BEGIN

            IF @Debug = 1
                BEGIN

                    EXEC [dbo].[PerfLogMonitor] @Section = '019' ,
                                                @ProcessName = @ProcessNameIn ,
                                                @ET = @ET ,
                                                @MasterET = @MasterET ,
                                                @ET_Out = @ET OUT ,
                                                @TableOutput = 0 ,
                                                @End = 0

                END

            SELECT   TOP 1 @SubprojectIdBPosition = [a].[SubprojectIdBPosition] ,
                     @SubprojectIdLength = [a].[SubprojectIdLength] ,
                     @ProviderIdBPosition = [a].[ProviderIdBPosition] ,
                     @ProviderIdLength = [a].[ProviderIdLength] ,
                     @Source01 = [a].[Source01]
            FROM     @ActionList [a]
            ORDER BY [a].[SubProjectId]

            IF @Debug = 1
                BEGIN

                    PRINT '[@SubprojectIdBPosition] = '
                          + ISNULL(
                                      CAST(@SubprojectIdBPosition AS VARCHAR(11)) ,
                                      'NULL'
                                  )
                    PRINT '[@SubprojectIdLength] = '
                          + ISNULL(
                                      CAST(@SubprojectIdLength AS VARCHAR(11)) ,
                                      'NULL'
                                  )
                    PRINT '[@ProviderIdBPosition] = '
                          + ISNULL(
                                      CAST(@ProviderIdBPosition AS VARCHAR(11)) ,
                                      'NULL'
                                  )
                    PRINT '[@ProviderIdLength] = '
                          + ISNULL(
                                      CAST(@ProviderIdLength AS VARCHAR(11)) ,
                                      'NULL'
                                  )
                    PRINT '[@Source01] = ' + ISNULL(@Source01, 'NULL')


                    EXEC [dbo].[PerfLogMonitor] @Section = '020' ,
                                                @ProcessName = @ProcessNameIn ,
                                                @ET = @ET ,
                                                @MasterET = @MasterET ,
                                                @ET_Out = @ET OUT ,
                                                @TableOutput = 0 ,
                                                @End = 0

                END

            UPDATE [p]
            SET    [p].[PCN_SubprojectId] = CASE WHEN SUBSTRING(
                                                                   [p].[HCC_PROCESSED_PCN] ,
                                                                   @SubprojectIdBPosition ,
                                                                   @SubprojectIdLength
                                                               ) IN (   SELECT LTRIM(RTRIM([SubProjectId]))
                                                                        FROM   @SubProjectIdList
                                                                    ) THEN
                                                     SUBSTRING(
                                                                  [p].[HCC_PROCESSED_PCN] ,
                                                                  @SubprojectIdBPosition ,
                                                                  @SubprojectIdLength
                                                              )
                                                 ELSE NULL
                                            END ,
                   [p].[PCN_ProviderId] = SUBSTRING(
                                                       [p].[HCC_PROCESSED_PCN] ,
                                                       @ProviderIdBPosition ,
                                                       @ProviderIdLength
                                                   )
            FROM   [Valuation].[NewHCCPartC] [p]
            WHERE  [p].[ProcessRunId] = @AutoProcessRunId
                   AND [p].[PCN_SubprojectId] IS NULL
                   AND [p].[HCC_PROCESSED_PCN] LIKE @Source01 + '%'

            IF @Debug = 1
                BEGIN

                    EXEC [dbo].[PerfLogMonitor] @Section = '021' ,
                                                @ProcessName = @ProcessNameIn ,
                                                @ET = @ET ,
                                                @MasterET = @MasterET ,
                                                @ET_Out = @ET OUT ,
                                                @TableOutput = 0 ,
                                                @End = 0

                END

            UPDATE [p]
            SET    [p].[PCN_SubprojectId] = SUBSTRING(
                                                         [p].[HCC_PROCESSED_PCN] ,
                                                         @SubprojectIdBPosition ,
                                                         @SubprojectIdLength
                                                     ) ,
                   [p].[PCN_ProviderId] = SUBSTRING(
                                                       [p].[HCC_PROCESSED_PCN] ,
                                                       @ProviderIdBPosition ,
                                                       @ProviderIdLength
                                                   )
            FROM   [Valuation].[NewHCCPartD] [p]
            WHERE  [p].[ProcessRunId] = @AutoProcessRunId
                   AND [p].[PCN_SubprojectId] IS NULL
                   AND [p].[HCC_PROCESSED_PCN] LIKE @Source01 + '%'

            IF @Debug = 1
                BEGIN

                    EXEC [dbo].[PerfLogMonitor] @Section = '022' ,
                                                @ProcessName = @ProcessNameIn ,
                                                @ET = @ET ,
                                                @MasterET = @MasterET ,
                                                @ET_Out = @ET OUT ,
                                                @TableOutput = 0 ,
                                                @End = 0

                END

            DELETE [m]
            FROM  @ActionList [m]
            WHERE ISNULL([m].[SubprojectIdBPosition], -1) = ISNULL(
                                                                      @SubprojectIdBPosition ,
                                                                      -1
                                                                  )
                  AND ISNULL([m].[SubprojectIdLength], -1) = ISNULL(
                                                                       @SubprojectIdLength ,
                                                                       -1
                                                                   )
                  AND ISNULL([m].[ProviderIdBPosition], -1) = ISNULL(
                                                                        @ProviderIdBPosition ,
                                                                        -1
                                                                    )
                  AND ISNULL([m].[ProviderIdLength], -1) = ISNULL(
                                                                     @ProviderIdLength ,
                                                                     -1
                                                                 )

            IF @Debug = 1
                BEGIN

                    EXEC [dbo].[PerfLogMonitor] @Section = '023' ,
                                                @ProcessName = @ProcessNameIn ,
                                                @ET = @ET ,
                                                @MasterET = @MasterET ,
                                                @ET_Out = @ET OUT ,
                                                @TableOutput = 0 ,
                                                @End = 0

                END

            /*-B Remove invalid SubprojectIds */

            UPDATE [p]
            SET    [p].[PCN_SubprojectId] = NULL ,
                   [p].[FailureReason] = NULL
            FROM   [Valuation].[NewHCCPartC] [p]
            WHERE  [p].[PCN_SubprojectId] NOT IN (   SELECT [m].[SubProjectId]
                                                     FROM   @SubProjectIdList [m]
                                                 )
                   AND [p].[ProcessRunId] = @AutoProcessRunId

            IF @Debug = 1
                BEGIN

                    EXEC [dbo].[PerfLogMonitor] @Section = '024' ,
                                                @ProcessName = @ProcessNameIn ,
                                                @ET = @ET ,
                                                @MasterET = @MasterET ,
                                                @ET_Out = @ET OUT ,
                                                @TableOutput = 0 ,
                                                @End = 0

                END

            UPDATE [p]
            SET    [p].[PCN_SubprojectId] = NULL ,
                   [p].[FailureReason] = NULL
            FROM   [Valuation].[NewHCCPartD] [p]
            WHERE  [p].[PCN_SubprojectId] NOT IN (   SELECT [m].[SubProjectId]
                                                     FROM   @SubProjectIdList [m]
                                                 )
                   AND [p].[ProcessRunId] = @AutoProcessRunId

            /*-E Remove invalid SubprojectIds */
            IF @Debug = 1
                BEGIN

                    EXEC [dbo].[PerfLogMonitor] @Section = '025' ,
                                                @ProcessName = @ProcessNameIn ,
                                                @ET = @ET ,
                                                @MasterET = @MasterET ,
                                                @ET_Out = @ET OUT ,
                                                @TableOutput = 0 ,
                                                @End = 0

                END

        END

    /*E Position */

    IF @Debug = 1
        BEGIN

            EXEC [dbo].[PerfLogMonitor] @Section = '026' ,
                                        @ProcessName = @ProcessNameIn ,
                                        @ET = @ET ,
                                        @MasterET = @MasterET ,
                                        @ET_Out = @ET OUT ,
                                        @TableOutput = 0 ,
                                        @End = 0

        END


    /*B Pattern */

    IF @Debug = 1
        BEGIN

            EXEC [dbo].[PerfLogMonitor] @Section = '027' ,
                                        @ProcessName = @ProcessNameIn ,
                                        @ET = @ET ,
                                        @MasterET = @MasterET ,
                                        @ET_Out = @ET OUT ,
                                        @TableOutput = 0 ,
                                        @End = 0

        END


    UPDATE [p]
    SET    [p].[PCN_SubprojectId] = CASE WHEN [p].[HCC_PROCESSED_PCN] LIKE ( '%'
                                                                             + [a1].[FullPattern]
                                                                             + '%'
                                                                           ) THEN
                                             [a1].[SubProjectId]
                                         ELSE NULL
                                    END ,
           [p].[FailureReason] = [a1].[FailureReason]
    FROM   [Valuation].[NewHCCPartC] [p]
           JOIN @ActionList [a1] ON [p].[HCC_PROCESSED_PCN] LIKE ( '%'
                                                                   + [a1].[FullPattern]
                                                                   + '%'
                                                                 )
    WHERE  [p].[ProcessRunId] = @AutoProcessRunId
           AND [p].[PCN_SubprojectId] IS NULL
           AND [a1].[FullPattern] IS NOT NULL


    IF @Debug = 1
        BEGIN

            EXEC [dbo].[PerfLogMonitor] @Section = '028' ,
                                        @ProcessName = @ProcessNameIn ,
                                        @ET = @ET ,
                                        @MasterET = @MasterET ,
                                        @ET_Out = @ET OUT ,
                                        @TableOutput = 0 ,
                                        @End = 0

        END


    UPDATE [p]
    SET    [p].[PCN_SubprojectId] = CASE WHEN [p].[HCC_PROCESSED_PCN] LIKE ( '%'
                                                                             + [a1].[FullPattern]
                                                                             + '%'
                                                                           ) THEN
                                             [a1].[SubProjectId]
                                         ELSE NULL
                                    END ,
           [p].[FailureReason] = [a1].[FailureReason]
    FROM   [Valuation].[NewHCCPartD] [p]
           JOIN @ActionList [a1] ON [p].[HCC_PROCESSED_PCN] LIKE ( '%'
                                                                   + [a1].[FullPattern]
                                                                   + '%'
                                                                 )
    WHERE  [p].[ProcessRunId] = @AutoProcessRunId
           AND [p].[PCN_SubprojectId] IS NULL
           AND [a1].[FullPattern] IS NOT NULL


    IF @Debug = 1
        BEGIN

            EXEC [dbo].[PerfLogMonitor] @Section = '029' ,
                                        @ProcessName = @ProcessNameIn ,
                                        @ET = @ET ,
                                        @MasterET = @MasterET ,
                                        @ET_Out = @ET OUT ,
                                        @TableOutput = 0 ,
                                        @End = 0

        END


    /*-B Remove invalid SubprojectIds */

    UPDATE [p]
    SET    [p].[PCN_SubprojectId] = NULL ,
           [p].[FailureReason] = NULL
    FROM   [Valuation].[NewHCCPartC] [p]
    WHERE  [p].[PCN_SubprojectId] NOT IN (   SELECT [m].[SubProjectId]
                                             FROM   @SubProjectIdList [m]
                                         )
           AND [p].[ProcessRunId] = @AutoProcessRunId

    IF @Debug = 1
        BEGIN

            EXEC [dbo].[PerfLogMonitor] @Section = '030' ,
                                        @ProcessName = @ProcessNameIn ,
                                        @ET = @ET ,
                                        @MasterET = @MasterET ,
                                        @ET_Out = @ET OUT ,
                                        @TableOutput = 0 ,
                                        @End = 0

        END

    UPDATE [p]
    SET    [p].[PCN_SubprojectId] = NULL ,
           [p].[FailureReason] = NULL
    FROM   [Valuation].[NewHCCPartD] [p]
    WHERE  [p].[PCN_SubprojectId] NOT IN (   SELECT [m].[SubProjectId]
                                             FROM   @SubProjectIdList [m]
                                         )
           AND [p].[ProcessRunId] = @AutoProcessRunId

    /*-E Remove invalid SubprojectIds */

    IF @Debug = 1
        BEGIN

            EXEC [dbo].[PerfLogMonitor] @Section = '031' ,
                                        @ProcessName = @ProcessNameIn ,
                                        @ET = @ET ,
                                        @MasterET = @MasterET ,
                                        @ET_Out = @ET OUT ,
                                        @TableOutput = 0 ,
                                        @End = 0

        END

    /*E Pattern */



    /*B Add FailureReason */

    UPDATE [p]
    SET    [p].[FailureReason] = [m].[FailureReason]
    FROM   [Valuation].[NewHCCPartC] [p]
           JOIN @SubProjectIdList [m] ON [p].[PCN_SubprojectId] = [m].[SubProjectId]
    WHERE  [p].[ProcessRunId] = @AutoProcessRunId
           AND [p].[FailureReason] IS NULL
           AND [p].[PCN_SubprojectId] IS NOT NULL


    IF @Debug = 1
        BEGIN

            EXEC [dbo].[PerfLogMonitor] @Section = '032' ,
                                        @ProcessName = @ProcessNameIn ,
                                        @ET = @ET ,
                                        @MasterET = @MasterET ,
                                        @ET_Out = @ET OUT ,
                                        @TableOutput = 0 ,
                                        @End = 0

        END

    UPDATE [p]
    SET    [p].[FailureReason] = [m].[FailureReason]
    FROM   [Valuation].[NewHCCPartD] [p]
           JOIN @SubProjectIdList [m] ON [p].[PCN_SubprojectId] = [m].[SubProjectId]
    WHERE  [p].[ProcessRunId] = @AutoProcessRunId
           AND [p].[FailureReason] IS NULL
           AND [p].[PCN_SubprojectId] IS NOT NULL

    /*E Add FailureReason */

    IF @Debug = 1
        BEGIN

            EXEC [dbo].[PerfLogMonitor] @Section = '033' ,
                                        @ProcessName = @ProcessNameIn ,
                                        @ET = @ET ,
                                        @MasterET = @MasterET ,
                                        @ET_Out = @ET OUT ,
                                        @TableOutput = 0 ,
                                        @End = 0

        END

        /*B PL_Audit 2016 patch */


        /**/;
    WITH [CTE_a1]
    AS ( SELECT   [CodingCompleteDate] = MIN([b].[CodingCompleteDate]) ,
                  [PatientControlNumber] = [a].[PatientControlNumber] ,
                  [SubprojectID] = [b].[SubprojectID]
         FROM     [dbo].[Raps_Accepted_rollup] [a] WITH ( NOLOCK )
                  JOIN [dbo].[CWFDetails] [b] ON [a].[HICN] = [b].[HICN]
                                                 AND [a].[DiagnosisCode] = [b].[DiagnosisCode]
                                                 AND [a].[FromDate] = [b].[DOSStartDt]
                                                 AND [a].[ThruDate] = [b].[DOSEndDt]
                                                 AND [b].[CurrentImageStatus] IN ( 'Coding/Review Complete' ,
                                                                                   'Ready for Release'
                                                                                 )
         WHERE    [a].[ProcessedBy] >= '2016-05-01 00:00:00'
                  AND [a].[ProcessedBy] <= '2016-07-01 00:00:00'
                  AND [a].[PatientControlNumber] LIKE 'PL_AUDIT_%'
         GROUP BY [a].[PatientControlNumber] ,
                  [b].[SubprojectID]
       )
    UPDATE [c1]
    SET    [c1].[PCN_SubprojectId] = [a1].[SubprojectID] ,
           [c1].[FailureReason] = 'N/a'
    FROM   [Valuation].[NewHCCPartC] [c1]
           JOIN [CTE_a1] [a1] ON [c1].[HCC_PROCESSED_PCN] = [a1].[PatientControlNumber]
    WHERE  [c1].[ProcessRunId] = @AutoProcessRunId
           AND [c1].[PCN_SubprojectId] IS NULL
           AND [c1].[Payment_Year] = 2016

    IF @Debug = 1
        BEGIN

            EXEC [dbo].[PerfLogMonitor] @Section = '034' ,
                                        @ProcessName = @ProcessNameIn ,
                                        @ET = @ET ,
                                        @MasterET = @MasterET ,
                                        @ET_Out = @ET OUT ,
                                        @TableOutput = 0 ,
                                        @End = 0

        END
        /**/;
    WITH [CTE_a1]
    AS ( SELECT   [CodingCompleteDate] = MIN([b].[CodingCompleteDate]) ,
                  [PatientControlNumber] = [a].[PatientControlNumber] ,
                  [SubprojectID] = [b].[SubprojectID]
         FROM     [dbo].[Raps_Accepted_rollup] [a] WITH ( NOLOCK )
                  JOIN [dbo].[CWFDetails] [b] ON [a].[HICN] = [b].[HICN]
                                                 AND [a].[DiagnosisCode] = [b].[DiagnosisCode]
                                                 AND [a].[FromDate] = [b].[DOSStartDt]
                                                 AND [a].[ThruDate] = [b].[DOSEndDt]
                                                 AND [b].[CurrentImageStatus] IN ( 'Coding/Review Complete' ,
                                                                                   'Ready for Release'
                                                                                 )
         WHERE    [a].[ProcessedBy] >= '2016-05-01 00:00:00'
                  AND [a].[ProcessedBy] <= '2016-07-01 00:00:00'
                  AND [a].[PatientControlNumber] LIKE 'PL_AUDIT_%'
         GROUP BY [a].[PatientControlNumber] ,
                  [b].[SubprojectID]
       )
    UPDATE [c1]
    SET    [c1].[PCN_SubprojectId] = [a1].[SubprojectID] ,
           [c1].[FailureReason] = 'N/a'
    FROM   [Valuation].[NewHCCPartD] [c1]
           JOIN [CTE_a1] [a1] ON [c1].[HCC_PROCESSED_PCN] = [a1].[PatientControlNumber]
    WHERE  [c1].[ProcessRunId] = @AutoProcessRunId
           AND [c1].[PCN_SubprojectId] IS NULL
           AND [c1].[Payment_Year] = 2016


    IF @Debug = 1
        BEGIN

            EXEC [dbo].[PerfLogMonitor] @Section = '035' ,
                                        @ProcessName = @ProcessNameIn ,
                                        @ET = @ET ,
                                        @MasterET = @MasterET ,
                                        @ET_Out = @ET OUT ,
                                        @TableOutput = 0 ,
                                        @End = 0

        END


    UPDATE [c1]
    SET    [c1].[PCN_SubprojectId] = [a1].[SubProjectId] ,
           [c1].[FailureReason] = ISNULL([a1].[FailureReason], 'N/a')
    FROM   [Valuation].[NewHCCPartC] [c1]
           JOIN [Valuation].[ConfigSubProjectSubstringPattern] [a1] ON SUBSTRING(
                                                                                    [c1].[HCC_PROCESSED_PCN] ,
                                                                                    1 ,
                                                                                    3
                                                                                ) = SUBSTRING(
                                                                                                 [a1].[PCNStringPattern] ,
                                                                                                 1 ,
                                                                                                 3
                                                                                             )
                                                                       AND SUBSTRING(
                                                                                        [c1].[HCC_PROCESSED_PCN] ,
                                                                                        4 ,
                                                                                        1
                                                                                    ) = SUBSTRING(
                                                                                                     [a1].[PCNStringPattern] ,
                                                                                                     4 ,
                                                                                                     1
                                                                                                 )
                                                                       AND SUBSTRING(
                                                                                        [c1].[HCC_PROCESSED_PCN] ,
                                                                                        5 ,
                                                                                        1
                                                                                    ) = SUBSTRING(
                                                                                                     [a1].[PCNStringPattern] ,
                                                                                                     5 ,
                                                                                                     1
                                                                                                 )
                                                                       AND SUBSTRING(
                                                                                        [c1].[HCC_PROCESSED_PCN] ,
                                                                                        6 ,
                                                                                        1
                                                                                    ) = SUBSTRING(
                                                                                                     [a1].[PCNStringPattern] ,
                                                                                                     6 ,
                                                                                                     1
                                                                                                 )
                                                                       AND SUBSTRING(
                                                                                        [c1].[HCC_PROCESSED_PCN] ,
                                                                                        7 ,
                                                                                        1
                                                                                    ) = SUBSTRING(
                                                                                                     [a1].[PCNStringPattern] ,
                                                                                                     7 ,
                                                                                                     1
                                                                                                 )
                                                                       AND SUBSTRING(
                                                                                        [c1].[HCC_PROCESSED_PCN] ,
                                                                                        8 ,
                                                                                        1
                                                                                    ) = SUBSTRING(
                                                                                                     [a1].[PCNStringPattern] ,
                                                                                                     8 ,
                                                                                                     1
                                                                                                 )
                                                                       AND SUBSTRING(
                                                                                        [c1].[HCC_PROCESSED_PCN] ,
                                                                                        9 ,
                                                                                        1
                                                                                    ) = SUBSTRING(
                                                                                                     [a1].[PCNStringPattern] ,
                                                                                                     9 ,
                                                                                                     1
                                                                                                 )
                                                                       AND SUBSTRING(
                                                                                        [c1].[HCC_PROCESSED_PCN] ,
                                                                                        10 ,
                                                                                        2
                                                                                    ) = SUBSTRING(
                                                                                                     [a1].[PCNStringPattern] ,
                                                                                                     10 ,
                                                                                                     2
                                                                                                 )
    WHERE  [a1].[ClientId] = @ClientId
           AND SUBSTRING([c1].[HCC_PROCESSED_PCN], 1, 3) = 'RQI'
           AND SUBSTRING([c1].[HCC_PROCESSED_PCN], 10, 2) <> 'ZZ'
           AND [a1].[ProjectId] IN (   SELECT [ProjectId]
                                       FROM   @tblProjectIdList
                                   )
           AND [c1].[ProcessRunId] = @AutoProcessRunId
           AND [c1].[PCN_SubprojectId] IS NULL

    IF @Debug = 1
        BEGIN

            EXEC [dbo].[PerfLogMonitor] @Section = '036' ,
                                        @ProcessName = @ProcessNameIn ,
                                        @ET = @ET ,
                                        @MasterET = @MasterET ,
                                        @ET_Out = @ET OUT ,
                                        @TableOutput = 0 ,
                                        @End = 0

        END

    UPDATE [c1]
    SET    [c1].[PCN_SubprojectId] = [a1].[SubProjectId] ,
           [c1].[FailureReason] = ISNULL([a1].[FailureReason], 'N/a')
    FROM   [Valuation].[NewHCCPartD] [c1]
           JOIN [Valuation].[ConfigSubProjectSubstringPattern] [a1] ON SUBSTRING(
                                                                                    [c1].[HCC_PROCESSED_PCN] ,
                                                                                    1 ,
                                                                                    3
                                                                                ) = SUBSTRING(
                                                                                                 [a1].[PCNStringPattern] ,
                                                                                                 1 ,
                                                                                                 3
                                                                                             )
                                                                       AND SUBSTRING(
                                                                                        [c1].[HCC_PROCESSED_PCN] ,
                                                                                        4 ,
                                                                                        1
                                                                                    ) = SUBSTRING(
                                                                                                     [a1].[PCNStringPattern] ,
                                                                                                     4 ,
                                                                                                     1
                                                                                                 )
                                                                       AND SUBSTRING(
                                                                                        [c1].[HCC_PROCESSED_PCN] ,
                                                                                        5 ,
                                                                                        1
                                                                                    ) = SUBSTRING(
                                                                                                     [a1].[PCNStringPattern] ,
                                                                                                     5 ,
                                                                                                     1
                                                                                                 )
                                                                       AND SUBSTRING(
                                                                                        [c1].[HCC_PROCESSED_PCN] ,
                                                                                        6 ,
                                                                                        1
                                                                                    ) = SUBSTRING(
                                                                                                     [a1].[PCNStringPattern] ,
                                                                                                     6 ,
                                                                                                     1
                                                                                                 )
                                                                       AND SUBSTRING(
                                                                                        [c1].[HCC_PROCESSED_PCN] ,
                                                                                        7 ,
                                                                                        1
                                                                                    ) = SUBSTRING(
                                                                                                     [a1].[PCNStringPattern] ,
                                                                                                     7 ,
                                                                                                     1
                                                                                                 )
                                                                       AND SUBSTRING(
                                                                                        [c1].[HCC_PROCESSED_PCN] ,
                                                                                        8 ,
                                                                                        1
                                                                                    ) = SUBSTRING(
                                                                                                     [a1].[PCNStringPattern] ,
                                                                                                     8 ,
                                                                                                     1
                                                                                                 )
                                                                       AND SUBSTRING(
                                                                                        [c1].[HCC_PROCESSED_PCN] ,
                                                                                        9 ,
                                                                                        1
                                                                                    ) = SUBSTRING(
                                                                                                     [a1].[PCNStringPattern] ,
                                                                                                     9 ,
                                                                                                     1
                                                                                                 )
                                                                       AND SUBSTRING(
                                                                                        [c1].[HCC_PROCESSED_PCN] ,
                                                                                        10 ,
                                                                                        2
                                                                                    ) = SUBSTRING(
                                                                                                     [a1].[PCNStringPattern] ,
                                                                                                     10 ,
                                                                                                     2
                                                                                                 )
    WHERE  [a1].[ClientId] = @ClientId
           AND SUBSTRING([c1].[HCC_PROCESSED_PCN], 1, 3) = 'RQI'
           AND SUBSTRING([c1].[HCC_PROCESSED_PCN], 10, 2) <> 'ZZ'
           AND [a1].[ProjectId] IN (   SELECT [ProjectId]
                                       FROM   @tblProjectIdList
                                   )
           AND [c1].[ProcessRunId] = @AutoProcessRunId
           AND [c1].[PCN_SubprojectId] IS NULL


    /*E PL_Audit 2016 patch */

    IF @Debug = 1
        BEGIN

            EXEC [dbo].[PerfLogMonitor] @Section = '037' ,
                                        @ProcessName = @ProcessNameIn ,
                                        @ET = @ET ,
                                        @MasterET = @MasterET ,
                                        @ET_Out = @ET OUT ,
                                        @TableOutput = 0 ,
                                        @End = 0

        END

    IF @Debug = 1
        BEGIN
            SELECT   [c].[PCN_SubprojectId] ,
                     [Count] = COUNT(*) ,
                     [c].[FailureReason]
            FROM     [Valuation].[NewHCCPartC] [c] WITH ( NOLOCK )
            WHERE    [c].[ProcessRunId] = @AutoProcessRunId
            GROUP BY [c].[PCN_SubprojectId] ,
                     [c].[FailureReason]
            ORDER BY [c].[PCN_SubprojectId]


            SELECT   [c].[PCN_SubprojectId] ,
                     [Count] = COUNT(*) ,
                     [c].[FailureReason]
            FROM     [Valuation].[NewHCCPartD] [c] WITH ( NOLOCK )
            WHERE    [c].[ProcessRunId] = @AutoProcessRunId
            GROUP BY [c].[PCN_SubprojectId] ,
                     [c].[FailureReason]
            ORDER BY [c].[PCN_SubprojectId]
        END


    IF @Debug = 1
        BEGIN

            EXEC [dbo].[PerfLogMonitor] @Section = '038' ,
                                        @ProcessName = @ProcessNameIn ,
                                        @ET = @ET ,
                                        @MasterET = @MasterET ,
                                        @ET_Out = @ET OUT ,
                                        @TableOutput = 0 ,
                                        @End = 1

        END


