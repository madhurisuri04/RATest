/* -- BitValue is a COMPUTED VALUE column -- */

CREATE TABLE [dve].[_LOBCode](
	[LOBCode] [smallint] NOT NULL,
	[BitValue]  AS (case when [LOBCode]<=(65) AND [LOBCode]>(0) then CONVERT([bigint],power((2.0),[LOBCode]-(1)),0) when [LOBCode]=(0) then (0)  end),
	[Descr] [varchar](300) NOT NULL,
	[EnableEdits] [bit] NOT NULL,
	[EnableTransforms] [bit] NOT NULL,
 CONSTRAINT [PK__LOBCode] PRIMARY KEY CLUSTERED 
(
	[LOBCode] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]