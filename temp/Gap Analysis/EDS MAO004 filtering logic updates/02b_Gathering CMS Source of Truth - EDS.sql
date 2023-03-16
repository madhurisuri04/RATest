--===============================================================================================================================================================
--EDS Extract
--Aetna Portion
IF OBJECT_ID (N'TempDB..#temp', N'U') IS NOT NULL DROP TABLE #temp;
GO
select	distinct m.*, FinalHICN = m.BeneficiaryIdentifier 
into	#temp
from	Aetna_ClientRepo.dbo.MAO004Response m 
Where	(	BeneficiaryIdentifier in (Select MemberNumber from ProdSupport.dbo.AETGapCheck_001a_UniqueMembers_AltHICN) 
			OR
			BeneficiaryIdentifier in (Select FinalMemberNumber from ProdSupport.dbo.AETGapCheck_001a_UniqueMembers_AltHICN)
		)
	and m.ThroughDateofService between '1/1/2019' and '12/31/2019'
go

create nonclustered index [IDX_BI] on #temp (BeneficiaryIdentifier)
create nonclustered index [IDX_MAO004ResponseID] on #temp (MAO004ResponseID)
go

Update	a
Set		a.FinalHICN = b.FinalMemberNumber
from	#temp a
	join	ProdSupport.dbo.AETGapCheck_001a_UniqueMembers_AltHICN b
		on	a.BeneficiaryIdentifier = b.MemberNumber
go

IF OBJECT_ID (N'TempDB..#temp2', N'U') IS NOT NULL DROP TABLE #temp2;
GO
SELECT	MAO004ResponseID = cast(a.MAO004ResponseID as bigint),
		a.BeneficiaryIdentifier,
		a.FinalHICN,
		a.EncounterICN,
		a.EncounterTypeSwitch,
		a.ICNofEncounterLinkedTo,
		a.AllowedDisallowedStatusofEncounterLinkedTo,
		a.EncounterLinkedToMAO004ResponseId,
		a.AllowedDisallowedFlagRiskAdjustment,
		a.AllowedDisallowedFlagRiskReasonCode,
		a.EncounterSubmissionDate,
		a.FromDateofService,
		a.ThroughDateofService,
		b.DiagnosisCode,
		b.AddOrDeleteFlag,
		b.IsActive,
		RiskAdjustable = 0,
		ProviderType = CAST(null as varchar(2))
into	#temp2
from	#temp a		--Aetna_ClientRepo.dbo.MAO004Response a 
    join Aetna_ClientRepo.dbo.MAO004ResponseDiagnosisCode b
		  on a.MAO004ResponseID = b.MAO004ResponseID
go


create nonclustered index [IDX_EncounterICN] on #temp2 (EncounterICN)
create nonclustered index [IDX_EncounterICN_Dx] on #temp2 (EncounterICN, DiagnosisCode)
create nonclustered index [IDX_ICNofEncounterLinkedTo] on #temp2 (ICNofEncounterLinkedTo)
create nonclustered index [IDX_EncounterTypeSwitch] on #temp2 (EncounterTypeSwitch)
create nonclustered index [IDX_AddorDeleteFlag] on #temp2 (AddorDeleteFlag)
go


Update	a
Set		a.RiskAdjustable = 1
FROM	#temp2 a
WHERE	a.EncounterSubmissionDate between '01/01/2019' AND '8/2/2021' --and a.BeneficiaryIdentifier = '9RX0V26YQ30'
	AND	(	(a.AllowedDisallowedFlagRiskAdjustment = 'A' and a.EncounterTypeSwitch <> '7')
			OR 
			a.EncounterTypeSwitch IN ('8','9')
			OR 
			(a.EncounterTypeSwitch = '7' AND a.AllowedDisallowedStatusofEncounterLinkedTo = 'A')
		)	
	AND a.AddOrDeleteFlag = 'A'
	AND a.EncounterTypeSwitch NOT IN ('2','5')
go


IF OBJECT_ID (N'TempDB..#temp3', N'U') IS NOT NULL DROP TABLE #temp3;
GO
Select	distinct ICNofEncounterLinkedTo, DiagnosisCode
into	#temp3
from	#temp2
Where	AddOrDeleteFlag = 'D'
go

create nonclustered index [IDX_ICNofEncounterLinkedTo_Dx] on #temp3 (ICNofEncounterLinkedTo, DiagnosisCode)
go

Update	a
Set		RiskAdjustable = 0
from	#temp2 a
	join	#temp3 b
		on	a.EncounterICN = b.ICNofEncounterLinkedTo
		and	a.DiagnosisCode = b.DiagnosisCode
go







--AetIH Portion
IF OBJECT_ID (N'TempDB..#TempIH', N'U') IS NOT NULL DROP TABLE #TempIH;
GO
select	distinct m.*, FinalHICN = m.BeneficiaryIdentifier 
into	#TempIH
from	AetIH_ClientRepo.dbo.MAO004Response m 
Where	(	BeneficiaryIdentifier in (Select MemberNumber from ProdSupport.dbo.AETGapCheck_001a_UniqueMembers_AltHICN) 
			OR
			BeneficiaryIdentifier in (Select FinalMemberNumber from ProdSupport.dbo.AETGapCheck_001a_UniqueMembers_AltHICN)
		)
	and m.ThroughDateofService between '1/1/2019' and '12/31/2019'
go

create nonclustered index [IDX_BI] on #TempIH (BeneficiaryIdentifier)
create nonclustered index [IDX_MAO004ResponseID] on #TempIH (MAO004ResponseID)
go

Update	a
Set		a.FinalHICN = b.FinalMemberNumber
from	#TempIH a
	join	ProdSupport.dbo.AETGapCheck_001a_UniqueMembers_AltHICN b
		on	a.BeneficiaryIdentifier = b.MemberNumber
go

IF OBJECT_ID (N'TempDB..#TempIH2', N'U') IS NOT NULL DROP TABLE #TempIH2;
GO
SELECT	MAO004ResponseID = cast(a.MAO004ResponseID as bigint),
		a.BeneficiaryIdentifier,
		a.FinalHICN,
		a.EncounterICN,
		a.EncounterTypeSwitch,
		a.ICNofEncounterLinkedTo,
		a.AllowedDisallowedStatusofEncounterLinkedTo,
		a.EncounterLinkedToMAO004ResponseId,
		a.AllowedDisallowedFlagRiskAdjustment,
		a.AllowedDisallowedFlagRiskReasonCode,
		a.EncounterSubmissionDate,
		a.FromDateofService,
		a.ThroughDateofService,
		b.DiagnosisCode,
		b.AddOrDeleteFlag,
		b.IsActive,
		RiskAdjustable = 0,
		ProviderType = CAST(null as varchar(2))
into	#TempIH2
from	#TempIH a		--AetIH_ClientRepo.dbo.MAO004Response a 
    join AetIH_ClientRepo.dbo.MAO004ResponseDiagnosisCode b
		  on a.MAO004ResponseID = b.MAO004ResponseID
go


create nonclustered index [IDX_EncounterICN] on #TempIH2 (EncounterICN)
create nonclustered index [IDX_EncounterICN_Dx] on #TempIH2 (EncounterICN, DiagnosisCode)
create nonclustered index [IDX_ICNofEncounterLinkedTo] on #TempIH2 (ICNofEncounterLinkedTo)
create nonclustered index [IDX_EncounterTypeSwitch] on #TempIH2 (EncounterTypeSwitch)
create nonclustered index [IDX_AddorDeleteFlag] on #TempIH2 (AddorDeleteFlag)
go


Update	a
Set		a.RiskAdjustable = 1
FROM	#TempIH2 a
WHERE	a.EncounterSubmissionDate between '01/01/2019' AND '8/2/2021' --and a.BeneficiaryIdentifier = '9RX0V26YQ30'
	AND	(	(a.AllowedDisallowedFlagRiskAdjustment = 'A' and a.EncounterTypeSwitch <> '7')
			OR 
			a.EncounterTypeSwitch IN ('8','9')
			OR 
			(a.EncounterTypeSwitch = '7' AND a.AllowedDisallowedStatusofEncounterLinkedTo = 'A')
		)	
	AND a.AddOrDeleteFlag = 'A'
	AND a.EncounterTypeSwitch NOT IN ('2','5')
go


IF OBJECT_ID (N'TempDB..#TempIH3', N'U') IS NOT NULL DROP TABLE #TempIH3;
GO
Select	distinct ICNofEncounterLinkedTo, DiagnosisCode
into	#TempIH3
from	#TempIH2
Where	AddOrDeleteFlag = 'D'
go

create nonclustered index [IDX_ICNofEncounterLinkedTo_Dx] on #TempIH3 (ICNofEncounterLinkedTo, DiagnosisCode)
go

Update	a
Set		RiskAdjustable = 0
from	#TempIH2 a
	join	#TempIH3 b
		on	a.EncounterICN = b.ICNofEncounterLinkedTo
		and	a.DiagnosisCode = b.DiagnosisCode
go


		--Capturing previous run		
		insert into	ProdSupport.dbo.hst_AETGapCheck_002e_EDS_Source
		select * from ProdSupport.dbo.AETGapCheck_002e_EDS_Source except select * from ProdSupport.dbo.hst_AETGapCheck_002e_EDS_Source 
		go

		truncate table 	ProdSupport.dbo.AETGapCheck_002e_EDS_Source
		go



declare @PopulatedDate datetime = getdate();
insert into	ProdSupport.dbo.AETGapCheck_002e_EDS_Source
select	RunID = 9,
		LOB = 'AET',
		a.*,
		PopulatedDate = @PopulatedDate
from	#Temp2 a
union
select	RunID = 9,
		LOB = 'IH',
		a.*,
		PopulatedDate = @PopulatedDate
from	#TempIH2 a
go--(21895170 row(s) affected)





declare @PopulatedDate datetime = getdate();
insert into ProdSupport.dbo.AETGapCheck_002e_EDS_Source (
		RunID,
		LOB,
		MAO004ResponseID,
		BeneficiaryIdentifier,
		FinalHICN,
		EncounterSubmissionDate,
		FromDateofService,
		ThroughDateofService,
		DiagnosisCode,
		RiskAdjustable,
		PopulatedDate,
		ProviderType
		)
SELECT	a.RunID,
		a.LOB,
		MAO004ResponseID = cast(a.RAPS_DiagHCC_RollupID as bigint),
		BeneficiaryIdentifier = a.HICN,
		a.FinalHICN,
		EncounterSubmissionDate = a.ProcessedBy,
		FromDateofService = a.FromDate,
		ThroughDateofService = a.ThruDate,
		a.DiagnosisCode,
		RiskAdjustable = 1,
		PopulatedDate = @PopulatedDate,
		a.ProviderType--select top 10 *
FROM	ProdSupport.dbo.AETGapCheck_002d_RAPS_Source [a]
	JOIN	ProdSupport.dbo.AETGapCheck_001e_SupplementalRAPSInpatient [s]
		ON	[a].[ProviderType] = [s].[ProviderType]
        AND YEAR([a].[ThruDate]) + 1 = [s].[PaymentYear]
go--(1364256 row(s) affected)

