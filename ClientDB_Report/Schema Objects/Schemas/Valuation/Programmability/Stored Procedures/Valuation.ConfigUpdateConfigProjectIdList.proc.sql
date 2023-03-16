CREATE PROC [Valuation].[ConfigUpdateConfigProjectIdList]
    (
     @ConfigProjectIdListId [INT] = NULL
   , @ConfigClientMainId [INT] = NULL
   , @ClientId [INT] = NULL
   , @ProjectId [INT] = NULL
   , @ProjectDescription [VARCHAR](85) = NULL
   , @ProjectSortOrder [INT] = NULL
   , @SuspectYR [CHAR](4) = NULL
   , @ActiveBDate [DATE] = NULL
   , @ActiveEDate [DATE] = NULL
   , @Reviewed [DATETIME] = NULL
   , @ReviewedBy [VARCHAR](257) = NULL
    )
AS
    SET NOCOUNT ON 

    RAISERROR('000', 0, 1) WITH NOWAIT

    IF (
        @ConfigProjectIdListId IS NULL
        AND @ConfigClientMainId IS NULL
        AND @ClientId IS NULL
        AND @ProjectId IS NULL
        AND @ProjectDescription IS NULL
        AND @ProjectSortOrder IS NULL
        AND @SuspectYR IS NULL
        AND @ActiveBDate IS NULL
        AND @ActiveEDate IS NULL
        AND @Reviewed IS NULL
        AND @ReviewedBy IS NULL
       )
        BEGIN 
        
            RAISERROR('001', 0, 1) WITH NOWAIT
                   
            SELECT
                [ConfigProjectIdListId] = [m].[ConfigProjectIdListId]
              , [ConfigClientMainId] = [m].[ConfigClientMainId]
              , [ClientId] = [m].[ClientId]
              , [ProjectId] = [m].[ProjectId]
              , [ProjectDescription] = [m].[ProjectDescription]
              , [ProjectSortOrder] = [m].[ProjectSortOrder]
              , [SuspectYR] = [m].[SuspectYR]
              , [ActiveBDate] = [m].[ActiveBDate]
              , [ActiveEDate] = [m].[ActiveEDate]
              , [Added] = [m].[Added]
              , [AddedBy] = [m].[AddedBy]
              , [Reviewed] = [m].[Reviewed]
              , [ReviewedBy] = [m].[ReviewedBy]
            FROM
                [Valuation].[ConfigProjectIdList] m
            ORDER BY
                [m].[ConfigProjectIdListId]
              , [m].[Added]
            
           
            RETURN

        END
    RAISERROR('002', 0, 1) WITH NOWAIT

    IF @ConfigProjectIdListId IS NOT NULL
        BEGIN 
            RAISERROR('003', 0, 1) WITH NOWAIT

            UPDATE
                m
            SET
                [m].[ConfigClientMainId] = ISNULL(@ConfigClientMainId, [m].[ConfigClientMainId])
              , [m].[ClientId] = ISNULL(@ClientId, [m].[ClientId])
              , [m].[ProjectId] = ISNULL(@ProjectId, [m].[ProjectId])
              , [m].[ProjectDescription] = ISNULL(@ProjectDescription, [m].[ProjectDescription])
              , [m].[ProjectSortOrder] = ISNULL(@ProjectSortOrder, [m].[ProjectSortOrder])
              , [m].[SuspectYR] = ISNULL(@SuspectYR, [m].[SuspectYR])
              , [m].[ActiveBDate] = ISNULL(@ActiveBDate, [m].[ActiveBDate])
              , [m].[ActiveEDate] = ISNULL(@ActiveEDate, [m].[ActiveEDate])
              , [m].[Reviewed] = ISNULL(@Reviewed, [m].[Reviewed])
              , [m].[ReviewedBy] = ISNULL(@ReviewedBy, [m].[ReviewedBy])
            FROM
                [Valuation].[ConfigProjectIdList] m
            WHERE
                m.[ConfigProjectIdListId] = @ConfigProjectIdListId
            RETURN
        END
    RAISERROR('004', 0, 1) WITH NOWAIT

    IF @ConfigProjectIdListId IS NULL
        AND @ClientId IS NOT NULL
        BEGIN
            RAISERROR('005', 0, 1) WITH NOWAIT
            
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
                   , [Reviewed]
                   , [ReviewedBy]
                    )
            SELECT
                [ConfigClientMainId] = @ConfigClientMainId
              , [ClientId] = @ClientId
              , [ProjectId] = @ProjectId
              , [ProjectDescription] = @ProjectDescription
              , [ProjectSortOrder] = @ProjectSortOrder
              , [SuspectYR] = @SuspectYR
              , [ActiveBDate] = @ActiveBDate
              , [ActiveEDate] = @ActiveEDate
              , [Reviewed] = @Reviewed
              , [ReviewedBy] = @ReviewedBy

            
          


            RETURN
        END
    RAISERROR('006', 0, 1) WITH NOWAIT
