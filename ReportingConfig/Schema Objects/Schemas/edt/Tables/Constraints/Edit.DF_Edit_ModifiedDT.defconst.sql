﻿ALTER TABLE [edt].[Edit] ADD  CONSTRAINT [DF_Edit_ModifiedDT]  DEFAULT (getdate()) FOR [ModifiedDT]