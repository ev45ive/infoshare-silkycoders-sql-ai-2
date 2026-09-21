/*
    Author:      Mateusz Kulesza <ev45ive@gmail.com>
    AI model:    Claude Sonnet 5
    Created:     2026-09-21
    Description: Manually logged data quality check results.

    Change log:
    - 2026-09-21 | Ticket: N/A | Mateusz Kulesza | Claude Sonnet 5 | Initial version
*/
CREATE TABLE [dbo].[DataQualityCheck]
(
    [CheckId]       INT            IDENTITY (1, 1) NOT NULL,
    [CheckedAt]     DATETIME2 (3)  NOT NULL CONSTRAINT [DF_DataQualityCheck_CheckedAt] DEFAULT (SYSUTCDATETIME()),
    [TableName]     NVARCHAR (128) NOT NULL,
    [CheckName]     NVARCHAR (100) NOT NULL,
    [ExpectedValue] NVARCHAR (100) NULL,
    [ActualValue]   NVARCHAR (100) NULL,
    [Status]        NVARCHAR (10)  NOT NULL,
    [Notes]         NVARCHAR (400) NULL,
    CONSTRAINT [PK_DataQualityCheck] PRIMARY KEY CLUSTERED ([CheckId] ASC),
    CONSTRAINT [CK_DataQualityCheck_Status] CHECK ([Status] IN (N'PASS', N'FAIL'))
);
