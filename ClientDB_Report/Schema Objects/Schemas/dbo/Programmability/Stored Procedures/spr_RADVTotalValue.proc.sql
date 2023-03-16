/*
Author:			Dianne Barba
TFS Request:	17141	
Description:	Caclulates the RADVMemberDetail TotalValue
Create date:	12/26/2013
Notes:			Prerequisites:
					1.  dbo.spr_RADVMemberMonths 
					2.  dbo.spr_RADVFactorType
					3.  dbo.spr_RADVBidAmount

exec dbo.spr_RADVTotalValue 0

Modifications:

*/

create procedure spr_RADVTotalValue
	(
		@debug bit = 0
	)
as

	declare @msg varchar(200)
	declare @procname varchar(100)
	declare @updatecnt int
	
	begin try		

-- update MemberDetail data for TotalValue
		if @debug = 1
			begin
				set @msg = 'Started updating TotalValue'
				exec dbo.messenger null, null, null, @procname, @msg, null, 'I'
			end	
		set @msg = 'updating TotalValue'			
		update rmd
			set TotalValue = isnull(rm.MemberMonths,0) * isnull(rm.BidAmount,0) * isnull(rmd.FactorValue,0)
		from 
			dbo.RADVMemberDetail rmd
			join dbo.RADVMember rm
				on rmd.RADVMemberID = rm.ID

		select @updatecnt = @@ROWCOUNT				

		if @debug = 1
			begin
				set @msg = 'Completed updating ' + cast(@updatecnt as varchar) + 'records'
				exec dbo.messenger null, null, null, @procname, @msg, null, 'I'			
			end				
			
	end try
	begin catch
		set @msg = 'Failed ' + @msg
		exec dbo.messenger null, null, null, @procname, @msg, null, 'E'
	end catch
		