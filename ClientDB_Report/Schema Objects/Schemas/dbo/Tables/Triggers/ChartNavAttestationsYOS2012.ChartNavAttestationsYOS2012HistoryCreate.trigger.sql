CREATE TRIGGER [ChartNavAttestationsYOS2012HistoryCreate]
    ON [dbo].[ChartNavAttestationsYOS2012]
    FOR INSERT, UPDATE 
    AS 
    BEGIN
    	SET NOCOUNT ON

		Insert into ChartNavAttestationsYOS2012History
		(	[AssignmentID], [CoderReview], [DateCoderReview], [CompletedReview], [MedicalRecordRequestID], [ImageID], [HICN], [DOSStart], [DOSEnd], [PageNum],
			[BegPage], [EndPage], [MemberLastName], [MemberFirstName], [DOB], [ProviderPhone], [ProviderFax], [ProviderAddress], [ProviderCity],
			[ProviderState], [ProviderZip], [ProviderLast], [ProviderFirst], [PrintDOS], [DatePrintedDOS], [PrintedLetter], [DatePrintedLetter], [FirstCall],
			[DateFirstCall], [CommentFirstCall], [SecondCall], [DateSecondCall], [CommentSecondCall], [ThirdCall], [DateThirdCall], [CommentThirdCall],
			[FourthCall], [DateFourthCall], [CommentFourthCall], [DateFaxed], [DateRefaxed], [DateReceived], [ScannedATT], [Project], [SubProject],
			[MedicalRecordReason], [DOSReason], [HCC], [PlanID], [PBP], [SCC], [ProviderID], [Filter], [ImageName], [AssignedTo], [AttestationFailure],
			[DateAdded], [AttestationSent], [AttestationSentDate], [LastUpdatingDatetime], [LastUpdateUser], [DeleteFlag], [ProviderTIN]
		)
	select  i.[AssignmentID], i.[CoderReview], i.[DateCoderReview], i.[CompletedReview], i.[MedicalRecordRequestID], i.[ImageID], i.[HICN], i.[DOSStart], i.[DOSEnd], i.[PageNum],
			i.[BegPage], i.[EndPage], i.[MemberLastName], i.[MemberFirstName], i.[DOB], i.[ProviderPhone], i.[ProviderFax], i.[ProviderAddress], i.[ProviderCity],
			i.[ProviderState], i.[ProviderZip], i.[ProviderLast], i.[ProviderFirst], i.[PrintDOS], i.[DatePrintedDOS], i.[PrintedLetter], i.[DatePrintedLetter], i.[FirstCall],
			i.[DateFirstCall], i.[CommentFirstCall], i.[SecondCall], i.[DateSecondCall], i.[CommentSecondCall], i.[ThirdCall], i.[DateThirdCall], i.[CommentThirdCall],
			i.[FourthCall], i.[DateFourthCall], i.[CommentFourthCall], i.[DateFaxed], i.[DateRefaxed], i.[DateReceived], i.[ScannedATT], i.[Project], i.[SubProject],
			i.[MedicalRecordReason], i.[DOSReason], i.[HCC], i.[PlanID], i.[PBP], i.[SCC], i.[ProviderID], i.[Filter], i.[ImageName], i.[AssignedTo], i.[AttestationFailure],
			i.[DateAdded], i.[AttestationSent], i.[AttestationSentDate], SYSDATETIME(), suser_name(), 0, i.[ProviderTIN]
	from inserted i
		left outer join deleted d on (select binary_checksum(*) from inserted where [AssignmentID] = i.[AssignmentID]) = (select binary_checksum(*) from deleted where [AssignmentID] = d.[AssignmentID])
    where d.[AssignmentID] is null
		

    END
