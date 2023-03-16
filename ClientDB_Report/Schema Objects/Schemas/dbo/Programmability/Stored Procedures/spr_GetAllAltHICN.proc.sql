CREATE PROCEDURE [dbo].[spr_GetAllAltHICN]
AS
/*********************************************************************************
Health Risk Partners
Author:		 Brett A. Burnam
Date:        07/29/2011

Purpose:	 To populate the AltHICNXref table

Parameters:	 none

Assumptions: 

Modifications:
08/31/2011 bab add logic to disable/enable non-clustered indexes on the target table

*********************************************************************************/

Set NoCount On
--Set XACT_ABORT ON

Begin Try

	-------------------------------------------------------------------------
	-- Declare variables and temp tables
	-------------------------------------------------------------------------	
	Declare @UpdateCnt					int,
			@InsertCnt					int,
			@IndexCnt					smallint,
			@IDXDisableCnt				smallint,
			@IDXEnableCnt				smallint,
			@DisableIndexSql			nvarchar(1000),
			@NonClusteredIndexName		varchar(1000),
			@EnableIndexSql			    nvarchar(1000),
			@TargetTableName			sysname
				

	Create Table #HICN1	
		(FinalHICN		varchar(12),
		 AltHICN		varchar(12),		
		 LastUpdated	datetime)
		 
	Declare @NonClusteredIndex Table
		(NonClusteredIndexID int identity primary key,
		 IndexName			 sysname)		 
		 
	-------------------------------------------------------------------------
	-- Set Variable Values
	-------------------------------------------------------------------------	  
	Set @UpdateCnt = 1
	Set @TargetTableName = 'AltHICNXref'
	Set @IDXDisableCnt = 1
	Set @IDXEnableCnt = 1	
		 
	-------------------------------------------------------------------------
	-- create dataset of all AltHICNs and HICNs from  the rollup table
	-------------------------------------------------------------------------
	Insert Into #HICN1
		(FinalHICN, AltHICN,LastUpdated)
	Select LTRIM(RTRIM(FinalHICN)),LTRIM(RTRIM(AltHICN)), Max(LastUpdated) As LastUpdated
	From dbo.tbl_AltHICN_rollup with (nolock)
	Group By LTRIM(RTRIM(FinalHICN)), LTRIM(RTRIM(AltHICN))
	Union
	Select LTRIM(RTRIM(FinalHICN)),LTRIM(RTRIM(HICN)), Max(LastUpdated) As LastUpdated
	From dbo.tbl_AltHICN_rollup with (nolock)
	Group By LTRIM(RTRIM(FinalHICN)), LTRIM(RTRIM(HICN))

	Set @InsertCnt = @@Rowcount

	-------------------------------------------------------------------------
	-- Create Index on temp table
	-------------------------------------------------------------------------
	If @InsertCnt > 100000
	  Begin
		Create Clustered Index [CLIDX_#HICN1_FinalHICN] On #HICN1 (FinalHICN asc, LastUpdated asc)
	  End
	  
	-------------------------------------------------------------------------
	-- Add records where the FinalHICN does not have a record with the AltHICN as the same value
	-------------------------------------------------------------------------
	Insert Into #HICN1
		(FinalHICN, AltHICN, LastUpdated)
	Select a.FinalHICN,a.FinalHICN As AltHICN, Max(a.LastUpdated)
	From #HICN1 a
	Where Not Exists (Select 1
					  From #HICN1 b
					  Where a.FinalHICN = b.FinalHICN
					  And a.FinalHICN = b.AltHICN)
	Group by a.FinalHICN

	-------------------------------------------------------------------------
	-- Update records where the FinalHICN is also an AltHICN for a different/more recent FinalHICN
	-------------------------------------------------------------------------
	While @UpdateCnt > 0
	  Begin

		Update a
			Set FinalHICN = b.FinalHICN,
				LastUpdated = b.LastUpdated
		From #HICN1 a
		Inner Join #HICN1 b
			On a.FinalHICN = b.AltHICN
			And a.FinalHICN <> b.FinalHICN
		Where a.LastUpdated < b.LastUpdated
		
		Set @UpdateCnt = @@Rowcount

	  End
	  
	-------------------------------------------------------------------------
	-- Disable NonClustered Indexes (if any)
	-------------------------------------------------------------------------
	Insert Into @NonClusteredIndex
		(IndexName)
	Select Name
	From sys.indexes
	Where object_id = OBJECT_ID(@TargetTableName)
	And type_desc = 'NONCLUSTERED'
	And is_disabled = 0	
	
	Set @IndexCnt = @@Rowcount
	
	While (@IDXDisableCnt <= @IndexCnt)
	  Begin
		Set @NonClusteredIndexName = (Select IndexName From @NonClusteredIndex Where NonClusteredIndexID = @IDXDisableCnt)
		
		Set @DisableIndexSql = 'Alter Index [' + @NonClusteredIndexName + '] on [dbo].[' + @TargetTableName + '] Disable'
		Execute sp_executesql @stmt = @DisableIndexSql
		
		Set @IDXDisableCnt = @IDXDisableCnt + 1
			 
	  End	  

	-------------------------------------------------------------------------
	-- Scratch and load target table
	-------------------------------------------------------------------------
	Begin Transaction

		Truncate Table dbo.AltHICNXref
		
		Insert Into dbo.AltHICNXref with (TABLOCKX)
			(FinalHICN, AltHICN, CreateDate)
		Select Distinct FinalHICN, AltHICN, getdate()
		From #HICN1
		
	Commit Transaction	
		
	-------------------------------------------------------------------------
	-- Clean Up
	-------------------------------------------------------------------------	
	Drop Table #HICN1
	
	-------------------------------------------------------------------------
	-- Enable all non-clustered indexes that were previously disabled on the table
	-------------------------------------------------------------------------	
	While (@IDXEnableCnt <= @IndexCnt)
	  Begin
		Set @NonClusteredIndexName = (Select IndexName From @NonClusteredIndex Where NonClusteredIndexID = @IDXEnableCnt)
		
		Set @EnableIndexSql = 'Alter Index [' + @NonClusteredIndexName + '] on [dbo].[' + @TargetTableName + '] Rebuild'
		Execute sp_executesql @stmt = @EnableIndexSql
		
		Set @IDXEnableCnt = @IDXEnableCnt + 1
			 
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
