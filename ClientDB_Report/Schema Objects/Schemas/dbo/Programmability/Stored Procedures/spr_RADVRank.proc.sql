/*
Author:			Dianne Barba
TFS Request:	17141	
Description:	Updates the RADVStatusID in [Client}_Report
Create date:	1/2/2014

exec dbo.spr_RADVRank 2011

Modifications:
	04/03/14 TFS26365 Added HCCs from RADVMemberSuspect table to #Hierarchy
	04/08/14 TFS26725 DMB Added code to force the translation of one HICN from alt value to CMS value		


*/
--alter procedure spr_RADVRank
CREATE procedure [dbo].[spr_RADVRank]
(
	@PaymentYear int,
	@debug bit = 0
)
as
	declare @msg varchar(200)
	declare @rowCnt int
	declare @curRow int
	declare @maxRow int
	declare @wrkRADVMemberID int
	declare @wrkHCCCode int
	declare @procname varchar(100)
	declare @wrkCreationDateTime datetime2
	
	begin try

-- get proc name
		set @procname = OBJECT_NAME(@@PROCID)		
		
-- get most recent ETL date
		select @wrkCreationDateTime = MAX(CreationDateTime) from dbo.RADVMemberDetail		
		
-- Reset all ranks to NULL for latest ETL run
		set @msg = 'setting RADVRank to null'
		if @debug = 1
			begin
				exec dbo.messenger null, null, null, @procname, @msg, null, 'I'
			end		
		update rmd
		set RADVRank = null
		from dbo.RADVMemberDetail rmd with (rowlock) where CreationDateTime = @wrkCreationDateTime

--Create Rank table 
		set @msg = 'dropping/creating #Rank'
		if @debug = 1
			begin
				exec dbo.messenger null, null, null, @procname, @msg, null, 'I'
			end		
		if OBJECT_ID('tempdb..#Rank') is not null
			drop table #Rank
			
		create table #Rank
		(
			ID int identity primary key,
			RADVStatusCodeID int,
			RADVStatusCode char(2),
			ProviderTypeCode char(2),
			RADVRank int
		)	

-- create #RADVMemberGroup table
		set @msg = 'dropping/creating #RADVMemberGroup'	
		if @debug = 1
			begin
				exec dbo.messenger null, null, null, @procname, @msg, null, 'I'
			end			
		if OBJECT_ID('tempdb..#RADVMemberGroup') is not null
			drop table #RADVMemberGroup
			
		create table #RADVMemberGroup
		(
			ID int identity primary key,
			RADVMemberID int,
			HCCCode int,
		)	

-- create #RADVMemberGroupDetail table
		set @msg = 'dropping/creating #RADVMemberGroupDetail'	
		if @debug = 1
			begin
				exec dbo.messenger null, null, null, @procname, @msg, null, 'I'
			end			
		if OBJECT_ID('tempdb..#RADVMemberGroupDetail') is not null
			drop table #RADVMemberGroupDetail
			
		create table #RADVMemberGroupDetail
		(
			ID int identity primary key,
			RADVMemberGroupID int,
			RADVMemberDetailID int,
			CodingDiagnosisID int,
			RADVStatusID int,
			ProviderTypeCD char(2),
			DOSStart datetime2,
			RADVRank int,
			RADVMemberHCCRank int			
		)			

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

-- Populate #Rank table
		set @msg = 'populating #Rank'
		if @debug = 1
			begin
				exec dbo.messenger null, null, null, @procname, @msg, null, 'I'
			end		
		insert into #Rank ( RADVStatusCodeID, RADVStatusCode, ProviderTypeCode,RADVRank)
		select rmr.RADVStatusCodeID, rms.RADVStatusCode, rmr.ProviderTypeCode, rmr.RADVRank from [dbo].[RADVMemberRank] rmr
		join [dbo].[RADVMemberStatuses] rms
			on rmr.RADVStatusCodeID = rms.ID
		-- select * from #rank
		select @rowCnt = @@ROWCOUNT
		if @rowCnt = 0
			begin
				set @msg = '- no records inserted into #Rank'
				raiserror(@msg, 16, 1)
			end			
			
-- Populate #RADVMemberGroup table
		set @msg = 'populating #RADVMemberGroup'
		if @debug = 1
			begin
				exec dbo.messenger null, null, null, @procname, @msg, null, 'I'
			end		
		insert into #RADVMemberGroup (RADVMemberID, HCCCode)
		select distinct s.RADVMemberID, s.TargetHCCNumber from dbo.RADVMemberDetail	d
		join dbo.RADVMemberSuspect s on d.RADVMemberID = s.RADVMemberID
		where d.CreationDateTime = @wrkCreationDateTime	
		-- select * from #RADVMemberGroup
		select @rowCnt = @@ROWCOUNT
		if @rowCnt = 0
			begin
				set @msg = '- no records inserted into #RADVMemberGroup'
				raiserror(@msg, 16, 1)
			end			

-- loop through #RADVMemberGroup and calculate the ranking for each member/HCC
		select @curRow = MIN(ID), @maxRow = MAX(ID) from #RADVMemberGroup
		while @curRow <= @maxRow
			begin
				select @wrkRADVMemberID = RADVMemberID, @wrkHCCCode = HCCCode from #RADVMemberGroup where ID = @curRow
				truncate table #RADVMemberGroupDetail
				set @msg = 'building #RADVMemberGroupDetail for RADVMemberID ' + CAST(@wrkRADVMemberID as varchar) + ', HCC ' + cast(@wrkHCCCode as varchar)
				if @debug = 1
					begin
						exec dbo.messenger null, null, null, @procname, @msg, null, 'I'
					end				
				insert into #RADVMemberGroupDetail 
					(RADVMemberGroupID,RADVMemberDetailID,CodingDiagnosisID,RADVStatusID,ProviderTypeCD,DOSStart, RADVRank, RADVMemberHCCRank)
					-- select * from #RADVMemberGroup
				select g.ID, rmd.ID, rmd.CodingDiagnosisID, rmd.RADVStatusID, rmd.ProviderTypeCd, rmd.DOSEnd, r.RADVRank, 
					ROW_NUMBER() over (order by r.RADVRank, RADVStatusID, CodingDiagnosisID, DOSEnd) as RADVMemberHCCRank
				from  #RADVMemberGroup g
				join dbo.RADVMemberDetail rmd
					on g.RADVMemberID = rmd.RADVMemberID
				join #Hierarchy h on 
					convert(varchar, g.HCCCode) = h.SuspectHCC and rmd.HCCCode = convert(varchar,h.CodedHCC)
				join dbo.RADVMemberRank r
					on r.RADVStatusCodeID = rmd.RADVStatusID
					and r.ProviderTypeCode = rmd.ProviderTypeCD
				where g.ID = @curRow   
					and rmd.CreationDateTime = @wrkCreationDateTime
				
				set @msg = 'updating RADVMemberID ' + CAST(@wrkRADVMemberID as varchar) + ', HCC ' + cast(@wrkHCCCode as varchar) + ' with rank' 		
				if @debug = 1
					begin
						exec dbo.messenger null, null, null, @procname, @msg, null, 'I'
					end		
				update rmd
				set RADVRank = RADVMemberHCCRank
				from #RADVMemberGroupDetail g
				join dbo.RADVMemberDetail rmd
					on g.RADVMemberDetailID = rmd.ID
				where rmd.CreationDateTime = @wrkCreationDateTime
				
				if @curRow = @maxRow
					break
				select @curRow = MIN(ID) from #RADVMemberGroup where ID > @curRow	
			end
			
		-- TFS26725 Force alt HICN back to CMS value
		set @msg = 'updating alt HICN back to CMS value'
		update	r 
		set HICN = '085144728D' from RADVMember r where HICN = '085144728B'
			
	end try
	begin catch
		set @msg = 'Failed ' + @msg
		exec dbo.messenger null, null, null, @procname, @msg, null, 'E'
	end catch