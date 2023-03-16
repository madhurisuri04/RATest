CREATE TABLE [dbo].[dbt_file_upload] (
    [plan_id]      VARCHAR (5)   NULL,
    [upload_month] DATETIME      NULL,
    [file_type]    VARCHAR (100) NULL,
    [file_count]   INT           NULL,
    [line_count]   INT           NULL,
    [populated]    SMALLDATETIME NULL
);

