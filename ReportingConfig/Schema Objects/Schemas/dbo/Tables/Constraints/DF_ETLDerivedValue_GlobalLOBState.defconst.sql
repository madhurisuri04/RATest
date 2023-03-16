ALTER TABLE [dbo].[ETLDerivedValue]
    ADD CONSTRAINT [DF_ETLDerivedValue_GlobalLOBState] DEFAULT ((0)) FOR [GlobalLOBState];

