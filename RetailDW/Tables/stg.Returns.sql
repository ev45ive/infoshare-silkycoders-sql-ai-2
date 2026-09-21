/*
    Author:      Mateusz Kulesza <ev45ive@gmail.com>
    AI model:    Claude Sonnet 5
    Created:     2026-09-21
    Description: Raw landing zone for return/adjustment extracts. Nullable by
                 default; validation happens in [etl].[LoadReturns].

    Change log:
    - 2026-09-21 | Ticket: N/A | Mateusz Kulesza | Claude Sonnet 5 | Initial version
*/
CREATE TABLE [stg].[Returns]
(
    [StagingRowId] BIGINT          IDENTITY (1, 1) NOT NULL,
    [ReturnNo]     NVARCHAR (30)   NULL,
    [SalesOrderNo] NVARCHAR (30)   NULL,
    [SalesLineNo]  INT             NULL,
    [ReturnDate]   DATE            NULL,
    [ProductCode]  NVARCHAR (20)   NULL,
    [StoreCode]    NVARCHAR (20)   NULL,
    [Quantity]     DECIMAL (18, 4) NULL,
    [ReturnAmount] DECIMAL (18, 4) NULL,
    [ReturnReason] NVARCHAR (30)   NULL,
    [Status]       NVARCHAR (20)   NULL,
    [SourceSystem] NVARCHAR (20)   NULL,
    [LoadedAt]     DATETIME2 (3)   NOT NULL CONSTRAINT [DF_stg_Returns_LoadedAt] DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT [PK_stg_Returns] PRIMARY KEY CLUSTERED ([StagingRowId] ASC)
);
