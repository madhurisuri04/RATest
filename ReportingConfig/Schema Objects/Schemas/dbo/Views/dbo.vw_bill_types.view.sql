CREATE VIEW dbo.vw_bill_types
AS
SELECT     '0' + bill_type AS bill_type,Effective_Date, Termination_Date, CMS_Acceptable
FROM         dbo.lk_bill_types
UNION ALL
SELECT     bill_type AS bill_type,Effective_Date, Termination_Date,CMS_Acceptable
FROM         dbo.lk_bill_types