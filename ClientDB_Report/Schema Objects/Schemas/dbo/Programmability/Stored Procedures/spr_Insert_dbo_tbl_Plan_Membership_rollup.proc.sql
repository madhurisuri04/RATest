CREATE PROCEDURE [dbo].[spr_Insert_dbo_tbl_Plan_Membership_rollup]
	@SourceDatabase	sysname,
	@PlanIdentifier	smallint,
	@EarliestDate	datetime = '1900-01-01'
AS
/*********************************************************************************
Health Risk Partners
Author:		 Brett A. Burnam
Date:        11/30/2011

Purpose:	 stored procedure to populate the tbl_Plan_Membership_rollup table in the
			 _Report database using the tbl_Plan_Membership table in each plan level 
			 database as the source.

Parameters:	 @SourceDatabase
			 @PlanIdentifier
			 @EarliestDate
			 
Assumptions: 

Modifications:

*********************************************************************************/

Set NoCount On

Begin Try

	-------------------------------------------------------------------------
	-- Declare variables
	-------------------------------------------------------------------------
	Declare @InsertSql			nvarchar(max)
					
	-------------------------------------------------------------------------
	-- Build insert statement
	-------------------------------------------------------------------------	
	Set @InsertSql = 'INSERT INTO [dbo].[tbl_Plan_Membership_rollup]' +
						' ([PlanIdentifier],[PlanMembershipID],[PLANID],[HICN],[LAST],[FIRST],[MI],[DOB],[GENDER],[SSN],[MEMBERID],' +
						' [COUNTY_OF_RESIDENCE],[MEDICAID_STATUS],[DISABILITY_STATUS],[PBP],[Start_Date],[End_Date],[EFFECTIVE_DATE],' +
						' [TERM_DATE],[TRANS_DATE],[WITHHOLD_OPTION],[Low_Income_Cost_Sharing],[LIS_SUBSIDY],[ESRD],[HOSPICE],[WORKING_AGED],' +
						' [INSTITUTIONAL],[GROUP_CODE],[LEP],[FILLER],[ADDRESS_1],[ADDRESS_2],[CITY],[STATE],[ZIP],[ZIP4],[RISK_SCORE],[RA_FACTOR_TYPE],' +
						' [PCP_ID],[PCP_FN],[PCP_LN],[DATE_IMPORTED],[RISK_SCORE_D],[MemberIDReceived])' +
					' Select ' + cast(@PlanIdentifier as varchar(3)) + ' ,[PlanMembershipID],[PLANID],LTRIM(RTRIM([HICN])),[LAST],[FIRST],[MI],[DOB],[GENDER],[SSN],[MEMBERID],' +
						' [COUNTY_OF_RESIDENCE],[MEDICAID_STATUS],[DISABILITY_STATUS],[PBP],[Start_Date],[End_Date],[EFFECTIVE_DATE],' +
						' [TERM_DATE],[TRANS_DATE],[WITHHOLD_OPTION],[Low_Income_Cost_Sharing],[LIS_SUBSIDY],[ESRD],[HOSPICE],[WORKING_AGED],' +
						' [INSTITUTIONAL],[GROUP_CODE],[LEP],[FILLER],[ADDRESS_1],[ADDRESS_2],[CITY],[STATE],[ZIP],[ZIP4],[RISK_SCORE],[RA_FACTOR_TYPE],' +
						' [PCP_ID],[PCP_FN],[PCP_LN],[DATE_IMPORTED],[RISK_SCORE_D],[MemberIDReceived]' +
					 ' From ' + @SourceDatabase + '.dbo.tbl_Plan_Membership pm with (nolock) ' +
					 ' Where End_Date >= ''' + CONVERT(varchar(10),@EarliestDate,101) + '''' +
					 ' Or IsNull(Term_Date,''2079-06-06'') >= ''' + CONVERT(varchar(10),@EarliestDate,101) + ''''
					 
	----------------------------------------------------------------------
	-- Populate the target table
	----------------------------------------------------------------------	
	Begin Transaction
	
		--Print @InsertSql
		Execute sp_executesql @stmt = @InsertSql
		
	Commit Transaction
	
End Try

-------------------------------------------------------------------------
-- Error handling
-------------------------------------------------------------------------	
Begin Catch
	If (XACT_STATE() = 1 Or XACT_STATE() = -1)
		Rollback Transaction

	Declare @ErrorMsg varchar(2000)
	Set @ErrorMsg = 'Error: ' + IsNull(Error_Procedure(),'script') + ': ' +  Error_Message() +
				    ', Error Number: ' + cast(Error_Number() as varchar(10)) + ' Line: ' + 
				    cast(Error_Line() as varchar(50))
	
	Raiserror (@ErrorMsg, 16, 1)

End Catch	
