CREATE TABLE [etl].[EligibilityRecyclingCheck] (
    [EligbilityRecyclingCheckID] INT           IDENTITY (1, 1) NOT NULL,
    [EDSEncounterExportID]       BIGINT        NULL,
    [EDSEncounterID]             BIGINT        NULL,
    [ContractNumber]             NVARCHAR (5)  NULL,
    [HICN]                       NVARCHAR (12) NULL,
    [ServiceStartDate]           SMALLDATETIME NULL,
    [ServiceEndDate]             SMALLDATETIME NULL,
    [LoadID]                     BIGINT        NULL,
    [LoadDate]                   DATETIME      NULL
);

