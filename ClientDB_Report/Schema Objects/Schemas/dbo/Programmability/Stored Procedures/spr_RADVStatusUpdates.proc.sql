/*
Author:			Dianne Barba, Steve Walker
TFS Request:	17141	
Description:	Updates the RADVStatusID in [Client}_Report
Create date:	12/20/2013

exec dbo.spr_RADVStatusUpdates 2011, 'HRPSTGDB002', 'Excellus_CN_ClientLevel', 'Excellus_Report' , 1

Modifications:
	04/03/14 TFS26365 Added HCCs from RADVMemberSuspect table to #Hierarchy

*/

CREATE procedure [dbo].[spr_RADVStatusUpdates]
(
	@PaymentYear int = 2011,
	@CNServerName varchar (50) = '',
	@ClientDBName varchar(50),
	@ReportDBName varchar(50),
	@debug bit = 0	
)
as
	declare @msg varchar(200)
	declare @nsql nvarchar(max)
	declare @sql varchar(max)
	declare @Y_statusID int
	declare @HY_statusID int
	declare @LY_statusID int
	declare @S_statusID int
	declare @HS_statusID int
	declare @LS_statusID int
	declare @CN_statusID int
	declare @N_statusID int
	declare @INP_statusID int
	declare @NC_statusID int
	declare @NW_statusID int
	declare @procname varchar(100)
	
	begin try

-- get proc name
		set @procname = OBJECT_NAME(@@PROCID)			
	
-- Drop / create synonyms for reporting tables	
		set @msg = 'dropping synonyms'	
		if @debug = 1
			begin
				exec dbo.messenger null, null, null, @procname, @msg, null, 'I'
			end
		if exists (select * from sys.synonyms where name = N'syn_DiagnosisIssueTypes')
			drop synonym dbo.syn_DiagnosisIssueTypes
		if exists (select * from sys.synonyms where name = N'syn_DateOfServiceIssueTypes')
			drop synonym dbo.syn_DateOfServiceIssueTypes		
		if exists (select * from sys.synonyms where name = N'syn_DiagnosisDateOfServiceIssues')
			drop synonym dbo.syn_DiagnosisDateOfServiceIssues	
		if exists (select * from sys.synonyms where name = N'syn_DiagnosisCodingErrors')
			drop synonym dbo.syn_DiagnosisCodingErrors										
				
		set @msg = 'creating synonyms'
		set @sql = 'create synonym dbo.syn_DiagnosisIssueTypes for ' + @CNServerName + '.' + @ClientDBName + '.dbo.DiagnosisIssueTypes'
		exec(@sql)	
		set @sql = 'create synonym dbo.syn_DateOfServiceIssueTypes for ' + @CNServerName + '.' + @ClientDBName + '.dbo.DateOfServiceIssueTypes'
		exec(@sql)
		set @sql = 'create synonym dbo.syn_DiagnosisDateOfServiceIssues for ' + @CNServerName + '.' + @ClientDBName + '.dbo.DiagnosisDateOfServiceIssues'
		exec(@sql)
		set @sql = 'create synonym dbo.syn_DiagnosisCodingErrors for ' + @CNServerName + '.' + @ClientDBName + '.dbo.DiagnosisCodingErrors'
		exec(@sql)		
	
----Reset all statuses to NULL
		set @msg = 'setting RADVStatusIDs to null'
		if @debug = 1
			begin
				exec dbo.messenger null, null, null, @procname, @msg, null, 'I'
			end		
		update rmd
		set RADVStatusID = null
		from dbo.RADVMemberDetail rmd with (rowlock)

--Create Hierarchy table to compare Suspect and Coded HCCs
		set @msg = 'dropping/creating #Hierarchy'
		if @debug = 1
			begin
				exec dbo.messenger null, null, null, @procname, @msg, null, 'I'
			end		
		if OBJECT_ID('tempdb..#Hierarchy') is not null
			drop table #Hierarchy
			
		create table #Hierarchy
		(
			ID int identity primary key,
			SuspectHCC varchar(50),
			CodedHCC varchar(50),
			ConfirmedStatus char(1)
		)	

-- Populate Hierarchy table
		set @msg = 'populating #Hierarchy'
		if @debug = 1
			begin
				exec dbo.messenger null, null, null, @procname, @msg, null, 'I'
			end		
		insert into #Hierarchy ( SuspectHCC, CodedHCC, ConfirmedStatus)
		select distinct HCC_KEEP_NUMBER, HCC_DROP_NUMBER, 'L'
		from [$(HRPReporting)].dbo.lk_Hierarchy_PartC
		where Payment_Year = @PaymentYear
		union
		select distinct HCC_DROP_NUMBER, HCC_KEEP_NUMBER, 'H'
		from [$(HRPReporting)].dbo.lk_Hierarchy_PartC
		where Payment_Year = @PaymentYear
		union
		select distinct HCC_KEEP_NUMBER, HCC_KEEP_NUMBER, 'E'
		from [$(HRPReporting)].dbo.lk_Hierarchy_PartC
		where Payment_Year = @PaymentYear
		union
		select distinct HCC_DROP_NUMBER, HCC_DROP_NUMBER, 'E'
		from [$(HRPReporting)].dbo.lk_Hierarchy_PartC
		where Payment_Year = @PaymentYear
		union
		select distinct targetHCCNumber, targetHCCNumber, 'E'
		from radvmembersuspect
		-- select * from #hierarchy
		if @@ROWCOUNT = 0
			begin
				raiserror(@msg, 16, 1)
			end
		
-- Populate status ID variables
		set @msg = 'retrieving status IDs'
		if @debug = 1
			begin
				exec dbo.messenger null, null, null, @procname, @msg, null, 'I'
			end		
		select @Y_statusID	= ID from dbo.RADVMemberStatuses where RADVStatusCode = 'Y'
		select @HY_statusID = ID from dbo.RADVMemberStatuses where RADVStatusCode = 'HY'		
		select @LY_statusID = ID from dbo.RADVMemberStatuses where RADVStatusCode = 'LY'		
		select @S_statusID	= ID from dbo.RADVMemberStatuses where RADVStatusCode = 'S'	
		select @HS_statusID = ID from dbo.RADVMemberStatuses where RADVStatusCode = 'HS'		
		select @LS_statusID = ID from dbo.RADVMemberStatuses where RADVStatusCode = 'LS'	
		select @CN_statusID = ID from dbo.RADVMemberStatuses where RADVStatusCode = 'CN'	
		select @N_statusID	= ID from dbo.RADVMemberStatuses where RADVStatusCode = 'N'	
		select @INP_statusID = ID from dbo.RADVMemberStatuses where RADVStatusCode = 'INP'	
		select @NC_statusID = ID from dbo.RADVMemberStatuses where RADVStatusCode = 'NC'
		select @NW_statusID = ID from dbo.RADVMemberStatuses where RADVStatusCode = 'NW'	
		
-- Status Confirmed and Equal
		set @msg = 'updating status to confirmed and equal'
		if @debug = 1
			begin
				exec dbo.messenger null, null, null, @procname, @msg, null, 'I'
			end		
		update rmd
			set RADVStatusID = @Y_statusID  -- select *
		from 
			dbo.RADVMember m
			join dbo.RADVMemberDetail rmd on m.ID = rmd.RADVMemberID
			join dbo.RADVMemberSuspect rms on m.ID = rms.RADVMemberID
			join #Hierarchy h on rms.TargetHCCNumber = h.SuspectHCC and rmd.HCCCode = h.CodedHCC
            LEFT OUTER JOIN syn_DiagnosisDateOfServiceIssues AS DDSI  (NOLOCK) ON DDSI.ID = rmd.DOSErrorID
            LEFT OUTER JOIN syn_DateOfServiceIssueTypes AS DSIT  (NOLOCK) ON DSIT.ID = DDSI.DateOfServiceIssueTypeID
            LEFT OUTER JOIN syn_DiagnosisCodingErrors AS DCE  (NOLOCK) ON DCE.ID = rmd.DiagnosisErrorID
            LEFT OUTER JOIN syn_DiagnosisIssueTypes AS DIT  (NOLOCK) ON DIT.ID = DCE.DiagnosisIssueTypeID
		where 
			( (rmd.DiagnosisErrorID is null and rmd.DOSErrorID is null and rmd.ImageFailureIssueID is null)
			or
			( (dit.FailureReason in ('Sig/Auth Missing','Unable to Determine Provider','Cred/Printed Name Missing')			
				or dsit.FailureReason in ('Sig/Auth Missing','Unable to Determine Provider','Cred/Printed Name Missing'))
			and rmd.AttestationReceivedDate is not null )
			)
			and rmd.RADVStatusID is null
			and rmd.ImageWorkflowStatusID = 20
			and h.ConfirmedStatus = 'E' 
		
-- Status Confirmed and Higher
		set @msg = 'updating status to confirmed and higher'
		if @debug = 1
			begin
				exec dbo.messenger null, null, null, @procname, @msg, null, 'I'
			end		
		update rmd
			set RADVStatusID = @HY_statusID -- select rmd.*
		from 
			dbo.RADVMember m
			join dbo.RADVMemberDetail rmd on m.ID = rmd.RADVMemberID
			join dbo.RADVMemberSuspect rms on m.ID = rms.RADVMemberID
			join #Hierarchy h on rms.TargetHCCNumber = h.SuspectHCC and rmd.HCCCode = h.CodedHCC
            LEFT OUTER JOIN syn_DiagnosisDateOfServiceIssues AS DDSI  (NOLOCK) ON DDSI.ID = rmd.DOSErrorID
            LEFT OUTER JOIN syn_DateOfServiceIssueTypes AS DSIT  (NOLOCK) ON DSIT.ID = DDSI.DateOfServiceIssueTypeID
            LEFT OUTER JOIN syn_DiagnosisCodingErrors AS DCE  (NOLOCK) ON DCE.ID = rmd.DiagnosisErrorID
            LEFT OUTER JOIN syn_DiagnosisIssueTypes AS DIT  (NOLOCK) ON DIT.ID = DCE.DiagnosisIssueTypeID
		where
			((rmd.DiagnosisErrorID is null and rmd.DOSErrorID is null)
			or
			((dit.FailureReason IN ('Sig/Auth Missing','Unable to Determine Provider','Cred/Printed Name Missing')
			   or dsit.FailureReason IN ('Sig/Auth Missing','Unable to Determine Provider','Cred/Printed Name Missing'))
			  and rmd.AttestationReceivedDate is not null))
			and rmd.RADVStatusID is null			  
			and rmd.ImageWorkflowStatusID = 20 
			and  h.ConfirmedStatus = 'H'


-- Status Confirmed and Lower
		set @msg = 'updating status to confirmed and lower'
		if @debug = 1
			begin
				exec dbo.messenger null, null, null, @procname, @msg, null, 'I'
			end		
		update rmd
			set RADVStatusID = @LY_statusID -- select rmd.*
		from 
			dbo.RADVMember m
			join dbo.RADVMemberDetail rmd on m.ID = rmd.RADVMemberID
			join dbo.RADVMemberSuspect rms on m.ID = rms.RADVMemberID
			join #Hierarchy h on rms.TargetHCCNumber = h.SuspectHCC and rmd.HCCCode = h.CodedHCC
            LEFT OUTER JOIN syn_DiagnosisDateOfServiceIssues AS DDSI  (NOLOCK) ON DDSI.ID = rmd.DOSErrorID
            LEFT OUTER JOIN syn_DateOfServiceIssueTypes AS DSIT  (NOLOCK) ON DSIT.ID = DDSI.DateOfServiceIssueTypeID
            LEFT OUTER JOIN syn_DiagnosisCodingErrors AS DCE  (NOLOCK) ON DCE.ID = rmd.DiagnosisErrorID
            LEFT OUTER JOIN syn_DiagnosisIssueTypes AS DIT  (NOLOCK) ON DIT.ID = DCE.DiagnosisIssueTypeID
		where
			((rmd.DiagnosisErrorID is null and rmd.DOSErrorID is null)
			or
			((dit.FailureReason IN ('Sig/Auth Missing','Unable to Determine Provider','Cred/Printed Name Missing')
			   or dsit.FailureReason IN ('Sig/Auth Missing','Unable to Determine Provider','Cred/Printed Name Missing'))
			  and rmd.AttestationReceivedDate is not null))
			and rmd.RADVStatusID is null			  
			and rmd.ImageWorkflowStatusID = 20 
			and h.ConfirmedStatus = 'L'
 
-- Status Confirmed and Equal, needing Att
		set @msg = 'updating status to confirmed and equal, needing attention'
		if @debug = 1
			begin
				exec dbo.messenger null, null, null, @procname, @msg, null, 'I'
			end		
		update rmd
			set RADVStatusID = @S_statusID -- select *
		from 
			dbo.RADVMember m
			join dbo.RADVMemberDetail rmd on m.ID = rmd.RADVMemberID
			join dbo.RADVMemberSuspect rms on m.ID = rms.RADVMemberID
			join #Hierarchy h on rms.TargetHCCNumber = h.SuspectHCC and rmd.HCCCode = h.CodedHCC
            LEFT OUTER JOIN syn_DiagnosisDateOfServiceIssues AS DDSI  (NOLOCK) ON DDSI.ID = rmd.DOSErrorID
            LEFT OUTER JOIN syn_DateOfServiceIssueTypes AS DSIT  (NOLOCK) ON DSIT.ID = DDSI.DateOfServiceIssueTypeID
            LEFT OUTER JOIN syn_DiagnosisCodingErrors AS DCE  (NOLOCK) ON DCE.ID = rmd.DiagnosisErrorID
            LEFT OUTER JOIN syn_DiagnosisIssueTypes AS DIT  (NOLOCK) ON DIT.ID = DCE.DiagnosisIssueTypeID
		where
			((dit.FailureReason in ('Sig/Auth Missing','Unable to Determine Provider','Cred/Printed Name Missing')			
				or dsit.FailureReason in ('Sig/Auth Missing','Unable to Determine Provider','Cred/Printed Name Missing'))
			and rmd.AttestationReceivedDate is null)
			and rmd.RADVStatusID is null			
			and rmd.ImageWorkflowStatusID = 20 
			and h.ConfirmedStatus = 'E'
		
-- Status Confirmed and Higher needing Att
		set @msg = 'updating status to confirmed and higher needing attention'
		if @debug = 1
			begin
				exec dbo.messenger null, null, null, @procname, @msg, null, 'I'
			end		
		update rmd
			set RADVStatusID = @HS_statusID -- select *
		from 
			dbo.RADVMember m
			join dbo.RADVMemberDetail rmd on m.ID = rmd.RADVMemberID
			join dbo.RADVMemberSuspect rms on m.ID = rms.RADVMemberID
			join #Hierarchy h on rms.TargetHCCNumber = h.SuspectHCC and rmd.HCCCode = h.CodedHCC
            LEFT OUTER JOIN syn_DiagnosisDateOfServiceIssues AS DDSI  (NOLOCK) ON DDSI.ID = rmd.DOSErrorID
            LEFT OUTER JOIN syn_DateOfServiceIssueTypes AS DSIT  (NOLOCK) ON DSIT.ID = DDSI.DateOfServiceIssueTypeID
            LEFT OUTER JOIN syn_DiagnosisCodingErrors AS DCE  (NOLOCK) ON DCE.ID = rmd.DiagnosisErrorID
            LEFT OUTER JOIN syn_DiagnosisIssueTypes AS DIT  (NOLOCK) ON DIT.ID = DCE.DiagnosisIssueTypeID
		where
			((dit.FailureReason in ('Sig/Auth Missing','Unable to Determine Provider','Cred/Printed Name Missing')			
				or dsit.FailureReason in ('Sig/Auth Missing','Unable to Determine Provider','Cred/Printed Name Missing'))
			and rmd.AttestationReceivedDate is null)
			and rmd.RADVStatusID is null			
			and rmd.ImageWorkflowStatusID = 20 
			and h.ConfirmedStatus = 'H'			

-- Status Confirmed and Lower needing Att
		set @msg = 'updating status to confirmed and lower needing attention'
		if @debug = 1
			begin
				exec dbo.messenger null, null, null, @procname, @msg, null, 'I'
			end		
		update rmd
			set RADVStatusID = @LS_statusID -- select *
		from 
			dbo.RADVMember m
			join dbo.RADVMemberDetail rmd on m.ID = rmd.RADVMemberID
			join dbo.RADVMemberSuspect rms on m.ID = rms.RADVMemberID
			join #Hierarchy h on rms.TargetHCCNumber = h.SuspectHCC and rmd.HCCCode = h.CodedHCC
            LEFT OUTER JOIN syn_DiagnosisDateOfServiceIssues AS DDSI  (NOLOCK) ON DDSI.ID = rmd.DOSErrorID
            LEFT OUTER JOIN syn_DateOfServiceIssueTypes AS DSIT  (NOLOCK) ON DSIT.ID = DDSI.DateOfServiceIssueTypeID
            LEFT OUTER JOIN syn_DiagnosisCodingErrors AS DCE  (NOLOCK) ON DCE.ID = rmd.DiagnosisErrorID
            LEFT OUTER JOIN syn_DiagnosisIssueTypes AS DIT  (NOLOCK) ON DIT.ID = DCE.DiagnosisIssueTypeID
		where
			((dit.FailureReason in ('Sig/Auth Missing','Unable to Determine Provider','Cred/Printed Name Missing')			
				or dsit.FailureReason in ('Sig/Auth Missing','Unable to Determine Provider','Cred/Printed Name Missing'))
			and rmd.AttestationReceivedDate is null)
			and rmd.RADVStatusID is null				
			and rmd.ImageWorkflowStatusID = 20 
			and h.ConfirmedStatus = 'L' 					
					
-- Status Failed, Error Reading Chart
		set @msg = 'updating status to failed, error reading chart'
		if @debug = 1
			begin
				exec dbo.messenger null, null, null, @procname, @msg, null, 'I'
			end		
		update rmd
			set RADVStatusID = @CN_statusID  -- select *
		from 
			dbo.RADVMember m
			join dbo.RADVMemberDetail rmd on m.ID = rmd.RADVMemberID
			--join dbo.RADVMemberSuspect rms on m.ID = rms.RADVMemberID
			--join #Hierarchy h on rms.TargetHCCNumber = h.SuspectHCC and rmd.HCCCode = h.SuspectHCC
			--left outer join coventry_cn_clientlevel.dbo.DiagnosisIssueTypes dit on rmd.DiagnosisErrorID = dit.ID 
			--left outer join coventry_cn_clientlevel.dbo.DateOfServiceIssueTypes dsit on rmd.DOSErrorID = dsit.ID
		where 
			rmd.ImageWorkflowStatusID = 16
			and rmd.RADVStatusID is null
				
-- Status Complete and Failed with errors
		set @msg = 'updating status to complete and failed with errors'
		if @debug = 1
			begin
				exec dbo.messenger null, null, null, @procname, @msg, null, 'I'
			end		
		update rmd
			set RADVStatusID = @N_statusID  -- select *
		from
			dbo.RADVMember m
			join dbo.RADVMemberDetail rmd on m.ID = rmd.RADVMemberID
			join dbo.RADVMemberSuspect rms on m.ID = rms.RADVMemberID
			join #Hierarchy h on rms.TargetHCCNumber = h.SuspectHCC and rmd.HCCCode = h.CodedHCC
            LEFT OUTER JOIN syn_DiagnosisDateOfServiceIssues AS DDSI  (NOLOCK) ON DDSI.ID = rmd.DOSErrorID
            LEFT OUTER JOIN syn_DateOfServiceIssueTypes AS DSIT  (NOLOCK) ON DSIT.ID = DDSI.DateOfServiceIssueTypeID
            LEFT OUTER JOIN syn_DiagnosisCodingErrors AS DCE  (NOLOCK) ON DCE.ID = rmd.DiagnosisErrorID
            LEFT OUTER JOIN syn_DiagnosisIssueTypes AS DIT  (NOLOCK) ON DIT.ID = DCE.DiagnosisIssueTypeID
		where			
			(
			(dit.FailureReason not in ('Sig/Auth Missing','Unable to Determine Provider','Cred/Printed Name Missing')
				and rmd.DiagnosisErrorID is not null)
			or
			(dsit.FailureReason not in ('Sig/Auth Missing','Unable to Determine Provider','Cred/Printed Name Missing')
				and rmd.DOSErrorID is not null)
			or
			rmd.ImageFailureIssueID is not null
			)
			and rmd.RADVStatusID is null			
			and rmd.ImageWorkflowStatusID = 20

-- Status Coding in progress or not started
		set @msg = 'updating status to coding in progress or not started'
		if @debug = 1
			begin
				exec dbo.messenger null, null, null, @procname, @msg, null, 'I'
			end		
		update rmd
			set RADVStatusID = @INP_statusID  -- select *
		from
			dbo.RADVMember m
			join dbo.RADVMemberDetail rmd on m.ID = rmd.RADVMemberID
			join dbo.RADVMemberSuspect rms on m.ID = rms.RADVMemberID
			left join #Hierarchy h on rms.TargetHCCNumber = h.SuspectHCC and rmd.HCCCode = h.CodedHCC
		where
			rmd.RADVStatusID is null
			and (rmd.ImageWorkflowStatusID = 15 or (rmd.ImageWorkFlowStatusID = 17 and h.SuspectHCC is not null))
			
			
-- Status No chart 
		set @msg = 'updading status to no chart'
		if @debug = 1
			begin
				exec dbo.messenger null, null, null, @procname, @msg, null, 'I'
			end		
		update rmd
			set RADVStatusID = @NC_statusID
		from
			dbo.RADVMemberDetail rmd
		where rmd.ImageID is null and rmd.RADVStatusID is null
		
-- Status New HCC 
		set @msg = 'updading status to new HCC'
		if @debug = 1
			begin
				exec dbo.messenger null, null, null, @procname, @msg, null, 'I'
			end		
		update rmd
			set RADVStatusID = @NW_statusID  -- select *
		from
			dbo.RADVMemberDetail rmd
			inner join dbo.RADVMemberSuspect rms 
				on rmd.RADVMemberID = rms.RADVMemberID
			left outer join #Hierarchy h 
				on rms.TargetHCCNumber = h.SuspectHCC and rmd.HCCCode = h.CodedHCC	
			where h.SuspectHCC is null and rmd.RADVStatusID is null
			
/* original code
		-- select *
		from
			dbo.RADVMemberDetail rmd
		
		where not exists (select 1
				from 
					dbo.RADVMemberSuspect rms
					inner join dbo.RADVMemberDetail rmd2 ON rms.RADVMemberID = rmd2.RADVMemberID 
					inner join #Hierarchy h on rms.TargetHCCNumber = h.SuspectHCC and rmd.HCCCode = h.CodedHCC
				WHERE rmd.ID = rmd2.ID )
		and rmd.HCCCode is not null
*/		
		
		set @msg = '- end of proc - dropping synonyms'	
		if @debug = 1
			begin
				exec dbo.messenger null, null, null, @procname, @msg, null, 'I'
			end		
		if exists (select * from sys.synonyms where name = N'syn_DiagnosisIssueTypes')
			drop synonym dbo.syn_DiagnosisIssueTypes
		if exists (select * from sys.synonyms where name = N'syn_DateOfServiceIssueTypes')
			drop synonym dbo.syn_DateOfServiceIssueTypes		
		if exists (select * from sys.synonyms where name = N'syn_DiagnosisDateOfServiceIssues')
			drop synonym dbo.syn_DiagnosisDateOfServiceIssues	
		if exists (select * from sys.synonyms where name = N'syn_DiagnosisCodingErrors')
			drop synonym dbo.syn_DiagnosisCodingErrors				
				
	end try
	begin catch
		if exists (select * from sys.synonyms where name = N'syn_DiagnosisIssueTypes')
			drop synonym dbo.syn_DiagnosisIssueTypes
		if exists (select * from sys.synonyms where name = N'syn_DateOfServiceIssueTypes')
			drop synonym dbo.syn_DateOfServiceIssueTypes	
		if exists (select * from sys.synonyms where name = N'syn_DiagnosisDateOfServiceIssues')
			drop synonym dbo.syn_DiagnosisDateOfServiceIssues	
		if exists (select * from sys.synonyms where name = N'syn_DiagnosisCodingErrors')
			drop synonym dbo.syn_DiagnosisCodingErrors				
		set @msg = 'Failed ' + @msg
		exec dbo.messenger null, null, null, @procname, @msg, null, 'E'
	end catch