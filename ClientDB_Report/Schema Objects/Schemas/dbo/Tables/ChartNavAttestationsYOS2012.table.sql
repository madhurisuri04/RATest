﻿CREATE TABLE [dbo].[ChartNavAttestationsYOS2012](
	[AssignmentID] [int] IDENTITY(1,1) NOT NULL,
	[CoderReview] varchar (255) NULL,
	[DateCoderReview] [datetime2](7) NULL,
	[CompletedReview] [datetime2](7) NULL,
	[MedicalRecordRequestID] varchar (10) NULL,
	[ImageID] int NULL,
	[HICN] varchar (15) NULL,
	[DOSStart] date NULL,
	[DOSEnd] date NULL,
	[PageNum] int NULL,
	[BegPage] int NULL,
	[EndPage] int NULL,
	[MemberLastName] varchar (255) NULL,
	[MemberFirstName] varchar (255) NULL,
	[DOB] date NULL,
	[ProviderPhone] varchar (20) NULL,
	[ProviderFax] varchar (20) NULL,
	[ProviderAddress] varchar (255) NULL,
	[ProviderCity] varchar (255) NULL,
	[ProviderState] char (2) NULL,
	[ProviderZip] char (5) NULL,
	[ProviderLast] varchar (255) NULL,
	[ProviderFirst] varchar (255) NULL,
	[PrintDOS] bit NULL,
	[DatePrintedDOS] date NULL,
	[PrintedLetter] bit NULL,
	[DatePrintedLetter] date NULL,
	[FirstCall] bit NULL,
	[DateFirstCall] date NULL,
	[CommentFirstCall] varchar (500) NULL,
	[SecondCall] bit NULL,
	[DateSecondCall] date NULL,
	[CommentSecondCall] varchar (500) NULL,
	[ThirdCall] bit NULL,
	[DateThirdCall] date NULL,
	[CommentThirdCall] varchar (500) NULL,
	[FourthCall] bit NULL,
	[DateFourthCall] date NULL,
	[CommentFourthCall] varchar (500) NULL,
	[DateFaxed] date NULL,
	[DateRefaxed] date NULL,
	[DateReceived] date NULL,
	[ScannedATT] date NULL,
	[Project] varchar (255) NULL,
	[SubProject] varchar (255) NULL,
	[MedicalRecordReason] varchar (255) NULL,
	[DOSReason] varchar (255) NULL,
	[HCC] varchar (255) NULL,
	[PlanID] char (5) NULL,
	[PBP] varchar (3) NULL,
	[SCC] char (5) NULL,
	[ProviderID] varchar (40) NULL,
	[Filter] varchar (255) NULL,
	[ImageName] varchar (255) NULL,
	[AssignedTo] varchar (100) NULL,
	[AttestationFailure] varchar(100) NULL,
	[DateAdded] date NULL,
	[AttestationSent] bit NULL default (0),
	[AttestationSentDate] date NULL,
	[ProviderTIN] varchar (20)
) ON [PRIMARY]
