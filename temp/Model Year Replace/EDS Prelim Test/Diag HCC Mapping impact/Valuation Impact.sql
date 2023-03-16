
select * 
into [Prodsupport].dbo.[tbl_NewHCC]
from 
(
select hicn, hcc_label from [Prodsupport].dbo.[tbl_Summary_RskAdj_EDS_Preliminary_03032022_After] where paymentyear = 2021
except
select hicn, hcc_label from [Prodsupport].dbo.[tbl_Summary_RskAdj_EDS_Preliminary_03032022_Before] where paymentyear = 2021
) a

select distinct a.* 
into [Prodsupport].dbo.[tbl_Summary_RskAdj_EDS_Preliminary_03032022_New]
from 
	[Prodsupport].dbo.[tbl_Summary_RskAdj_EDS_Preliminary_03032022_After] a,
	[Prodsupport].dbo.[tbl_NewHCC] b
where a.paymentyear = 2021
and a.hicn = b.hicn
and a.hcc_label = b.hcc_label

drop table #FromCoding
select distinct hicn, hcc_label 
into #FromCoding
from [Prodsupport].dbo.[tbl_Summary_RskAdj_EDS_Preliminary_03032022_New] a
where RecordID is not null
and riskAdjustable = 1
and ReplacementEncounterSwitch >= 4
and not exists (
	select 1 from [Prodsupport].dbo.[tbl_Summary_RskAdj_EDS_Preliminary_03032022_New] b
	where a.HICN = b.HICN
	and a.HCC_Label = b.HCC_Label
	and b.RecordID is null
	and riskAdjustable = 1
)


select * from #FromCoding