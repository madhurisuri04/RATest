﻿CREATE VIEW [dbo].[tbl_Connection] AS
SELECT
	Connection_ID,
	Connection_Display_Name,
	Connection_Name,
	Populate_Discrepancies,
	Populate_ReconQ_w_MMR_Import,
	Populate_PDE_Q,
	Run_Imports,
	Part_D_Only_Plan,
	Populate_DOB_Discrepancies,
	Populate_ESRD_Discrepancies,
	Populate_GENDER_Discrepancies,
	Populate_HOSPICE_Discrepancies,
	Populate_INSTITUTIONAL_Discrepancies,
	Populate_INSTITUTIONAL_Part_D_Discrepancies,
	Populate_LIS_Discrepancies,
	Populate_MEDICAID_Discrepancies,
	Populate_PBP_Discrepancies,
	Populate_SCC_Discrepancies,
	Populate_WORKING_AGED_Discrepancies,
	Populate_ON_CMS_NOT_PLAN_Discrepancies,
	Populate_ON_PLAN_NOT_CMS_Discrepancies,
	Populate_MA_Premium_Discrepancies,
	Populate_Part_D_Direct_Subsidy_Discrepancies,
	Populate_Reinsurance_Discrepancies,
	Populate_LICS_Discrepancies,
	Populate_LIPS_Discrepancies,
	Populate_Part_D_Rebates_Discrepancies,
	Populate_Part_C_Rebates_Discrepancies,
	Auto_Run_Triangle_Population,
	Auto_Run_RAPS_Dup_Check,
	Email_To_Send_RAPS_Dup_Notification,
	Default_User_ID,
	Start_Date_For_Plan_Membership_Q,
	PDE_Claim_Control_Number_Left_Char_Comparison_Count,
	CMS_SUBMITTER_ID,
	RAPS_FILE_CREATE_PROD_TEST_IND,
	RAPS_EARLIEST_SUBMISSION_DATE,
	User_To_Receive_Recycled_RAPS_File,
	Day_Of_Month_To_Recycle_Raps,
	Path_To_HTTP_FTP_Root,
	Number_Months_Live_Data_On_Hand,
	Password_Validation_Reg_Expression,
	Password_Validation_Failed_Message,
	Possible_Source_IPs,
	Number_Of_Days_Users_Must_Change_Passwords,
	Server_To_Process_Windows_Services,
	ESRD_Use_CMS,
	Hospice_Use_CMS,
	RA_Factor_Use_CMS,
	SCC_Use_CMS,
	Risk_Score_C_Use_CMS,
	Risk_Score_D_Use_CMS,
	INST_Use_CMS,
	WA_Use_CMS,
	Medicaid_Use_CMS,
	DS_Discrep_Allowable,
	Populate_Direct_Subsidy_Discrepancies,
	Plan_ID,
	HRPChartsEmailContact,
	CodeChartsInHouse,
	Database_Server_Name,
	ChartNavDefaultDiagnosisEntryStatus,
	Use_TRR_in_MM_population,
	Populate_MPWO_Flag_Discrepancies,
	Populate_MPWO_Amount_Discrepancies,
	PDEQ_Include_Error_Code_777,
	Active_CMS_Plan,
	Show_On_Activity_Report
FROM [$(HRPReporting)].[dbo].[tbl_Connection]