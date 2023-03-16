Create View dbo.vw_RollupTableStatusState
As

Select rc.ClientName,rt.RollupTableName,rts.RollupStatus,rts.RollupState
From dbo.RollupTableStatus rts
Inner Join dbo.RollupTableConfig rtc
      On rts.RollupTableConfigID = rtc.RollupTableConfigID
Inner Join dbo.RollupClient rc
      On rtc.ClientIdentifier = rc.ClientIdentifier
Inner Join dbo.RollupTable rt
      On rtc.RollupTableID = rt.RollupTableID
