﻿ALTER TABLE [edt].[Range] ADD  CONSTRAINT [DF_Range_ModifiedDT]  DEFAULT (getdate()) FOR [ModifiedDT]