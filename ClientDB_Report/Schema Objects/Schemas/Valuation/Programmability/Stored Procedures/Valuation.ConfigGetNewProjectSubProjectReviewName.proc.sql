CREATE PROC Valuation.ConfigGetNewProjectSubProjectReviewName
    (
     @ClientLevelDb VARCHAR(128)
   , @Debug BIT = 0
    )
AS
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

    DECLARE @ProjectIdListSQL VARCHAR(8000)

    IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE()
                - @ET, 114) + ' || TET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121) 
            SET @ET = GETDATE()
            RAISERROR('000', 0, 1) WITH NOWAIT
        END

    SET @ProjectIdListSQL = '
    INSERT  INTO [Valuation].[ConfigProjectIdList]
            (
            [ConfigClientMainId]
            , [ClientId]
            
           , [ProjectId]
           , [ProjectDescription]
           , [ProjectSortOrder]
           , [SuspectYR]
           , [ActiveBDate]
           , [ActiveEDate]
            )
    SELECT [ConfigClientMainId] = -2
    ,
        [ClientId] = ISNULL([p].[OnBehalfOfOrganizationID], [p].[OrganizationID])
      , [ProjectId] = [p].[ID]
      , [ProjectDescription] = [p].[Description]
      , [ProjectSortOrder] = 99
      , [SuspectYR] = NULL
      , [ActiveBDate] = CAST([p].[CreationDateTime] AS DATE)
      , [ActiveEDate] = NULL
    FROM
        [' + @ClientLevelDb + '].dbo.[vwProject] p
    WHERE
        [p].[IsActive] = 1
        AND [p].[CreationDateTime] IS NOT NULL
        AND NOT EXISTS ( SELECT
                            1
                         FROM
                            [Valuation].[ConfigProjectIdList] pl
                         WHERE
                            ISNULL([p].[OnBehalfOfOrganizationID], [p].[OrganizationID]) = pl.[ClientId]
                            AND [p].[ID] = pl.[ProjectId] )
'

    IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE()
                - @ET, 114) + ' || TET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121) 
            SET @ET = GETDATE()

            PRINT '--================================================================='
            PRINT @ProjectIdListSQL
            PRINT '--================================================================='
            RAISERROR('001', 0, 1) WITH NOWAIT
        END


    IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE()
                - @ET, 114) + ' || TET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121) 
            SET @ET = GETDATE()
            RAISERROR('002', 0, 1) WITH NOWAIT
        END

    EXEC (@ProjectIdListSQL)

    IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE()
                - @ET, 114) + ' || TET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121) 
            SET @ET = GETDATE()
            RAISERROR('003', 0, 1) WITH NOWAIT
        END

    DECLARE @SubProjectSubstringPatternSQL VARCHAR(8000)

    IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE()
                - @ET, 114) + ' || TET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121) 
            SET @ET = GETDATE()
            RAISERROR('004', 0, 1) WITH NOWAIT
        END

    SET @SubProjectSubstringPatternSQL = '
    INSERT  INTO [Valuation].[ConfigSubProjectSubstringPattern]
            (
             [ClientId]
           , [ProjectId]
           , [SubProjectId]
           , [SubprojectDescription]
           , [Source01]
           , [ProviderType]
           , [Type]
           , [ProjectCategory]
           , [SubProjectSortOrder]
           , [ActiveBDate]
           , [ActiveEDate]
           , [FilteredAuditActiveBDate]
           , [FilteredAuditActiveEDate]
           , [OnShoreOffShore]
           , [ID_VAN]
           , [PMH]
           , [MissingSignature]
           , [Filler01]
           , [Filler02]
           , [UniquePattern]
           , [PCNStringPattern]
           , [FailureReason]
            )
    SELECT
        [ClientId] = ISNULL([p].[OnBehalfOfOrganizationID], [p].[OrganizationID])
      , [ProjectId] = [sp].[ProjectID]
      , [SubProjectId] = [rs].[SubProjectID]
      , [SubProjectDescription] = ISNULL([sp].[Description], ''NA'')
      , [Source01] = NULL
      , [ProviderType] = NULL
      , [Type] = NULL
      , [ProjectCategory] = [p].[Description]
      , [SubProjectSortOrder] = 99
      , [ActiveBDate] = ISNULL(MAX(CAST([rs].[CreationDateTime] AS DATE)), CAST(GETDATE() AS DATE))
      , [ActiveEDate] = NULL
      , [FilteredAuditActiveBDate] = NULL
      , [FilteredAuditActiveEDate] = NULL
      , [OnShoreOffShore] = NULL
      , [ID_VAN] = NULL
      , [PMH] = NULL
      , [MissingSignature] = NULL
      , [Filler01] = NULL
      , [Filler02] = NULL
      , [UniquePattern] = CASE WHEN LEN(LTRIM(RTRIM([sp].[RAPSSourceCode]))) < 17
                                    AND LEN(LTRIM(RTRIM([sp].[RAPSSourceCode]))) > 7
                               THEN REPLICATE(''Z'', 17 - LEN(LTRIM(RTRIM([sp].[RAPSSourceCode]))))
                               ELSE NULL
                          END
      , [PCNStringPattern] = CASE WHEN LEN(LTRIM(RTRIM([sp].[RAPSSourceCode]))) < 17
                                       AND LEN(LTRIM(RTRIM([sp].[RAPSSourceCode]))) > 7
                                  THEN LTRIM(RTRIM([sp].[RAPSSourceCode])) + REPLICATE(''Z'',
                                                                                       17
                                                                                       - LEN(LTRIM(RTRIM([sp].[RAPSSourceCode]))))
                                  ELSE LTRIM(RTRIM([sp].[RAPSSourceCode]))
                             END
      , [FailureReason] = NULL
    FROM
        [' + @ClientLevelDb + '].dbo.[vwReviewSteps] rs
    JOIN [' + @ClientLevelDb + '].dbo.[vwSubProject] sp
        ON [sp].[ID] = [rs].[SubProjectID]
           AND [sp].[IsActive] = 1
    JOIN [' + @ClientLevelDb + '].dbo.[vwProject] p
        ON [p].[ID] = [sp].[ProjectID]
           AND [p].[IsActive] = 1
    JOIN [Valuation].[ConfigProjectIdList] pl WITH (NOLOCK)
        ON [sp].[ProjectID] = [pl].[ProjectId]
    WHERE
        rs.[IsActive] = 1
        AND [rs].[ReviewName] IS NOT NULL
        AND NOT EXISTS ( SELECT
                            1
                         FROM
                            [Valuation].[ConfigSubProjectSubstringPattern] spsp
                         WHERE
                            ISNULL([p].[OnBehalfOfOrganizationID], [p].[OrganizationID]) = [spsp].[ClientId]
                            AND [sp].[ProjectID] = [spsp].[ProjectId]
                            AND rs.[SubProjectID] = [spsp].[SubProjectId] )
    GROUP BY
        ISNULL([p].[OnBehalfOfOrganizationID], [p].[OrganizationID])
      , [sp].[ProjectID]
      , [rs].[SubProjectID]
      , ISNULL([sp].[Description], ''NA'')
      , [p].[Description]
      , [sp].[RAPSSourceCode]
  ' 
    IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE()
                - @ET, 114) + ' || TET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121) 
            SET @ET = GETDATE()
            PRINT '--================================================================='
            PRINT @SubProjectSubstringPatternSQL
            PRINT '--================================================================='
            RAISERROR('005', 0, 1) WITH NOWAIT
        END



    IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE()
                - @ET, 114) + ' || TET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121) 
            SET @ET = GETDATE()
            RAISERROR('006', 0, 1) WITH NOWAIT
        END

    EXEC (@SubProjectSubstringPatternSQL)

    IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE()
                - @ET, 114) + ' || TET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121) 
            SET @ET = GETDATE()
            RAISERROR('007', 0, 1) WITH NOWAIT
        END

    DECLARE @SubProjectReviewNameSQL VARCHAR(8000)

    IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE()
                - @ET, 114) + ' || TET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121) 
            SET @ET = GETDATE()
            RAISERROR('008', 0, 1) WITH NOWAIT
        END

    SET @SubProjectReviewNameSQL = '

    INSERT  INTO [Valuation].[ConfigSubProjectReviewName]
            (
             [ClientId]
           , [ProjectId]
           , [SubProjectId]
           , [ReviewName]
           , [ActiveBDate]
           , [ActiveEDate]
            )
    SELECT
        [ClientId] = ISNULL([p].[OnBehalfOfOrganizationID], [p].[OrganizationID])
      , [ProjectId] = [sp].[ProjectID]
      , [SubProjectId] = [rs].[SubProjectID]
      , [ReviewName] = [rs].[ReviewName]
      , [ActiveBDate] = CAST([rs].[CreationDateTime] AS DATE)
      , [ActiveEDate] = NULL
    FROM
        [' + @ClientLevelDb + '].dbo.[vwReviewSteps] rs
    JOIN [' + @ClientLevelDb + '].dbo.[vwSubProject] sp
        ON [sp].[ID] = [rs].[SubProjectID]
           AND [sp].[IsActive] = 1
    JOIN [' + @ClientLevelDb + '].dbo.[vwProject] p
        ON [p].[ID] = [sp].[ProjectID]
           AND [p].[IsActive] = 1
    JOIN [Valuation].[ConfigSubProjectSubstringPattern] spsp
        ON [sp].[ProjectID] = [spsp].[ProjectId]
           AND [rs].[SubProjectID] = [spsp].[SubProjectId]
    WHERE
        [rs].[ReviewName] IS NOT NULL
        AND rs.[IsActive] = 1
        AND NOT EXISTS (
        SELECT 1
        FROM [Valuation].[ConfigSubProjectReviewName] sprn
        WHERE ISNULL([p].[OnBehalfOfOrganizationID], [p].[OrganizationID]) = sprn.[ClientId]
        AND [sp].[ProjectID] = sprn.[ProjectID]
        AND [rs].[SubProjectID] = sprn.[subProjectId]
        AND [rs].[ReviewName] = sprn.[ReviewName]
        )
        
'
    IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE()
                - @ET, 114) + ' || TET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121) 
            SET @ET = GETDATE()
            PRINT '--================================================================='
            PRINT @SubProjectReviewNameSQL
            PRINT '--================================================================='
            RAISERROR('009', 0, 1) WITH NOWAIT
        END



    IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE()
                - @ET, 114) + ' || TET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121) 
            SET @ET = GETDATE()
            RAISERROR('010', 0, 1) WITH NOWAIT
        END


    EXEC(@SubProjectReviewNameSQL)


    IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE()
                - @ET, 114) + ' | ' + CONVERT(CHAR(23), GETDATE(), 121) 
            RAISERROR('011', 0, 1) WITH NOWAIT
            PRINT 'Total ET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' | ' + CONVERT(CHAR(23), GETDATE(), 121) 
            RAISERROR('Done.|', 0, 1) WITH NOWAIT
        END

