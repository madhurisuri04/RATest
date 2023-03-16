CREATE TABLE [etl].[SummaryIntermediatePartDRskAdjRAPSPreliminary]
    (
        SummaryIntermediatePartDRskAdjRAPSPreliminaryID BIGINT IDENTITY(1, 1) NOT NULL,
        PaymentYear INT NOT NULL,
        ModelYear INT NULL,
        HICN VARCHAR(12) NULL,
        PartDRAFTProjected CHAR(2) NULL,
        RAPSDiagHCCRollupID INT NOT NULL,
        ProcessedBy SMALLDATETIME NOT NULL,
        DiagnosisCode VARCHAR(7) NULL,
        FileID VARCHAR(18) NULL,
        PatientControlNumber VARCHAR(40) NULL,
        SeqNumber VARCHAR(7) NULL,
        ThruDate SMALLDATETIME NULL,
        VoidIndicator BIT NULL,
        Deleted CHAR(1) NULL,
        SourceId INT NULL,
        ProviderId VARCHAR(40) NULL,
        RAC CHAR(1) NULL,
        RxHCCLabel VARCHAR(50) NULL,
        RxHCCNumber INT NULL
    );