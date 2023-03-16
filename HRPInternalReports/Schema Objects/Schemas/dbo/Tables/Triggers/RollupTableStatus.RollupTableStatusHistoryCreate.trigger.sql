CREATE Trigger [dbo].[RollupTableStatusHistoryCreate] 
   On  [dbo].[RollupTableStatus]
   After Update
As
/*********************************************************************************
Health Risk Partners
Author:		 Brett A. Burnam
Date:        07/22/2011

Purpose:		to popluate the RollupTableStatusHistory and RollupTableStatusPlanHistory
				tables to track the runtimes of rollup activity
 
Assumptions: 

Modifications:

*********************************************************************************/
Begin

Set NoCount On

Begin Try

	-------------------------------------------------------------------------
	-- Determine if any rows were updated by the update statement
	-------------------------------------------------------------------------	
	Declare @RC As Int = (Select COUNT(*) from (Select top (2) * From inserted) As D)
	
	-------------------------------------------------------------------------
	-- If now rows were updated exit the trigger
	-------------------------------------------------------------------------	
	If @RC = 0 
	  Return
	  
	-------------------------------------------------------------------------
	-- populate the RollupTableStatusHistory table for each table rollup
	-------------------------------------------------------------------------		        
    Insert Into [dbo].[RollupTableStatusHistory]
		(RollupTableStatusID,RollupStart,RollupEnd,HistoryCreateDate,HistoryModifiedDate)
	Select i.RollupTableStatusID,i.RollupStart,i.RollupEnd,GETDATE(),GETDATE()
	From inserted i
	Inner Join deleted d
		On i.RollupTableStatusID = d.RollupTableStatusID		
	Where i.RollupStart Is Not Null
	And i.RollupEnd Is Not Null
	And d.RollupEnd Is Null
	And i.RollupStatus in ('Stable','IndexBuild')
	And d.RollupStatus = 'InProcess'
	
	-------------------------------------------------------------------------
	-- populate the RollupTableStatusPlanHistory table for each Plan rolled up
	-------------------------------------------------------------------------		
	Insert Into [dbo].[RollupTableStatusPlanHistory]
		(RollupTableStatusID,PlanIdentifier,PlanRollupStart,PlanRollupEnd,HistoryCreateDate,HistoryModifiedDate)
	Select i.RollupTableStatusID,d.PlanIdentifierCurrentlyProcessing,d.ModifiedDate,GETDATE(),getdate(),GETDATE()
	From inserted i
	Inner Join deleted d
		On i.RollupTableStatusID = d.RollupTableStatusID
	Where i.RollupStatus <> 'Unstable'
	And d.PlanIdentifierCurrentlyProcessing Is Not Null
	And IsNull(d.PlanIdentifierCurrentlyProcessing,'') <> IsNull(i.PlanIdentifierCurrentlyProcessing,'')
	
	-------------------------------------------------------------------------
	-- populate the RollupTableStatusIndexBuildHistory for each index build
	-------------------------------------------------------------------------
    Insert Into [dbo].[RollupTableStatusIndexBuildHistory]
		(RollupTableStatusID,IndexBuildStart,IndexBuildEnd,HistoryCreateDate,HistoryModifiedDate)
	Select i.RollupTableStatusID,i.RollupStart,i.RollupEnd,GETDATE(),GETDATE()
	From inserted i
	Inner Join deleted d
		On i.RollupTableStatusID = d.RollupTableStatusID		
	Where i.IndexBuildStart Is Not Null
	And i.IndexBuildEnd Is Not Null
	And d.IndexBuildEnd Is Null
	And i.RollupStatus = 'Stable'
	And d.RollupStatus = 'IndexBuild'		
	
End Try	
	
-------------------------------------------------------------------------
-- Error Handling
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
			
End