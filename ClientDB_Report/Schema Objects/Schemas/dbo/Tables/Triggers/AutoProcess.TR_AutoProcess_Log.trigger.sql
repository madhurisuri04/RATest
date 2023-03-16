CREATE TRIGGER [dbo].[TR_AutoProcess_Log] ON [dbo].[AutoProcess]
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
                INSERT  INTO [dbo].[LogAutoProcess]
                        (
                        [AutoProcessId],
						[AutoProcessName],
						[AutoProcessName_old],
						[ActiveBDate],
						[ActiveBDate_old],
						[ActiveEDate],
						[ActiveEDate_old],
						[Added],
						[Added_old],
						[AddedBy],
						[AddedBy_old],
						[Edited],
						[EditedBy],
						[Action]
                       )
                SELECT
                    [AutoProcessId]= ISNULL(new.[AutoProcessId],old.[AutoProcessId])
                    ,[AutoProcessName] = new.[AutoProcessName]
					,[AutoProcessName_old]= old.[AutoProcessName]
					,[ActiveBDate] = new.[ActiveBDate]
					,[ActiveBDate_old] = old.[ActiveBDate]
					,[ActiveEDate]= new.[ActiveEDate]
					,[ActiveEDate_old] = old.[ActiveEDate]
					,[Added]= new.[Added]
					,[Added_old] = old.[Added]
					,[AddedBy] = new.[AddedBy]
					,[AddedBy_old] = old.[AddedBy]
					, [Edited] = GETDATE()
					, [EditedBy] = USER_NAME()
					, [Action] = @Action
                FROM
                    inserted new
                LEFT JOIN [Deleted] old
                    ON [new].[AutoProcessId] = [old].[AutoProcessId]

            END        
      
        IF @Action = 'D'
            BEGIN 

                INSERT  INTO [dbo].[LogAutoProcess]
                        (
                        [AutoProcessId],
						[AutoProcessName_old],
						[ActiveBDate_old],
						[ActiveEDate_old],
						[Added_old],
						[AddedBy_old],
						[Edited],
                        [EditedBy],
                        [Action]
                        )
                SELECT 
					
                    [AutoProcessId] = [old].[AutoProcessId]
                  , [AutoProcessName_old] = old.[AutoProcessName]
                  , [ActiveBDate_old] = old.[ActiveBDate]
                  , [ActiveEDate_old] = old.[ActiveEDate]
                  , [Added_old] = old.[Added]
                  , [AddedBy_old] = old.[AddedBy]
                  , [Edited] = GETDATE()
                  , [EditedBy] = USER_NAME()
                  , [Action] = 'D'
                FROM
                    DELETEd old       
            END 

    END
