-- =============================================
-- Script Template
-- =============================================
SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRANSACTION;

MERGE dbo.RiskModelClientMap  AS target
USING (
select OrganizationID 'OrganizationID', 2 'RiskModelID', 'FEDERAL' 'ModelCode'
from dbo.Organization	
) AS source
ON (
target.[OrganizationID] = source.[OrganizationID]
)
WHEN NOT MATCHED THEN	
    INSERT 
    (
      [OrganizationID]     
    , RiskModelId      
    , ModelCode
    , CreateDateTime   
    )
    VALUES 
    (
	  source.[OrganizationID]
	, source.RiskModelId
	, source.ModelCode
	, Getdate()
	);
    
COMMIT;
