/*  Created By:		Kosta Dombrovskiy,Dianne Barba
	TFS 17141
	Description:	Create a stored procedure to extract the latest RADV data for Reporting purposes.
	Date: 06212013
	
	exec dbo.ETL_RADVMerge 909, 'hrpstgdb002', 'Excellus_CN_ClientLevel', 'Excellus_Report'
	exec dbo.ETL_RADVMerge 925, 'hrpstgdb002', 'Excellus_CN_ClientLevel', 'Excellus_Report'
	exec dbo.ETL_RADVMerge 130, 'hrpdevdb01', 'MVP_CN_ClientLevel', 'MVP_Report'		
	
	Modifications:
	03/19/14 TFS10235 DMB Changed where PlanProviderID is loaded from
	03/24/14 TFS26187 DMB Fixed join for RADVMember to include subprojectID.  Adjusted the suspect
	                      so that the pivot was not just on member ID but also on HCCModelYearID
	03/28/14 TFS26365 DMB Added ProviderTypeDescription and Comments to RADVMemberDetail table.  Purged
						  the contents of RADVMemberDetail, RADVMemberSuspect and RADVMember before
						  adding new data.

*/

--alter procedure ETL_RADVMerge
CREATE procedure [dbo].[ETL_RADVMerge]
( 
	@SubProjectID int, 
	@CNServerName varchar (50) = '',
	@ClientDBName varchar(50),
	@ReportDBName varchar(50),
	@debug bit = 0
)
as

	declare @msg varchar(200)
	declare @wrk_RADVETLMemberid int
	declare @cntr int
	declare @wrk_ID int
	declare @max_ID int
	declare @wrk_HCCModelYearID varchar(10)
	declare @base char(13)		
	declare @nsql nvarchar(max)
	declare @sql varchar(max)
	declare @dbname varchar(100)
	declare @projecttypedesc varchar(100)
	declare @StageDBName varchar(50)
	declare @Base_Object_Name varchar(100)	
	declare @procname varchar(100)	
	Declare @LastUpdateImageDate datetime2 
	declare @LastUpdateCodingDate datetime2 	
	declare @LastDateCoded datetime2

	BEGIN TRY		
		
-- get proc name
	set @procname = OBJECT_NAME(@@PROCID)
			
-- verify input params
		if isnull(@SubProjectID,0) = 0
			begin
				set @SubProjectID = 0
				set @msg = '- Missing input parameter @SubProjectID'
				raiserror(@msg, 16, 1)
			end

-- build staging Server/DB name
		set @StageDBName = @CNServerName + '.' + REPLACE(@ClientDBName, 'ClientLevel', 'Staging')

-- drop Client Staging synonyms
		set @msg = 'dropping Client Staging synonyms'
		if @debug = 1
			begin
				exec dbo.messenger null, null, null, @procname, @msg, null, 'I'
			end		
		if exists (select * from sys.synonyms where name = N'syn_RADVMemberStage')
			drop synonym dbo.syn_RADVMemberStage					
		if exists (select * from sys.synonyms where name = N'syn_RADVMemberDetailStage')
			drop synonym dbo.syn_RADVMemberDetailStage	
		if exists (select * from sys.synonyms where name = N'syn_RADVMemberSuspectStage')
			drop synonym dbo.syn_RADVMemberSuspectStage	
		if exists (select * from sys.synonyms where name = N'syn_RADVMemberCodingDetailStage')	
			drop synonym dbo.syn_RADVMemberCodingDetailStage			

-- create Client Staging synonyms
		set @msg = 'creating Client Staging synonyms'	
		if @debug = 1
			begin
				exec dbo.messenger null, null, null, @procname, @msg, null, 'I'
			end		
		set @sql = 'create synonym dbo.syn_RADVMemberStage for ' + @StageDBName + '.dbo.RADVMemberStage'
		exec(@sql)	
		set @sql = 'create synonym dbo.syn_RADVMemberDetailStage for ' + @StageDBName + '.dbo.RADVMemberDetailStage'
		exec(@sql)	
		set @sql = 'create synonym dbo.syn_RADVMemberSuspectStage for ' + @StageDBName + '.dbo.RADVMemberSuspectStage'
		exec(@sql)	
		set @sql = 'create synonym dbo.syn_RADVMemberCodingDetailStage for ' + @StageDBName + '.dbo.RADVMemberCodingDetailStage'
		exec(@sql)					
		
-- set the base value for PivotColumn
		set @base = 'TargetICDCode'	
		
-- Create temp table to hold assembled member data from CN staging
		set @msg = 'dropping/creating #RADVETLMember'
		if @debug = 1
			begin
				exec dbo.messenger null, null, null, @procname, @msg, null, 'I'
			end		
		if OBJECT_ID ('tempdb..#RADVETLMember') is not null
			drop table #RADVETLMember

		Create table #RADVETLMember
		(
			ID Int Primary Key,
			HICN varchar (20),
			MemberLastName varchar (50),
			MemberFirstName varchar (25),
			MemberDOB date, 
			RADVContractID varchar (5),
			RADVYear char (4),
			MAOrgName varchar (255), 
			MaskedH# varchar (5), 
			CurrentContractID varchar (5), 
			EnrolleeID varchar (10),
			SubProjectID int,
			SubProjectDescription varchar (255),
			EnrolleeRRBHIC varchar(25),
			RAFactorType char(2),
			SCC varchar(5),
			PBP char(3),
			HierarchyApplied char(1)
		)
		
-- Create temp table to hold assembled suspect data from CN
		set @msg = 'dropping/creating #RADVETLSuspect'
		if @debug = 1
			begin
				exec dbo.messenger null, null, null, @procname, @msg, null, 'I'
			end		
		if OBJECT_ID ('tempdb..#RADVETLSuspect') is not null
			drop table #RADVETLSuspect

		Create table #RADVETLSuspect
		(
			ID int primary key,
			RADVETLMemberID int,
			TargetHCCModelYearID varchar (10),
			TargetICDCode varchar (10),
			HierarchyApplied char (1),
			PivotColumn varchar(15)
		)
		
		set @msg = 'dropping/creating #RADVETLSuspectHCCs'
		if @debug = 1
			begin
				exec dbo.messenger null, null, null, @procname, @msg, null, 'I'
			end		
		if OBJECT_ID ('tempdb..#RADVETLSuspectHCCs') is not null
			drop table #RADVETLSuspect
		create table #RADVETLSuspectHCCs
		(
			ID int identity primary key,
			RADVETLMemberID int,
			TargetHCCModelYearID varchar (10),
			TargetICDCode varchar(10)
		)
			
-- Create temp table to hold pivoted suspect data from #RADVETLSuspect
		set @msg = 'dropping/creating #RADVETLSuspectPivot'
		if @debug = 1
			begin
				exec dbo.messenger null, null, null, @procname, @msg, null, 'I'
			end		
		if OBJECT_ID ('tempdb..#RADVETLSuspectPivot') is not null
			drop table #RADVETLSuspectPivot

		Create table #RADVETLSuspectPivot
		(
			ID int identity primary key,
			RADVETLMemberID int,
			TargetHCCModelYearID varchar (10),
			TargetICDCode1 varchar (10),
			TargetICDCode2 varchar (10),
			TargetICDCode3 varchar (10),
			TargetICDCode4 varchar (10),
			TargetICDCode5 varchar (10),
			TargetICDCode6 varchar (10),
			TargetICDCode7 varchar (10),
			TargetICDCode8 varchar (10),
			TargetICDCode9 varchar (10),
			TargetICDCode10 varchar (10),
			TargetICDCode11 varchar (10),
			TargetICDCode12 varchar (10),
			HierarchyApplied char (1)
		)			

-- Create temp table to hold assembled detail data from CN
-- TFS10235 Removed PlanProviderID
		set @msg = 'dropping/creating #RADVETLDetail'
		if @debug = 1
			begin
				exec dbo.messenger null, null, null, @procname, @msg, null, 'I'
			end		
		if OBJECT_ID ('tempdb..#RADVETLDetail') is not null
			drop table #RADVETLDetail

		Create table #RADVETLDetail
		(
			ID int  primary key,
			RADVETLMemberID int,
			SubProjectID int,
			SubProjectName varchar (50),
			SubProjectMedicalRecordID int, 
			SPMRStatusID int,
			SPMRLogDate datetime2,
			MedicalRecordRequestID int,
			MedicalRecordRequestStateID int,
			MedicalRecordImageWorkflowID int,
			MedicalRecordImageWorkflowStatusID int,
			MedicalRecordImageWorkflowStepID int,
			ReviewStepID int,
			ImageLastUpdateDateTime datetime2,
			MedicalRecordImageID int,
			ImageFilePath varchar (255),
			MRRLastUpdateDateTime datetime2
		)

-- Create temp table to hold assembled coding detail data from CN
-- TFS10235 Added PlanProviderID
		set @msg = 'dropping/creating #RADVETLCodingDetail'
		if @debug = 1
			begin
				exec dbo.messenger null, null, null, @procname, @msg, null, 'I'
			end		
		if OBJECT_ID ('tempdb..#RADVETLCodingDetail') is not null
			drop table #RADVETLCodingDetail

		Create table #RADVETLCodingDetail
		(
			ID int  primary key,
			RADVETLDetailID int,
			CodingDiagnosisID int,
			DiagnosisStatusID int,
			DOSEnd date,
			DOSStart date,
			ProviderTypeCD char (2),
			ProviderTypeDescription varchar(50),
			ICDCode char (10),
			ICDVersion char(2),
			StartPage int,
			EndPage int,
			DateCoded datetime2,
			HCCModelYearID int,
			HCCNumber varchar (10),
			HCCPartID int,
			ImageFailureIssueID int,
			ImageFailureDescription varchar(50),
			ImageReviewStepID int,
			DiagnosisErrorID int,
			DOSErrorID int,
			AttestationReceivedDate datetime2,
			CodingReviewStepID int,
			PlanProviderID varchar (50),
			Comments varchar(200)
		)

-- Build Member Level Data
-- select * from #RADVETLMember
		set @msg = 'pulling member level data'
		if @debug = 1
			begin
				exec dbo.messenger null, null, null, @procname, @msg, null, 'I'
			end		
		insert into #RADVETLMember 
			(ID, HICN, MemberLastName, MemberFirstName, MemberDOB, RADVContractID, RADVYear, MAOrgName, 
			 MaskedH#, CurrentContractID, EnrolleeID, SubProjectID, SubProjectDescription, EnrolleeRRBHIC, 
			 RAFactorType, SCC, PBP, HierarchyApplied)
		select 
			 ID, HICN, MemberLastName, MemberFirstName, MemberDOB, RADVContractID, RADVYear, MAOrgName, 
			 MaskedH#, CurrentContractID, EnrolleeID, SubProjectID, SubProjectDescription, EnrolleeRRBHIC, 
			 RAFactorType, SCC, PBP, HierarchyApplied
		--select *
		from dbo.syn_RADVMemberStage
			
-- Build Suspect Level Data
-- select * from #RADVETLSuspect
		set @msg = 'pulling suspect level data'
		if @debug = 1
			begin
				exec dbo.messenger null, null, null, @procname, @msg, null, 'I'
			end		
		insert into #RADVETLSuspect 
			(ID, RADVETLMemberID, TargetHCCModelYearID, TargetICDCode, HierarchyApplied)
		select ID, RADVETLMemberID, TargetHCCModelYearID, TargetICDCode, HierarchyApplied
		-- select * 
		from dbo.syn_RADVMemberSuspectStage

-- Get image data where coding has been completed.
-- TFS10235 Removed PlanProviderID
-- select * from #RADVETLDetail	
		set @msg = 'pulling coding complete detail data'
		if @debug = 1
			begin
				exec dbo.messenger null, null, null, @procname, @msg, null, 'I'
			end		
		insert into #RADVETLDetail 
			(ID, RADVETLMemberID, SubProjectID, SubProjectName, SubProjectMedicalRecordID, SPMRStatusID, 
			 MedicalRecordRequestID, MedicalRecordRequestStateID, MedicalRecordImageWorkflowID, MedicalRecordImageWorkflowStatusID,
			 MedicalRecordImageWorkflowStepID, ReviewStepID, MedicalRecordImageID, ImageFilePath, SPMRLogDate, ImageLastUpdateDateTime, MRRLastUpdateDateTime)
		select  
			ID, RADVETLMemberID, SubProjectID, SubProjectName, SubProjectMedicalRecordID, SPMRStatusID, 
			MedicalRecordRequestID, MedicalRecordRequestStateID, MedicalRecordImageWorkflowID, MedicalRecordImageWorkflowStatusID,
			MedicalRecordImageWorkflowStepID, ReviewStepID, MedicalRecordImageID, ImageFilePath, SPMRLogDate, ImageLastUpdateDateTime, MRRLastUpdateDateTime
		-- select * 						
		from dbo.syn_RADVMemberDetailStage etld

-- get diagnosis data for the images where coding has been completed
-- TFS10235 Added PlanProviderID
-- TFS26365 Added ProviderTypeDescription, Comments
-- select * from #RADVETLCodingDetail
		set @msg = 'pulling diagnosis data'
		if @debug = 1
			begin
				exec dbo.messenger null, null, null, @procname, @msg, null, 'I'
			end		
		insert into #RADVETLCodingDetail
			(ID, RADVETLDetailID, CodingDiagnosisID, DiagnosisStatusID, DOSEnd, DOSStart, ProviderTypeCD, ProviderTypeDescription, 
			 ICDCode, ICDVersion, StartPage, EndPage, DateCoded, HCCModelYearID, HCCNumber, HCCPartID, ImageFailureIssueID,
			 ImageFailureDescription, ImageReviewStepID, DiagnosisErrorID, DOSErrorID, AttestationReceivedDate,
			 CodingReviewStepID, PlanProviderID, Comments)		 
		select 
			ID, RADVETLDetailID, CodingDiagnosisID, DiagnosisStatusID, DOSEnd, DOSStart, ProviderTypeCD, ProviderTypeDescription, 
			ICDCode, ICDVersion, StartPage, EndPage, DateCoded, HCCModelYearID, HCCNumber, HCCPartID, ImageFailureIssueID,
			ImageFailureDescription, ImageReviewStepID, DiagnosisErrorID, DOSErrorID, AttestationReceivedDate,
			CodingReviewStepID, PlanProviderID, Comments
		from
			dbo.syn_RADVMemberCodingDetailStage etld

-- update #RADVETLSuspect pivotcolumn
-- select * from #RADVETLSuspect
		set @msg = 'populating PivotColumn in #RADVETLSuspect'
		if @debug = 1
			begin
				exec dbo.messenger null, null, null, @procname, @msg, null, 'I'
			end		
			
		select @wrk_RADVETLMemberid = min(RADVETLMemberID) from #RADVETLSuspect
		select @wrk_HCCModelYearID = min(TargetHCCModelYearID)from #RADVETLSuspect where RADVETLMemberID = @wrk_RADVETLMemberID
		while 1=1
			begin
				select @cntr = count(*) from #RADVETLSuspect where RADVETLMemberID = @wrk_RADVETLMemberid and TargetHCCModelYearID = @wrk_HCCModelYearID
				if @cntr = 1
					begin
						update s
						set PivotColumn = 'TargetICDCode1'
						from #RADVETLSuspect s 
						where RADVETLMemberID = @wrk_RADVETLMemberid and TargetHCCModelYearID = @wrk_HCCModelYearID
					end
				else
					begin
						truncate table #RADVETLSuspectHCCs
						
						insert into #RADVETLSuspectHCCs (RADVETLMemberID, TargetHCCModelYearID, TargetICDCode)
						select RADVETLMemberID, TargetHCCModelYearID, TargetICDCode 
						from #RADVETLSuspect
						where RADVETLMemberID = @wrk_RADVETLMemberid and TargetHCCModelYearID = @wrk_HCCModelYearID
						
						update s
						set PivotColumn = 'TargetICDCode' + cast(hs.ID as varchar)
						from #RADVETLSuspect s
						join #RADVETLSuspectHCCs hs on s.RADVETLMemberID = hs.RADVETLMemberID and s.TargetHCCModelYearID = hs.TargetHCCModelYearID and s.TargetICDCode = hs.TargetICDCode
					end
				select @wrk_HCCModelYearID = min(TargetHCCModelYearID)from #RADVETLSuspect where RADVETLMemberID = @wrk_RADVETLMemberID and TargetHCCModelYearID > @wrk_HCCModelYearID
				if isnull(@wrk_HCCModelYearID,0) = 0
					begin
						select @wrk_RADVETLMemberid = min(RADVETLMemberID) from #RADVETLSuspect where RADVETLMemberID > @wrk_RADVETLMemberid
						if isnull(@wrk_RADVETLMemberid,0) = 0
							break
						select @wrk_HCCModelYearID = min(TargetHCCModelYearID)from #RADVETLSuspect where RADVETLMemberID = @wrk_RADVETLMemberID
					end
			end

-- pivot #RADVETLSuspect
-- select * from #RADVETLSuspectPivot
		set @msg = 'pivoting #RADVETLSuspect'
		if @debug = 1
			begin
				exec dbo.messenger null, null, null, @procname, @msg, null, 'I'
			end		
		Insert into #RADVETLSuspectPivot (RADVETLMemberID, TargetHCCModelYearID, TargetICDCode1, TargetICDCode2,TargetICDCode3,
			TargetICDCode4,TargetICDCode5,TargetICDCode6,TargetICDCode7,TargetICDCode8,TargetICDCode9,TargetICDCode10,TargetICDCode11,
			TargetICDCode12,HierarchyApplied)
		SELECT RADVETLMemberID, TargetHCCModelYearID,[TargetICDCode1],[TargetICDCode2],[TargetICDCode3],
			[TargetICDCode4],[TargetICDCode5],[TargetICDCode6],[TargetICDCode7],[TargetICDCode8],[TargetICDCode9],[TargetICDCode10],[TargetICDCode11],
			[TargetICDCode12],HierarchyApplied
		from 
            (
                select 
					RADVETLMemberID,
					TargetHCCModelYearID,
					HierarchyApplied,	
                    TargetICDCode,
                    PivotColumn
                from #RADVETLSuspect 
              ) as x
				pivot 
				(
					min(TargetICDCode)
					for PivotColumn in ([TargetICDCode1],[TargetICDCode2],[TargetICDCode3],[TargetICDCode4],[TargetICDCode5],[TargetICDCode6],[TargetICDCode7],[TargetICDCode8],[TargetICDCode9],[TargetICDCode10],[TargetICDCode11],[TargetICDCode12])
				) as p 

-- TFS26365 Truncate RADVMember table
		set @msg = 'truncating RADVMember'
		if @debug = 1
			begin
				exec dbo.messenger null, null, null, @procname, @msg, null, 'I'
			end	
		truncate table RADVMember
--Insert Parent records.  Hard coded values are just temporary per Kosta.  SCC comes from member demographics table.  PBP comes from PBPs table.
-- TFS26365 Removed join on RADVMember
		set @msg = 'inserting parent records'
		if @debug = 1
			begin
				exec dbo.messenger null, null, null, @procname, @msg, null, 'I'
			end		
		insert into dbo.RADVMember 
			(HICN, MemberFirstName, MemberLastName, MemberDOB, RADVPlanName, RADVYear, CurrentPlanName, PBP, SCC, 
			 SubProjectID, RAFactorType, RBBHIC, MAOrgName, MaskedH#, EnrolleeID, SubProjectDescription)
		select  
			etlm.HICN, etlm.MemberFirstName, etlm.MemberLastName, etlm.MemberDOB, etlm.RADVContractID, etlm.RADVYear, etlm.CurrentContractID, etlm.PBP, etlm.SCC, 
			etlm.SubProjectID, etlm.RAFactorType, etlm.EnrolleeRRBHIC, etlm.MAOrgName, etlm.MaskedH#, etlm.EnrolleeID, etlm.SubProjectDescription
		from #RADVETLMember etlm
		
-- TFS26365 Truncate RADVMemberDetail table
		set @msg = 'truncating RADVMemberDetail'
		if @debug = 1
			begin
				exec dbo.messenger null, null, null, @procname, @msg, null, 'I'
			end	
		truncate table RADVMemberDetail		
-- Insert new Detail records
-- TFS10235 Changed PlanProviderID to come from #RADVETLCodingDetail
-- TFS26365 Added ProviderTypeDescription and Comments.
		set @msg = 'inserting detail records'
		if @debug = 1
			begin
				exec dbo.messenger null, null, null, @procname, @msg, null, 'I'
			end		
		insert into dbo.RADVMemberDetail 
			(RADVMemberID, ProviderNumber, SubProjectMedicalRecordID, SPMRLastUpdateDateTime, SPMRStatusID, MedicalRecordRequestID,
			 MRRLastUpdateDateTime, ImageID, ImageWorkflowStatusID, ImageLastUpdateDateTime, ImageFilePath, ImageFailureIssueID,
			 ImageFailureDescription, ImageReviewStepID, StartPage, EndPage, DOSStart, DOSEnd, ProviderTypeCd, ProviderTypeDescription, ICDCode, ICDVersion, 
			 HCCCode, HCCPartID, CodingDiagnosisID, DateCoded, CodingStatusID, CodingReviewStepID, DiagnosisErrorID, 
			 DOSErrorID, AttestationReceivedDate, Comments)
		select distinct
			rm.ID, etlcd.PlanProviderID, etld.SubProjectMedicalRecordID, etld.SPMRLogDate, etld.SPMRStatusID, etld.MedicalRecordRequestID,
			etld.MRRLastUpdateDateTime, etld.MedicalRecordImageID, etld.MedicalRecordImageWorkflowStatusID, etld.ImageLastUpdateDateTime, etld.ImageFilePath, etlcd.ImageFailureIssueID,
			etlcd.ImageFailureDescription, etlcd.ImageReviewStepID, etlcd.StartPage, etlcd.EndPage, etlcd.DOSStart, etlcd.DOSEnd, etlcd.ProviderTypeCD, etlcd.ProviderTypeDescription, 
			etlcd.ICDCode, etlcd.ICDVersion, etlcd.HCCNumber, etlcd.HCCPartID, etlcd.CodingDiagnosisID, etlcd.DateCoded, etlcd.DiagnosisStatusID, etlcd.ImageReviewStepID, etlcd.DiagnosisErrorID, 
			etlcd.DOSErrorID, etlcd.AttestationReceivedDate, etlcd.Comments
		-- select rmd.* 	
		from 
			#RADVETLMember etlm
			join #RADVETLDetail etld on etld.RADVETLMemberID = etlm.ID
			left outer join #RADVETLCodingDetail etlcd on etlcd.RADVETLDetailID = etld.ID
			join dbo.RADVMember rm on etlm.HICN = rm.HICN  and etlm.SubProjectID = rm.SubProjectID
-- TFS26365 Truncate RADVMemberSuspect table
		set @msg = 'truncating RADVMemberSuspect'
		if @debug = 1
			begin
				exec dbo.messenger null, null, null, @procname, @msg, null, 'I'
			end	
		truncate table RADVMemberSuspect
-- Insert Suspect records	
		set @msg = ' inserting suspect records'
		if @debug = 1
			begin
				exec dbo.messenger null, null, null, @procname, @msg, null, 'I'
			end		
		Insert into dbo.RADVMemberSuspect
			(RADVMemberID, TargetHCCNumber, TargetICDCode1, TargetICDCode2, TargetICDCode3, TargetICDCode4, TargetICDCode5
			, TargetICDCode6, TargetICDCode7, TargetICDCode8, TargetICDCode9, TargetICDCode10, TargetICDCode11, TargetICDCode12
			, HierarchyApplied
			)	
		select 
			rm.ID, etlsp.TargetHCCModelYearID, etlsp.TargetICDCode1, etlsp.TargetICDCode2, etlsp.TargetICDCode3, etlsp.TargetICDCode4, etlsp.TargetICDCode5,
			etlsp.TargetICDCode6, etlsp.TargetICDCode7, etlsp.TargetICDCode8, etlsp.TargetICDCode9, etlsp.TargetICDCode10, etlsp.TargetICDCode11, etlsp.TargetICDCode12,
			etlsp.HierarchyApplied
		from 
			#RADVETLMember etlm			
			join #RADVETLSuspectPivot etlsp on etlsp.RADVETLMemberID = etlm.ID	
			join dbo.RADVMember rm on etlm.HICN = rm.HICN 
				and etlm.SubProjectID = rm.SubProjectID
			
		set @msg = 'dropping Client Staging synonyms'
		if @debug = 1
			begin
				exec dbo.messenger null, null, null, @procname, @msg, null, 'I'
			end		
		if exists (select * from sys.synonyms where name = N'syn_RADVMemberStage')
			drop synonym dbo.syn_RADVMemberStage					
		if exists (select * from sys.synonyms where name = N'syn_RADVMemberDetailStage')
			drop synonym dbo.syn_RADVMemberDetailStage	
		if exists (select * from sys.synonyms where name = N'syn_RADVMemberSuspectStage')
			drop synonym dbo.syn_RADVMemberSuspectStage	
		if exists (select * from sys.synonyms where name = N'syn_RADVMemberCodingDetailStage')	
			drop synonym dbo.syn_RADVMemberCodingDetailStage				

	END TRY
	
	BEGIN CATCH

		if exists (select * from sys.synonyms where name = N'syn_RADVMemberStage')
			drop synonym dbo.syn_RADVMemberStage					
		if exists (select * from sys.synonyms where name = N'syn_RADVMemberDetailStage')
			drop synonym dbo.syn_RADVMemberDetailStage	
		if exists (select * from sys.synonyms where name = N'syn_RADVMemberSuspectStage')
			drop synonym dbo.syn_RADVMemberSuspectStage	
		if exists (select * from sys.synonyms where name = N'syn_RADVMemberCodingDetailStage')	
			drop synonym dbo.syn_RADVMemberCodingDetailStage	
	
		set @msg = 'Failed ' + @msg
		exec dbo.messenger null, null, @SubProjectID, @procname, @msg, null, 'E'
	
	END CATCH