CREATE TABLE rev.SummaryRskAdjMORSourcePartD
(
	[ConvertedMORID] [Bigint] IDENTITY(1,1) NOT NULL,
	[PlanID] [Varchar](6) NOT NULL,
	[PayMonth] [Varchar](8) NULL,
	[HICN] [Varchar](12) NULL,
    [MemberIDReceived] [Varchar](12) NULL,
	[HCC] [Varchar](50) NULL,
	[RecordType] [Char](1) NULL,
    [Factor] [Float] Null ,
    [ESRD]  [Varchar](5) Null, 
    [Source] [Varchar](50) Null,
	[LoadDate] [Datetime] NOT NULL,
	[LoadID] [Bigint] NOT NULL
);

