CREATE PROC [Valuation].[ConfigUpdateConfigSubProjectSubstringPattern]
    (
     @SubProjectSubstringPatternId [INT] = NULL
   , @ClientId [INT] = NULL
   , @ProjectId [INT] = NULL
   , @SubProjectId [INT] = NULL
   , @SubprojectDescription [VARCHAR](255) = NULL
   , @Source01 [NVARCHAR](255) = NULL
   , @ProviderType [CHAR](2) = NULL
   , @Type [VARCHAR](15) = NULL
   , @ProjectCategory [VARCHAR](85) = NULL
   , @SubProjectSortOrder [SMALLINT] = NULL
   , @ActiveBDate [DATE] = NULL
   , @ActiveEDate [DATE] = NULL
   , @FilteredAuditActiveBDate [DATE] = NULL
   , @FilteredAuditActiveEDate [DATE] = NULL
   , @OnShoreOffShore [CHAR](1) = NULL
   , @ID_VAN [CHAR](1) = NULL
   , @PMH [CHAR](1) = NULL
   , @MissingSignature [CHAR](1) = NULL
   , @Filler01 [CHAR](1) = NULL
   , @Filler02 [CHAR](1) = NULL
   , @UniquePattern [VARCHAR](255) = NULL
   , @PCNStringPattern [VARCHAR](255) = NULL
   , @FailureReason [VARCHAR](20) = NULL
   , @Reviewed [DATETIME] = NULL
   , @ReviewedBy [VARCHAR](257) = NULL
    )
AS
    SET NOCOUNT ON 


    RAISERROR('000', 0, 1) WITH NOWAIT

    IF (
        @SubProjectSubstringPatternId IS NULL
        AND @ClientId IS NULL
        AND @ProjectId IS NULL
        AND @SubProjectId IS NULL
        AND @SubprojectDescription IS NULL
        AND @Source01 IS NULL
        AND @ProviderType IS NULL
        AND @Type IS NULL
        AND @ProjectCategory IS NULL
        AND @SubProjectSortOrder IS NULL
        AND @ActiveBDate IS NULL
        AND @ActiveEDate IS NULL
        AND @FilteredAuditActiveBDate IS NULL
        AND @FilteredAuditActiveEDate IS NULL
        AND @OnShoreOffShore IS NULL
        AND @ID_VAN IS NULL
        AND @PMH IS NULL
        AND @MissingSignature IS NULL
        AND @Filler01 IS NULL
        AND @Filler02 IS NULL
        AND @UniquePattern IS NULL
        AND @PCNStringPattern IS NULL
        AND @FailureReason IS NULL
        AND @Reviewed IS NULL
        AND @ReviewedBy IS NULL
       )
        BEGIN 
        
            RAISERROR('001', 0, 1) WITH NOWAIT
                   
            SELECT
                [SubProjectSubstringPatternId] = [m].[SubProjectSubstringPatternId]
              , [ClientId] = [m].[ClientId]
              , [ProjectId] = [m].[ProjectId]
              , [SubProjectId] = [m].[SubProjectId]
              , [SubprojectDescription] = [m].[SubprojectDescription]
              , [Source01] = [m].[Source01]
              , [ProviderType] = [m].[ProviderType]
              , [Type] = [m].[Type]
              , [ProjectCategory] = [m].[ProjectCategory]
              , [SubProjectSortOrder] = [m].[SubProjectSortOrder]
              , [ActiveBDate] = [m].[ActiveBDate]
              , [ActiveEDate] = [m].[ActiveEDate]
              , [FilteredAuditActiveBDate] = [m].[FilteredAuditActiveBDate]
              , [FilteredAuditActiveEDate] = [m].[FilteredAuditActiveEDate]
              , [OnShoreOffShore] = [m].[OnShoreOffShore]
              , [ID_VAN] = [m].[ID_VAN]
              , [PMH] = [m].[PMH]
              , [MissingSignature] = [m].[MissingSignature]
              , [Filler01] = [m].[Filler01]
              , [Filler02] = [m].[Filler02]
              , [UniquePattern] = [m].[UniquePattern]
              , [PCNStringPattern] = [m].[PCNStringPattern]
              , [FailureReason] = [m].[FailureReason]
              , [Added] = [m].[Added]
              , [AddedBy] = [m].[AddedBy]
              , [Reviewed] = [m].[Reviewed]
              , [ReviewedBy] = [m].[ReviewedBy]
            FROM
                [Valuation].[ConfigSubProjectSubstringPattern] m
            ORDER BY
                [m].[SubProjectSubstringPatternId]
              , [m].[Added]
            
           
            RETURN

        END
    RAISERROR('002', 0, 1) WITH NOWAIT

    IF @SubProjectSubstringPatternId IS NOT NULL
        BEGIN 
            RAISERROR('003', 0, 1) WITH NOWAIT

            UPDATE
                m
            SET
                [m].[ClientId] = ISNULL(@ClientId, [m].[ClientId])
              , [m].[ProjectId] = ISNULL(@ProjectId, [m].[ProjectId])
              , [m].[SubProjectId] = ISNULL(@SubProjectId, [m].[SubProjectId])
              , [m].[SubprojectDescription] = ISNULL(@SubprojectDescription, [m].[SubprojectDescription])
              , [m].[Source01] = ISNULL(@Source01, [m].[Source01])
              , [m].[ProviderType] = ISNULL(@ProviderType, [m].[ProviderType])
              , [m].[Type] = ISNULL(@Type, [m].[Type])
              , [m].[ProjectCategory] = ISNULL(@ProjectCategory, [m].[ProjectCategory])
              , [m].[SubProjectSortOrder] = ISNULL(@SubProjectSortOrder, [m].[SubProjectSortOrder])
              , [m].[ActiveBDate] = ISNULL(@ActiveBDate, [m].[ActiveBDate])
              , [m].[ActiveEDate] = ISNULL(@ActiveEDate, [m].[ActiveEDate])
              , [m].[FilteredAuditActiveBDate] = ISNULL(@FilteredAuditActiveBDate, [m].[FilteredAuditActiveBDate])
              , [m].[FilteredAuditActiveEDate] = ISNULL(@FilteredAuditActiveEDate, [m].[FilteredAuditActiveEDate])
              , [m].[OnShoreOffShore] = ISNULL(@OnShoreOffShore, [m].[OnShoreOffShore])
              , [m].[ID_VAN] = ISNULL(@ID_VAN, [m].[ID_VAN])
              , [m].[PMH] = ISNULL(@PMH, [m].[PMH])
              , [m].[MissingSignature] = ISNULL(@MissingSignature, [m].[MissingSignature])
              , [m].[Filler01] = ISNULL(@Filler01, [m].[Filler01])
              , [m].[Filler02] = ISNULL(@Filler02, [m].[Filler02])
              , [m].[UniquePattern] = ISNULL(@UniquePattern, [m].[UniquePattern])
              , [m].[PCNStringPattern] = ISNULL(@PCNStringPattern, [m].[PCNStringPattern])
              , [m].[FailureReason] = ISNULL(@FailureReason, [m].[FailureReason])
              , [m].[Reviewed] = ISNULL(@Reviewed, [m].[Reviewed])
              , [m].[ReviewedBy] = ISNULL(@ReviewedBy, [m].[ReviewedBy])
            FROM
                [Valuation].[ConfigSubProjectSubstringPattern] m
            WHERE
                m.[SubProjectSubstringPatternId] = @SubProjectSubstringPatternId
            RETURN
        END
        
    RAISERROR('004', 0, 1) WITH NOWAIT

    IF @SubProjectSubstringPatternId IS NULL
        AND @ClientId IS NOT NULL
        BEGIN
            RAISERROR('005', 0, 1) WITH NOWAIT
           
            INSERT  INTO [Valuation].[ConfigSubProjectSubstringPattern]
                    (
                     [ClientId]
                   , [ProjectId]
                   , [SubProjectId]
                   , [SubprojectDescription]
                   , [Source01]
                   , [ProviderType]
                   , [Type]
                   , [ProjectCategory]
                   , [SubProjectSortOrder]
                   , [ActiveBDate]
                   , [ActiveEDate]
                   , [FilteredAuditActiveBDate]
                   , [FilteredAuditActiveEDate]
                   , [OnShoreOffShore]
                   , [ID_VAN]
                   , [PMH]
                   , [MissingSignature]
                   , [Filler01]
                   , [Filler02]
                   , [UniquePattern]
                   , [PCNStringPattern]
                   , [FailureReason]
                   , [Reviewed]
                   , [ReviewedBy]
                    )
            SELECT
                [ClientId] = @ClientId
              , [ProjectId] = @ProjectId
              , [SubProjectId] = @SubProjectId
              , [SubprojectDescription] = @SubprojectDescription
              , [Source01] = @Source01
              , [ProviderType] = @ProviderType
              , [Type] = @Type
              , [ProjectCategory] = @ProjectCategory
              , [SubProjectSortOrder] = @SubProjectSortOrder
              , [ActiveBDate] = @ActiveBDate
              , [ActiveEDate] = @ActiveEDate
              , [FilteredAuditActiveBDate] = @FilteredAuditActiveBDate
              , [FilteredAuditActiveEDate] = @FilteredAuditActiveEDate
              , [OnShoreOffShore] = @OnShoreOffShore
              , [ID_VAN] = @ID_VAN
              , [PMH] = @PMH
              , [MissingSignature] = @MissingSignature
              , [Filler01] = @Filler01
              , [Filler02] = @Filler02
              , [UniquePattern] = @UniquePattern
              , [PCNStringPattern] = @PCNStringPattern
              , [FailureReason] = @FailureReason
              , [Reviewed] = @Reviewed
              , [ReviewedBy] = @ReviewedBy

            RETURN
        END
        
    RAISERROR('006', 0, 1) WITH NOWAIT

