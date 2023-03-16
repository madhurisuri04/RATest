CREATE TRIGGER [Valuation].[TR_ValuationConfigStaticParameters_Log] ON [Valuation].[ConfigStaticParameters]
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
            
                INSERT  INTO [Valuation].[LogConfigStaticParameters]
                        (
                         [ConfigStaticParametersId]
                                 , [AutoProcessId] 
                                 , [AutoProcessId_old]
                       , [ClientId]
                       , [ClientId_old]
                       , [AutoProcessActionCatalogId]
                                 , [AutoProcessActionCatalogId_old]
                                 , [ParameterName]
                       , [ParameterName_old]
                       , [ParameterValue]
                       , [ParameterValue_old]
                       , [Description]
                       , [Description_old]
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
                    [ConfigStaticParametersId] = ISNULL([new].[ConfigStaticParametersId], [old].[ConfigStaticParametersId])
                  , [AutoProcessId] = new.[AutoProcessId]
                          , [AutoProcessId_old] = old.[AutoProcessId]
                          , [ClientId] = new.[ClientId]
                  , [ClientId_old] = old.[ClientId]
                          , [AutoProcessActionCatalogId] = new.[AutoProcessActionCatalogId]
                          , [AutoProcessActionCatalogId_old] = old.[AutoProcessActionCatalogId]
                  , [ParameterName] = new.[ParameterName]
                  , [ParameterName_old] = old.[ParameterName]
                  , [ParameterValue] = new.[ParameterValue]
                  , [ParameterValue_old] = old.[ParameterValue]
                  , [Description] = new.[Description]
                  , [Description_old] = old.[Description]
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
                    ON [new].[ConfigStaticParametersId] = [old].[ConfigStaticParametersId]


            

            END        
      
        IF @Action = 'D'
            BEGIN 

                INSERT  INTO [Valuation].[LogConfigStaticParameters]
                        (
                         [ConfigStaticParametersId]
                       , [ClientId_old]
                       , [ParameterName_old]
                       , [ParameterValue_old]
                       , [Description_old]
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
                    [ConfigStaticParametersId] = [old].[ConfigStaticParametersId]
                  , [ClientId_old] = old.[ClientId]
                  , [ParameterName_old] = old.[ParameterName]
                  , [ParameterValue_old] = old.[ParameterValue]
                  , [Description_old] = old.[Description]
                  , [ActiveBDate_old] = old.[ActiveBDate]
                  , [ActiveEDate_old] = old.[ActiveEDate]
                  , [Added_old] = old.[Added]
                  , [AddedBy_old] = old.[AddedBy]
                  , [Reviewed_old] = old.[Reviewed]
                  , [ReviewedBy_old] = old.[ReviewedBy]
                  , [Edited] = GETDATE()
                  , [EditedBy] = USER_NAME()
                  , [Action] = @Action
                FROM
                    DELETEd old       


            END 
    END
