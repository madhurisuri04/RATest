/*
Author:			Dianne Barba
TFS Request:	17141
Description:	Updates the RADVMember BidAmount	
Create date:	12/24/2013

exec dbo.spr_RADVBidAmount 2011, 'HRPDEVDB01', 'MVP_CN_ClientLevel', 'MVP_Report'
exec dbo.spr_RADVBidAmount 2011, 'HRPSTGDB001', 'Excellus_CN_ClientLevel', 'Excellus_Report'

Modifications:
	03/31/14 TFS26365 DMB Changed how the BID amount was being determined.  This is a quick
						  and dirty fix for Excellus.  A more graceful way will be figured
						  out later on.


*/

CREATE procedure [dbo].[spr_RADVBidAmount]
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
	declare @procname varchar(100)	
	declare @ClientName varchar(100)	-- TFS26365
	declare @charpos int				-- TFS26365
	declare @rollupPlanID varchar(10)	-- TFS26365
	declare @planDBName varchar(100)	-- TFS26365
	
	begin try
	
-- initialize variables
		set @procname = OBJECT_NAME(@@PROCID)	
		select @charpos = charindex('_',@ClientDBName)
		select @ClientName = substring(@ClientDBName,1,@charpos-1)
		select @rollupPlanID = x.radvplanname from
		(
			select distinct RADVPlanName from dbo.RADVMember as radvplanname
		) as x
		set @planDBName = @ClientName + '_' + @rollupPlanID
		
-- Drop / create synonyms for reporting and client level tables	
		set @msg = 'dropping synonyms'
		if @debug = 1
			begin
				exec dbo.messenger null, null, null, @procname, @msg, null, 'I'
			end		
		if exists (select * from sys.synonyms where name = N'syn_tbl_BIDS')
			drop synonym dbo.syn_tbl_BIDS
			
		set @msg = 'creating synonyms'
		set @sql = 'create synonym dbo.syn_tbl_BIDS for ' + @planDBName + '.dbo.tbl_BIDS'
		exec(@sql)

-- update Member data with Bid amount
		set @msg = 'updating BidAmount'
		if @debug = 1
			begin
				exec dbo.messenger null, null, null, @procname, @msg, null, 'I'
			end		
		update m
			set BidAmount = b.MA_BID 
		-- select * 	
		from syn_tbl_BIDS b
			join dbo.RADVMember m 
				on --p.ContractNumber = m.RADVPlanName
				--and 
				m.PBP = b.PBP and m.SCC = b.SCC
		where b.Bid_Year = @PaymentYear
		and b.PlanID = @rollupPlanID
			and BidAmount is null
			
		set @msg = '- end of proc - dropping synonyms'
		if @debug = 1
			begin
				exec dbo.messenger null, null, null, @procname, @msg, null, 'I'
			end		
		if exists (select * from sys.synonyms where name = N'syn_tbl_BIDS')
			drop synonym dbo.syn_tbl_BIDS
		
	end try
	begin catch
		if exists (select * from sys.synonyms where name = N'syn_tbl_BIDS')
			drop synonym dbo.syn_tbl_BIDS
			
		set @msg = 'Failed ' + @msg
		exec dbo.messenger null, null, null, @procname, @msg, null, 'E'
		
	end catch