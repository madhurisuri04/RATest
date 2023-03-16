CREATE TABLE [dbo].[dbt_cn_tracking] (
    [Medical Records Requested]                       INT           NULL,
    [Medical Records Received]                        INT           NULL,
    [Medical Records Remaining for Retrieval]         INT           NULL,
    [Medical Records First Pass Coded]                INT           NULL,
    [Medical Records Remaining for First Pass Coding] INT           NULL,
    [Medical Records RTCMS Eligible]                  INT           NULL,
    [Medical Records RTCMS Completed]                 INT           NULL,
    [Medical Records Remaining for RTCMS Review]      INT           NULL,
    [Medical Records QA Reviewed]                     INT           NULL,
    [Project Start Date]                              DATETIME      NULL,
    [Project End Date]                                DATETIME      NULL,
    [Start Date]                                      DATETIME      NULL,
    [End Date]                                        DATETIME      NULL,
    [Include Home Assessments]                        VARCHAR (3)   NOT NULL,
    [Output Type]                                     INT           NULL,
    [Populated]                                       SMALLDATETIME NULL
);

