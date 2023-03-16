CREATE TABLE [dbo].[dbt_cn_qa] (
    [Total Coded]                     INT             NULL,
    [Total Unique Part C HCCs]        INT             NULL,
    [Total Unique Part D HCCs]        INT             NULL,
    [Total Dx Passed]                 INT             NULL,
    [Total Unique Part C HCCs Passed] INT             NULL,
    [Total Unique Part D HCCs Passed] INT             NULL,
    [Total Dx Errors]                 INT             NULL,
    [Total Unique Part C HCCs Errors] INT             NULL,
    [Total Unique Part D HCCs Errors] INT             NULL,
    [Total Dx Missed]                 INT             NULL,
    [Total Unique Part C HCCs Missed] INT             NULL,
    [Total Unique Part D HCCs Missed] INT             NULL,
    [Coding Accuracy %]               DECIMAL (10, 1) NULL,
    [Part C Coding Accuracy %]        DECIMAL (10, 1) NULL,
    [Part D Coding Accuracy %]        DECIMAL (10, 1) NULL,
    [Start Date]                      DATETIME        NULL,
    [End Date]                        DATETIME        NULL,
    [Coder ID(s)]                     VARCHAR (3)     NULL,
    [Output Type]                     INT             NULL,
    [Populated]                       SMALLDATETIME   NULL
);

