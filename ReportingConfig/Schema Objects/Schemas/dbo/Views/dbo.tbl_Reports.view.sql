CREATE VIEW [dbo].[tbl_Reports] AS
SELECT
	[ReportID],
	[Report_Display_Name],
	[Report_File_Name],
	[Report_Stored_Proc_Name],
	[External_Description],
	[Internal_Description],
	[Active],
	[ReportOrderBy],
	[Export_Crystal],
	[Export_CSV],
	[Export_Excel],
	[Export_Excel_Headers],
	[Export_CSV_Headers],
	[Has_Parameters],
	[Export_SSRS],
	[SSRS_Report_Path],
	[Export_Appends_Plan_ID],
	[RunInClone],
	[Creation_Date],
	[ReportConnectionTypeID]
FROM [$(HRPReporting)].[dbo].[tbl_Reports]