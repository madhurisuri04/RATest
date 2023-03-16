CREATE PROCEDURE [dbo].[spr_Rollup]
	@ClientIdentifier int,
	@RestartFromFailure	bit = 0,
	@SequenceNumberToStartFrom smallint = NULL
AS
/*********************************************************************************
Health Risk Partners
Author:		 Brett A. Burnam
Date:        07/21/2011

Purpose:	To call the spr_RollupTable stored procedure for each table in the
			RollupTable as configured.

Parameters:	 @ClientIdentifier
			    -the client to process
			 @RestartFromFailure
				-this bit will start from the previous point of failure if set to to 1
				-the point of failure is the TableID associated with the min ExecutionSequenceNumber
				 that is in the status of 'InProcess' or 'Unstable'
			 @SequenceNumberToStartFrom
				-will start from the RollupTableConfigID associated with the sequence number specified,
				 if not set then the process will start processing the RollupTableConfigID associated with
				 the lowest squence number 

Assumptions:	If the @RestartFromFailure parameter is set to 1 the process will start from
				where it previously failed even if the @SequenceNumberToStartFrom is specified.
				

Modifications:
09/09/2011 bab changes for the configuration tables moving from the client level to HRPInternalReports

*********************************************************************************/

Set NoCount On
--Set XACT_ABORT ON

Begin Try

	-------------------------------------------------------------------------
	-- Declare variables
	-------------------------------------------------------------------------
	Declare @RollupTableCnt				smallint,
			@Cnt						smallint,
			@TableConfigID				int,
			@Status						varchar(10),
			@CaughtUp					bit,
			@ExecutionSequenceNumber	smallint

	Declare @RollupTableExecution Table
		(RollupTableExecutionID		int Identity Primary Key NOT NULL,
		 RollupTableConfigID		int Not Null,
		 RollupStatus				varchar(10) Not Null,
		 ExecutionSequenceNumber	smallint NULL)
		 
	-------------------------------------------------------------------------
	-- Set variable values
	-------------------------------------------------------------------------			 
	Set @Cnt = 1
	Set @CaughtUp = 0
  
	-------------------------------------------------------------------------
	-- popluate the list of tables to rollup
	-------------------------------------------------------------------------
	Insert Into @RollupTableExecution
		(RollupTableConfigID,RollupStatus,ExecutionSequenceNumber)
	Select rtc.RollupTableConfigID,rts.RollupStatus,rt.ExecutionSequenceNumber
	From dbo.RollupTableConfig rtc
	Inner Join dbo.RollupTable rt
		On rtc.RollupTableID = rt.RollupTableID
	Inner Join dbo.RollupTableStatus rts
		On rtc.RollupTableConfigID = rts.RollupTableConfigID
			And rts.RollupState = 'OutOfDate'
	Inner Join dbo.RollupClient rc
		On rtc.ClientIdentifier = rc.ClientIdentifier
		And rc.Active = 1
		And rc.UseForRollup = 1	
	Where rtc.ClientIDentifier = @ClientIdentifier
	And rtc.Active = 1
	Order by rt.ExecutionSequenceNumber asc
								  
	Set @RollupTableCnt = @@Rowcount
	
	-------------------------------------------------------------------------
	-- If this is a regular execution determine the ExecutionSequenceNumber to start with
	-------------------------------------------------------------------------	
	If (@SequenceNumberToStartFrom IS NULL And @RestartFromFailure = 0 And @RollupTableCnt > 0)
	  Begin
		Select @SequenceNumberToStartFrom = Min(ExecutionSequenceNumber)
		From @RollupTableExecution
	  End		
	
	-------------------------------------------------------------------------
	-- Call the spr_RollupTable stored procecure for each table
	-------------------------------------------------------------------------	
	If @RestartFromFailure = 0 --Start from the begining or from the @SequenceNumberToStartFrom
		While @Cnt <= @RollupTableCnt
		  Begin
			
			Select @TableConfigID = RollupTableConfigID,
				   @ExecutionSequenceNumber = ExecutionSequenceNumber 
			From @RollupTableExecution 
			Where RollupTableExecutionID = @Cnt			
			
			If (@ExecutionSequenceNumber = IsNull(@SequenceNumberToStartFrom,'') Or @CaughtUp = 1)
			  Begin	
				--Print 'Execute [dbo].[spr_RollupTable] @RollupTableConfigID = ' + cast(@TableConfigID as varchar(3))
				Execute [dbo].[spr_RollupTable] @RollupTableConfigID = @TableConfigID
				
				Set @CaughtUp = 1
			  End
			
			Set @Cnt = @Cnt + 1
		  End
	Else -- Start processing from where the failure occurred or from where the process was aborted
		While @Cnt <= @RollupTableCnt
		  Begin
		  	
			Select @TableConfigID = RollupTableConfigID,
				   @Status = RollupStatus
			From @RollupTableExecution 
			Where RollupTableExecutionID = @Cnt
			
			If (@Status In ('InProcess','Unstable') Or @CaughtUp = 1)
			  Begin
				If @Status = 'InProcess'
				  Update rts
					Set RollupStatus = 'Unstable',
						RollupStart = NULL,
						PlanIDCurrentlyProcessing = NULL,
						RollupEnd = NULL,
						PlanIdentifierCurrentlyProcessing = NULL,
						PlanNumberCurrentlyProcessing = NULL,
						NumberOfPlansToProcess = NULL,
						ModifiedDate = GETDATE()
				  From dbo.RollupTableStatus rts
				  Where rts.RollupTableConfigID = @TableConfigID
				  				 									  
				--Print 'Execute [dbo].[spr_RollupTable] @RollupTableConfigID = ' + cast(@TableConfigID as varchar(3))
				Execute [dbo].[spr_RollupTable] @RollupTableConfigID = @TableConfigID
				
				Set @CaughtUp = 1 
			  End
			  
			  Set @Cnt = @Cnt + 1			
		  End	
			  
	  	
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
