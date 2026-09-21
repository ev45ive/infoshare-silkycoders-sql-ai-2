/*
    Author:      Mateusz Kulesza <ev45ive@gmail.com>
    AI model:    Claude Sonnet 5
    Created:     2026-09-21
    Description: Raw landing zone for order sub-item detail extracts. Everything
                 is nullable on purpose: validation happens in [etl].[LoadFactSalesItem].

    Change log:
    - 2026-09-21 | Ticket: N/A | Mateusz Kulesza | Claude Sonnet 5 | Initial version
    - 2026-09-21 | Ticket: N/A | Mateusz Kulesza | Claude Sonnet 5 | Add CustomerCode (optional - not every sale is tied to an identified customer)
*/
CREATE TABLE [stg].[SalesItems]
(
    [StagingRowId]   BIGINT          IDENTITY (1, 1) NOT NULL,
    [SalesOrderNo]   NVARCHAR (30)   NULL,
    [SalesLineNo]    INT             NULL,
    [SubItemNo]      INT             NULL,
    [SalesDate]      DATE            NULL,
    [ProductCode]    NVARCHAR (20)   NULL,
    [StoreCode]      NVARCHAR (20)   NULL,
    [CustomerCode]   NVARCHAR (20)   NULL,
    [Quantity]       DECIMAL (18, 4) NULL,
    [UnitPrice]      DECIMAL (18, 4) NULL,
    [DiscountAmount] DECIMAL (18, 4) NULL,
    [LineTotal]      DECIMAL (18, 4) NULL,
    [SourceSystem]   NVARCHAR (20)   NULL,
    [LoadedAt]       DATETIME2 (3)   NOT NULL CONSTRAINT [DF_stg_SalesItems_LoadedAt] DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT [PK_stg_SalesItems] PRIMARY KEY CLUSTERED ([StagingRowId] ASC)
);
