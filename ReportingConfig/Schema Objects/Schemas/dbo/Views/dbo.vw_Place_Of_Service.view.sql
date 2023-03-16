CREATE VIEW dbo.vw_Place_Of_Service
AS
SELECT     POS_ID, POS_CODE, POS_NAME, DESCRIPTION,Effective_Date, Termination_Date
FROM         dbo.lk_Place_Of_Service
WHERE     (POS_NAME <> 'Unassigned')