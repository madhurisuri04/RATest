CREATE TRIGGER [Valuation].[TR_ValuationConfigClientMain_Log] ON [Valuation].[ConfigClientMain]
    AFTER INSERT, UPDATE, DELETE
AS
    BEGIN

        DECLARE @Action CHAR(1)

        IF EXISTS ( SELECT
                        1
                    FROM
                        inserted )
            IF EXISTS ( SELECT
                            1
                        FROM
                            deleted )
                SET @Action = 'U'
            ELSE
                SET @Action = 'I'
        ELSE
            SET @Action = 'D'


        IF @Action IN ('I', 'U')
            BEGIN 
                INSERT  INTO [Valuation].[LogConfigClientMain]
                        (
                         [ConfigClientMainId]
                       , [ClientName]
                       , [ClientName_old]
                       , [ClientId]
                       , [ClientId_old]
                       , [ClientReportDb]
                       , [ClientReportDb_old]
                       , [ClientLevelDb]
                       , [ClientLevelDb_old]
                       , [CTRSummaryServer]
                       , [CTRSummaryServer_old]
                       , [CTRSummaryDb]
                       , [CTRSummaryDb_old]
                       , [FilteredAuditRetention]
                       , [FilteredAuditRetention_old]
                       , [MaxWorkers]
                       , [MaxWorkers_old]
                       , [ActiveBDate]
                       , [ActiveBDate_old]
                       , [ActiveEDate]
                       , [ActiveEDate_old]
                       , [Added]
                       , [Added_old]
                       , [AddedBy]
                       , [AddedBy_old]
                       , [Reviewed]
                       , [Reviewed_old]
                       , [ReviewedBy]
                       , [ReviewedBy_old]
                       , [Edited]
                       , [EditedBy]
                       , [Action]
                        )
                SELECT
                    [ConfigClientMainId] = ISNULL([new].[ConfigClientMainId], [old].[ConfigClientMainId])
                  , [ClientName] = new.[ClientName]
                  , [ClientName_old] = old.[ClientName]
                  , [ClientId] = new.[ClientId]
                  , [ClientId_old] = old.[ClientId]
                  , [ClientReportDb] = new.[ClientReportDb]
                  , [ClientReportDb_old] = old.[ClientReportDb]
                  , [ClientLevelDb] = new.[ClientLevelDb]
                  , [ClientLevelDb_old] = old.[ClientLevelDb]
                  , [CTRSummaryServer] = new.[CTRSummaryServer]
                  , [CTRSummaryServer_old] = old.[CTRSummaryServer]
                  , [CTRSummaryDb] = new.[CTRSummaryDb]
                  , [CTRSummaryDb_old] = old.[CTRSummaryDb]
                  , [FilteredAuditRetention] = new.[FilteredAuditRetention]
                  , [FilteredAuditRetention_old] = old.[FilteredAuditRetention]
                  , [MaxWorkers] = new.[MaxWorkers]
                  , [MaxWorkers_old] = old.[MaxWorkers]
                  , [ActiveBDate] = new.[ActiveBDate]
                  , [ActiveBDate_old] = old.[ActiveBDate]
                  , [ActiveEDate] = new.[ActiveEDate]
                  , [ActiveEDate_old] = old.[ActiveEDate]
                  , [Added] = new.[Added]
                  , [Added_old] = old.[Added]
                  , [AddedBy] = new.[AddedBy]
                  , [AddedBy_old] = old.[AddedBy]
                  , [Reviewed] = new.[Reviewed]
                  , [Reviewed_old] = old.[Reviewed]
                  , [ReviewedBy] = new.[ReviewedBy]
                  , [ReviewedBy_old] = old.[ReviewedBy]
                  , [Edited] = GETDATE()
                  , [EditedBy] = USER_NAME()
                  , [Action] = @Action
                FROM
                    inserted new
                LEFT JOIN [Deleted] old
                    ON [new].[ConfigClientMainId] = [old].[ConfigClientMainId]

            END        
      
        IF @Action = 'D'
            BEGIN 

                INSERT  INTO [Valuation].[LogConfigClientMain]
                        (
                         [ConfigClientMainId]
                       , [ClientName_old]
                       , [ClientId_old]
                       , [ClientReportDb_old]
                       , [ClientLevelDb_old]
                       , [CTRSummaryServer_old]
                       , [CTRSummaryDb_old]
                       , [FilteredAuditRetention_old]
                       , [MaxWorkers_old]
                       , [ActiveBDate_old]
                       , [ActiveEDate_old]
                       , [Added_old]
                       , [AddedBy_old]
                       , [Reviewed_old]
                       , [ReviewedBy_old]
                       , [Edited]
                       , [EditedBy]
                       , [Action]
                        )
                SELECT
                    [ConfigClientMainId] = [old].[ConfigClientMainId]
                  , [ClientName_old] = old.[ClientName]
                  , [ClientId_old] = old.[ClientId]
                  , [ClientReportDb_old] = old.[ClientReportDb]
                  , [ClientLevelDb_old] = old.[ClientLevelDb]
                  , [CTRSummaryServer_old] = old.[CTRSummaryServer]
                  , [CTRSummaryDb_old] = old.[CTRSummaryDb]
                  , [FilteredAuditRetention_old] = old.[FilteredAuditRetention]
                  , [MaxWorkers_old] = old.[MaxWorkers]
                  , [ActiveBDate_old] = old.[ActiveBDate]
                  , [ActiveEDate_old] = old.[ActiveEDate]
                  , [Added_old] = old.[Added]
                  , [AddedBy_old] = old.[AddedBy]
                  , [Reviewed_old] = old.[Reviewed]
                  , [ReviewedBy_old] = old.[ReviewedBy]
                  , [Edited] = GETDATE()
                  , [EditedBy] = USER_NAME()
                  , [Action] = 'D'
                FROM
                    DELETEd old       
            END 
    END
