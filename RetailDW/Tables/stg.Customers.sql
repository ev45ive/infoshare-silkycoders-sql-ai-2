/*
    Author:      Mateusz Kulesza <ev45ive@gmail.com>
    AI model:    Claude Sonnet 5
    Created:     2026-09-21
    Description: Raw landing zone for customer master extracts. Nullable by
                 default; validation happens in [etl].[LoadCustomers].

    Change log:
    - 2026-09-21 | Ticket: N/A | Mateusz Kulesza | Claude Sonnet 5 | Initial version
*/
CREATE TABLE [stg].[Customers]
(
    [StagingRowId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [CustomerCode] NVARCHAR (20)  NULL,
    [Name]         NVARCHAR (100) NULL,
    [Tier]         NVARCHAR (20)  NULL,
    [Region]       NVARCHAR (50)  NULL,
    [SourceSystem] NVARCHAR (20)  NULL,
    [LoadedAt]     DATETIME2 (3)  NOT NULL CONSTRAINT [DF_stg_Customers_LoadedAt] DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT [PK_stg_Customers] PRIMARY KEY CLUSTERED ([StagingRowId] ASC)
);
