CREATE  PROCEDURE [rev].[LoadIntermediarySuppEncounterEDSData]
   
AS
    BEGIN
        SET NOCOUNT ON

/************************************************************************        
* Name			:	rev.[LoadIntermediarySuppEncounterEDSData].proc     	*                                                     
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
RRI 1279     6/1/21           Madhuri Suri       Pull Supplemental Data 
                                                 for SSIS EDS Source
RRI-2344	 6/1/22			  Anand				 Change to view for IH 	
**************************************************************************/   


  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

 DECLARE @SourceSQL VARCHAR(MAX)
 DECLARE @Curr_DB VARCHAR(128) = NULL
 DECLARE @Clnt_DB VARCHAR(128) = NULL


 SET @Curr_DB =
    (
        SELECT [Current Database] = DB_NAME()
    )

    SET @Clnt_DB = SUBSTRING(@Curr_DB, 0, CHARINDEX('_Report', @Curr_DB));


DECLARE @FinalResult TABLE 
	(
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[ClaimID] [varchar](50) NULL,
	[EntityDiscriminator] [varchar](2) NULL,
	[BaseClaimID] [varchar](50) NULL,
	[SecondaryClaimID] [varchar](50) NULL,
	[ClaimIndicator] [char](1) NULL,
	[ServiceEndDate] [datetime] NULL,
	[EncounterRiskAdjustable] [bit] NULL,
	[RecordID] [varchar](80) NULL,
	[SystemSource] [varchar](30) NULL,
	[VendorID] [varchar](100) NULL,
	[MedicalRecordImageID] [int] NULL,
	[SubProjectMedicalRecordID] [int] NULL,
	[SubProjectID] [int] NULL,
	[SubProjectName] [varchar](100) NULL,
	[SupplementalID] [bigint] NULL,
	[DerivedPatientControlNumber] [varchar](50) NULL,
	[EncounterICN] [bigint] NULL,
	[Diagnosis] [varchar](7) NULL
	)

IF @Curr_DB = 'AETIH_Report'

Begin 

INSERT INTO @FinalResult
(
    [ClaimID],
	[EntityDiscriminator],
	[BaseClaimID],
	[SecondaryClaimID],
	[ClaimIndicator],
	[ServiceEndDate],
	[EncounterRiskAdjustable],
	[RecordID],
	[SystemSource],
	[VendorID],
	[MedicalRecordImageID],
	[SubProjectMedicalRecordID],
	[SubProjectID],
	[SubProjectName],
	[SupplementalID],
	[DerivedPatientControlNumber],
	[EncounterICN],
	[Diagnosis]
)
SELECT 
	  [ClaimID]  = ClaimID
	, [EntityDiscriminator] = EntityDiscriminator
	, [BaseClaimID] = BaseClaimID
	, [SecondaryClaimID]  = SecondaryClaimID
	, [ClaimIndicator] = ClaimIndicator
	, [ServiceEndDate] = ServiceEndDate
	, [EncounterRiskAdjustable] = EncounterRiskAdjustable
	, [RecordID]= RecordID
	, [SystemSource]  = SystemSource
	, [VendorID]  = VendorID
	, [MedicalRecordImageID] = MedicalRecordImageID 
	, [SubProjectMedicalRecordID] = SubProjectMedicalRecordID
	, [SubProjectID] = SubProjectID 
	, [SubProjectName] = SubProjectName
	, [SupplementalID] = SupplementalID
	, [DerivedPatientControlNumber] = NULL
	, [ICN] As [EncounterICN]
	, [Diagnosis] 
	
FROM [rev].[Vw_RptEDSEncountersDiagnosis] s

End

Else 

Begin 

SET @SourceSQL =

'
SELECT 
	  [ClaimID]  = c.ClaimID
	, [EntityDiscriminator] = c.EntityDiscriminator
	, [BaseClaimID] = c.BaseClaimID
	, [SecondaryClaimID]  = c.SecondaryClaimID
	, [ClaimIndicator] = c.ClaimIndicator
	, [ServiceEndDate] = s.[ServiceEndDate]
	, [EncounterRiskAdjustable] = c.EncounterRiskAdjustable
	, [RecordID]= s.RecordID
	, [SystemSource]  = s.SystemSource
	, [VendorID]  = s.VendorID
	, [MedicalRecordImageID] = s.MedicalRecordImageID 
	, [SubProjectMedicalRecordID] = s.SubProjectMedicalRecordID
	, [SubProjectID] = s.SubProjectID 
	, [SubProjectName] = s.SubProjectName
	, [SupplementalID] = s.SupplementalID
	, [DerivedPatientControlNumber] = NULL
	--, [DerivedPatientControlNumber] =	CASE	when c.EntityDiscriminator = ''EU''
	--										THEN ISNULL(c.SecondaryClaimId,c.ClaimID)
	--									else Cast(IsNull(s.VendorID,'''') as nchar(50))
	--										+ ''_'' + Cast(IsNull(s.RecordID,'''') as nchar(50))
	--										+ Case when s.SubProjectID is not NULL Then ''_'' + Cast(IsNull(s.SubProjectID,'''') as nchar(50)) Else '''' END 

	--							End 
	, CAST (erev.ICN as Bigint) AS ICN
	, ed.[Diagnosis] 
	
FROM 
	' + @Clnt_DB + '.dbo.encounterresponseEDIValue erev  WITH (NOLOCK)--intermediary table required to join between ClientRepo and encounters table
	--Tells us that MAO-002 is accepted. 
	JOIN ' + @Clnt_DB + '.dbo.Encounters c with (nolock)
	ON erev.EncounterID = c.ID
	JOIN ' + @Clnt_DB + '.dbo.EncounterDiagnosis ed with (nolock)
	on c.ID = ed.EncounterID
	--AND b.DiagnosisCode = ed.Diagnosis
	JOIN [rev].[IntermediarySupplemental] s  with (nolock)
	ON ed.SupplementalID=s.SupplementalID
WHERE
	erev.ServiceLineNum = 0 --This pertains to claim level items
	AND erev.EncounterResponseEDITypeID = 8 --Only using MAO-002 file type and not 277 file type
	AND erev.isValid = 1 '

 
INSERT INTO @FinalResult
EXEC (@SourceSQL)

End
 
SELECT 
[ClaimID]
      ,[EntityDiscriminator]
      ,[BaseClaimID]
      ,[SecondaryClaimID]
      ,[ClaimIndicator]
      ,[ServiceEndDate]
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
      ,[EncounterICN]
      ,[Diagnosis]
FROM @FinalResult

END
