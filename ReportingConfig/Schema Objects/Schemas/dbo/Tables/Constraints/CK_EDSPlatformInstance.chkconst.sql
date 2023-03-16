ALTER TABLE [dbo].[EDSPlatformInstance]
    ADD CONSTRAINT [CK_EDSPlatformInstance] 
      CHECK ([EDSPlatformAppCode]='HIM' OR [EDSPlatformAppCode]='EDS' OR [EDSPlatformAppCode]='HHL' OR [EDSPlatformAppCode]='PLC');