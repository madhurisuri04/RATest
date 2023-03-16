CREATE PROCEDURE [dbo].[spr_Insert_dbo_tbl_Member_months_plan_rollup]
	@SourceDatabase	sysname,
	@PlanIdentifier	smallint,
	@EarliestDate	datetime = '1900-01-01'
AS
/*********************************************************************************
Health Risk Partners
Author:		 Brett A. Burnam
Date:        10/06/2011

Purpose:	 stored procedure to populate the tbl_Member_months_plan_rollup table in the
			 _Report database using the tbl_Member_months_plan table in each plan level 
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
	Set @InsertSql = 'INSERT INTO [dbo].[tbl_Member_Months_Plan_rollup]' + 
						 ' ([PlanIdentifier],[PLANID],[PAYMSTART],[HICN],[LAST],[FIRST],[MI],[DOB],[GENDER],[SSN],' +
						 ' [MEMBERID],[COUNTY_OF_RESIDENCE],[MEDICAID_STATUS],[DISABILITY_STATUS],[PBP],[WITHHOLD_OPTION],' +
						 ' [Low_Income_Cost_Sharing],[LIS_SUBSIDY],[ESRD],[HOSPICE],[WORKING_AGED],[INSTITUTIONAL],[GROUP],' +
						 ' [ADDRESS1],[ADDRESS2],[CITY],[STATE],[ZIP],[PLAN_RISK_SCORE_C],[PLAN_RISK_SCORE_D],[POPULATED],[Phone],[MemberIDReceived])' +
				   ' Select ' + cast(@PlanIdentifier as varchar(3)) + ',PLANID,mmp.PAYMSTART,LTRIM(RTRIM(mmp.HICN)),[LAST],[FIRST],MI,DOB,GENDER,SSN,MEMBERID,COUNTY_OF_RESIDENCE,' +
						' MEDICAID_STATUS,DISABILITY_STATUS,PBP,WITHHOLD_OPTION,Low_Income_Cost_Sharing,LIS_SUBSIDY,ESRD,' +
						' HOSPICE,WORKING_AGED,INSTITUTIONAL,[GROUP],ADDRESS1,ADDRESS2,CITY,[STATE],ZIP,PLAN_RISK_SCORE_C,' +
						' PLAN_RISK_SCORE_D,POPULATED,s.Filler As PhoneNumber, mmp.MemberIDReceived' +
					' From ' + @SourceDatabase + '.dbo.tbl_Member_months_plan mmp ' +
					' Inner Join (Select LTRIM(RTRIM(mmp2.HICN)) As HICN, MAX(mmp2.PaymStart) as MaxPaymStart' +
								' From  ' + @SourceDatabase + '.dbo.tbl_Member_months_plan mmp2 ' +
								' Group By LTRIM(RTRIM(HICN))) x' +
						' On LTRIM(RTRIM(mmp.HICN)) = x.HICN' +
						' And mmp.PaymStart = x.MaxPaymStart' +
					' Left Outer Join (select LTRIM(RTRIM(tpm.HICN)) As HICN,Filler,tpm.Effective_Date' +
									' From  ' + @SourceDatabase + '.dbo.tbl_plan_membership tpm' +
									' Inner Join (Select LTRIM(RTRIM(tpm2.HICN)) As HICN, Max(tpm2.Effective_Date) MaxEffective_Date' +
												' From  ' + @SourceDatabase + '.dbo.tbl_plan_membership tpm2' +
												' Where tpm2.Filler Is Not Null' +
												' Group by LTRIM(RTRIM(tpm2.HICN))) x2' +
										' On LTRIM(RTRIM(tpm.HICN)) = x2.HICN' +
										' And tpm.Effective_Date = x2.MaxEffective_Date) s' +
							' On LTRIM(RTRIM(mmp.HICN)) = s.HICN'
								
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