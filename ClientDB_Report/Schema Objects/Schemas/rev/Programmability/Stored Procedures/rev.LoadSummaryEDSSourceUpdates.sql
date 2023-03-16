/************************************************************************        
* Name			:	rev.[SummaryEDSSourceUpdates].proc						*                                                     
* Type 			:	Stored Procedure									*                
* Author       	:	Madhuri Suri     									*
* Date          :	7/1/2021									     	*	
* Ticket        :   
* Version		:        												*
* Description	:	Updates Supplemetal Encounter data into EDS Source Tables	            *

*************************************************************************/   

/*************************************************************************
TICKET       DATE              NAME                DESCRIPTION
RRI 1279     2/20/22           Madhuri Suri       Updates Supplemetal Encounter data into EDS Source Tables	
**************************************************************************/   

CREATE  PROCEDURE [rev].[LoadSummaryEDSSourceUpdates]

AS
    BEGIN
        SET NOCOUNT ON

 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DECLARE @Curr_DB VARCHAR(128) = NULL;
DECLARE @IH_DB VARCHAR(128) = NULL;
DECLARE @UpdateSourceSQL VARCHAR(MAX);
DECLARE @ClientID INT;
DECLARE @ClientDBCN VARCHAR(128) = NULL;
DECLARE @MRAExtractSQL VARCHAR(MAX); 
SET @Curr_DB =
(
    SELECT [Current Database] = DB_NAME()
);

SET @ClientID = (SELECT Client_ID  FROM [$(HRPReporting)].dbo.tbl_Clients WHERE Report_DB = @Curr_DB)

--Select Report_DB from HRPReporting.dbo.tbl_Clients
--where Client_ID = 76

 /**Update Encounter Data to tbl_Summary_RskAdj_EDS_source**/
  
     UPDATE Rev.tbl_Summary_RskAdj_EDS_Source
                                    SET [ClaimID]  = ed.ClaimID
			 , [EntityDiscriminator] = ed.EntityDiscriminator
			 , [BaseClaimID] = ed.BaseClaimID
			 , [SecondaryClaimID]  = ed.SecondaryClaimID
			 , [ClaimIndicator] = ed.ClaimIndicator
			 , [RecordID]= ed.RecordID
			 , [SystemSource]  = ed.SystemSource
			 , [VendorID]  = ed.VendorID
			 , [MedicalRecordImageID] = ed.MedicalRecordImageID 
			 , [SubProjectMedicalRecordID] = ed.SubProjectMedicalRecordID
			 , [SubProjectID] = ed.SubProjectID 
			 , [SubProjectName] = ed.SubProjectName
			 , [SupplementalID] = ed.SupplementalID
			 , [DerivedPatientControlNumber] =  ed.DerivedPatientControlNumber
 
	
	FROM Rev.tbl_Summary_RskAdj_EDS_Source m
		       JOIN [rev].[IntermediarySupplementalEncounter] ed 
				ON m.DiagnosisCode = ed.Diagnosis
						  AND m.SentEncounterICN = ed.EncounterICN

/********************************************************************************/

 IF @ClientID = 19  

 BEGIN

 SET @ClientDBCN = (SELECT Client_DB_CN  FROM [$(HRPReporting)].dbo.tbl_Clients WHERE Report_DB = @Curr_DB)

 DECLARE @ServiceEnd DATETIME , @ServiceStart DATETIME , @RetroYear INT

  CREATE TABLE #ActiveYearPlans
        (
            ActiveYearPlanID SMALLINT IDENTITY(1, 1) PRIMARY KEY NOT NULL,
            PaymentYear VARCHAR(4) NOT NULL,
            ServiceStart SMALLDATETIME NULL,
            ServiceEnd SMALLDATETIME NULL
        );

       INSERT INTO #ActiveYearPlans
        (
            PaymentYear, 
            ServiceStart,
            ServiceEnd
        )
        SELECT 
               RPY.Payment_Year,
               RPY.From_Date ,
               RPY.Thru_Date 
        FROM rev.tbl_Summary_RskAdj_RefreshPY RPY WITH (NOLOCK)
        GROUP BY RPY.Payment_Year,
                 RPY.From_Date,
				 RPY.Thru_Date;
     
SET @ServiceStart = (SELECT MIN(ServiceStart) FROM #ActiveYearPlans [r1]) 
SET @ServiceEnd =  (SELECT MAX(ServiceEnd) FROM #ActiveYearPlans [r1]) 
SET @RetroYear =   (SELECT MAX(RetroYear) FROM [rev].[ProjectSubproject] [r1] WHERE Active = 1) 

---For 2022 retro year 2021?
---
 ---------------------------------------------------------------------
 --Innovation Health Supplemental Encountet Updates 
 ---------------------------------------------------------------------
SET @IH_DB = (SELECT Report_DB FROM [$(HRPReporting)].dbo.tbl_Clients WHERE Client_ID = 76)
 
SET @UpdateSourceSQL
    = 
      'UPDATE Rev.tbl_Summary_RskAdj_EDS_Source
                                    SET [ClaimID]  = ed.ClaimID
			 , [EntityDiscriminator] = ed.EntityDiscriminator
			 , [BaseClaimID] = ed.BaseClaimID
			 , [SecondaryClaimID]  = ed.SecondaryClaimID
			 , [ClaimIndicator] = ed.ClaimIndicator
			 , [RecordID]= ed.RecordID
			 , [SystemSource]  = ed.SystemSource
			 , [VendorID]  = ed.VendorID
			 , [MedicalRecordImageID] = ed.MedicalRecordImageID 
			 , [SubProjectMedicalRecordID] = ed.SubProjectMedicalRecordID
			 , [SubProjectID] = ed.SubProjectID 
			 , [SubProjectName] = ed.SubProjectName
			 , [SupplementalID] = ed.SupplementalID
			 , [DerivedPatientControlNumber] =  ed.DerivedPatientControlNumber
 
	
	FROM ' + @IH_DB
      + '.Rev.tbl_Summary_RskAdj_EDS_Source m
		       ' + @IH_DB
      + '.JOIN [rev].[IntermediarySupplementalEncounter] ed 
				ON m.DiagnosisCode = ed.Diagnosis
						  AND m.SentEncounterICN = ed.EncounterICN'

EXEC (@UpdateSourceSQL);
 
 ---------------------------------------------------------------
 --Duals Update
 ---------------------------------------------------------------

DROP TABLE IF EXISTS #MRAExtract

CREATE TABLE #MRAExtract
	(   
		HICN	varchar	(50),
		ChaseID	varchar	(100),
		DiagnosisCode	VARCHAR	(250),
		DOSStart	DATE,	
		DOSEnd	DATE,	
		ProjectID	INT	, 
		SubprojectID	INT	
	)

	SET @MRAExtractSQL = '
	INSERT INTO #MRAExtract
	(
	HICN, 
	 ChaseID, 
	 DiagnosisCode, 
	 DOSStart, 
	 DOSEnd, 
	 ProjectID,
	 SubprojectID
	)
	SELECT DISTINCT 
		   cwf.HICN
		   ,mra.ChaseID
		   ,mra.DiagnosisCode
		   ,mra.DOSStart
		   ,mra.DOSEnd
		   ,cwf.ProjectID
		   ,cwf.SubprojectID

	FROM '+@ClientDBCN+'.dbo.mraextract (NOLOCK) mra
		   JOIN dbo.cwfdetails (NOLOCK) cwf
		   ON 1=1
		   AND mra.ChaseID = cwf.ListChaseID
		   AND mra.SPMRID = cwf.SubprojectMedicalRecordID
		   AND mra.DiagnosisCode = cwf.DiagnosisCode
		   AND mra.DOSEnd = cwf.DOSEndDt
		   AND mra.DOSStart = cwf.DOSStartDt 
	WHERE mra.DOSEnd BETWEEN ' + @ServiceStart + ' AND ' + @ServiceEnd + '
		   AND cwf.projectID in (select distinct projectID from [rev].[ProjectSubproject] where ClientLOB = ''Aetna Duals''
                                                                                                     and RetroYear = ' + @RetroYear + ') '

EXEC (@MRAExtractSQL);

-------------------select * from Aetna_Report.[rev].[ProjectSubproject]
--------------------MISSING 2021 retro year in table
--------------------2021 Aetna Duals: 1303, 1304, 1305, 1306, 1307, 1345, 1347, 1355, 1357 

UPDATE A 
       SET 
       a.VendorID = 'Cotiviti Dual'
       , a.SubProjectID = b.SubProjectID
       , a.recordID = b.ChaseID
FROM  REV.tbl_Summary_RskAdj_EDS_Source  a 
       JOIN #MRAExtract b 
       ON 1=1
       AND a.HICN = b.HICN
       AND a.DiagnosisCode = b.DiagnosisCode
       AND a.ServiceStartDate = b.DOSStart
       AND a.ServiceEndDate = b.DOSEnd
WHERE  a.ServiceStartDate BETWEEN @ServiceStart AND @ServiceEnd
       AND a.ReplacementEncounterSwitch >= 4 --Indicates dgn came from charts
       AND RecordID IS NULL and VendorID IS NULL

 ---------------------------------------------------------------
 --Non-Duals Update
 ---------------------------------------------------------------
--Update SubprojectID for non Duals
--This MUST happen after the encounter Updates from Aetna and IH


DROP TABLE IF EXISTS #CWFDetails
CREATE TABLE #CWFDetails
(
ProjectID	INT,
SubprojectID	INT,
ListChaseID	VARCHAR(50))

INSERT INTO #CWFDetails(
ProjectID,
SubprojectID,
ListChaseID	
)
SELECT DISTINCT 
ProjectID, 
SubprojectID, 
ListChaseID 

FROM dbo.cwfdetails
WHERE projectid in (SELECT DISTINCT ProjectID FROM [rev].[ProjectSubproject] WHERE RetroYear = @RetroYear) --Add retroyear parameter

UPDATE V 
SET v.subprojectid = c.subprojectid
FROM 
       #CWFDetails c,
       REV.tbl_Summary_RskAdj_EDS_Source v
WHERE 
       c.listChaseID = REPLACE(v.recordID, 'Cotiviti_', '')
       and (left(recordID,3) = 'MRA' or left(recordID,8) = 'Cotiviti')


END --End Aetna Specific Updates


END 