/* -- BitValue is a COMPUTED VALUE column -- */

CREATE TABLE [dve].[_LOBState](
	[LOBStateID] [int] IDENTITY(-1,1) NOT NULL,
	[BitValue]  AS (case when [LOBStateID]<=(65) AND [LOBStateID]>(0) then CONVERT([bigint],power((2.0),[LOBStateID]-(1)),0) when [LOBStateID]=(0) then (0)  end),
	[LOBState] [varchar](2) NOT NULL,
	[EnableEdits] [bit] NOT NULL,
	[EnableTransforms] [bit] NOT NULL,
 CONSTRAINT [PK__LOBState] PRIMARY KEY CLUSTERED 
(
	[LOBStateID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]