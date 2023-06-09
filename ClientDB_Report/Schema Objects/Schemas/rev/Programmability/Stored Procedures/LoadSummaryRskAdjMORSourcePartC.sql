/*******************************************************************************************************************************
* Name			:	[rev].[LoadSummaryRskAdjMORSourcePartC]
* Type 			:	Stored Procedure          
* Author       	:	Anand
*JIRA#          :   RRI-1236
* Date          :	10/06/2021
* Version		:	1.0
* Version History :
  Author			Date		Version#	TFS Ticket#			Description
* -----------------	----------	--------	-----------			------------
    Anand			10/06/2021	1.0			RRI-1236			Load rev.SummaryRskAdjMORSourcePartC table
	Anand			11/08/2021	1.1			RRI-1750			Format HCC Label - D_ to D-
	Anand			11/15/2021	1.2			RRI-1802			Modify Proc to loop Plan DB's to insert into SummaryRskAdjMORSourcePartC table
*********************************************************************************************************************************/
CREATE PROCEDURE [rev].[LoadSummaryRskAdjMORSourcePartC]
(
	@ClientID INT,
	@RowCountC INT OUT
)
AS

   BEGIN

SET @RowCountC = 0;


IF (OBJECT_ID('tempdb.dbo.[#Client_Connections]') IS NOT NULL)
BEGIN
    DROP TABLE [#Client_Connections];
END;

 	CREATE TABLE [#Client_Connections]
		(
			[Id] [INT] IDENTITY(1, 1) PRIMARY KEY NOT NULL ,
			[Client_ID] INT NULL,
			[Connection_ID] INT NULL
		);

	INSERT INTO [#Client_Connections] (   [Client_ID] ,
                                           [Connection_ID]
                                       )
            SELECT ISNULL([mg].[MergedClientID], [x].[Client_ID]) AS [Client_ID] ,
                   [x].[Connection_ID]
            FROM   [$(HRPReporting)].[dbo].[xref_Client_Connections] [x]    
                   LEFT OUTER JOIN [$(HRPReporting)].[dbo].[MergedClients] [mg] ON [x].[Client_ID] = [mg].[ClientID]
                                                                                AND [mg].[Product] = 'RAPS'
                                                                                AND [mg].[ClientID] <> 11

IF (OBJECT_ID('tempdb.dbo.[#PlanDatabase]') IS NOT NULL)
BEGIN
    DROP TABLE [#PlanDatabase];
END;

Create Table #PlanDatabase 
	(
		[Id] INT IDENTITY(1, 1) PRIMARY KEY,
		[DatabaseName] sysname NULL,
		[PlanID] varchar(5) NULL
	);

Insert Into #PlanDatabase
		(
			DatabaseName, 
			PlanID
		)	
	Select 
		DISTINCT 
		conn.Connection_Name As DatabaseName, 
		conn.Plan_ID
	From [$(HRPReporting)].dbo.tbl_Clients c with (nolock)
	Inner Join [#Client_Connections] CC with (nolock) 
		On c.Client_ID = CC.Client_ID
	Inner Join  [$(HRPReporting)].dbo.tbl_Connection conn with (nolock)
		On CC.Connection_ID = conn.Connection_ID
	Inner Join [$(HRPInternalReportsDB)].dbo.[RollupPlan] p with (nolock)
		On conn.Plan_ID = p.PlanID
		And p.Active = 1
		And p.UseForRollup = 1
	Inner Join [$(HRPInternalReportsDB)].dbo.RollupClient rc
		On p.ClientIdentifier = rc.ClientIdentifier
		And rc.Active = 1
		And rc.UseForRollup = 1
		And rc.ClientIdentifier=@ClientID
		AND 
		(
				(c.Client_Name = rc.ClientName)
			OR 
				(rc.ClientName = 'Innovation Health')
		)
 
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DECLARE @SourceSQL VARCHAR(MAX)
DECLARE @C INT
DECLARE @ID INT = (SELECT COUNT([Id]) FROM  [#PlanDatabase])
DECLARE @DatabaseName VARCHAR(128)
DECLARE @PlanID varchar(5)


SET @C = 1

WHILE ( @C <= @ID )

BEGIN 

	SELECT @DatabaseName = [DatabaseName],
		   @PlanID		 = [PlanID]
        FROM   [#PlanDatabase]
		WHERE  [ID] = @C

SET @SourceSQL =
'
 SELECT 
		''' + @PlanID + ''' as PlanID,
		[Paymo], 
		[HICN], 
		[MemberIDReceived],
		[HCC],
		[RecordType],
		[Factor],
		[ESRD],
		[Source],
		Getdate() as [LoadDate],
		-1 as [LoadID]
From 
(
 	SELECT 
		[Paymo], 
		[HICN], 
		[MemberIDReceived],
		REPLACE (REPLACE(HCC, ''Disabled_Disease_'', ''D-''),''DSBLD_DISEASE_'', ''D-'') HCC,
		[RecordType],
		Null as [Factor],
		[ESRD],
		''MOR2012'' as Source,		
Value 
FROM ' + @DatabaseName + '.[dbo].[MOR2012] WITH(NOLOCK)
UNPIVOT
(
	Value 
	FOR HCC in (
HCC001	,
HCC002	,
HCC006	,
HCC008	,
HCC009	,
HCC010	,
HCC011	,
HCC012	,
HCC017	,
HCC018	,
HCC019	,
HCC021	,
HCC022	,
HCC023	,
HCC027	,
HCC028	,
HCC029	,
HCC033	,
HCC034	,
HCC035	,
HCC039	,
HCC040	,
HCC046	,
HCC047	,
HCC048	,
HCC051	,
HCC052	,
HCC054	,
HCC055	,
HCC057	,
HCC058	,
HCC070	,
HCC071	,
HCC072	,
HCC073	,
HCC074	,
HCC075	,
HCC076	,
HCC077	,
HCC078	,
HCC079	,
HCC080	,
HCC082	,
HCC083	,
HCC084	,
HCC085	,
HCC086	,
HCC087	,
HCC088	,
HCC096	,
HCC099	,
HCC100	,
HCC103	,
HCC104	,
HCC106	,
HCC107	,
HCC108	,
HCC110	,
HCC111	,
HCC112	,
HCC114	,
HCC115	,
HCC122	,
HCC124	,
HCC134	,
HCC135	,
HCC136	,
HCC137	,
HCC138	,
HCC139	,
HCC140	,
HCC141	,
HCC157	,
HCC158	,
HCC159	,
HCC160	,
HCC161	,
HCC162	,
HCC166	,
HCC167	,
HCC169	,
HCC170	,
HCC173	,
HCC176	,
HCC186	,
HCC188	,
HCC189	,
DSBLD_DISEASE_HCC006	,
DSBLD_DISEASE_HCC034	,
DSBLD_DISEASE_HCC046	,
DSBLD_DISEASE_HCC054	,
DSBLD_DISEASE_HCC055	,
DSBLD_DISEASE_HCC110	,
DSBLD_DISEASE_HCC176	,
INT8	,
INT3	,
INT5	,
INT9	,
INT1	,
INT7	,
Disabled_Disease_HCC039 ,
Disabled_Disease_HCC077	,
Disabled_Disease_HCC085	,
Disabled_Disease_HCC161	,
INT13	,
INT15	,
INT14	,
INT17	,
INT16	,
INT18	,
INT11	,
INT12	,
INT10	

)
) AS HCCUnpivot  
WHERE  Value = 1
AND LEFT(PayMo, 4) In 
		(
		Select distinct 
			[Payment_Year]
		FROM [rev].[tbl_Summary_RskAdj_RefreshPY]
		)

UNION 


SELECT 
		[Paymo], 
		[HICN], 
		[MemberIDReceived],
		REPLACE (REPLACE (REPLACE(HCC, ''Disabled_Disease_'', ''D-''),''DSBLD_DISEASE_'', ''D-''),''D_'',''D-'') HCC,
		[RecordType],
		Null as [Factor],
		Null as [ESRD],
		''MORTypeCPlus'' as Source,
Value 
	FROM ' + @DatabaseName + '.[dbo].[MORTypeCPlus] WITH(NOLOCK)
UNPIVOT
(
	Value 
	FOR HCC in (HCC001	,
HCC002	,
HCC006	,
HCC008	,
HCC009	,
HCC010	,
HCC011	,
HCC012	,
HCC017	,
HCC018	,
HCC019	,
HCC021	,
HCC022	,
HCC023	,
HCC027	,
HCC028	,
HCC029	,
HCC033	,
HCC034	,
HCC035	,
HCC039	,
HCC040	,
HCC046	,
HCC047	,
HCC048	,
HCC054	,
HCC055	,
HCC057	,
HCC058	,
HCC070	,
HCC071	,
HCC072	,
HCC073	,
HCC074	,
HCC075	,
HCC076	,
HCC077	,
HCC078	,
HCC079	,
HCC080	,
HCC082	,
HCC083	,
HCC084	,
HCC085	,
HCC086	,
HCC087	,
HCC088	,
HCC096	,
HCC099	,
HCC100	,
HCC103	,
HCC104	,
HCC106	,
HCC107	,
HCC108	,
HCC110	,
HCC111	,
HCC112	,
HCC114	,
HCC115	,
HCC122	,
HCC124	,
HCC134	,
HCC135	,
HCC136	,
HCC137	,
HCC157	,
HCC158	,
HCC161	,
HCC162	,
HCC166	,
HCC167	,
HCC169	,
HCC170	,
HCC173	,
HCC176	,
HCC186	,
HCC188	,
HCC189	,
D_HCC006	,
D_HCC034	,
D_HCC046	,
D_HCC054	,
D_HCC055	,
D_HCC110	,
D_HCC176	,
INT8	,
INT3	,
INT5	,
INT9	,
INT1	,
INT7	,
D_HCC039	,
D_HCC077	,
D_HCC085	,
D_HCC161	,
INT13	,
INT15	,
INT14	,
INT17	,
INT16	,
INT18	,
INT11	,
INT12	,
INT10	,	
INT19	,
INT20	,
HCC056	,
HCC059	,
HCC060	,
HCC138	,
HCC051	,
HCC052	,
HCC159	
	
)
) AS HCCUnpivot

WHERE  Value = 1
AND LEFT(PayMo, 4) in 
		(
		Select distinct 
			[Payment_Year]
		FROM [rev].[tbl_Summary_RskAdj_RefreshPY]
		)
)A
'
	INSERT INTO 
		[rev].[SummaryRskAdjMORSourcePartC]
		EXEC (@SourceSQL)

		SET @RowCountC = ISNULL(@RowCountC, 0) + @@ROWCOUNT;
		
	SET @C = @C + 1

	END

END

