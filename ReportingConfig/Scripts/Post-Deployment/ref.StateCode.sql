-- =============================================
-- Script Template
-- =============================================

BEGIN TRANSACTION;

MERGE [ref].[StateCode] AS target

USING (

 SELECT 1 AS [StateCodeID], N'AK'  AS [StateCode],0 AS [IsDualSplitState]   UNION ALL
 SELECT 2 AS [StateCodeID], N'AL'  AS [StateCode],0 AS [IsDualSplitState]   UNION ALL
 SELECT 3 AS [StateCodeID], N'AR'  AS [StateCode],0 AS [IsDualSplitState]   UNION ALL
 SELECT 4 AS [StateCodeID], N'AZ'  AS [StateCode],0 AS [IsDualSplitState]   UNION ALL
 SELECT 5 AS [StateCodeID], N'CA'  AS [StateCode],1 AS [IsDualSplitState]   UNION ALL
 SELECT 6 AS [StateCodeID], N'CO'  AS [StateCode],0 AS [IsDualSplitState]   UNION ALL
 SELECT 7 AS [StateCodeID], N'CT'  AS [StateCode],0 AS [IsDualSplitState]   UNION ALL
 SELECT 8 AS [StateCodeID], N'DC'  AS [StateCode],0 AS [IsDualSplitState]   UNION ALL
 SELECT 9 AS [StateCodeID], N'DE'  AS [StateCode],0 AS [IsDualSplitState]   UNION ALL
 SELECT 10 AS [StateCodeID], N'FL'  AS [StateCode],0 AS [IsDualSplitState]   UNION ALL
 SELECT 11 AS [StateCodeID], N'GA'  AS [StateCode],0 AS [IsDualSplitState]   UNION ALL
 SELECT 12 AS [StateCodeID], N'HI'  AS [StateCode],0 AS [IsDualSplitState]   UNION ALL
 SELECT 13 AS [StateCodeID], N'IA'  AS [StateCode],0 AS [IsDualSplitState]   UNION ALL
 SELECT 14 AS [StateCodeID], N'ID'  AS [StateCode],0 AS [IsDualSplitState]   UNION ALL
 SELECT 15 AS [StateCodeID], N'IL'  AS [StateCode],1 AS [IsDualSplitState]   UNION ALL
 SELECT 16 AS [StateCodeID], N'IN'  AS [StateCode],0 AS [IsDualSplitState]   UNION ALL
 SELECT 17 AS [StateCodeID], N'KS'  AS [StateCode],0 AS [IsDualSplitState]   UNION ALL
 SELECT 18 AS [StateCodeID], N'KY'  AS [StateCode],0 AS [IsDualSplitState]   UNION ALL
 SELECT 19 AS [StateCodeID], N'LA'  AS [StateCode],0 AS [IsDualSplitState]   UNION ALL
 SELECT 20 AS [StateCodeID], N'MA'  AS [StateCode],0 AS [IsDualSplitState]   UNION ALL
 SELECT 21 AS [StateCodeID], N'MD'  AS [StateCode],0 AS [IsDualSplitState]   UNION ALL
 SELECT 22 AS [StateCodeID], N'ME'  AS [StateCode],0 AS [IsDualSplitState]   UNION ALL
 SELECT 23 AS [StateCodeID], N'MI'  AS [StateCode],0 AS [IsDualSplitState]   UNION ALL
 SELECT 24 AS [StateCodeID], N'MN'  AS [StateCode],0 AS [IsDualSplitState]   UNION ALL
 SELECT 25 AS [StateCodeID], N'MO'  AS [StateCode],0 AS [IsDualSplitState]   UNION ALL
 SELECT 26 AS [StateCodeID], N'MS'  AS [StateCode],0 AS [IsDualSplitState]   UNION ALL
 SELECT 27 AS [StateCodeID], N'MT'  AS [StateCode],0 AS [IsDualSplitState]   UNION ALL
 SELECT 28 AS [StateCodeID], N'NC'  AS [StateCode],0 AS [IsDualSplitState]   UNION ALL
 SELECT 29 AS [StateCodeID], N'ND'  AS [StateCode],0 AS [IsDualSplitState]   UNION ALL
 SELECT 30 AS [StateCodeID], N'NE'  AS [StateCode],0 AS [IsDualSplitState]   UNION ALL
 SELECT 31 AS [StateCodeID], N'NH'  AS [StateCode],0 AS [IsDualSplitState]   UNION ALL
 SELECT 32 AS [StateCodeID], N'NJ'  AS [StateCode],0 AS [IsDualSplitState]   UNION ALL
 SELECT 33 AS [StateCodeID], N'NM'  AS [StateCode],0 AS [IsDualSplitState]   UNION ALL
 SELECT 34 AS [StateCodeID], N'NV'  AS [StateCode],0 AS [IsDualSplitState]   UNION ALL
 SELECT 35 AS [StateCodeID], N'NY'  AS [StateCode],0 AS [IsDualSplitState]   UNION ALL
 SELECT 36 AS [StateCodeID], N'OH'  AS [StateCode],0 AS [IsDualSplitState]   UNION ALL
 SELECT 37 AS [StateCodeID], N'OK'  AS [StateCode],0 AS [IsDualSplitState]   UNION ALL
 SELECT 38 AS [StateCodeID], N'OR'  AS [StateCode],0 AS [IsDualSplitState]   UNION ALL
 SELECT 39 AS [StateCodeID], N'PA'  AS [StateCode],0 AS [IsDualSplitState]   UNION ALL
 SELECT 40 AS [StateCodeID], N'RI'  AS [StateCode],0 AS [IsDualSplitState]   UNION ALL
 SELECT 41 AS [StateCodeID], N'SC'  AS [StateCode],0 AS [IsDualSplitState]   UNION ALL
 SELECT 42 AS [StateCodeID], N'SD'  AS [StateCode],0 AS [IsDualSplitState]   UNION ALL
 SELECT 43 AS [StateCodeID], N'TN'  AS [StateCode],0 AS [IsDualSplitState]   UNION ALL
 SELECT 44 AS [StateCodeID], N'TX'  AS [StateCode],0 AS [IsDualSplitState]   UNION ALL
 SELECT 45 AS [StateCodeID], N'US'  AS [StateCode],0 AS [IsDualSplitState]   UNION ALL
 SELECT 46 AS [StateCodeID], N'UT'  AS [StateCode],0 AS [IsDualSplitState]   UNION ALL
 SELECT 47 AS [StateCodeID], N'VA'  AS [StateCode],0 AS [IsDualSplitState]   UNION ALL
 SELECT 48 AS [StateCodeID], N'VT'  AS [StateCode],0 AS [IsDualSplitState]   UNION ALL
 SELECT 49 AS [StateCodeID], N'WA'  AS [StateCode],0 AS [IsDualSplitState]   UNION ALL
 SELECT 50 AS [StateCodeID], N'WI'  AS [StateCode],0 AS [IsDualSplitState]   UNION ALL
 SELECT 51 AS [StateCodeID], N'WV'  AS [StateCode],0 AS [IsDualSplitState]   UNION ALL
 SELECT 52 AS [StateCodeID], N'WY'	AS [StateCode],0 AS [IsDualSplitState]

)AS Source
ON (target.StateCodeID = source.StateCodeID)
WHEN MATCHED THEN 
    UPDATE SET 
		StateCode = source.StateCode,
		IsDualSplitState=source.IsDualSplitState
WHEN NOT MATCHED THEN	
    INSERT (StateCodeID, StateCode,IsDualSplitState)
    VALUES (source.StateCodeID, source.StateCode,source.IsDualSplitState);

COMMIT;
