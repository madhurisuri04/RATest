CREATE TABLE [dbo].[RptOpsMetricsConfiguration] 
(
    [RptOpsMetricsConfigurationID] INT IDENTITY (1, 1) NOT NULL,
    [ConfigurationDefinitionID] INT NOT NULL,
    [ConfigurationValue] VARCHAR (256) NOT NULL,
    [UserID] VARCHAR(30) NOT NULL,
    [LoadID] BIGINT NOT NULL,
    [LoadDate] DATETIME2 NOT NULL
);