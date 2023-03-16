CREATE PROCEDURE [dbo].[spr_Insert_dbo_vw_RAPS_DiagHCC_rollup]
	@SourceDatabase	sysname,
	@PlanIdentifier	smallint,
	@EarliestDate	datetime = '1900-01-01'
AS
/*********************************************************************************
Health Risk Partners
Author:		 Brett A. Burnam
Date:        07/18/2011

Purpose:	 stored procedure to populate the RAPS_DiagHCC_rollup table in the
			 _Report database using the vw_RAPS_DiagHCC view in each plan level 
			 database as the source.

Parameters:	 @SourceDatabase
			 @PlanIdentifier
			 @EarliestDate
			 
Assumptions: 

Modifications:

*********************************************************************************/

Set NoCount On
--Set XACT_ABORT ON

Begin Try

	-------------------------------------------------------------------------
	-- Declare variables
	-------------------------------------------------------------------------
	Declare @InsertSql			nvarchar(4000)
				
	-------------------------------------------------------------------------
	-- Build insert statement
	-------------------------------------------------------------------------	
	Set @InsertSql = 'Insert Into dbo.RAPS_DiagHCC_rollup ' +
						'(PlanIdentifier,rapSID,ProcessedBy,CorrectedHICN,Descr,DiagnosisCode,DiagnosisError1,DiagnosisError2, '+
						 'DOB,DOBError,FileID,Filler,FromDate,HICN,HICNError,PatientControlNumber,ProviderType, ' +
						 'SeqError,SeqNumber,ThruDate,Void_Indicator,Voided_by_rapSID,PartC_HCC,PartD_HCC,Accepted,Deleted, 
						 Source_Id, Provider_Id, RAC, RAC_Error, Image_ID) ' +
					'Select ' + cast(@PlanIdentifier as varchar(3)) + ',rapSID,ProcessedBy,LTRIM(RTRIM(CorrectedHICN)),Descr,DiagnosisCode,DiagnosisError1,DiagnosisError2, ' +
						 'DOB,DOBError,FileID,Filler,FromDate,LTRIM(RTRIM(HICN)),HICNError,PatientControlNumber,ProviderType, ' +
						 'SeqError,SeqNumber,ThruDate,Void_Indicator,Voided_by_rapSID,HCC As PartC_HCC,dhd.HCC_Label As PartD_HCC, ' +
						 'case when rap.DOBError IS NULL ' +
									'AND rap.SeqError IS NULL ' +
									'AND isnull(rap.HICNError,''600'') > ''499''  ' +
									'AND isnull(rap.DiagnosisError1,''600'') > ''500'' ' +
									'AND isnull(rap.DiagnosisError2,''600'') > ''500'' ' +
									'AND rap.Void_Indicator IS NULL ' +
									'AND rap.Deleted IS NULL ' +
									'AND rap.RAC_Error IS NULL ' +
							 'then 1 else 0 end As Accepted, ' +	 
							 'rap.Deleted, rap.SourceId, rap.ProviderId, rap.RAC, rap.RAC_Error, rap.Image_ID  ' +
					'From ' + @SourceDatabase + '.dbo.vw_rapS_DiagHCC rap ' +
					'left join [$(HRPReporting)].dbo.lk_DiagnosesHCC_PartD dhd with (nolock) ' +
						'on rap.DiagnosisCode=dhd.ICD9 ' +
						'and year(rap.thrudate)+1=dhd.Payment_Year ' +
					'Where rap.ProcessedBy >=  ''' + CONVERT(varchar(10),@EarliestDate,101) + ''''
								
	----------------------------------------------------------------------
	-- Populate the target table
	----------------------------------------------------------------------	
	Begin Transaction
	
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