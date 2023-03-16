
/*
Author: Madhuri Suri 
Desc: Insert New Plan H4045 into Rollup Configuration Table for Santa Clara 
Server: RQIRPTDBS905
Database: HRPInternalReports
*/
Use HRPInternalReports
GO 

INSERT INTO dbo.Rollupplan
([PlanID]
,[ClientIdentifier]
,[UseForRollup]
,[Active]
,[CreateDate]
,[ModifiedDate])

SELECT 'H4045', 27, 1, 1, GETDATE(), GETDATE()