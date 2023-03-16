CREATE PROC [Valuation].[ConfigUpdateConfigSubProjectReviewName]
    (
     @SubProjectReviewNameId [INT] = NULL
   , @ClientId [INT] = NULL
   , @ProjectId [INT] = NULL
   , @SubProjectId [INT] = NULL
   , @ReviewName [VARCHAR](50) = NULL
   , @ActiveBDate [DATE] = NULL
   , @ActiveEDate [DATE] = NULL
   , @Reviewed [DATETIME] = NULL
   , @ReviewedBy [VARCHAR](257) = NULL
    )
AS
    SET NOCOUNT ON 


    RAISERROR('000', 0, 1) WITH NOWAIT

    IF (
        @SubProjectReviewNameId IS NULL
        AND @ClientId IS NULL
        AND @ProjectId IS NULL
        AND @SubProjectId IS NULL
        AND @ReviewName IS NULL
        AND @ActiveBDate IS NULL
        AND @ActiveEDate IS NULL
        AND @Reviewed IS NULL
        AND @ReviewedBy IS NULL
       )
        BEGIN 
        
            RAISERROR('001', 0, 1) WITH NOWAIT
                   
            SELECT
                [SubProjectReviewNameId] = [m].[SubProjectReviewNameId]
              , [ClientId] = [m].[ClientId]
              , [ProjectId] = [m].[ProjectId]
              , [SubProjectId] = [m].[SubProjectId]
              , [ReviewName] = [m].[ReviewName]
              , [ActiveBDate] = [m].[ActiveBDate]
              , [ActiveEDate] = [m].[ActiveEDate]
              , [Added] = [m].[Added]
              , [AddedBy] = [m].[AddedBy]
              , [Reviewed] = [m].[Reviewed]
              , [ReviewedBy] = [m].[ReviewedBy]
            FROM
                [Valuation].[ConfigSubProjectReviewName] m
            ORDER BY
                [m].[SubProjectReviewNameId]
              , [m].[Added]
            
           
            RETURN

        END
    RAISERROR('002', 0, 1) WITH NOWAIT

    IF @SubProjectReviewNameId IS NOT NULL
        BEGIN 
            RAISERROR('003', 0, 1) WITH NOWAIT

            UPDATE
                m
            SET
                [m].[ClientId] = ISNULL(@ClientId, [m].[ClientId])
              , [m].[ProjectId] = ISNULL(@ProjectId, [m].[ProjectId])
              , [m].[SubProjectId] = ISNULL(@SubProjectId, [m].[SubProjectId])
              , [m].[ReviewName] = ISNULL(@ReviewName, [m].[ReviewName])
              , [m].[ActiveBDate] = ISNULL(@ActiveBDate, [m].[ActiveBDate])
              , [m].[ActiveEDate] = ISNULL(@ActiveEDate, [m].[ActiveEDate])
              , [m].[Reviewed] = ISNULL(@Reviewed, [m].[Reviewed])
              , [m].[ReviewedBy] = ISNULL(@ReviewedBy, [m].[ReviewedBy])
            FROM
                [Valuation].[ConfigSubProjectReviewName] m
            WHERE
                m.[SubProjectReviewNameId] = @SubProjectReviewNameId
            RETURN
        END
    RAISERROR('004', 0, 1) WITH NOWAIT

    IF @SubProjectReviewNameId IS NULL
        AND @ClientId IS NOT NULL
        BEGIN
            RAISERROR('005', 0, 1) WITH NOWAIT
            
            INSERT  INTO [Valuation].[ConfigSubProjectReviewName]
                    (
                     [ClientId]
                   , [ProjectId]
                   , [SubProjectId]
                   , [ReviewName]
                   , [ActiveBDate]
                   , [ActiveEDate]
                   , [Reviewed]
                   , [ReviewedBy]
                    )
            SELECT
                [ClientId] = @ClientId
              , [ProjectId] = @ProjectId
              , [SubProjectId] = @SubProjectId
              , [ReviewName] = @ReviewName
              , [ActiveBDate] = @ActiveBDate
              , [ActiveEDate] = @ActiveEDate
              , [Reviewed] = @Reviewed
              , [ReviewedBy] = @ReviewedBy
            

            RETURN
        END
        
    RAISERROR('006', 0, 1) WITH NOWAIT
