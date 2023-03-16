CREATE TABLE [dbo].[tbl_AltHICN_rollup] (
    [tbl_AltHICN_rollupID] INT          IDENTITY (1, 1) NOT NULL,
    [PlanIdentifier]       SMALLINT     NOT NULL,
    [HICN]                 VARCHAR (12) NULL,
    [ALTHICN]              VARCHAR (12) NULL,
    [DataSource]           VARCHAR (15) NULL,
    [FinalHICN]            VARCHAR (12) NULL,
    [LastUpdated]          DATETIME     NULL,
	[MemberIDReceived]	   VARCHAR(12)  NULL    
);

