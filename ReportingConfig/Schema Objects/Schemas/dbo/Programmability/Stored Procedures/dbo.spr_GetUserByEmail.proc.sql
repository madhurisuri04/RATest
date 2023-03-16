
CREATE PROC [dbo].[spr_GetUserByEmail] 
    @Email VARCHAR(100)
AS 
	SET NOCOUNT ON 

	SELECT 
		[User_ID], 
		[First_Name], 
		[Last_Name], 
		[Phone_Number], 
		[Email], 
		[Password], 
		[Admin_User], 
		[Active], 
		[Receive_System_Email], 
		[Can_Upload_Files], 
		[Can_Access_ReconQ], 
		[Can_Access_PDEQ], 
		[Exclude_From_Log_Report], 
		[IsUserAdmin], 
		[Can_Download_Data_Files], 
		[Force_Password_Change], 
		[Password_Last_Changed], 
		[Can_Access_Bid_Update], 
		[Can_Access_Chart_Utility], 
		[Can_Access_Chart_Nav], 
		[Can_Access_Workspace], 
		[Can_User_Resolve], 
		[Can_Access_RAPS_Interface], 
		[Can_Send_RAPS], 
		[Can_Delete_RAPS], 
		[Can_Merge_RAPS_Batch], 
		[Can_Delete_RAPS_Batch], 
		[Can_Update_CMS_Submitter], 
		[Secret_Question_1], 
		[Secret_Answer_1], 
		[Secret_Question_2], 
		[Secret_Answer_2], 
		[Password_Reset_Key], 
		[Password_Reset_Key_Expires_On], 
		[Can_Access_EDSQ], 
		[Can_Mass_Update_Encounter], 
		[Can_Tag_Encounter], 
		[Can_Access_EDSQ_Workbench], 
		[Can_Unlock_Encounter],
		[Can_Override_Encounter_Threshold],
		[Can_Access_Star_Nav],
		[Can_Access_Rev_Nav]
	FROM   [dbo].[tbl_Users] 
	WHERE  Email = @Email