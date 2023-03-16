CREATE TRIGGER [Valuation].[TR_ValuationConfigClientPlan_Log] ON [Valuation].[ConfigClientPlan]
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
            
                INSERT  INTO [Valuation].[LogConfigClientPlan]
                        (
                         [ConfigClientPlanId]
                       , [ConfigClientMainId]
                       , [ConfigClientMainId_old]
                       , [ClientId]
                       , [ClientId_old]
                       , [PlanId]
                       , [PlanId_old]
                       , [PlanDb]
                       , [PlanDb_old]
                       , [Priority]
                       , [Priority_old]
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
                    [ConfigClientPlanId] = ISNULL(new.[ConfigClientPlanId], old.[ConfigClientPlanId])
                  , [ConfigClientMainId] = new.[ConfigClientMainId]
                  , [ConfigClientMainId_old] = old.[ConfigClientMainId]
                  , [ClientId] = new.[ClientId]
                  , [ClientId_old] = old.[ClientId]
                  , [PlanId] = new.[PlanId]
                  , [PlanId_old] = old.[PlanId]
                  , [PlanDb] = new.[PlanDb]
                  , [PlanDb_old] = old.[PlanDb]
                  , [Priority] = new.[Priority]
                  , [Priority_old] = old.[Priority]
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
                  , [ReviewedBy] = [new].[ReviewedBy]
                  , [ReviewedBy_old] = [old].[ReviewedBy]
                  , [Edited] = GETDATE()
                  , [EditedBy] = USER_NAME()
                  , [Action] = @Action
                FROM
                    inserted new
                LEFT JOIN [Deleted] old
                    ON [new].[ConfigClientPlanId] = [old].[ConfigClientPlanId]

            END        
      
        IF @Action = 'D'
            BEGIN 

                INSERT  INTO [Valuation].[LogConfigClientPlan]
                        (
                         [ConfigClientPlanId]
                       , [ConfigClientMainId_old]
                       , [ClientId_old]
                       , [PlanId_old]
                       , [PlanDb_old]
                       , [Priority_old]
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
                    [ConfigClientPlanId] = old.[ConfigClientPlanId]
                  , [ConfigClientMainId_old] = old.[ConfigClientMainId]
                  , [ClientId_old] = old.[ClientId]
                  , [PlanId_old] = old.[PlanId]
                  , [PlanDb_old] = old.[PlanDb]
                  , [Priority_old] = old.[Priority]
                  , [ActiveBDate_old] = old.[ActiveBDate]
                  , [ActiveEDate_old] = old.[ActiveEDate]
                  , [Added_old] = old.[Added]
                  , [AddedBy_old] = old.[AddedBy]
                  , [Reviewed_old] = old.[Reviewed]
                  , [ReviewedBy_old] = [old].[ReviewedBy]
                  , [Edited] = GETDATE()
                  , [EditedBy] = USER_NAME()
                  , [Action] = 'D'
                FROM
                    DELETEd old       

            END 
    END
