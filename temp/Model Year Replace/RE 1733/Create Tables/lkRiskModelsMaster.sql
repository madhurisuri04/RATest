use HRPReporting

CREATE TABLE [dbo].[lkRiskModelsMaster](
	[lkRiskModelsMasterID] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[PaymentYear] [int] NOT NULL,
	[SplitSegmentNumber] [int] NULL,
	[SplitSegmentWeight] [decimal](20, 4) NULL,
	[PaymStart] [datetime] NULL,
	[PaymEnd] [datetime] NULL,
	[RecordType] [char](1) NULL,
	[PartCD_Flag] [char](1) NULL,
	[RAFactorType] [varchar](5) NULL,
	[NormalizationFactor] [decimal](20, 4) NULL,
	[CodingIntensity] [decimal](20, 4) NULL,
	[MSP_Reduction] [decimal](20, 4) NULL,
	[ESRDMSPReduction] [decimal](20, 4) NULL,
	[Segment] [varchar](50) NULL,
	[CMSModel] [varchar](50) NULL,
	[ModelVersion] [smallint] NULL,
	[BidRate] [varchar](50) NULL,
	[SubmissionModel] [varchar](5) NOT NULL,
	[SubmissionModelNumber] [tinyint] NOT NULL,
	[UserID] [varchar](128) NOT NULL,
	[LoadDate] [datetime] NOT NULL,
	[APCCFlag] [char](1) NULL,
 CONSTRAINT [PK_lkRiskModelsMasterID] PRIMARY KEY CLUSTERED 
(
	[lkRiskModelsMasterID] ASC
)
)

