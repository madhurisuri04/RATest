/*	Created By:		Jim Wilson
	Create Date:	02/17/2017
	Notes:			TFS-57342 Jim Wilson Drop Obsolete Table at ClientReport
	Revisions:
*/



Print 'Begin Script: TFS_57342_Jim_Wilson_DropObsoleteTable_ClientReport'		

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[CNClientBillingSummary]') AND type in (N'U'))
DROP Table [dbo].[CNClientBillingSummary]
GO



Print 'End Script: TFS_57342_Jim_Wilson_DropObsoleteTable_ClientReport'