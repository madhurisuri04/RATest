CREATE TRIGGER [Valuation].[TR_ValuationConfigSubProjectSubstringPattern_Log] ON [Valuation].[ConfigSubProjectSubstringPattern]
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
            
                INSERT  INTO [Valuation].[LogConfigSubProjectSubstringPattern]
                        (
                         [SubProjectSubstringPatternId]
                       , [ClientId]
                       , [ClientId_old]
                       , [ProjectId]
                       , [ProjectId_old]
                       , [SubProjectId]
                       , [SubProjectId_old]
                       , [SubprojectDescription]
                       , [SubprojectDescription_old]
                       , [Source01]
                       , [Source01_old]
                       , [ProviderType]
                       , [ProviderType_old]
                       , [Type]
                       , [Type_old]
                       , [ProjectCategory]
                       , [ProjectCategory_old]
                       , [SubProjectSortOrder]
                       , [SubProjectSortOrder_old]
                       , [ActiveBDate]
                       , [ActiveBDate_old]
                       , [ActiveEDate]
                       , [ActiveEDate_old]
                       , [FilteredAuditActiveBDate]
                       , [FilteredAuditActiveBDate_old]
                       , [FilteredAuditActiveEDate]
                       , [FilteredAuditActiveEDate_old]
                       , [OnShoreOffShore]
                       , [OnShoreOffShore_old]
                       , [ID_VAN]
                       , [ID_VAN_old]
                       , [PMH]
                       , [PMH_old]
                       , [MissingSignature]
                       , [MissingSignature_old]
                       , [Filler01]
                       , [Filler01_old]
                       , [Filler02]
                       , [Filler02_old]
                       , [UniquePattern]
                       , [UniquePattern_old]
                       , [PCNStringPattern]
                       , [PCNStringPattern_old]
                       , [FailureReason]
                       , [FailureReason_old]
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
					   , [Payment_Year]
					   , [Payment_Year_old] 
				       , [SubprojectIdBPosition]
				       , [SubprojectIdBPosition_old]
				       , [SubprojectIdEPosition]
				       , [SubprojectIdEPosition_old]
				       , [SubprojectIdLength] 
				       , [SubprojectIdLength_old]  
				       , [ProviderIdBPosition] 
				       , [ProviderIdBPosition_old] 
				       , [ProviderIdLength] 
				       , [ProviderIdLength_old] 
				       , [ProviderIdEPosition] 
				       , [ProviderIdEPosition_old] 
				       , [UpdateStatement] 
				      
					   , [UpdateStatement_old] 
					   

					                           )
                SELECT
                    [SubProjectSubstringPatternId] = ISNULL(new.[SubProjectSubstringPatternId], old.[SubProjectSubstringPatternId])
                  , [ClientId] = new.[ClientId]
                  , [ClientId_old] = old.[ClientId]
                  , [ProjectId] = new.[ProjectId]
                  , [ProjectId_old] = old.[ProjectId]
                  , [SubProjectId] = new.[SubProjectId]
                  , [SubProjectId_old] = old.[SubProjectId]
                  , [SubprojectDescription] = new.[SubprojectDescription]
                  , [SubprojectDescription_old] = old.[SubprojectDescription]
                  , [Source01] = new.[Source01]
                  , [Source01_old] = old.[Source01]
                  , [ProviderType] = new.[ProviderType]
                  , [ProviderType_old] = old.[ProviderType]
                  , [Type] = new.[Type]
                  , [Type_old] = old.[Type]
                  , [ProjectCategory] = new.[ProjectCategory]
                  , [ProjectCategory_old] = old.[ProjectCategory]
                  , [SubProjectSortOrder] = new.[SubProjectSortOrder]
                  , [SubProjectSortOrder_old] = old.[SubProjectSortOrder]
                  , [ActiveBDate] = new.[ActiveBDate]
                  , [ActiveBDate_old] = old.[ActiveBDate]
                  , [ActiveEDate] = new.[ActiveEDate]
                  , [ActiveEDate_old] = old.[ActiveEDate]
                  , [FilteredAuditActiveBDate] = new.[FilteredAuditActiveBDate]
                  , [FilteredAuditActiveBDate_old] = old.[FilteredAuditActiveBDate]
                  , [FilteredAuditActiveEDate] = new.[FilteredAuditActiveEDate]
                  , [FilteredAuditActiveEDate_old] = old.[FilteredAuditActiveEDate]
                  , [OnShoreOffShore] = new.[OnShoreOffShore]
                  , [OnShoreOffShore_old] = old.[OnShoreOffShore]
                  , [ID_VAN] = new.[ID_VAN]
                  , [ID_VAN_old] = old.[ID_VAN]
                  , [PMH] = new.[PMH]
                  , [PMH_old] = old.[PMH]
                  , [MissingSignature] = new.[MissingSignature]
                  , [MissingSignature_old] = old.[MissingSignature]
                  , [Filler01] = new.[Filler01]
                  , [Filler01_old] = old.[Filler01]
                  , [Filler02] = new.[Filler02]
                  , [Filler02_old] = old.[Filler02]
                  , [UniquePattern] = new.[UniquePattern]
                  , [UniquePattern_old] = old.[UniquePattern]
                  , [PCNStringPattern] = new.[PCNStringPattern]
                  , [PCNStringPattern_old] = old.[PCNStringPattern]
                  , [FailureReason] = new.[FailureReason]
                  , [FailureReason_old] = old.[FailureReason]
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
				  , [Payment_Year] = new.[Payment_Year]
				  , [Payment_Year_old] = old.[Payment_Year]
				  , [SubprojectIdBPosition] = new.[SubprojectIdBPosition]
				  , [SubprojectIdBPosition_old] = old.[SubprojectIdBPosition]
				  , [SubprojectIdEPosition] = new.[SubprojectIdEPosition]
				  , [SubprojectIdEPosition_old] = old.[SubprojectIdEPosition]
				  , [SubprojectIdLength] = new.[SubprojectIdLength] 
				  , [SubprojectIdLength_old] = old.[SubprojectIdLength] 
				  , [ProviderIdBPosition] = new.[ProviderIdBPosition]
				  , [ProviderIdBPosition_old] = old.[ProviderIdBPosition]
				  , [ProviderIdLength] = new.[ProviderIdLength]
				  , [ProviderIdLength_old] = old.[ProviderIdLength]
				  , [ProviderIdEPosition] = new.[ProviderIdEPosition]
				  , [ProviderIdEPosition_old] = old.[ProviderIdEPosition]
				  , [UpdateStatement] = new.[UpdateStatement]
				  , [UpdateStatement_old] = old.[UpdateStatement]




                FROM
                    inserted new
                LEFT JOIN [Deleted] old
                    ON [new].[SubProjectSubstringPatternId] = [old].[SubProjectSubstringPatternId]

            
            

            END        
      
        IF @Action = 'D'
            BEGIN 

                INSERT  INTO [Valuation].[LogConfigSubProjectSubstringPattern]
                        (
                         [SubProjectSubstringPatternId]
                       , [ClientId_old]
                       , [ProjectId_old]
                       , [SubProjectId_old]
                       , [SubprojectDescription_old]
                       , [Source01_old]
                       , [ProviderType_old]
                       , [Type_old]
                       , [ProjectCategory_old]
                       , [SubProjectSortOrder_old]
                       , [ActiveBDate_old]
                       , [ActiveEDate_old]
                       , [FilteredAuditActiveBDate_old]
                       , [FilteredAuditActiveEDate_old]
                       , [OnShoreOffShore_old]
                       , [ID_VAN_old]
                       , [PMH_old]
                       , [MissingSignature_old]
                       , [Filler01_old]
                       , [Filler02_old]
                       , [UniquePattern_old]
                       , [PCNStringPattern_old]
                       , [FailureReason_old]
                       , [Added_old]
                       , [AddedBy_old]
                       , [Reviewed_old]
                       , [ReviewedBy_old]
                       , [Edited]
                       , [EditedBy]
                       , [Action]
					   , [Payment_Year_old]
					   , [SubprojectIdBPosition_old]
				       , [SubprojectIdEPosition_old]
				       , [SubprojectIdLength_old] 
				       , [ProviderIdBPosition_old] 
				       , [ProviderIdLength_old] 
				       , [ProviderIdEPosition_old] 
				       , [UpdateStatement_old] 
				       
                        )
                SELECT
                    [SubProjectSubstringPatternId] = old.[SubProjectSubstringPatternId]
                  , [ClientId_old] = old.[ClientId]
                  , [ProjectId_old] = old.[ProjectId]
                  , [SubProjectId_old] = old.[SubProjectId]
                  , [SubprojectDescription_old] = old.[SubprojectDescription]
                  , [Source01_old] = old.[Source01]
                  , [ProviderType_old] = old.[ProviderType]
                  , [Type_old] = old.[Type]
                  , [ProjectCategory_old] = old.[ProjectCategory]
                  , [SubProjectSortOrder_old] = old.[SubProjectSortOrder]
                  , [ActiveBDate_old] = old.[ActiveBDate]
                  , [ActiveEDate_old] = old.[ActiveEDate]
                  , [FilteredAuditActiveBDate_old] = old.[FilteredAuditActiveBDate]
                  , [FilteredAuditActiveEDate_old] = old.[FilteredAuditActiveEDate]
                  , [OnShoreOffShore_old] = old.[OnShoreOffShore]
                  , [ID_VAN_old] = old.[ID_VAN]
                  , [PMH_old] = old.[PMH]
                  , [MissingSignature_old] = old.[MissingSignature]
                  , [Filler01_old] = old.[Filler01]
                  , [Filler02_old] = old.[Filler02]
                  , [UniquePattern_old] = old.[UniquePattern]
                  , [PCNStringPattern_old] = old.[PCNStringPattern]
                  , [FailureReason_old] = old.[FailureReason]
                  , [Added_old] = old.[Added]
                  , [AddedBy_old] = old.[AddedBy]
                  , [Reviewed_old] = old.[Reviewed]
                  , [ReviewedBy_old] = old.[ReviewedBy]
                  , [Edited] = GETDATE()
                  , [EditedBy] = USER_NAME()
                  , [Action] = @Action
				  , [Payment_Year_old] = old.[Payment_Year]
				  , [SubprojectIdBPosition_old] = old.[SubprojectIdBPosition]
				  , [SubprojectIdEPosition_old] = old.[SubprojectIdEPosition]
				  , [SubprojectIdLength_old] = old.[SubprojectIdLength] 
				  , [ProviderIdBPosition_old] = old.[ProviderIdBPosition]
				  , [ProviderIdLength_old] = old.[ProviderIdLength]
				  , [ProviderIdEPosition_old] = old.[ProviderIdEPosition]
				  , [UpdateStatement_old] = old.[UpdateStatement]
				  
                FROM
                    DELETEd old       


            END 
    END
