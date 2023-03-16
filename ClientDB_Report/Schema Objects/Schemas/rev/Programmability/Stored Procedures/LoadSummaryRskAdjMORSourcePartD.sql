/*******************************************************************************************************************************
* Name			:	[rev].[LoadSummaryRskAdjMORSourcePartD]
* Type 			:	Stored Procedure          
* Author       	:	Anand
*JIRA#          :   RRI-1236
* Date          :	10/06/2021
* Version		:	1.0
* Version History :
  Author			Date		Version#	TFS Ticket#			Description
* -----------------	----------	--------	-----------			------------
    Anand			10/06/2021	1.0			RRI-1236			Load rev.LoadSummaryRskAdjMORSourcePartD table
	Anand			11/15/2021	1.1			RRI-1802			Modify Proc to loop Plan DB's to insert into SummaryRskAdjMORSourcePartD table
*********************************************************************************************************************************/
CREATE PROCEDURE [rev].[LoadSummaryRskAdjMORSourcePartD]
(
	@ClientID INT,
	@RowCountD INT OUT
)
AS

   BEGIN

SET @RowCountD = 0;

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
		REPLACE (REPLACE(HCC, ''NONAGED_'', ''D-''),''RX'', '''') HCC,
		[RecordType],
		Null as [Factor],
		Null as [ESRD],
		''MORD_2016Forward'' as Source,
		Value 
FROM ' + @DatabaseName + '.[dbo].[MORD_2016Forward] WITH(NOLOCK)
UNPIVOT
(
	Value 
	FOR HCC in (
       [RXHCC1]
      ,[RXHCC5]
      ,[RXHCC15]
      ,[RXHCC16]
      ,[RXHCC17]
      ,[RXHCC18]
      ,[RXHCC19]
      ,[RXHCC30]
      ,[RXHCC31]
      ,[RXHCC40]
      ,[RXHCC41]
      ,[RXHCC42]
      ,[RXHCC43]
      ,[RXHCC45]
      ,[RXHCC54]
      ,[RXHCC55]
      ,[RXHCC65]
      ,[RXHCC66]
      ,[RXHCC67]
      ,[RXHCC68]
      ,[RXHCC80]
      ,[RXHCC82]
      ,[RXHCC83]
      ,[RXHCC84]
      ,[RXHCC87]
      ,[RXHCC95]
      ,[RXHCC96]
      ,[RXHCC97]
      ,[RXHCC98]
      ,[RXHCC111]
      ,[RXHCC112]
      ,[RXHCC130]
      ,[RXHCC131]
      ,[RXHCC132]
      ,[RXHCC133]
      ,[RXHCC134]
      ,[RXHCC135]
      ,[RXHCC145]
      ,[RXHCC146]
      ,[RXHCC147]
      ,[RXHCC148]
      ,[RXHCC156]
      ,[RXHCC157]
      ,[RXHCC159]
      ,[RXHCC160]
      ,[RXHCC161]
      ,[RXHCC163]
      ,[RXHCC164]
      ,[RXHCC165]
      ,[RXHCC166]
      ,[RXHCC168]
      ,[RXHCC185]
      ,[RXHCC186]
      ,[RXHCC187]
      ,[RXHCC188]
      ,[RXHCC193]
      ,[RXHCC206]
      ,[RXHCC207]
      ,[RXHCC215]
      ,[RXHCC216]
      ,[RXHCC225]
      ,[RXHCC226]
      ,[RXHCC227]
      ,[RXHCC241]
      ,[RXHCC243]
      ,[RXHCC260]
      ,[RXHCC261]
      ,[RXHCC262]
      ,[RXHCC263]
      ,[RXHCC311]
      ,[RXHCC314]
      ,[RXHCC316]
      ,[RXHCC355]
      ,[RXHCC395]
      ,[RXHCC396]
      ,[RXHCC397]
      ,[NONAGED_RXHCC1]
      ,[NONAGED_RXHCC130]
      ,[NONAGED_RXHCC131]
      ,[NONAGED_RXHCC132]
      ,[NONAGED_RXHCC133]
      ,[NONAGED_RXHCC134]
      ,[NONAGED_RXHCC135]
      ,[NONAGED_RXHCC160]
      ,[NONAGED_RXHCC163]
      ,[NONAGED_RXHCC145]
      ,[NONAGED_RXHCC164]
      ,[NONAGED_RXHCC165]
)
) AS HCCUnpivot  
WHERE  Value = 1
AND LEFT(PayMo, 4) In 
		(
		Select distinct 
			[Payment_Year]
		FROM [rev].[tbl_Summary_RskAdj_RefreshPY]
		)
)A
'
	INSERT INTO [rev].[SummaryRskAdjMORSourcePartD]
		
		EXEC (@SourceSQL)

	SET @RowCountD = ISNULL(@RowCountD, 0) + @@ROWCOUNT;

	SET @C = @C + 1

	END
END