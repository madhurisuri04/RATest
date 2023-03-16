CREATE TABLE [dbo].[CNCoreProject] (
    [CNCoreProjectID]           INT           IDENTITY (1, 1) NOT NULL,
    [ProjectID]                 INT           NULL,
    [ProjectDescription]        VARCHAR (100)  NULL,
    [ProjectPlannedStartDate]   DATE          NULL,
    [ProjectPlannedEndDate]     DATE          NULL,
    [ProjectType]               VARCHAR (50)  NULL,
    [Area]                      VARCHAR (20)  NULL,
    [WorkflowDisplayName]       VARCHAR (140) NULL,
    [WorkflowStepName]          VARCHAR (100) NULL,
    [WorkFlowStatusDescription] VARCHAR (100) NULL,
    [MedicalRecordCount]        INT           NULL,
    [LoadDate]                  DATETIME      NULL,
    PRIMARY KEY CLUSTERED ([CNCoreProjectID] ASC) WITH (ALLOW_PAGE_LOCKS = ON, ALLOW_ROW_LOCKS = ON, PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF)
);

