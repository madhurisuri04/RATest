CREATE  PROCEDURE [rev].[LoadIntermediarySupplementalEDSData]
AS
    BEGIN
        SET NOCOUNT ON

/************************************************************************        
* Name			:	rev.[LoadIntermediarySupplementalEDSData].proc     	*                                                     
* Type 			:	Stored Procedure									*                
* Author       	:	Madhuri Suri     									*
* Date          :	7/1/2021									     	*	
* Ticket        :   
* Version		:        												*
* Description	:	Populates Supplemetal data from client DBs to 
                                           Client_Report Db	            *

*************************************************************************/   

/*************************************************************************
TICKET       DATE              NAME                DESCRIPTION
RRI 1279     6/1/21           Madhuri Suri       Pull Supplemental Data 
                                                 for SSIS EDS Source
RRI-2344	 6/1/22			  Anand				 Change to view for IH 	
**************************************************************************/   

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

DECLARE @FinalResults TABLE
(
[RecordID] [VARCHAR](80) NULL  ,
[SystemSource] [VARCHAR](30)  NULL,
[VendorID]   [VARCHAR](100) NULL,
[ServiceEndDate]   [DATETIME] NULL ,
[MedicalRecordImageID]   [INT] NULL  ,
[SubProjectMedicalRecordID]    [INT], 
[SubProjectID]   [INT] NULL ,
[SubProjectName]    [VARCHAR](100) NULL ,
[SupplementalID]   [BIGINT]  NULL
)

DECLARE @SourceSQL VARCHAR(MAX)
DECLARE @Curr_DB VARCHAR(128) = NULL
DECLARE @Clnt_DB VARCHAR(128) = NULL
DECLARE @ServiceStart datetime 
DECLARE @ServiceEnd datetime 
Declare @SourceViewtable VARCHAR(128) = NULL

SET @Curr_DB =
    (
        SELECT [Current Database] = DB_NAME()
    )

SET @Clnt_DB = SUBSTRING(@Curr_DB, 0, CHARINDEX('_Report', @Curr_DB));
SET @ServiceStart = (SELECT MIN([From_Date]) FROM [rev].[tbl_Summary_RskAdj_RefreshPY] [r1]) 
SET @ServiceEnd =  (SELECT MAX([THRU_Date]) FROM [rev].[tbl_Summary_RskAdj_RefreshPY] [r1]) 


IF @Curr_DB = 'AETIH_Report'
BEGIN
	SET @SourceViewtable = '[rev].[Vw_RptEDSSupplemental]'
END
	ELSE
BEGIN
	SET @SourceViewtable =  @Clnt_DB + '.sup.Supplemental'
End

 
SET @SourceSQL = 
'    
SELECT  

      [RecordID]= s.RecordID
    , [SystemSource]  = s.SystemSource
    , [VendorID]  = s.VendorID
    , [ServiceEndDate] = s.ServiceEnddate
    , [MedicalRecordImageID] = s.MedicalRecordImageID 
    , [SubProjectMedicalRecordID] = s.SubProjectMedicalRecordID
    , [SubProjectID] = S.SubProjectID 
    , [SubProjectName] = s.SubProjectName
    , [SupplementalID] = s.SupplementalID

FROM ' + @SourceViewtable + ' s  
WHERE 
    s.ServiceEndDate between  CAST(''' + CONVERT(NVARCHAR(24), @ServiceStart, 101)
          + ''' AS DATE) AND CAST(''' + CONVERT(NVARCHAR(24), @ServiceEnd, 101) + ''' AS DATE)
    AND 
    (
        s.VendorID = ''Cotiviti''
        OR 
        (
            s.VendorID = ''VH'' 
            and S.SubProjectID in
            (    SELECT SUBProjectID FROM [rev].[ProjectSubproject] v with (nolock)
                WHERE retroyear in (SELECT Payment_Year FROM [rev].[tbl_Summary_RskAdj_RefreshPY] [r1])
            )
        )
    )
    '

INSERT INTO @FinalResults
EXEC (@SourceSQL);

SELECT [RecordID]
      ,[SystemSource]
      ,[VendorID]
      ,[ServiceEndDate]
      ,[MedicalRecordImageID]
      ,[SubProjectMedicalRecordID]
      ,[SubProjectID]
      ,[SubProjectName]
      ,[SupplementalID] 
	  FROM @FinalResults

END
