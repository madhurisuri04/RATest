﻿ALTER TABLE [dbo].[RollupTableStatusHistory] ADD  DEFAULT (getdate()) FOR [HistoryModifiedDate]