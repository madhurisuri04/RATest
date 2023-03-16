Create PROCEDURE [rev].[LoadSummaryPartDRskAdjEDSPreliminary]
    (
        @FullRefresh BIT = 0 ,
        @YearRefresh INT = NULL ,
        @LoadDateTime DATETIME = NULL ,
        @RowCount INT OUT ,
        @Debug BIT = 0
    )
AS

    /**********************************************************************************************************************************/
    /* Name			:	rev.LoadSummaryPartDRskAdjEDSPreliminary																	  */
    /* Type 			:	Stored Procedure																						  */
    /* Author       	:	David Waddell																							  */
    /* Date			:	2017-10-27																									  */
    /* Version			:																											  */
    /* Description		: The Part D Summary EDS Preliminary stored procedure will gather EDS return information (diagnosis           */
    /*                     encounters) for the entire client. This data will then be sorted for membership eligibility, and the 	  */
    /*					diagnoses will have Part D HCCs mapped to them. The final step of this process will insert the data into a 	  */
    /*					permanent table output.																						  */
    /*																																  */
    /* Version History :																											  */
    /* =================================================================================================							  */
    /* Author			Date		Version#    TFS Ticket#		Description															  */
    /* -----------------	----------  --------    -----------		------------													  */
    /* D. Waddell		2017-10-30	1.0			67731			Initial																  */
    /* Anand			2019-10-28	2.0			77146			Removed temp for Source and add EDS Source table.					  */																				  
	/* D.Waddell		10/31/2019	2.1		77159/RE-6981	    Set Transaction Isolation Level Read to UNCOMMITTED                   */
	/* Madhuri Suri 	3/29/2020	3.0  	   78036       	    EDS MOR Isuue for correctng the PlanID/ContractID join      
	/*Madhuri Suri      3/17/2021   3.1        80979             Join correction for Plan and Contract ID  */                         */                                                                                                                            
    /**********************************************************************************************************************************/

    SET STATISTICS IO OFF;
    SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

    /*****************************************************************/
    /* Initialize value of local variables                           */
    /*****************************************************************/

    DECLARE @Min_Lagged_From_Date DATETIME = NULL;
    DECLARE @Max_PY_MmrHicnList INT = NULL;
    DECLARE @PY_FutureYear INT = NULL;
    DECLARE @Curr_DB VARCHAR(128) = NULL;
    DECLARE @Clnt_DB VARCHAR(128) = NULL;
    DECLARE @RskAdj_SourceSQL VARCHAR(MAX);
    DECLARE @Summary_RskAdj_EDS_SQL VARCHAR(MAX);
    DECLARE @Today DATETIME = GETDATE();
    DECLARE @ErrorMessage VARCHAR(500);
    DECLARE @ErrorSeverity INT;
    DECLARE @ErrorState INT;



    IF @Debug = 1
        BEGIN
            SET STATISTICS IO ON
            DECLARE @ET DATETIME
            DECLARE @MasterET DATETIME
            DECLARE @ProcessNameIn VARCHAR(128)
            SET @ET = GETDATE()
            SET @MasterET = @ET
            SET @ProcessNameIn = OBJECT_NAME(@@PROCID)
            EXEC [dbo].[PerfLogMonitor] @Section = '000' ,
                                        @ProcessName = @ProcessNameIn ,
                                        @ET = @ET ,
                                        @MasterET = @MasterET ,
                                        @ET_Out = @ET OUT ,
                                        @TableOutput = 0 ,
                                        @End = 0
        END

    SET @LoadDateTime = ISNULL(@LoadDateTime, GETDATE())


    IF @Debug = 1
        BEGIN
            EXEC [dbo].[PerfLogMonitor] '001' ,
                                        @ProcessNameIn ,
                                        @ET ,
                                        @MasterET ,
                                        @ET OUT ,
                                        0 ,
                                        0
        END

    IF ( OBJECT_ID('tempdb.dbo.[#Refresh_PY]') IS NOT NULL )
        BEGIN
            DROP TABLE [#Refresh_PY]
        END

    IF @Debug = 1
        BEGIN
            EXEC [dbo].[PerfLogMonitor] '001.1' ,
                                        @ProcessNameIn ,
                                        @ET ,
                                        @MasterET ,
                                        @ET OUT ,
                                        0 ,
                                        0
        END

    /* B Get Refresh PY data */

    CREATE TABLE [#Refresh_PY]
        (
            [Id] INT IDENTITY(1, 1) PRIMARY KEY ,
            [Payment_Year] INT NOT NULL ,
            [From_Date] SMALLDATETIME NULL ,
            [Thru_Date] SMALLDATETIME NULL ,
            [Lagged_From_Date] SMALLDATETIME NULL ,
            [Lagged_Thru_Date] SMALLDATETIME NULL
        )

    IF @Debug = 1
        BEGIN
            EXEC [dbo].[PerfLogMonitor] '002' ,
                                        @ProcessNameIn ,
                                        @ET ,
                                        @MasterET ,
                                        @ET OUT ,
                                        0 ,
                                        0
        END


    /* Insert into Refresh Payment Year Temp Table*/

    INSERT INTO [#Refresh_PY] (   [Payment_Year] ,
                                  [From_Date] ,
                                  [Thru_Date] ,
                                  [Lagged_From_Date] ,
                                  [Lagged_Thru_Date]
                              )
                SELECT [Payment_Year] = [a1].[Payment_Year] ,
                       [From_Date] = [a1].[From_Date] ,
                       [Thru_Date] = [a1].[Thru_Date] ,
                       [Lagged_From_Date] = [a1].[Lagged_From_Date] ,
                       [Lagged_Thru_Date] = [a1].[Lagged_Thru_Date]
                FROM   [rev].[tbl_Summary_RskAdj_RefreshPY] [a1]

    /* E Get Refresh PY data */

    IF @Debug = 1
        BEGIN
            EXEC [dbo].[PerfLogMonitor] '003' ,
                                        @ProcessNameIn ,
                                        @ET ,
                                        @MasterET ,
                                        @ET OUT ,
                                        0 ,
                                        0
        END

    IF ( OBJECT_ID('tempdb.dbo.[#Vw_LkRiskModelsDiagHCC]') IS NOT NULL )
        BEGIN
            DROP TABLE [#Vw_LkRiskModelsDiagHCC]
        END

    IF @Debug = 1
        BEGIN
            EXEC [dbo].[PerfLogMonitor] '003.1' ,
                                        @ProcessNameIn ,
                                        @ET ,
                                        @MasterET ,
                                        @ET OUT ,
                                        0 ,
                                        0
        END

    SET @Curr_DB = ( SELECT [Current Database] = DB_NAME())

    SET @Clnt_DB = SUBSTRING(@Curr_DB, 0, CHARINDEX('_Report', @Curr_DB))

    IF @Debug = 1
        BEGIN
            EXEC [dbo].[PerfLogMonitor] '004' ,
                                        @ProcessNameIn ,
                                        @ET ,
                                        @MasterET ,
                                        @ET OUT ,
                                        0 ,
                                        0
        END

    /* Create #Vw_LkRiskModelsDiagHCC table */
    CREATE TABLE [#Vw_LkRiskModelsDiagHCC]
        (
            [ICDCode] [NVARCHAR](255) NULL ,
            [HCC_Label] [NVARCHAR](255) NULL ,
            [Payment_Year] [FLOAT] NULL ,
            [Factor_Type] [VARCHAR](3) NOT NULL ,
            [ICDClassification] [TINYINT] NULL ,
            [StartDate] [DATETIME] NOT NULL ,
            [EndDate] [DATETIME] NOT NULL
        )

    IF @Debug = 1
        BEGIN
            EXEC [dbo].[PerfLogMonitor] '005' ,
                                        @ProcessNameIn ,
                                        @ET ,
                                        @MasterET ,
                                        @ET OUT ,
                                        0 ,
                                        0
        END

    /* Insert into  #Vw_LkRiskModelsDiagHCC table */

    INSERT INTO [#Vw_LkRiskModelsDiagHCC] (   [ICDCode] ,
                                              [HCC_Label] ,
                                              [Payment_Year] ,
                                              [Factor_Type] ,
                                              [ICDClassification] ,
                                              [StartDate] ,
                                              [EndDate]
                                          )
                SELECT [ICDCode] = [icd].[ICDCode] ,
                       [HCC_Label] = [icd].[HCCLabel] ,
                       [Payment_Year] = [icd].[PaymentYear] ,
                       [Factor_Type] = [icd].[FactorType] ,
                       [ICDClassification] = [icd].[ICDClassification] ,
                       [StartDate] = [ef].[StartDate] ,
                       [EndDate] = [ef].[EndDate]
                FROM   [$(HRPReporting)].[dbo].[Vw_LkRiskModelsDiagHCC] [icd]
                       JOIN [$(HRPReporting)].[dbo].[ICDEffectiveDates] [ef] ON [icd].[ICDClassification] = [ef].[ICDClassification]


    IF @Debug = 1
        BEGIN
            EXEC [dbo].[PerfLogMonitor] '006' ,
                                        @ProcessNameIn ,
                                        @ET ,
                                        @MasterET ,
                                        @ET OUT ,
                                        0 ,
                                        0
        END
 
 
    SET @Min_Lagged_From_Date = (   SELECT MIN([Lagged_From_Date])
                                    FROM   [#Refresh_PY]
                                )

    IF @Debug = 1
        BEGIN
            EXEC [dbo].[PerfLogMonitor] '006.1' ,
                                        @ProcessNameIn ,
                                        @ET ,
                                        @MasterET ,
                                        @ET OUT ,
                                        0 ,
                                        0
        END

 
    IF ( OBJECT_ID('tempdb.dbo.[#tbl_0010_MmrHicnList]') IS NOT NULL )
        BEGIN
            DROP TABLE [#tbl_0010_MmrHicnList]
        END

    IF @Debug = 1
        BEGIN
            EXEC [dbo].[PerfLogMonitor] '007' ,
                                        @ProcessNameIn ,
                                        @ET ,
                                        @MasterET ,
                                        @ET OUT ,
                                        0 ,
                                        0
        END

    CREATE TABLE [#tbl_0010_MmrHicnList]
        (
            [PlanIdentifier] [INT] NULL ,
            [PaymentYear] [INT] NULL ,
            [HICN] [VARCHAR](12) NULL ,
            [PartDRAFTProjected] [VARCHAR](2) NULL
        )

    IF @Debug = 1
        BEGIN
            EXEC [dbo].[PerfLogMonitor] '008' ,
                                        @ProcessNameIn ,
                                        @ET ,
                                        @MasterET ,
                                        @ET OUT ,
                                        0 ,
                                        0
        END

    INSERT INTO [#tbl_0010_MmrHicnList] (   [PlanIdentifier] ,
                                            [PaymentYear] ,
                                            [HICN] ,
                                            [PartDRAFTProjected]
                                        )
                SELECT DISTINCT [PlanIdentifier] = [mmr].[PlanID] ,
                       [PaymentYear] = [mmr].[PaymentYear] ,
                       [HICN] = [mmr].[HICN] ,
                       [PartDRAFTProjected] = [mmr].[PartDRAFTProjected]
                FROM   [rev].[tbl_Summary_RskAdj_MMR] [mmr] WITH ( NOLOCK )
                       JOIN [#Refresh_PY] [py] ON [mmr].[PaymentYear] = [py].[Payment_Year]

    IF @Debug = 1
        BEGIN
            EXEC [dbo].[PerfLogMonitor] '008.1' ,
                                        @ProcessNameIn ,
                                        @ET ,
                                        @MasterET ,
                                        @ET OUT ,
                                        0 ,
                                        0
        END

    --1/31/2017 TFS61874     HasanMF
    SET @PY_FutureYear = (   SELECT MAX([Payment_Year])
                             FROM   [#Refresh_PY]
                         )
    SET @Max_PY_MmrHicnList = (   SELECT MAX([PaymentYear])
                                  FROM   [#tbl_0010_MmrHicnList]
                              )

    IF @Debug = 1
        BEGIN
            EXEC [dbo].[PerfLogMonitor] '009' ,
                                        @ProcessNameIn ,
                                        @ET ,
                                        @MasterET ,
                                        @ET OUT ,
                                        0 ,
                                        0
        END

    IF @PY_FutureYear > YEAR(GETDATE())
        BEGIN
            IF @Debug = 1
                BEGIN
                    EXEC [dbo].[PerfLogMonitor] '009.1' ,
                                                @ProcessNameIn ,
                                                @ET ,
                                                @MasterET ,
                                                @ET OUT ,
                                                0 ,
                                                0
                END

            INSERT INTO [#tbl_0010_MmrHicnList] (   [PlanIdentifier] ,
                                                    [PaymentYear] ,
                                                    [HICN] ,
                                                    [PartDRAFTProjected]
                                                )
                        SELECT DISTINCT [PlanIdentifier] ,
                               [PaymentYear] + 1 ,
                               [HICN] ,
                               [PartDRAFTProjected]
                        FROM   [#tbl_0010_MmrHicnList]
                        WHERE  [PaymentYear] = @Max_PY_MmrHicnList

            IF @Debug = 1
                BEGIN
                    EXEC [dbo].[PerfLogMonitor] '010' ,
                                                @ProcessNameIn ,
                                                @ET ,
                                                @MasterET ,
                                                @ET OUT ,
                                                0 ,
                                                0
                END

        END --1/31/2017 HasanMF
 

    IF @Debug = 1
        BEGIN
            EXEC [dbo].[PerfLogMonitor] '011' ,
                                        @ProcessNameIn ,
                                        @ET ,
                                        @MasterET ,
                                        @ET OUT ,
                                        0 ,
                                        0
        END
 
	if (object_id('[Etl].[IntermediateEDSAltHicnPartD]') is not null)
	begin
	    Truncate table [Etl].[IntermediateEDSAltHicnPartD]
	end
 

    INSERT INTO [Etl].[IntermediateEDSAltHicnPartD]
							  (   
								  [PlanIdentifier] ,
                                  [PaymentYear] ,
                                  [ModelYear] ,
                                  [PartDRAFTProjected]	,
								  [MAO004ResponseID] ,
                                  [stgMAO004ResponseID] ,
                                  [ContractID] ,
                                  [HICN] ,
                                  [SentEncounterICN] ,
                                  [ReplacementEncounterSwitch] ,
                                  [SentICNEncounterID] ,
                                  [OriginalEncounterICN] ,
                                  [OriginalICNEncounterID] ,
                                  [PlanSubmissionDate] ,
                                  [ServiceStartDate] ,
                                  [ServiceEndDate] ,
                                  [ClaimType] ,
                                  [FileImportID] ,
                                  [LoadID] ,
                                  [LoadDate] ,
                                  [SentEncounterRiskAdjustableFlag] ,
                                  [RiskAdjustableReasonCodes] ,
                                  [OriginalEncounterRiskAdjustableFlag] ,
                                  [MAO004ResponseDiagnosisCodeID] ,
                                  [DiagnosisCode] ,
                                  [DiagnosisICD] ,
                                  [DiagnosisFlag] ,
                                  [IsDelete] ,
                                  [ClaimID] ,
                                  [EntityDiscriminator] ,
                                  [BaseClaimID] ,
                                  [SecondaryClaimID] ,
                                  [ClaimIndicator] ,
                                  [EncounterRiskAdjustable] ,
                                  [RecordID] ,
                                  [SystemSource] ,
                                  [VendorID] ,
                                  [MedicalRecordImageID] ,
                                  [SubProjectMedicalRecordID] ,
                                  [SubProjectID] ,
                                  [SubProjectName] ,
                                  [SupplementalID] ,
                                  [DerivedPatientControlNumber] ,
                                  [YearServiceEndDate]
                              )
                SELECT 
					   [PlanIdentifier]	= [b].[PlanIdentifier],
                       [PaymentYear]	=[b].[PaymentYear],	
                       [ModelYear] =[b].[PaymentYear],
                       [PartDRAFTProjected]	= [b].[PartDRAFTProjected],
					   [MAO004ResponseID] = [a].[MAO004ResponseID] ,
                       [stgMAO004ResponseID] = [a].[stgMAO004ResponseID] ,
                       [ContractID] =  [a].[ContractID] ,
                       [HICN] = [a].[HICN] ,
                       [SentEncounterICN] = [a].[SentEncounterICN] ,
                       [ReplacementEncounterSwitch] = [a].[ReplacementEncounterSwitch] ,
                       [SentICNEncounterID] = [a].[SentICNEncounterID] ,
                       [OriginalEncounterICN] = [a].[OriginalEncounterICN] ,
                       [OriginalICNEncounterID] = [a].[OriginalICNEncounterID] ,
                       [PlanSubmissionDate] = [a].[PlanSubmissionDate] ,
                       [ServiceStartDate] = [a].[ServiceStartDate] ,
                       [ServiceEndDate] = [a].[ServiceEndDate] ,
                       [ClaimType] = [a].[ClaimType] ,
                       [FileImportID] = [a].[FileImportID] ,
                       [LoadID] = [a].[LoadID] ,
                       [LoadDate] = [a].[SrcLoadDate] ,
                       [SentEncounterRiskAdjustableFlag] = [a].[SentEncounterRiskAdjustableFlag] ,
                       [RiskAdjustableReasonCodes] = [a].[RiskAdjustableReasonCodes] ,
                       [OriginalEncounterRiskAdjustableFlag] = [a].[OriginalEncounterRiskAdjustableFlag] ,
                       [MAO004ResponseDiagnosisCodeID] = [a].[MAO004ResponseDiagnosisCodeID] ,
                       [DiagnosisCode] = [a].[DiagnosisCode] ,
                       [DiagnosisICD] = [a].[DiagnosisICD] ,
                       [DiagnosisFlag] = [a].[DiagnosisFlag] ,
                       [IsDelete] = [a].[IsDelete] ,
                       [ClaimID] = [a].[ClaimID] ,
                       [EntityDiscriminator] = [a].[EntityDiscriminator] ,
                       [BaseClaimID] = [a].[BaseClaimID] ,
                       [SecondaryClaimID] = [a].[SecondaryClaimID] ,
                       [ClaimIndicator] = [a].[ClaimIndicator] ,
                       [EncounterRiskAdjustable] = [a].[EncounterRiskAdjustable] ,
                       [RecordID] = [a].[RecordID] ,
                       [SystemSource] = [a].[SystemSource] ,
                       [VendorID] = [a].[VendorID] ,
                       [MedicalRecordImageID] = [a].[MedicalRecordImageID] ,
                       [SubProjectMedicalRecordID] = [a].[SubProjectMedicalRecordID] ,
                       [SubProjectID] = [a].[SubProjectID] ,
                       [SubProjectName] = [a].[SubProjectName] ,
                       [SupplementalID] = [a].[SupplementalID] ,
                       [DerivedPatientControlNumber] = [a].[DerivedPatientControlNumber] ,
                       [YearServiceEndDate] = YEAR([a].[ServiceEndDate]) + 1
                FROM   [rev].[tbl_Summary_RskAdj_EDS_Source] [a]

				Join [#tbl_0010_MmrHicnList] [B] on [B].[HICN]=[a].[HICN]
									and year([a].[ServiceEndDate]) + 1=[b].[PaymentYear]
				--JOIN [$(HRPInternalReportsDB)].dbo.RollupPlan r ON r.PlanIdentifier = b.PlanIdentifier
	   --                               AND r.PlanID = a.ContractID --RRI 799
                WHERE  [a].[HICN] IS NOT NULL
                       AND [a].[ServiceEndDate] >= @Min_Lagged_From_Date 


    IF @Debug = 1
        BEGIN
            EXEC [dbo].[PerfLogMonitor] '012' ,
                                        @ProcessNameIn ,
                                        @ET ,
                                        @MasterET ,
                                        @ET OUT ,
                                        0 ,
                                        0
        END



    IF @Debug = 1
        BEGIN
            EXEC [dbo].[PerfLogMonitor] '013' ,
                                        @ProcessNameIn ,
                                        @ET ,
                                        @MasterET ,
                                        @ET OUT ,
                                        0 ,
                                        0
        END



    IF @Debug = 1
        BEGIN
            SET STATISTICS IO OFF
        END




    IF @Debug = 1
        BEGIN
            SET STATISTICS IO ON
        END

    IF @Debug = 1
        BEGIN
            EXEC [dbo].[PerfLogMonitor] '014' ,
                                        @ProcessNameIn ,
                                        @ET ,
                                        @MasterET ,
                                        @ET OUT ,
                                        0 ,
                                        0
        END

 
    IF @Debug = 1
        BEGIN
            EXEC [dbo].[PerfLogMonitor] '015' ,
                                        @ProcessNameIn ,
                                        @ET ,
                                        @MasterET ,
                                        @ET OUT ,
                                        0 ,
                                        0
        END




    /* Truncate the ETL Summary PartDRskAdjMORD Table */

    IF  (   SELECT COUNT(1)
            FROM   [etl].[SummaryPartDRskAdjEDSPreliminary]
        ) > 0
        BEGIN
            TRUNCATE TABLE [etl].[SummaryPartDRskAdjEDSPreliminary]
        END




    IF @Debug = 1
        BEGIN
            EXEC [dbo].[PerfLogMonitor] '016' ,
                                        @ProcessNameIn ,
                                        @ET ,
                                        @MasterET ,
                                        @ET OUT ,
                                        0 ,
                                        0
        END



    /* Insert data into etl.SummaryPartDRskAdjEDSPreliminary table                       */


    INSERT INTO [etl].[SummaryPartDRskAdjEDSPreliminary] (   [PlanIdentifier] ,
                                                             [PaymentYear] ,
                                                             [ModelYear] ,
                                                             [HICN] ,
                                                             [PartDRAFTProjected] ,
                                                             [MAO004ResponseID] ,
                                                             [StgMAO004ResponseID] ,
                                                             [ContractID] ,
                                                             [SentEncounterICN] ,
                                                             [ReplacementEncounterSwitch] ,
                                                             [SentICNEncounterID] ,
                                                             [OriginalEncounterICN] ,
                                                             [OriginalICNEncounterID] ,
                                                             [PlanSubmissionDate] ,
                                                             [ServiceStartDate] ,
                                                             [ServiceEndDate] ,
                                                             [ClaimType] ,
                                                             [FileImportID] ,
                                                             [SourceLoadID] ,
                                                             [SourceLoadDate] ,
                                                             [SentEncounterRiskAdjustableFlag] ,
                                                             [RiskAdjustableReasonCodes] ,
                                                             [OriginalEncounterRiskAdjustableFlag] ,
                                                             [MAO004ResponseDiagnosisCodeID] ,
                                                             [DiagnosisCode] ,
                                                             [DiagnosisICD] ,
                                                             [DiagnosisFlag] ,
                                                             [IsDelete] ,
                                                             [ClaimID] ,
                                                             [EntityDiscriminator] ,
                                                             [BaseClaimID] ,
                                                             [SecondaryClaimID] ,
                                                             [ClaimIndicator] ,
                                                             [RecordID] ,
                                                             [SystemSource] ,
                                                             [VendorID] ,
                                                             [MedicalRecordImageID] ,
                                                             [SubProjectMedicalRecordID] ,
                                                             [SubProjectID] ,
                                                             [SubProjectName] ,
                                                             [SupplementalID] ,
                                                             [DerivedPatientControlNumber] ,
                                                             [VoidIndicator] ,
                                                             [VoidedByMAO004ResponseDiagnosisCodeID] ,
                                                             [RiskAdjustable] ,
                                                             [Deleted] ,
                                                             [RxHCCLabel] ,
                                                             [RxHCCNumber] ,
                                                             [Matched] ,
                                                             [UserID] ,
                                                             [LoadDate]
                                                         )
                SELECT distinct [PlanIdentifier] = [a].[PlanIdentifier] ,
                       [PaymentYear] = [a].[PaymentYear] ,
                       [ModelYear] = [a].[PaymentYear] ,
                       [HICN] = [a].[HICN] ,
                       [PartDRAFTProjected] = [a].[PartDRAFTProjected] ,
                       [MAO004ResponseID] = [a].[MAO004ResponseID] ,
                       [stgMAO004ResponseID] = [a].[stgMAO004ResponseID] ,
                       [ContractID] = [a].[ContractID] ,
                       [SentEncounterICN] = [a].[SentEncounterICN] ,
                       [ReplacementEncounterSwitch] = [a].[ReplacementEncounterSwitch] ,
                       [SentICNEncounterID] = [a].[SentICNEncounterID] ,
                       [OriginalEncounterICN] = CASE WHEN [a].[OriginalEncounterICN] = 0 THEN
                                                         NULL
                                                     ELSE
                                                         [a].[OriginalEncounterICN]
                                                END , --TFS 65132   DW 6/1/2017
                       [OriginalICNEncounterID] = [a].[OriginalICNEncounterID] ,
                       [PlanSubmissionDate] = [a].[PlanSubmissionDate] ,
                       [ServiceStartDate] = [a].[ServiceStartDate] ,
                       [ServiceEndDate] = [a].[ServiceEndDate] ,
                       [ClaimType] = [a].[ClaimType] ,
                       [FileImportID] = [a].[FileImportID] ,
                       [SourceLoadID] = [a].[LoadID] ,
                       [SourceLoadDate] = [a].[LoadDate] ,
                       [SentEncounterRiskAdjustableFlag] = [a].[SentEncounterRiskAdjustableFlag] ,
                       [RiskAdjustableReasonCodes] = [a].[RiskAdjustableReasonCodes] ,
                       [OriginalEncounterRiskAdjustableFlag] = [a].[OriginalEncounterRiskAdjustableFlag] ,
                       [MAO004ResponseDiagnosisCodeID] = [a].[MAO004ResponseDiagnosisCodeID] ,
                       [DiagnosisCode] = [a].[DiagnosisCode] ,
                       [DiagnosisICD] = [a].[DiagnosisICD] ,
                       [DiagnosisFlag] = [a].[DiagnosisFlag] ,
                       [IsDelete] = [a].[IsDelete] ,
                       [ClaimID] = [a].[ClaimID] ,
                       [EntityDiscriminator] = [a].[EntityDiscriminator] ,
                       [BaseClaimID] = [a].[BaseClaimID] ,
                       [SecondaryClaimID] = [a].[SecondaryClaimID] ,
                       [ClaimIndicator] = [a].[ClaimIndicator] ,
                       [RecordID] = [a].[RecordID] ,
                       [SystemSource] = [a].[SystemSource] ,
                       [VendorID] = [a].[VendorID] ,
                       [MedicalRecordImageID] = [a].[MedicalRecordImageID] ,
                       [SubProjectMedicalRecordID] = [a].[SubProjectMedicalRecordID] ,
                       [SubProjectID] = [a].[SubProjectID] ,
                       [SubProjectName] = [a].[SubProjectName] ,
                       [SupplementalID] = [a].[SupplementalID] ,
                       [DerivedPatientControlNumber] = [a].[DerivedPatientControlNumber] ,
                       [VoidIndicator] = 0 ,
                       [VoidedByMAO004ResponseDiagnosisCodeID] = 0 ,
                       [RiskAdjustable] = CASE WHEN [a].[SentEncounterRiskAdjustableFlag] = 'A' THEN
                                                   1
                                               WHEN [a].[SentEncounterRiskAdjustableFlag] = 'D' THEN
                                                   0
                                               ELSE 0
                                          END ,       --TFS 65132   DW 6/1/2017
                       [Deleted] = [a].[IsDelete] ,
                       [RxHCCLabel] = [hcc].[HCC_Label] ,
                       [RxHCCNumber] = CAST(LTRIM(REVERSE(LEFT(REVERSE([hcc].[HCC_Label]), PATINDEX(
                                                                                                       '%[A-Z]%' ,
                                                                                                       REVERSE([hcc].[HCC_Label])
                                                                                                   )
                                                                                           - 1)
                                                         )
                                                 ) AS INT) ,
                       [MATCHED] = CASE WHEN [a].[ReplacementEncounterSwitch] > 3
                                             AND [a].[OriginalICNEncounterID] IS NOT NULL THEN
                                            'Y'
                                        WHEN [a].[ReplacementEncounterSwitch] > 3
                                             AND [a].[OriginalICNEncounterID] IS NULL THEN
                                            'N'
                                        ELSE NULL
                                   END ,
                       [UserID] = CURRENT_USER ,
                       [LoadDate] = @LoadDateTime
                FROM   [Etl].[IntermediateEDSAltHicnPartD] [a]
                       JOIN [#Vw_LkRiskModelsDiagHCC] [hcc] ON [a].[ModelYear] = [hcc].[Payment_Year]
                                                               AND [a].[ServiceEndDate]
                                                               BETWEEN [hcc].[StartDate] AND [hcc].[EndDate]
                                                               AND [a].[PartDRAFTProjected] = [hcc].[Factor_Type]
                                                               AND [a].[DiagnosisCode] = [hcc].[ICDCode]

    SET @RowCount = @@ROWCOUNT

    IF @Debug = 1
        BEGIN
            EXEC [dbo].[PerfLogMonitor] '017' ,
                                        @ProcessNameIn ,
                                        @ET ,
                                        @MasterET ,
                                        @ET OUT ,
                                        0 ,
                                        0
        END



    /* Begin  Update Void Indicator Section */

    UPDATE [a]
    SET    [a].[VoidIndicator] = 1 ,
           [a].[VoidedByMAO004ResponseDiagnosisCodeID] = [b].[MAO004ResponseDiagnosisCodeID] ,
           [a].[RiskAdjustable] = 0
    FROM   [etl].[SummaryPartDRskAdjEDSPreliminary] [a]
           JOIN [etl].[SummaryPartDRskAdjEDSPreliminary] [b] ON [a].[SentEncounterICN] = [b].[OriginalEncounterICN]
    WHERE  [b].[ReplacementEncounterSwitch] NOT IN ( 1, 4, 7 )

    IF @Debug = 1
        BEGIN
            EXEC [dbo].[PerfLogMonitor] '018' ,
                                        @ProcessNameIn ,
                                        @ET ,
                                        @MasterET ,
                                        @ET OUT ,
                                        0 ,
                                        0
        END


    --Void Diagnosis cluster when there is a corresponding Chart Review delete encounter

    UPDATE [a]
    SET    [a].[VoidIndicator] = 1 ,
           [a].[VoidedByMAO004ResponseDiagnosisCodeID] = [b].[MAO004ResponseDiagnosisCodeID] ,
           [a].[RiskAdjustable] = 0
    FROM   [etl].[SummaryPartDRskAdjEDSPreliminary] [a]
           JOIN [etl].[SummaryPartDRskAdjEDSPreliminary] [b] ON [a].[SentEncounterICN] = [b].[OriginalEncounterICN]
                                                                AND [a].[DiagnosisCode] = [b].[DiagnosisCode]
    WHERE  [b].[ReplacementEncounterSwitch] IN ( 7, 8, 9 )




    /* End  Update Void Indicator Section */


    IF @Debug = 1
        BEGIN
            EXEC [dbo].[PerfLogMonitor] '019' ,
                                        @ProcessNameIn ,
                                        @ET ,
                                        @MasterET ,
                                        @ET OUT ,
                                        0 ,
                                        0
        END


    SET @Summary_RskAdj_EDS_SQL = '
		Update a
Set [SystemSource] = [edv].[SystemSource]
from [etl].[SummaryPartDRskAdjEDSPreliminary] a
Join ' + @Clnt_DB + '.[dbo].[EncounterDerivedValues] edv
      on a.[SentICNEncounterID] = edv.[EncounterID]
where a.[SystemSource] is NULL'

    IF @Debug = 1
        BEGIN
            EXEC [dbo].[PerfLogMonitor] '019.1' ,
                                        @ProcessNameIn ,
                                        @ET ,
                                        @MasterET ,
                                        @ET OUT ,
                                        0 ,
                                        0
        END

    EXEC ( @Summary_RskAdj_EDS_SQL )

    IF @Debug = 1
        BEGIN
            EXEC [dbo].[PerfLogMonitor] '020' ,
                                        @ProcessNameIn ,
                                        @ET ,
                                        @MasterET ,
                                        @ET OUT ,
                                        0 ,
                                        1
        END



    /* Switch partitions for each PaymentYear */

    DECLARE @I INT
    DECLARE @ID INT = (   SELECT COUNT(DISTINCT Payment_Year)
                          FROM   [#Refresh_PY]
                      )

    SET @I = 1

    WHILE ( @I <= @ID )
        BEGIN

            DECLARE @PaymentYear SMALLINT = (   SELECT [Payment_Year]
                                                FROM   [#Refresh_PY]
                                                WHERE  [Id] = @I
                                            )

            PRINT @PaymentYear

            BEGIN TRY

                BEGIN TRANSACTION SwitchPartitions;

                TRUNCATE TABLE [out].[SummaryPartDRskAdjEDSPreliminary]

                -- Switch Partition for History SummaryPartDRskAdjMORD 

                ALTER TABLE [hst].[SummaryPartDRskAdjEDSPreliminary] SWITCH PARTITION $Partition.[pfn_SummPY](@PaymentYear)TO [out].[SummaryPartDRskAdjEDSPreliminary] PARTITION $Partition.[pfn_SummPY](@PaymentYear)

                -- Switch Partition for REV SummaryPartDRskAdjMORD 
                ALTER TABLE [rev].[SummaryPartDRskAdjEDSPreliminary] SWITCH PARTITION $Partition.[pfn_SummPY](@PaymentYear)TO [hst].[SummaryPartDRskAdjEDSPreliminary] PARTITION $Partition.[pfn_SummPY](@PaymentYear)

                -- Switch Partition for ETL SummaryPartDRskAdjMORD	
                ALTER TABLE [etl].[SummaryPartDRskAdjEDSPreliminary] SWITCH PARTITION $Partition.[pfn_SummPY](@PaymentYear)TO [rev].[SummaryPartDRskAdjEDSPreliminary] PARTITION $Partition.[pfn_SummPY](@PaymentYear)

                COMMIT TRANSACTION SwitchPartitions;

                PRINT 'Partition Completed For PaymentYear : '
                      + CONVERT(VARCHAR(4), @PaymentYear)

            END TRY
            BEGIN CATCH

                SELECT @ErrorMessage = ERROR_MESSAGE() ,
                       @ErrorSeverity = ERROR_SEVERITY() ,
                       @ErrorState = ERROR_STATE();

                IF (   XACT_STATE() = 1
                       OR XACT_STATE() = -1
                   )
                    BEGIN
                        ROLLBACK TRANSACTION SwitchPartitions;
                    END;

                RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);

                RETURN;

            END CATCH;

            SET @I = @I + 1

        END

    IF @Debug = 1
        BEGIN
            EXEC [dbo].[PerfLogMonitor] '021' ,
                                        @ProcessNameIn ,
                                        @ET ,
                                        @MasterET ,
                                        @ET OUT ,
                                        0 ,
                                        0
        END