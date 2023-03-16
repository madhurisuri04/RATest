CREATE PROC [Valuation].[ConfigUpdateConfigClientPlan]
    (
     @ConfigClientPlanId [INT] = NULL
   , @ConfigClientMainId [INT] = NULL
   , @ClientId [INT] = NULL
   , @PlanId [VARCHAR](32) = NULL
   , @PlanDb [VARCHAR](130) = NULL
   , @Priority [INT] = NULL
   , @ActiveBDate [DATE] = NULL
   , @ActiveEDate [DATE] = NULL
   , @Reviewed [DATETIME] = NULL
   , @ReviewedBy [VARCHAR](257) = NULL
    )
AS
    SET NOCOUNT ON 

    RAISERROR('000', 0, 1) WITH NOWAIT

    IF (
        @ConfigClientPlanId IS NULL
        AND @ConfigClientMainId IS NULL
        AND @ClientId IS NULL
        AND @PlanId IS NULL
        AND @PlanDb IS NULL
        AND @Priority IS NULL
        AND @ActiveBDate IS NULL
        AND @ActiveEDate IS NULL
        AND @Reviewed IS NULL
        AND @ReviewedBy IS NULL
       )
        BEGIN 
        
            RAISERROR('001', 0, 1) WITH NOWAIT
                   
            SELECT
                [ConfigClientPlanId] = [m].[ConfigClientPlanId]
              , [ConfigClientMainId] = [m].[ConfigClientMainId]
              , [ClientId] = [m].[ClientId]
              , [PlanId] = [m].[PlanId]
              , [PlanDb] = [m].[PlanDb]
              , [Priority] = [m].[Priority]
              , [ActiveBDate] = [m].[ActiveBDate]
              , [ActiveEDate] = [m].[ActiveEDate]
              , [Added] = [m].[Added]
              , [AddedBy] = [m].[AddedBy]
              , [Reviewed] = [m].[Reviewed]
              , [ReviewedBy] = [m].[ReviewedBy]
            FROM
                [Valuation].[ConfigClientPlan] m
            ORDER BY
                [m].[ConfigClientPlanId]
              , [m].[Added]
            
           
            RETURN

        END
    RAISERROR('002', 0, 1) WITH NOWAIT

    IF @ConfigClientPlanId IS NOT NULL
        BEGIN 
            RAISERROR('003', 0, 1) WITH NOWAIT

            UPDATE
                m
            SET
                [m].[ConfigClientMainId] = ISNULL(@ConfigClientMainId, [m].[ConfigClientMainId])
              , [m].[ClientId] = ISNULL(@ClientId, [m].[ClientId])
              , [m].[PlanId] = ISNULL(@PlanId, [m].[PlanId])
              , [m].[PlanDb] = ISNULL(@PlanDb, [m].[PlanDb])
              , [m].[Priority] = ISNULL(@Priority, [m].[Priority])
              , [m].[ActiveBDate] = ISNULL(@ActiveBDate, [m].[ActiveBDate])
              , [m].[ActiveEDate] = ISNULL(@ActiveEDate, [m].[ActiveEDate])
              , [m].[Reviewed] = ISNULL(@Reviewed, [m].[Reviewed])
              , [m].[ReviewedBy] = ISNULL(@ReviewedBy, [m].[ReviewedBy])
            FROM
                [Valuation].[ConfigClientPlan] m
            WHERE
                m.[ConfigClientPlanId] = @ConfigClientPlanId
            RETURN
        END
    RAISERROR('004', 0, 1) WITH NOWAIT

    IF @ConfigClientPlanId IS NULL
        AND @ClientId IS NOT NULL
        BEGIN
            RAISERROR('005', 0, 1) WITH NOWAIT
            INSERT  INTO [Valuation].[ConfigClientPlan]
                    (
                     [ConfigClientMainId]
                   , [ClientId]
                   , [PlanId]
                   , [PlanDb]
                   , [Priority]
                   , [ActiveBDate]
                   , [ActiveEDate]
                   , [Reviewed]
                   , [ReviewedBy]
                    )
            SELECT
                [ConfigClientMainId] = @ConfigClientMainId
              , [ClientId] = @ClientId
              , [PlanId] = @PlanId
              , [PlanDb] = @PlanDb
              , [Priority] = @Priority
              , [ActiveBDate] = @ActiveBDate
              , [ActiveEDate] = @ActiveEDate
              , [Reviewed] = @Reviewed
              , [ReviewedBy] = @ReviewedBy


            RETURN
        END
    RAISERROR('006', 0, 1) WITH NOWAIT
