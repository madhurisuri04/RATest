/*
Author:			Dianne Barba
TFS Request:	17141	
Description:	Updates the RADVFactorType [Client}_Report
Create date:	12/23/2013

Modifications:

exec dbo.spr_RADVFactorType 2010, 'HRPDEVDB01', 'MVP_CN_ClientLevel', 'MVP_Report'

*/

create procedure spr_RADVFactorType
(
	@PaymentYear int = 2010, 
	@CNServerName varchar (50) = '',
	@ClientDBName varchar(50),
	@ReportDBName varchar(50),
	@debug bit = 0	
)
as
	declare @msg varchar(200)
	declare @procname varchar(100)
	
	begin try
	
-- get proc name
	set @procname = OBJECT_NAME(@@PROCID)	
		
----Reset all factor values to NULL
		set @msg = 'setting FactorValue to null'
		if @debug = 1
			begin
				exec dbo.messenger null, null, null, @procname, @msg, null, 'I'
			end		
		update rmd
		set FactorValue = null
		from dbo.RADVMemberDetail rmd with (rowlock)

-- Update factorvalue
		set @msg = 'updating FactorValue'
		if @debug = 1
			begin
				exec dbo.messenger null, null, null, @procname, @msg, null, 'I'
			end		
		update rmd
			set FactorValue = COMM  -- select *
		from 
			dbo.RADVMemberDetail rmd
			join [$(HRPReporting)].dbo.lk_Factors_PartC f on rmd.HCCCode = f.HCC_Number
 				
	end try
	begin catch
		set @msg = 'Failed ' + @msg
		exec dbo.messenger null, null, null, @procname, @msg, null, 'E'
	end catch