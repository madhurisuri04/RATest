/*
Author:	Dianne Barba
TFS Request:  17141	
Description:	Updates the Member Months
Create date:	12/23/2013

exec dbo.spr_RADVMemberMonths 2011, 'HRPDEVDB01', 'MVP_CN_ClientLevel', 'MVP_Report'

Modifications:

*/

create procedure spr_RADVMemberMonths
(
	@PaymentYear int = 2011, 
	@CNServerName varchar (50) = '',
	@ClientDBName varchar(50),
	@ReportDBName varchar(50),
	@debug bit = 0	
)
as

	declare @msg varchar(200)
	declare @sql varchar(max)
	declare @nsql nvarchar(max)	
	declare @procname varchar(100)
	
	begin try
	
-- get proc name
		set @procname = OBJECT_NAME(@@PROCID)	

-- Create temp table to hold member month data from Reporting
		set @msg = 'creating #RADVETLMemberMonths'  
		if @debug = 1
			begin
				exec dbo.messenger null, null, null, @procname, @msg, null, 'I'
			end		
		if OBJECT_ID('tempdb..#RADVETLMemberMonths') is not null
			drop table #RADVETLMemberMonths
			
		Create table #RADVETLMemberMonths
		(
			ID int identity primary key,
			RADVETLMemberID int,
			MemberMonths int
		)

-- Build Member Months data
		set @msg = 'building member months data'
		if @debug = 1
			begin
				exec dbo.messenger null, null, null, @procname, @msg, null, 'I'
			end		
		insert into #RADVETLMemberMonths
			(RADVETLMemberID, MemberMonths)
		select 
			etlm.ID, COUNT(month(m.PaymStart))			
		from 
			RADVMember etlm
			join dbo.tbl_Member_Months_rollup m on etlm.HICN = m.HICN
		where
			YEAR(m.PaymStart) = @paymentyear
		group by etlm.ID

-- update Member data with member months
		set @msg = 'updating MemberMonths'	
		if @debug = 1
			begin
				exec dbo.messenger null, null, null, @procname, @msg, null, 'I'
			end			
		update etlm
			set MemberMonths = mm.MemberMonths 
		from 
			dbo.RADVMember etlm
			join #RADVETLMemberMonths mm
				on etlm.ID = mm.RADVETLMemberID
			
	end try
	begin catch
		set @msg = 'Failed ' + @msg
		exec dbo.messenger null, null, null, @procname, @msg, null, 'E'
	end catch
		