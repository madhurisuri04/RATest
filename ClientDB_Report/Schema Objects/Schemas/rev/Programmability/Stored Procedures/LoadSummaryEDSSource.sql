/************************************************************************        
* Name			:	rev.[LoadSummaryEDSSource].proc						*                                                     
* Type 			:	Stored Procedure									*                
* Author       	:	Madhuri Suri     									*
* Date          :	7/1/2021									     	*	
* Ticket        :   
* Version		:        												*
* Description	:	Populates Supplemetal Encounter data from client DBs to 
                                           Client_Report Db	            *

*************************************************************************/   

/*************************************************************************
TICKET       DATE              NAME                DESCRIPTION
RRI 1279     6/1/21           Madhuri Suri       Load Summary EDS Source
RRI 1754     11/1/21          Madhuri Suri       EDS Deletes
RRI 1912     12/16/21         Madhuri Suri       UseforRollup addition
RRI-2344	 6/1/22			  Anand				 Change to view for IH 	
**************************************************************************/   

CREATE PROCEDURE [rev].[LoadSummaryEDSSource]

AS
    BEGIN
        SET NOCOUNT ON

 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

 DECLARE @SourceSQL VARCHAR(MAX)
 DECLARE @Curr_DB VARCHAR(128) = NULL
 DECLARE @ClntRepo_DB VARCHAR(128) = NULL
 DECLARE @ServiceStart datetime 
 DECLARE @ServiceEnd datetime 
 
    
SET @ServiceStart = (SELECT MIN([From_Date]) FROM [rev].[tbl_Summary_RskAdj_RefreshPY] [r1]) 
SET  @ServiceEnd =  (SELECT MAX([THRU_Date]) FROM [rev].[tbl_Summary_RskAdj_RefreshPY] [r1]) 


 SET @Curr_DB =
    (
        SELECT [Current Database] = DB_NAME()
    )

SET @ClntRepo_DB = SUBSTRING(@Curr_DB, 0, CHARINDEX('_Report', @Curr_DB)) + '_ClientRepo';

DECLARE  @DateStart DATETIME = NULL
DECLARE  @DateEnd DATETIME = NULL
SET @DateStart = @ServiceStart
SET @DateEnd = DATEADD(MONTH, 6, @ServiceStart)


IF @Curr_DB = 'AETIH_Report'

Begin 

WHILE (@DateEnd <= @ServiceEnd)

	Begin

    INSERT INTO Rev.tbl_Summary_RskAdj_EDS_Source
	( [MAO004ResponseID]
      ,[stgMAO004ResponseID]
      ,[ContractID]
      ,[HICN]
      ,[SentEncounterICN]
      ,[ReplacementEncounterSwitch]
      ,[SentICNEncounterID]
      ,[OriginalEncounterICN]
      ,[OriginalICNEncounterID]
      ,[PlanSubmissionDate]
      ,[ServiceStartDate]
      ,[ServiceEndDate]
      ,[ClaimType]
      ,[FileImportID]
      ,[SrcLoadDate]
      ,[SentEncounterRiskAdjustableFlag]
      ,[RiskAdjustableReasonCodes]
      ,[OriginalEncounterRiskAdjustableFlag]
      ,[MAO004ResponseDiagnosisCodeID]
      ,[DiagnosisCode]
      ,[DiagnosisICD]
      ,[DiagnosisFlag]
      ,[ClaimID]
      ,[EntityDiscriminator]
      ,[BaseClaimID]
      ,[SecondaryClaimID]
      ,[ClaimIndicator]
      ,[EncounterRiskAdjustable]
      ,[RecordID]
      ,[SystemSource]
      ,[VendorID]
      ,[MedicalRecordImageID]
      ,[SubProjectMedicalRecordID]
      ,[SubProjectID]
      ,[SubProjectName]
      ,[SupplementalID]
      ,[DerivedPatientControlNumber]
      ,[IsDelete]
	  ,[Loaddatetime]
	  ,[LoadID])
	SELECT 
	       [MAO004ResponseID] = MAO004ResponseID
		 , [StgMAO004ResponseID] = MAO004ResponseID
		 , [ContractID] = [ContractID]
		 , [HICN] = [HICN] 
		 , [SentEncounterICN] =  [EncounterICN]
		 , [ReplacementEncounterSwitch] =  [EncounterTypeSwitch]
		 , [SentICNEncounterID]  = NULL
		 , [OriginalEncounterICN] = [ICNofEncounterLinkedTo]
		 , [OriginalICNEncounterID] = NULL
		 , [PlanSubmissionDate] =[EncounterSubmissionDate]
		 , [ServiceStartDate] =[FromDateofService]
		 , [ServiceEndDate] = [ThroughDateofService]
		 , [ClaimType] = [ServiceType]
		 , [FileImportID] = FileImportID
		 , [SrcLoadDate]  = [LastUpdateDatetime]
		 , [SentEncounterRiskAdjustableFlag] = [AllowedDisallowedFlagRiskAdjustment]
		 , [RiskAdjustableReasonCodes] = [AllowedDisallowedFlagRiskReasonCode]
		 , [OriginalEncounterRiskAdjustableFlag] = [AllowedDisallowedStatusofEncounterLinkedTo]
		 , [MAO004ResponseDiagnosisCodeID] = MAO004ResponseDiagnosisCodeID
		 , [DiagnosisCode] = DiagnosisCode
		 , [DiagnosisICD] = NULL
		 , [DiagnosisFlag]  = IsActive
		 , [ClaimID]  = NULL 
		 , [EntityDiscriminator] = NULL 
		 , [BaseClaimID] = NULL 
		 , [SecondaryClaimID]  = NULL 
		 , [ClaimIndicator] = NULL 
		 , [EncounterRiskAdjustable] = 0 
		 , [RecordID]= NULL 
		 , [SystemSource]  = NULL 
		 , [VendorID]  = NULL
		 , [MedicalRecordImageID] =NULL 
		 , [SubProjectMedicalRecordID] = NULL
		 , [SubProjectID] = NULL 
		 , [SubProjectName] = NULL
		 , [SupplementalID] = NULL
		 , [DerivedPatientControlNumber] =  NULL 
		 , [IsDelete] = [IsDelete]   		
		 , [Loaddatetime] = GetDate()
	     , [LoadID] = -1
		FROM [rev].[Vw_RPTEDSMAO004ResponseDiagnosis] m
        WHERE m.[ThroughDateofService] >= CAST(@DateStart AS DATE) 
			 AND m.[ThroughDateofService] < CAST(@DateEnd AS DATE)

EXEC (@SourceSQL)

SET @DateStart = DATEADD(MONTH, 6, @DateStart)
SET @DateEnd = CASE WHEN DATEADD(MONTH, 6, @DateEnd) = DATEADD (Day, 1, @ServiceEnd) THEN @ServiceEnd 
                            ELSE DATEADD(MONTH, 6, @DateEnd) END 

	END

End

Else

Begin 

WHILE (@DateEnd <= @ServiceEnd)

BEGIN 

	SET @SourceSQL =

	'
    INSERT INTO Rev.tbl_Summary_RskAdj_EDS_Source
	( [MAO004ResponseID]
      ,[stgMAO004ResponseID]
      ,[ContractID]
      ,[HICN]
      ,[SentEncounterICN]
      ,[ReplacementEncounterSwitch]
      ,[SentICNEncounterID]
      ,[OriginalEncounterICN]
      ,[OriginalICNEncounterID]
      ,[PlanSubmissionDate]
      ,[ServiceStartDate]
      ,[ServiceEndDate]
      ,[ClaimType]
      ,[FileImportID]
      ,[SrcLoadDate]
      ,[SentEncounterRiskAdjustableFlag]
      ,[RiskAdjustableReasonCodes]
      ,[OriginalEncounterRiskAdjustableFlag]
      ,[MAO004ResponseDiagnosisCodeID]
      ,[DiagnosisCode]
      ,[DiagnosisICD]
      ,[DiagnosisFlag]
      ,[ClaimID]
      ,[EntityDiscriminator]
      ,[BaseClaimID]
      ,[SecondaryClaimID]
      ,[ClaimIndicator]
      ,[EncounterRiskAdjustable]
      ,[RecordID]
      ,[SystemSource]
      ,[VendorID]
      ,[MedicalRecordImageID]
      ,[SubProjectMedicalRecordID]
      ,[SubProjectID]
      ,[SubProjectName]
      ,[SupplementalID]
      ,[DerivedPatientControlNumber]
      ,[IsDelete]
	  ,[Loaddatetime]
	  ,[LoadID])
	SELECT 
	      [MAO004ResponseID] = m.MAO004ResponseID
		 , [StgMAO004ResponseID] = m.MAO004ResponseID
		 , [ContractID] = m.[MedicareAdvantageContractID]
		 , [HICN] = ISNULL([althcn].[FINALHICN], m.[BeneficiaryIdentifier]) 
		 , [SentEncounterICN] =  m.[EncounterICN]
		 , [ReplacementEncounterSwitch] =  m.[EncounterTypeSwitch]
		 , [SentICNEncounterID]  = NULL
		 , [OriginalEncounterICN] = m.[ICNofEncounterLinkedTo]
		 , [OriginalICNEncounterID] = NULL
		 , [PlanSubmissionDate] =m.[EncounterSubmissionDate]
		 , [ServiceStartDate] =m.[FromDateofService]
		 , [ServiceEndDate] = m.[ThroughDateofService]
		 , [ClaimType] = m.[ServiceType]
		 , [FileImportID] = m.FileImportID
		 , [SrcLoadDate]  = m.[LastUpdateDatetime]
		 , [SentEncounterRiskAdjustableFlag] = m.[AllowedDisallowedFlagRiskAdjustment]
		 , [RiskAdjustableReasonCodes] = m.[AllowedDisallowedFlagRiskReasonCode]
		 , [OriginalEncounterRiskAdjustableFlag] = m.[AllowedDisallowedStatusofEncounterLinkedTo]
		 , [MAO004ResponseDiagnosisCodeID] = b.MAO004ResponseDiagnosisCodeID
		 , [DiagnosisCode] = b.DiagnosisCode
		 , [DiagnosisICD] = NULL
		 , [DiagnosisFlag]  = b.IsActive
		 , [ClaimID]  = NULL 
		 , [EntityDiscriminator] = NULL 
		 , [BaseClaimID] = NULL 
		 , [SecondaryClaimID]  = NULL 
		 , [ClaimIndicator] = NULL 
		 , [EncounterRiskAdjustable] = 0 
		 , [RecordID]= NULL 
		 , [SystemSource]  = NULL 
		 , [VendorID]  = NULL
		 , [MedicalRecordImageID] =NULL 
		 , [SubProjectMedicalRecordID] = NULL
		 , [SubProjectID] = NULL 
		 , [SubProjectName] = NULL
		 , [SupplementalID] = NULL
		 , [DerivedPatientControlNumber] =  NULL 
		 , [IsDelete] = CASE WHEN b.AddOrDeleteFlag = ''A'' THEN  1 
							WHEN B.AddOrDeleteFlag= ''D'' THEN  0 
							WHEN B.AddOrDeleteFlag = ''N'' THEN  NULL 
							ELSE NULL END    		
		 , [Loaddatetime] = GetDate()
	     , [LoadID] = -1
		FROM ' + @ClntRepo_DB + '.dbo.MAO004Response m 
		    JOIN ' + @ClntRepo_DB + '.dbo.MAO004ResponseDiagnosisCode b
				  on m.MAO004ResponseID = b.MAO004ResponseID
		    LEFT JOIN [$(HRPInternalReportsDB)].[dbo].[Rollupplan] r
                  ON r.PlanID = m.MedicareAdvantageContractID                  
		    LEFT JOIN [rev].[tbl_Summary_RskAdj_AltHICN] [althcn]
				ON r.PlanIdentifier = [althcn].[PlanID]
				   AND m.BeneficiaryIdentifier = [althcn].[HICN]
        WHERE m.[ThroughDateofService] >= 
		  CAST(''' + CONVERT(NVARCHAR(24), @DateStart, 101)
          + ''' AS DATE) AND m.[ThroughDateofService] < CAST(''' + CONVERT(NVARCHAR(24), @DateEnd, 101) + ''' AS DATE)
          AND r.UseForRollup = 1 AND R.Active = 1'

EXEC (@SourceSQL)

SET @DateStart = DATEADD(MONTH, 6, @DateStart)
SET @DateEnd = CASE WHEN DATEADD(MONTH, 6, @DateEnd) = DATEADD (Day, 1, @ServiceEnd) THEN @ServiceEnd 
                            ELSE DATEADD(MONTH, 6, @DateEnd) END 


 End

End

/***RRI 1754*/
/***Temporary Fix for DELETE PROCESS UPDATES*/


--AddOrDeleteFlag = 'A' => IsDelete = 1
--AddOrDeleteFlag = 'D' => IsDelete = 0
--AddOrDeleteFlag = Rest => IsDelete = NULL

/**

Update	a
Set		a.RiskAdjustable = 1
FROM	#MAO004Source a
WHERE	a.EncounterSubmissionDate between '01/01/2019' AND '8/2/2021' 
	AND	(	(a.AllowedDisallowedFlagRiskAdjustment = 'A' and a.EncounterTypeSwitch <> '7')
			OR 
			a.EncounterTypeSwitch IN ('8','9')
			OR 
			(a.EncounterTypeSwitch = '7' AND a.AllowedDisallowedStatusofEncounterLinkedTo = 'A')
		)	
	AND a.AddOrDeleteFlag = 'A'
	AND a.EncounterTypeSwitch NOT IN ('2','5')

[EncounterICN] [bigint] NULL,	  [SentEncounterICN] =  m.[EncounterICN]
[EncounterTypeSwitch] [char](1) NULL,	  [ReplacementEncounterSwitch] =  m.[EncounterTypeSwitch]
[ICNofEncounterLinkedTo] [bigint] NULL,	  [OriginalEncounterICN] = m.[ICNofEncounterLinkedTo]
[EncounterSubmissionDate] [date] NULL,	  [PlanSubmissionDate] =m.[EncounterSubmissionDate]
[AllowedDisallowedFlagRiskAdjustment] [char](1) NULL,	  [SentEncounterRiskAdjustableFlag] = m.[AllowedDisallowedFlagRiskAdjustment]
[AllowedDisallowedFlagRiskReasonCode] [char](1) NULL,	  [RiskAdjustableReasonCodes] = m.[AllowedDisallowedFlagRiskReasonCode]
[AllowedDisallowedStatusofEncounterLinkedTo] [char](1) NULL,	  [OriginalEncounterRiskAdjustableFlag] = m.[AllowedDisallowedStatusofEncounterLinkedTo]
[MAO004ResponseDiagnosisCodeID] [bigint] NULL,	  [MAO004ResponseDiagnosisCodeID] = b.MAO004ResponseDiagnosisCodeID
[DiagnosisCode] [varchar](7) NULL,	  [DiagnosisCode] = b.DiagnosisCode
[DiagnosisICD] [char](1) NULL,	  [DiagnosisICD] = NULL
[IsActive] [bit] NOT NULL,	  [DiagnosisFlag]  = b.IsActive
[AddOrDeleteFlag] [bit] NULL,	  [IsDelete]  = NULL
[RiskAdjustable] [bit] NULL,	  [RiskAdjustable] = 0


	*/
	UPDATE	a
	SET		a.EncounterRiskAdjustable = 1
	FROM	REV.tbl_Summary_RskAdj_EDS_Source a
	WHERE	((a.[SentEncounterRiskAdjustableFlag] = 'A' and a.ReplacementEncounterSwitch <> '7')
				OR 
				a.ReplacementEncounterSwitch IN ('8','9')
				OR 
				(a.ReplacementEncounterSwitch = '7' AND a.OriginalEncounterRiskAdjustableFlag = 'A')
			)	
		AND a.IsDelete  = 1 
		AND a.ReplacementEncounterSwitch NOT IN ('2','5');

	IF OBJECT_ID (N'TempDB..#Deletes', N'U') IS NOT NULL
	Begin
			DROP TABLE #Deletes;
	END

	CREATE TABLE [#Deletes]
	(
		ID INT Identity(1, 1), 
		[ICNofEncounterLinkedTo] [bigint] NULL,
		[DiagnosisCode] [VARCHAR](7) NULL
	);

	INSERT INTO [#Deletes]
	(
		[ICNofEncounterLinkedTo], 
		[DiagnosisCode]
	)
	SELECT	
		DISTINCT 
			OriginalEncounterICN, 
			DiagnosisCode
	FROM	[REV].[tbl_Summary_RskAdj_EDS_Source]
	WHERE	IsDelete = 0;	

	CREATE NONCLUSTERED INDEX [IDX_ICNofEncounterLinkedTo_Dx] on [#Deletes] (ICNofEncounterLinkedTo, DiagnosisCode);
    
    ---1912
	UPDATE a
         SET a.EncounterRiskAdjustable = 0
       FROM REV.tbl_Summary_RskAdj_EDS_Source a
       JOIN #Deletes b
                  ON a.SentEncounterICN = b.ICNofEncounterLinkedTo
                  AND a.DiagnosisCode = b.DiagnosisCode
  
END
