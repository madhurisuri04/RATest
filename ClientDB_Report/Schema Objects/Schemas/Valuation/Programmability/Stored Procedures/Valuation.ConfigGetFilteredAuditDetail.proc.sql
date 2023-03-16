CREATE PROC [Valuation].[ConfigGetFilteredAuditDetail]
    @ClientId INT
  , @AutoProcessRunId INT
  , @ClientLevelDb VARCHAR(128) --= 'Aetna_CN_ClientLevel'  
  , @ClientReportDb VARCHAR(128) --= 'Aetna_Report_TFS30212'
  , @Debug BIT = 1
AS
    --
    /************************************************************************************************************************ 
* Name			:	Valuation.ConfigGetFilteredAuditDetail    															*
* Type 			:	Stored Procedure																					*
* Author       	:	Mitch Casto																							*
* Date			:	2015-04-21																							*
* Version			:																									*
* Description		:																									*
*																														*
* Version History :																										*
* =================																										*
* Author			Date			Version#    TFS Ticket#		Description												*
* -----------------	----------		--------    -----------		------------											*
* MCasto			2016-11-17		1.1			59770			Changed column name from VeriskRequestId to RequestId	*
*																on @ClientReportDb.dbo.CWFDetails (Section 003)			*																	*
* Madhuri Suri      2018-08-26      1.2         72809           Update MBI to valuation FilteredAuditCWFDetail table																											*
************************************************************************************************************************/

    SET NOCOUNT ON
    SET STATISTICS IO OFF

    IF @Debug = 1
        BEGIN
            SET STATISTICS IO ON
            DECLARE @ET DATETIME
            DECLARE @MasterET DATETIME
            SET @ET = GETDATE()
            SET @MasterET = @ET
        END


    IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)
            SET @ET = GETDATE()
            RAISERROR('000', 0, 1) WITH NOWAIT
        END


    IF (OBJECT_ID('tempdb.dbo.#CR_Images') IS NOT NULL)
        BEGIN
            DROP TABLE [#CR_Images]
        END

    IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)
            SET @ET = GETDATE()
            RAISERROR('001', 0, 1) WITH NOWAIT
        END

    CREATE TABLE [#CR_Images] (
        [Id] [INT] IDENTITY(1, 1) PRIMARY KEY
      , [ProjectID] [INT]
      , [Subproject ID] [INT] NOT NULL
      , [Subproject Description] [VARCHAR](85) NULL
      , [Review Step ID] [INT] NULL
      , [ReviewName] [VARCHAR](50) NULL
      , [MedicalRecordImageReviewStatusID] [INT] NULL
      , [ImageID] [INT] NULL)

    IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)
            SET @ET = GETDATE()
            RAISERROR('002', 0, 1) WITH NOWAIT
        END

    DECLARE @CR_ImageSQL VARCHAR(6144)

    SET @CR_ImageSQL
        = '
/**/;
WITH CTE_A1
AS
(
	/*B  Pulls active filtered audit records CBB */

	SELECT
		  a.[MedicalRecordImageworkflowID]
		, a.[ID]
	FROM [' + @ClientLevelDb + '].[dbo].[vwMedicalRecordImageReviews] a
	JOIN [' + @ClientLevelDb + '].[dbo].[vwReviewSteps] rs             
			ON a.[ReviewStepId] = rs.[Id]
	JOIN [' + @ClientLevelDb + '].[dbo].[vwSubProject] sp              
			ON rs.[SubProjectID] = sp.[Id]
	JOIN [' + @ClientLevelDb
          + '].[dbo].[vwProject] p                  
			ON sp.[ProjectId] = p.[Id]
	WHERE --sp.[ProjectId] IN (303, 304, 305, 306, 307)
		--AND
		sp.[IsActive] = 1
		AND p.[IsActive] = 1
	GROUP BY a.[MedicalRecordImageworkflowID]
	,        a.[Id]
	/*E  Pulls active filtered audit records CBB */

)
,    CTE_B1
AS
(
	/*B Pulls records adding LastUpdateDatetime.  A 1 in this field is the most recent CBB */
	SELECT
		  a.[MedicalRecordImageworkflowID]
		, a.[ReviewStepId]
		, a.[MedicalRecordImageReviewStatusId]
		, a.[Id]
		, [IsMostRecentRecord] = RANK() OVER (PARTITION BY a.[MedicalRecordImageWorkflowID], a.[ReviewStepId] ORDER BY a.[LastUpdateDateTime] DESC)
	FROM [' + @ClientLevelDb
          + '].[dbo].[vwMedicalRecordImageReviews] a
	JOIN CTE_A1 b                           
			ON a.[MedicalRecordImageWorkflowID] = b.[MedicalRecordImageWorkflowID]
				AND a.[Id] = b.[Id]
	WHERE a.[MedicalRecordImageReviewStatusId] NOT IN (''4'', ''5'') ---pulls only ready for review, review in progress, review complete CBB

	/*E Pulls records adding LastUpdateDatetime.  A 1 in this field is the most recent CBB */
)

/*B Gets the most recent completed reviews imageIDs - this is completed count for filtered audits  CBB */

SELECT
	  [ProjectID] = sp.[ProjectId]
	, [Subproject ID] = sp.[Id]
	, [Subproject Description] = sp.[Description]
	, [Review Step ID] = a.[ReviewStepId]
	, [ReviewName] = rs.[ReviewName]
	, [MedicalRecordImageReviewStatusID] = a.[MedicalRecordImageReviewStatusID]
	, [ImageID] = mriw.[MedicalRecordImageID]
FROM [' + @ClientLevelDb + '].[dbo].[vwMedicalRecordImageReviews] a       
JOIN [' + @ClientLevelDb + '].[dbo].[vwReviewSteps] rs                    
		ON a.[ReviewStepId] = rs.[Id]
JOIN [' + @ClientLevelDb + '].[dbo].[vwSubProject] sp                     
		ON rs.[SubProjectId] = sp.[Id]
JOIN [' + @ClientLevelDb
          + '].[dbo].[vwMedicalRecordImageReviewStatuses] s
		ON s.[Id] = a.[MedicalRecordImageReviewStatusId]
JOIN [' + @ClientLevelDb + '].[dbo].[vwProject] p                         
		ON sp.[ProjectId] = p.[Id]
JOIN [' + @ClientLevelDb
          + '].[dbo].[vwMedicalRecordImageWorkflow] mriw   
		ON mriw.[Id] = a.[MedicalRecordImageWorkflowId]
JOIN CTE_B1 b                                  
		ON a.[Id] = b.[Id]
			AND a.[MedicalRecordImageWorkflowId] = b.[MedicalRecordImageWorkflowId]
			AND a.[ReviewStepId] = b.[ReviewStepId]
WHERE 
	b.[IsMostRecentRecord] = 1 ---one is the most recent  CBB
	AND a.[MedicalRecordImageReviewStatusId] = ''3'' ----to select only completed review status IDs  CBB
GROUP BY sp.[ProjectId]
,        sp.[Id]
,        sp.[Description]
,        a.[ReviewStepId]
,        rs.[ReviewName]
,        a.[MedicalRecordImageReviewStatusId]
,        mriw.[MedicalRecordImageId]

/*E Gets the most recent completed reviews imageIDs - this is completed count for filtered audits  CBB */
'

    IF @Debug = 1
        BEGIN
            PRINT '--======================--'
            PRINT '@ClientLevelDb: ' + @ClientLevelDb

            PRINT '--======================--'
            PRINT @CR_ImageSQL
            PRINT '--======================--'
            RAISERROR('', 0, 1) WITH NOWAIT
        END

    INSERT INTO [#CR_Images] ([ProjectID]
                            , [Subproject ID]
                            , [Subproject Description]
                            , [Review Step ID]
                            , [ReviewName]
                            , [MedicalRecordImageReviewStatusID]
                            , [ImageID])
    EXEC(@CR_ImageSQL)


    IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)
            SET @ET = GETDATE()
            RAISERROR('003', 0, 1) WITH NOWAIT
        END

    DECLARE @FilteredAuditCNCompletedChartSQL VARCHAR(4096)

    SET @FilteredAuditCNCompletedChartSQL
        = '
DELETE m
FROM [' + @ClientReportDb + '].[Valuation].[FilteredAuditCNCompletedChart] m
WHERE m.[AutoProcessRunId] = ' + CAST(@AutoProcessRunId AS VARCHAR(11))
          + '

/*B Select all records in #CR_Images pivot by subproject and join to get unique record ids for CN counts */
INSERT INTO [' + @ClientReportDb
          + '].[Valuation].[FilteredAuditCNCompletedChart] 
        ([ClientId] 
        ,[AutoProcessRunId]
	, [ProjectId]
	, [SubProjectId]
	, [SubProjectDescription]
	, [ReviewName]
	, [VeriskRequestId] )
SELECT DISTINCT
    [ClientId] = ' + CAST(@ClientId AS VARCHAR(11)) + '
    ,  [AutoProcessRunId] = ' + CAST(@AutoProcessRunId AS VARCHAR(11))
          + '
	, [ProjectId] = b.[ProjectId]
	, [SubProjectId] = b.[SubprojectId]
	, [SubProjectDescription] = b.[SubProjectDescription]
	, [ReviewName] = a.[ReviewName]
	, [VeriskRequestId] = b.[RequestId]
FROM      #CR_Images a                                
LEFT JOIN [' + @ClientReportDb
          + '].[dbo].[CWFDetails] b
		ON a.[ImageId] = b.[MedicalRecordImageId]
			AND a.[Subproject Id] = b.[SubprojectId]
'


    IF @Debug = 1
        BEGIN
            PRINT '--======================--'
            PRINT '@AutoProcessRunId: ' + CAST(@AutoProcessRunId AS VARCHAR(11))
            PRINT '@ClientReportDb: ' + @ClientReportDb
            PRINT '--======================--'
            PRINT @FilteredAuditCNCompletedChartSQL
            PRINT '--======================--'
            RAISERROR('', 0, 1) WITH NOWAIT
        END

    EXEC (@FilteredAuditCNCompletedChartSQL)


    /*E Select all records in #CR_Images pivot by subproject and join to get unique record ids for CN counts */

    IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)
            SET @ET = GETDATE()
            RAISERROR('005', 0, 1) WITH NOWAIT
        END

    /*B ADD HICN, Provider ID, ENDDOS, DIAG to join to HCC data -CBB */
    DECLARE @FilteredAuditCWFDetailSQL VARCHAR(4096)

    SET @FilteredAuditCWFDetailSQL
        = '
DELETE m
FROM [' + @ClientReportDb + '].[Valuation].[FilteredAuditCWFDetail] m
WHERE m.[AutoProcessRunId] = ' + CAST(@AutoProcessRunId AS VARCHAR(11)) + '

INSERT INTO [' + @ClientReportDb
          + '].[Valuation].[FilteredAuditCWFDetail] ( [AutoProcessRunId]
, [ClientId]
	, [ProjectId]
	, [SubProjectId]
	, [SubProjectDescription]
	, [ReviewName]
	, [CurrentImageStatus]
	, [ImageId]
	, [HICN]
	, [DOB]
	, [ProviderId]
	, [DOSEndDt]
	, [DiagnosisCode] )

SELECT
	  [AutoProcessRunId] = ' + CAST(@AutoProcessRunId AS VARCHAR(11)) + '
, [ClientId] = ' + CAST(@ClientId AS VARCHAR(11))
          + '
	, [ProjectId] = a.[ProjectId]
	, [SubprojectId] = b.[SubprojectId]
	, [SubProjectDescription] = b.[SubProjectDescription]
	, [ReviewName] = a.[ReviewName]
	, [CurrentImageStatus] = b.[CurrentImageStatus]
	, [ImageId] = a.[ImageId]
	, [HICN] = RTRIM(LTRIM(b.[HICN]))
	, [DOB] = b.[MemberDOB]
	, [ProviderId] = RTRIM(LTRIM(b.[ProviderId]))
	, [DOSEndDt] = b.[DOSEndDt]
	, [DiagnosisCode] = RTRIM(LTRIM(b.[DiagnosisCode]))
FROM      #CR_Images a                                
LEFT JOIN [' + @ClientReportDb
          + '].[dbo].[CWFDetails] b
		ON a.[ImageId] = b.[MedicalRecordImageId]
			AND a.[Subproject Id] = b.[SubprojectId]
WHERE b.[SubProjectId] IS NOT NULL
	AND b.[CurrentImageStatus] NOT IN (''Cannot be Coded'', ''Ready for Coding'', ''Ready for Review'')
	
GROUP BY a.[ProjectId]
,        b.[SubprojectId]
,        b.[SubProjectDescription]
,        a.[ReviewName]
,        b.[CurrentImageStatus]
,        a.[ImageId]
,        b.[HICN]
,        b.[MemberDOB]
,        b.[ProviderId]
,        b.[DOSEndDt]
,        b.[DiagnosisCode]


UPDATE a
SET a.HICN = b.FinalHICN
from [' + @ClientReportDb
          + '].[Valuation].[FilteredAuditCWFDetail] a
JOIN [' + @ClientReportDb
          + '].rev.tbl_Summary_RskAdj_AltHICN b
      on a.HICN = b.HICN
Where AutoProcessRunId = ' + CAST(@AutoProcessRunId AS VARCHAR(11)) + '
/*E ADD HICN, Provider ID, ENDDOS, DIAG to join to HCC data -CBB */
'

    IF @Debug = 1
        BEGIN
            PRINT '--======================--'
            PRINT '@ClientReportDb: ' + @ClientReportDb
            PRINT '@AutoProcessRunId: ' + CAST(@AutoProcessRunId AS VARCHAR(11))
            PRINT '--======================--'
            PRINT @FilteredAuditCWFDetailSQL
            PRINT '--======================--'
            RAISERROR('', 0, 1) WITH NOWAIT

        END


		
EXEC (@FilteredAuditCWFDetailSQL)

    IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' | ' + CONVERT(CHAR(23), GETDATE(), 121)
            RAISERROR('007', 0, 1) WITH NOWAIT
            PRINT 'Total ET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' | ' + CONVERT(CHAR(23), GETDATE(), 121)
            RAISERROR('Done.|', 0, 1) WITH NOWAIT
        END


