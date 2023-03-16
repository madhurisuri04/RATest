CREATE TRIGGER [Valuation].[TR_ValuationConfigProjectIdList_Log]
ON [Valuation].[ConfigProjectIdList]
AFTER INSERT, UPDATE, DELETE
AS
    BEGIN

        DECLARE @Action CHAR(1)

        IF EXISTS (SELECT 1
                     FROM [Inserted])
            IF EXISTS (SELECT 1
                         FROM [Deleted])
                SET @Action = 'U'
            ELSE
                SET @Action = 'I'
        ELSE
            SET @Action = 'D'


        IF @Action IN ('I', 'U')
            BEGIN


                INSERT INTO [Valuation].[LogConfigProjectIdList] ([ConfigProjectIdListId]
                                                                , [ConfigClientMainId]
                                                                , [ConfigClientMainId_old]
                                                                , [ClientId]
                                                                , [ClientId_old]
                                                                , [ProjectId]
                                                                , [ProjectId_old]
                                                                , [ProjectDescription]
                                                                , [ProjectDescription_old]
                                                                , [ProjectSortOrder]
                                                                , [ProjectSortOrder_old]
                                                                , [SuspectYR]
                                                                , [SuspectYR_old]
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
                                                                , [ProjectYear]
                                                                , [ProjectYear_old]
                                                                , [RecommendedBy]
                                                                , [RecommendedBy_old])
                SELECT [ConfigProjectIdListId] = ISNULL([new].[ConfigProjectIdListId], [old].[ConfigProjectIdListId])
                     , [ConfigClientMainId] = [new].[ConfigClientMainId]
                     , [ConfigClientMainId_old] = [old].[ConfigClientMainId]
                     , [ClientId] = [new].[ClientId]
                     , [ClientId_old] = [old].[ClientId]
                     , [ProjectId] = [new].[ProjectId]
                     , [ProjectId_old] = [old].[ProjectId]
                     , [ProjectDescription] = [new].[ProjectDescription]
                     , [ProjectDescription_old] = [old].[ProjectDescription]
                     , [ProjectSortOrder] = [new].[ProjectSortOrder]
                     , [ProjectSortOrder_old] = [old].[ProjectSortOrder]
                     , [SuspectYR] = [new].[SuspectYR]
                     , [SuspectYR_old] = [old].[SuspectYR]
                     , [ActiveBDate] = [new].[ActiveBDate]
                     , [ActiveBDate_old] = [old].[ActiveBDate]
                     , [ActiveEDate] = [new].[ActiveEDate]
                     , [ActiveEDate_old] = [old].[ActiveEDate]
                     , [Added] = [new].[Added]
                     , [Added_old] = [old].[Added]
                     , [AddedBy] = [new].[AddedBy]
                     , [AddedBy_old] = [old].[AddedBy]
                     , [Reviewed] = [new].[Reviewed]
                     , [Reviewed_old] = [old].[Reviewed]
                     , [ReviewedBy] = [new].[ReviewedBy]
                     , [ReviewedBy_old] = [old].[ReviewedBy]
                     , [Edited] = GETDATE()
                     , [EditedBy] = USER_NAME()
                     , [Action] = @Action
                     , [ProjectYear] = [new].[ProjectYear]
                     , [ProjectYear_old] = [old].[ProjectYear]
                     , [RecommendedBy] = [new].[RecommendedBy]
                     , [RecommendedBy_old] = [old].[RecommendedBy]
                  FROM [Inserted] [new]
                  LEFT JOIN [Deleted] [old]
                    ON      [new].[ConfigProjectIdListId] = [old].[ConfigProjectIdListId]
            END

        IF @Action = 'D'
            BEGIN

                INSERT INTO [Valuation].[LogConfigProjectIdList] ([ConfigProjectIdListId]
                                                                , [ConfigClientMainId_old]
                                                                , [ClientId_old]
                                                                , [ProjectId_old]
                                                                , [ProjectDescription_old]
                                                                , [ProjectSortOrder_old]
                                                                , [SuspectYR_old]
                                                                , [ActiveBDate_old]
                                                                , [ActiveEDate_old]
                                                                , [Added_old]
                                                                , [AddedBy_old]
                                                                , [Reviewed_old]
                                                                , [ReviewedBy_old]
                                                                , [Edited]
                                                                , [EditedBy]
                                                                , [Action]
                                                                , [ProjectYear_old]
                                                                , [RecommendedBy_old])
                SELECT [ConfigProjectIdListId] = [old].[ConfigProjectIdListId]
                     , [ConfigClientMainId_old] = [old].[ConfigClientMainId]
                     , [ClientId_old] = [old].[ClientId]
                     , [ProjectId_old] = [old].[ProjectId]
                     , [ProjectDescription_old] = [old].[ProjectDescription]
                     , [ProjectSortOrder_old] = [old].[ProjectSortOrder]
                     , [SuspectYR_old] = [old].[SuspectYR]
                     , [ActiveBDate_old] = [old].[ActiveBDate]
                     , [ActiveEDate_old] = [old].[ActiveEDate]
                     , [Added_old] = [old].[Added]
                     , [AddedBy_old] = [old].[AddedBy]
                     , [Reviewed_old] = [old].[Reviewed]
                     , [ReviewedBy_old] = [old].[ReviewedBy]
                     , [Edited] = GETDATE()
                     , [EditedBy] = USER_NAME()
                     , [Action] = 'D'
                     , [ProjectYear_old] = [old].[ProjectYear]
                     , [RecommendedBy_old] = [old].[RecommendedBy]
                  FROM [Deleted] [old]
            END
    END
