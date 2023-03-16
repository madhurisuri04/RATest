CREATE TRIGGER [ChartNavAttestationsYOS2012HistoryDelete]
    ON [dbo].[ChartNavAttestationsYOS2012]
    FOR DELETE
    AS 
    BEGIN
    	SET NOCOUNT ON

		Insert into ChartNavAttestationsYOS2012History
		(	
			[AssignmentID], [CoderReview], [DateCoderReview], [CompletedReview], [MedicalRecordRequestID], [ImageID], [HICN], [DOSStart], [DOSEnd], [PageNum],
			[BegPage], [EndPage], [MemberLastName], [MemberFirstName], [DOB], [ProviderPhone], [ProviderFax], [ProviderAddress], [ProviderCity],
			[ProviderState], [ProviderZip], [ProviderLast], [ProviderFirst], [PrintDOS], [DatePrintedDOS], [PrintedLetter], [DatePrintedLetter], [FirstCall],
			[DateFirstCall], [CommentFirstCall], [SecondCall], [DateSecondCall], [CommentSecondCall], [ThirdCall], [DateThirdCall], [CommentThirdCall],
			[FourthCall], [DateFourthCall], [CommentFourthCall], [DateFaxed], [DateRefaxed], [DateReceived], [ScannedATT], [Project], [SubProject],
			[MedicalRecordReason], [DOSReason], [HCC], [PlanID], [PBP], [SCC], [ProviderID], [Filter], [ImageName], [AssignedTo], [AttestationFailure],
			[DateAdded], [AttestationSent], [AttestationSentDate], [LastUpdatingDatetime], [LastUpdateUser], [DeleteFlag], [ProviderTIN]
		)
	select  
			d.[AssignmentID], d.[CoderReview], d.[DateCoderReview], d.[CompletedReview], d.[MedicalRecordRequestID], d.[ImageID], d.[HICN], d.[DOSStart], d.[DOSEnd], d.[PageNum],
			d.[BegPage], d.[EndPage], d.[MemberLastName], d.[MemberFirstName], d.[DOB], d.[ProviderPhone], d.[ProviderFax], d.[ProviderAddress], d.[ProviderCity],
			d.[ProviderState], d.[ProviderZip], d.[ProviderLast], d.[ProviderFirst], d.[PrintDOS], d.[DatePrintedDOS], d.[PrintedLetter], d.[DatePrintedLetter], d.[FirstCall],
			d.[DateFirstCall], d.[CommentFirstCall], d.[SecondCall], d.[DateSecondCall], d.[CommentSecondCall], d.[ThirdCall], d.[DateThirdCall], d.[CommentThirdCall],
			d.[FourthCall], d.[DateFourthCall], d.[CommentFourthCall], d.[DateFaxed], d.[DateRefaxed], d.[DateReceived], d.[ScannedATT], d.[Project], d.[SubProject],
			d.[MedicalRecordReason], d.[DOSReason], d.[HCC], d.[PlanID], d.[PBP], d.[SCC], d.[ProviderID], d.[Filter], d.[ImageName], d.[AssignedTo], d.[AttestationFailure],
			d.[DateAdded], d.[AttestationSent], d.[AttestationSentDate], SYSDATETIME(), suser_name(), 1, d.[ProviderTIN]
	from deleted d


    END
