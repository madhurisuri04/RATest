CREATE TABLE [dbo].[dbt_hcc_prov_type] (
    [Plan_ID]       VARCHAR (5)   NULL,
    [ProcessedBy]   DATETIME      NULL,
    [Provider_Type] VARCHAR (10)  NULL,
    [Submissions]   INT           NULL,
    [Member_Count]  INT           NULL,
    [HCC_Count]     INT           NULL,
    [Order_by]      INT           NULL,
    [Populated]     SMALLDATETIME NULL
);

