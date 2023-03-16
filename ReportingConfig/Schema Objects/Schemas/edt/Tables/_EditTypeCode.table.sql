/* -- BitValue is a COMPUTED VALUE column -- */

CREATE TABLE [edt].[_EditTypeCode](
	[TypeCode] [smallint] NOT NULL,
	[BitValue]  AS (case when [TypeCode]<=(65) AND [TypeCode]>(0) then CONVERT([bigint],power((2.0),[TypeCode]-(1)),0) when [TypeCode]=(0) then (0)  end),
	[Descr] [varchar](300) NOT NULL,
 CONSTRAINT [PK__EditTypeCode] PRIMARY KEY CLUSTERED 
(
	[TypeCode] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]