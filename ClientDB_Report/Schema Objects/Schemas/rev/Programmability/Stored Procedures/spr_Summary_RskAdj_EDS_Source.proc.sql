CREATE PROC [rev].[spr_Summary_RskAdj_EDS_Source]
(
    @FullRefresh BIT = 0,
    @YearRefresh INT = NULL,
    @LoadDateTime DATETIME = NULL,
    @DeleteBatch INT = NULL,
    @RowCount INT OUT,
    @Debug BIT = 0
)
AS
/******************************************************************************************************************************** 
* Name			:	rev.spr_Summary_RskAdj_EDS_Source																		*
* Type 			:	Stored Procedure																							*																																																																																																																																																																																																																																																																																																																																																																																														
* Author       	:	Anand
* Date			:	2019-06-20																									*
* Version		:  1.0 2019-08-28 - RE - 6243 - 1.0 Truncated EDS_Source table before Insert																											*																																																									*
* Description		:Store procedure to load data into Summary from EDS Source tables.											
* Version History :																												*
* =================================================================================================								*
* Author			Date		Version#    TFS Ticket#		Description															*																*
* -----------------	----------  --------    -----------		------------														*	
* D.Waddell			10/29/2019	1.1			RE-6981			Set Transaction Isolation Level Read to Uncommitted                 *
*********************************************************************************************************************************/

BEGIN

    SET STATISTICS IO OFF;
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

    /*****************************************************************/
    /* Initialize value of local variables                           */
    /*****************************************************************/

    DECLARE @Min_Lagged_From_Date DATETIME = NULL;
    DECLARE @Curr_DB VARCHAR(128) = NULL;
    DECLARE @Clnt_DB VARCHAR(128) = NULL;
    DECLARE @RskAdj_SourceSQL VARCHAR(MAX);
    DECLARE @Startdate DATE;
    DECLARE @Enddate DATE;

    IF @Debug = 1
    BEGIN
        SET STATISTICS IO ON;
        DECLARE @ET DATETIME;
        DECLARE @MasterET DATETIME;
        DECLARE @ProcessNameIn VARCHAR(128);
        SET @ET = GETDATE();
        SET @MasterET = @ET;
        SET @ProcessNameIn = OBJECT_NAME(@@procid);
        EXEC [dbo].[PerfLogMonitor] @Section = '000',
                                    @ProcessName = @ProcessNameIn,
                                    @ET = @ET,
                                    @MasterET = @MasterET,
                                    @ET_Out = @ET OUT,
                                    @TableOutput = 0,
                                    @End = 0;
    END;

    SET @LoadDateTime = ISNULL(@LoadDateTime, GETDATE());
    SET @DeleteBatch = ISNULL(@DeleteBatch, 300000);

    IF @Debug = 1
    BEGIN
        EXEC [dbo].[PerfLogMonitor] '001',
                                    @ProcessNameIn,
                                    @ET,
                                    @MasterET,
                                    @ET OUT,
                                    0,
                                    0;
    END;



    SET @Curr_DB =
    (
        SELECT [Current Database] = DB_NAME()
    );

    SET @Clnt_DB = SUBSTRING(@Curr_DB, 0, CHARINDEX('_Report', @Curr_DB));

    IF @Debug = 1
    BEGIN
        EXEC [dbo].[PerfLogMonitor] '002',
                                    @ProcessNameIn,
                                    @ET,
                                    @MasterET,
                                    @ET OUT,
                                    0,
                                    0;
    END;


    IF (OBJECT_ID('tempdb.dbo.[#Refresh_PY]') IS NOT NULL)
    BEGIN
        DROP TABLE [#Refresh_PY];
    END;



    CREATE TABLE [#Refresh_PY]
    (
        [Id] INT IDENTITY(1, 1) PRIMARY KEY,
        [Payment_Year] INT NOT NULL,
        [From_Date] SMALLDATETIME NULL,
        [Thru_Date] SMALLDATETIME NULL,
        [Lagged_From_Date] SMALLDATETIME NULL,
        [Lagged_Thru_Date] SMALLDATETIME NULL
    );


    INSERT INTO [#Refresh_PY]
    (
        [Payment_Year],
        [From_Date],
        [Thru_Date],
        [Lagged_From_Date],
        [Lagged_Thru_Date]
    )
    SELECT [Payment_Year] = [a1].[Payment_Year],
           [From_Date] = [a1].[From_Date],
           [Thru_Date] = [a1].[Thru_Date],
           [Lagged_From_Date] = [a1].[Lagged_From_Date],
           [Lagged_Thru_Date] = [a1].[Lagged_Thru_Date]
    FROM [rev].[tbl_Summary_RskAdj_RefreshPY] [a1];

    SET @Startdate =
    (
        SELECT MIN(Lagged_From_Date) FROM [#Refresh_PY]
    );
    SET @Enddate =
    (
        SELECT MAX(Thru_Date) FROM [#Refresh_PY]
    );


    IF @Debug = 1
    BEGIN
        EXEC [dbo].[PerfLogMonitor] '003',
                                    @ProcessNameIn,
                                    @ET,
                                    @MasterET,
                                    @ET OUT,
                                    0,
                                    0;
    END;

    -- RE - 6243 - Start 

    TRUNCATE TABLE [rev].[tbl_Summary_RskAdj_EDS_Source];

    -- RE - 6243 - End

    SET @RskAdj_SourceSQL
        = 'INSERT INTO [rev].[tbl_Summary_RskAdj_EDS_Source]
		(
			[MAO004ResponseID] 
		   , [stgMAO004ResponseID] 
		   , [ContractID]
		   , [HICN] 
		   , [SentEncounterICN]
		   , [ReplacementEncounterSwitch] 
		   , [SentICNEncounterID] 
		   , [OriginalEncounterICN] 
		   , [OriginalICNEncounterID] 
		   , [PlanSubmissionDate]
		   , [ServiceStartDate]
		   , [ServiceEndDate]
		   , [ClaimType]
           , [FileImportID]
		   , [LoadID] 
		   , [SrcLoadDate] 
		   , [SentEncounterRiskAdjustableFlag]
		   , [RiskAdjustableReasonCodes]
		   , [OriginalEncounterRiskAdjustableFlag]
		   , [MAO004ResponseDiagnosisCodeID]
		   , [DiagnosisCode]
		   , [DiagnosisICD] 
		   , [DiagnosisFlag] 
		   , [IsDelete] 
		   , [ClaimID] 
		   , [EntityDiscriminator] 
		   , [BaseClaimID]
		   , [SecondaryClaimID] 
		   , [ClaimIndicator]
		   , [EncounterRiskAdjustable]
		   , [RecordID] 
		   , [SystemSource] 
		   , [VendorID] 
		   , [MedicalRecordImageID]
		   , [SubProjectMedicalRecordID]
		   , [SubProjectID]
		   , [SubProjectName] 
		   , [SupplementalID] 
		   , [DerivedPatientControlNumber]
		   , [Loaddatetime]
		)
		SELECT 
			[MAO004ResponseID] = m.MAO004ResponseID
		 , [stgMAO004ResponseID] =  m.stgMAO004ResponseID
		 , [ContractID] = m.ContractID
		 , [HICN] = m.HICN
		 , [SentEncounterICN] =  m.SentEncounterICN
		 , [ReplacementEncounterSwitch] =  m.ReplacementEncounterSwitch
		 , [SentICNEncounterID]  = m.SentICNEncounterID
		 , [OriginalEncounterICN] = m.OriginalEncounterICN
		 , [OriginalICNEncounterID] = m.OriginalICNEncounterID
		 , [PlanSubmissionDate] =m.PlanSubmissionDate
		 , [ServiceStartDate] =m.ServiceStartDate
		 , [ServiceEndDate] = m.ServiceEndDate
		 , [ClaimType] = m.ClaimType
		 , [FileImportID] = m.FileImportID
		 , [LoadID] = m.LoadID
		 , [SrcLoadDate]  = m.LoadDate
		 , [SentEncounterRiskAdjustableFlag] = m.SentEncounterRiskAdjustableFlag
		 , [RiskAdjustableReasonCodes] = m.RiskAdjustableReasonCodes
		 , [OriginalEncounterRiskAdjustableFlag] = m.OriginalEncounterRiskAdjustableFlag
		 , [MAO004ResponseDiagnosisCodeID] = b.MAO004ResponseDiagnosisCodeID
		 , [DiagnosisCode] = b.DiagnosisCode
		 , [DiagnosisICD] = b.DiagnosisICD
		 , [DiagnosisFlag]  = b.DiagnosisFlag
		 , [IsDelete]  = b.IsDelete
		 , [ClaimID]  = c.ClaimID
		 , [EntityDiscriminator] = c.EntityDiscriminator
		 , [BaseClaimID] = c.BaseClaimID
		 , [SecondaryClaimID]  = c.SecondaryClaimID
		 , [ClaimIndicator] = c.ClaimIndicator
		 , [EncounterRiskAdjustable] = c.EncounterRiskAdjustable
		 , [RecordID]= s.RecordID
		 , [SystemSource]  = s.SystemSource
		 , [VendorID]  = s.VendorID
		 , [MedicalRecordImageID] = s.MedicalRecordImageID 
		 , [SubProjectMedicalRecordID] = s.SubProjectMedicalRecordID
		 , [SubProjectID] = s.SubProjectID 
		 , [SubProjectName] = s.SubProjectName
		 , [SupplementalID] = s.SupplementalID
		 , [DerivedPatientControlNumber] =	CASE	when c.EntityDiscriminator = ''EU'' 
													THEN ISNULL(c.SecondaryClaimId,c.ClaimID)
												else Cast(IsNull(s.VendorID,'''') as nchar(10))
													+ ''_'' + Cast(IsNull(s.RecordID,'''') as nchar(10))
													+ Case when s.SubProjectID is not NULL Then ''_'' + Cast(IsNull(s.SubProjectID,'''') as nchar(10)) Else '''' END 

										End 
		 , Getdate()
		from ' + @Clnt_DB + '.dbo.MAO004Response m 
		    join ' + +@Clnt_DB
          + '.dbo.MAO004ResponseDiagnosisCode b
				  on m.MAO004ResponseID = b.MAO004ResponseID
			join ' + @Clnt_DB + '.dbo.Encounters c
				  on m.SentICNEncounterID = c.ID
			join ' + @Clnt_DB
          + '.dbo.EncounterDiagnosis ed
				  on c.ID = ed.EncounterID
				  and b.DiagnosisCode = ed.Diagnosis
			Left join ' + @Clnt_DB
          + '.sup.Supplemental s 
				  on ed.SupplementalID=s.SupplementalID
            where m.ServiceEndDate between CAST(''' + CONVERT(NVARCHAR(24), @Startdate, 101)
          + ''' AS DATE) AND CAST(''' + CONVERT(NVARCHAR(24), @Enddate, 101) + ''' AS DATE)';



    EXEC (@RskAdj_SourceSQL);

    SET @RowCount = @@rowcount;

    IF @Debug = 1
    BEGIN
        EXEC [dbo].[PerfLogMonitor] '004',
                                    @ProcessNameIn,
                                    @ET,
                                    @MasterET,
                                    @ET OUT,
                                    0,
                                    0;
    END;
    /*As Part of */
    /*[[tbl_Summary_RskAdj_EDS_Source]*/
    UPDATE a
    SET a.HICN = ISNULL([althcn].[FINALHICN], [a].[HICN])
    FROM [rev].[tbl_Summary_RskAdj_EDS_Source] a
        JOIN [#Refresh_PY] [py]
            ON YEAR([a].[ServiceEndDate]) + 1 = [py].[Payment_Year]
        JOIN [$(HRPInternalReportsDB)].dbo.rollupplan r
            ON r.planID = a.ContractID
        LEFT JOIN [rev].[tbl_Summary_RskAdj_AltHICN] [althcn]
            ON r.PlanIdentifier = [althcn].[PlanID]
               AND [a].[HICN] = [althcn].[HICN];


    IF (OBJECT_ID('tempdb.dbo.[#Refresh_PY]') IS NOT NULL)
    BEGIN
        DROP TABLE [#Refresh_PY];
    END;

END;
