CREATE PROC [Valuation].[ConfigUpdateConfigClientMain]
    (
     @ConfigClientMainId [INT] = NULL
   , @ClientName [VARCHAR](128) = NULL
   , @ClientId [INT] = NULL
   , @ClientReportDb [VARCHAR](130) = NULL
   , @ClientLevelDb [VARCHAR](130) = NULL
   , @CTRSummaryServer [VARCHAR](130) = NULL
   , @CTRSummaryDb [VARCHAR](130) = NULL
   , @FilteredAuditRetention [INT] = NULL
   , @MaxWorkers [TINYINT] = NULL
   , @ActiveBDate [DATE] = NULL
   , @ActiveEDate [DATE] = NULL
   , @Reviewed [DATETIME] = NULL
   , @ReviewedBy [VARCHAR](257) = NULL
    )
AS
    SET NOCOUNT ON 

    RAISERROR('000', 0, 1) WITH NOWAIT

    IF (
        @ConfigClientMainId IS NULL
        AND @ClientName IS NULL
        AND @ClientId IS NULL
        AND @ClientReportDb IS NULL
        AND @ClientLevelDb IS NULL
        AND @CTRSummaryServer IS NULL
        AND @CTRSummaryDb IS NULL
        AND @FilteredAuditRetention IS NULL
        AND @MaxWorkers IS NULL
        AND @ActiveBDate IS NULL
        AND @ActiveEDate IS NULL
        AND @Reviewed IS NULL
        AND @ReviewedBy IS NULL
       )
        BEGIN 
            RAISERROR('001', 0, 1) WITH NOWAIT
            SELECT
                [ConfigClientMainId] = [m].[ConfigClientMainId]
              , [ClientName] = [m].[ClientName]
              , [ClientId] = [m].[ClientId]
              , [ClientReportDb] = [m].[ClientReportDb]
              , [ClientLevelDb] = [m].[ClientLevelDb]
              , [CTRSummaryServer] = [m].[CTRSummaryServer]
              , [CTRSummaryDb] = [m].[CTRSummaryDb]
              , [FilteredAuditRetention] = [m].[FilteredAuditRetention]
              , [MaxWorkers] = [m].[MaxWorkers]
              , [ActiveBDate] = [m].[ActiveBDate]
              , [ActiveEDate] = [m].[ActiveEDate]
              , [Added] = [m].[Added]
              , [AddedBy] = [m].[AddedBy]
              , [Reviewed] = [m].[Reviewed]
              , [ReviewedBy] = [m].[ReviewedBy]
            FROM
                [Valuation].[ConfigClientMain] m
            ORDER BY
                [ClientName]
              , [Added]
            RETURN
        END
    RAISERROR('002', 0, 1) WITH NOWAIT

    IF @ConfigClientMainId IS NOT NULL
        BEGIN 
            RAISERROR('003', 0, 1) WITH NOWAIT

            UPDATE
                m
            SET
                m.[ClientName] = ISNULL(@ClientName, m.[ClientName])
              , m.[ClientId] = ISNULL(@ClientId, m.[ClientId])
              , m.[ClientReportDb] = ISNULL(@ClientReportDb, m.[ClientReportDb])
              , m.[ClientLevelDb] = ISNULL(@ClientLevelDb, m.[ClientLevelDb])
              , m.[CTRSummaryServer] = ISNULL(@CTRSummaryServer, m.[CTRSummaryServer])
              , m.[CTRSummaryDb] = ISNULL(@CTRSummaryDb, m.[CTRSummaryDb])
              , m.[FilteredAuditRetention] = ISNULL(@FilteredAuditRetention, m.[FilteredAuditRetention])
              , m.[MaxWorkers] = ISNULL(@MaxWorkers, m.[MaxWorkers])
              , m.[ActiveBDate] = ISNULL(@ActiveBDate, m.[ActiveBDate])
              , m.[ActiveEDate] = ISNULL(@ActiveEDate, m.[ActiveEDate])
              , m.[Reviewed] = ISNULL(@Reviewed, m.[Reviewed])
              , m.[ReviewedBy] = ISNULL(@ReviewedBy, m.[ReviewedBy])
            FROM
                [Valuation].[ConfigClientMain] m
            WHERE
                m.[ConfigClientMainId] = @ConfigClientMainId
            RETURN
        END
    RAISERROR('004', 0, 1) WITH NOWAIT

    IF @ConfigClientMainId IS NULL
        AND @ClientId IS NOT NULL
        BEGIN
            RAISERROR('005', 0, 1) WITH NOWAIT

            INSERT  INTO [Valuation].[ConfigClientMain]
                    (
                     [ClientName]
                   , [ClientId]
                   , [ClientReportDb]
                   , [ClientLevelDb]
                   , [CTRSummaryServer]
                   , [CTRSummaryDb]
                   , [FilteredAuditRetention]
                   , [MaxWorkers]
                   , [ActiveBDate]
                   , [ActiveEDate]
                   , [Reviewed]
                   , [ReviewedBy]
                    )
            SELECT
                [ClientName] = @ClientName
              , [ClientId] = @ClientId
              , [ClientReportDb] = @ClientReportDb
              , [ClientLevelDb] = @ClientLevelDb
              , [CTRSummaryServer] = @CTRSummaryServer
              , [CTRSummaryDb] = @CTRSummaryDb
              , [FilteredAuditRetention] = @FilteredAuditRetention
              , [MaxWorkers] = @MaxWorkers
              , [ActiveBDate] = @ActiveBDate
              , [ActiveEDate] = @ActiveEDate
              , [Reviewed] = @Reviewed
              , [ReviewedBy] = @ReviewedBy
            RETURN
        END
    RAISERROR('006', 0, 1) WITH NOWAIT


