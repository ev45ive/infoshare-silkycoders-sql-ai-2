/*
    Author:      Mateusz Kulesza <ev45ive@gmail.com>
    AI model:    Claude Sonnet 5
    Created:     2026-09-21
    Description: Product returns and order adjustments, tied to the original
                 sold order line.

    Change log:
    - 2026-09-21 | Ticket: N/A | Mateusz Kulesza | Claude Sonnet 5 | Initial version
*/
CREATE TABLE [dbo].[FactReturns]
(
    [ReturnKey]    BIGINT          NOT NULL,
    [ReturnNo]     NVARCHAR (30)   NOT NULL,
    [SalesOrderNo] NVARCHAR (30)   NOT NULL,
    [SalesLineNo]  INT             NOT NULL,
    [ReturnDate]   DATE            NOT NULL,
    [ProductKey]   INT             NOT NULL,
    [StoreKey]     INT             NOT NULL,
    [Quantity]     DECIMAL (18, 4) NOT NULL,
    [ReturnAmount] DECIMAL (18, 4) NOT NULL,
    [ReturnReason] NVARCHAR (30)   NULL,
    [Status]       NVARCHAR (20)   NOT NULL CONSTRAINT [DF_FactReturns_Status] DEFAULT (N'REQUESTED'),
    [SourceSystem] NVARCHAR (20)   NOT NULL,
    [LoadId]       INT             NOT NULL,
    CONSTRAINT [PK_FactReturns] PRIMARY KEY CLUSTERED ([ReturnKey] ASC),
    CONSTRAINT [UQ_FactReturns_ReturnNo] UNIQUE NONCLUSTERED ([ReturnNo] ASC),
    CONSTRAINT [CK_FactReturns_Status] CHECK ([Status] IN (N'REQUESTED', N'APPROVED', N'REFUNDED', N'REJECTED')),
    CONSTRAINT [FK_FactReturns_FactSales] FOREIGN KEY ([SalesOrderNo], [SalesLineNo]) REFERENCES [dbo].[FactSales] ([SalesOrderNo], [SalesLineNo]),
    CONSTRAINT [FK_FactReturns_DimProduct] FOREIGN KEY ([ProductKey]) REFERENCES [dbo].[DimProduct] ([ProductKey]),
    CONSTRAINT [FK_FactReturns_DimStore] FOREIGN KEY ([StoreKey]) REFERENCES [dbo].[DimStore] ([StoreKey]),
    CONSTRAINT [FK_FactReturns_LoadLog] FOREIGN KEY ([LoadId]) REFERENCES [dbo].[LoadLog] ([LoadId])
);
GO

CREATE NONCLUSTERED INDEX [IX_FactReturns_ReturnDate]
    ON [dbo].[FactReturns] ([ReturnDate] ASC)
    INCLUDE ([ProductKey], [StoreKey], [ReturnAmount]);
