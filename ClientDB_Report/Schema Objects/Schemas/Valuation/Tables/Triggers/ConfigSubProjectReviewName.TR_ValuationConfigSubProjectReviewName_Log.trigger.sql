CREATE TRIGGER [Valuation].[TR_ValuationConfigSubProjectReviewName_Log]
ON [Valuation].[ConfigSubProjectReviewName]
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

                INSERT INTO [Valuation].[LogConfigSubProjectReviewName] ([SubProjectReviewNameId]
                                                                       , [ClientId]
                                                                       , [ClientId_old]
                                                                       , [ProjectId]
                                                                       , [ProjectId_old]
                                                                       , [SubProjectId]
                                                                       , [SubProjectId_old]
                                                                       , [ReviewName]
                                                                       , [ReviewName_old]
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
                                                                       , [SubGroup]
                                                                       , [SubGroup_old])
                SELECT [SubProjectReviewNameId] = ISNULL([new].[SubProjectReviewNameId], [old].[SubProjectReviewNameId])
                     , [ClientId] = [new].[ClientId]
                     , [ClientId_old] = [old].[ClientId]
                     , [ProjectId] = [new].[ProjectId]
                     , [ProjectId_old] = [old].[ProjectId]
                     , [SubProjectId] = [new].[SubProjectId]
                     , [SubProjectId_old] = [old].[SubProjectId]
                     , [ReviewName] = [new].[ReviewName]
                     , [ReviewName_old] = [old].[ReviewName]
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
                     , [SubGroup] = [new].[SubGroup]
                     , [SubGroup_old] = [old].[SubGroup]

                  FROM [Inserted] [new]
                  LEFT JOIN [Deleted] [old]
                    ON [new].[SubProjectReviewNameId] = [old].[SubProjectReviewNameId]


            END

        IF @Action = 'D'
            BEGIN

                INSERT INTO [Valuation].[LogConfigSubProjectReviewName] ([SubProjectReviewNameId]
                                                                       , [ClientId]
                                                                       , [ProjectId]
                                                                       , [SubProjectId]
                                                                       , [ReviewName]
                                                                       , [ActiveBDate]
                                                                       , [ActiveEDate]
                                                                       , [Added]
                                                                       , [AddedBy]
                                                                       , [Reviewed]
                                                                       , [ReviewedBy]
                                                                       , [Edited]
                                                                       , [EditedBy]
                                                                       , [Action]
                                                                       , [SubGroup])
                SELECT [SubProjectReviewNameId] = [old].[SubProjectReviewNameId]
                     , [ClientId_old] = [old].[ClientId]
                     , [ProjectId_old] = [old].[ProjectId]
                     , [SubProjectId_old] = [old].[SubProjectId]
                     , [ReviewName_old] = [old].[ReviewName]
                     , [ActiveBDate_old] = [old].[ActiveBDate]
                     , [ActiveEDate_old] = [old].[ActiveEDate]
                     , [Added_old] = [old].[Added]
                     , [AddedBy_old] = [old].[AddedBy]
                     , [Reviewed_old] = [old].[Reviewed]
                     , [ReviewedBy_old] = [old].[ReviewedBy]
                     , [Edited] = GETDATE()
                     , [EditedBy] = USER_NAME()
                     , [Action] = @Action
                     , [SubGroup] = [old].[SubGroup]

                  FROM [Deleted] [old]

            END
    END

