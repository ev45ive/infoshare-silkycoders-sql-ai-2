/*
    Author:      Mateusz Kulesza <ev45ive@gmail.com>
    AI model:    Claude Sonnet 5
    Created:     2026-09-21
    Description: Sub-item level detail for sold order lines (e.g. bundle
                 components and add-ons billed separately within a line).

    Change log:
    - 2026-09-21 | Ticket: N/A | Mateusz Kulesza | Claude Sonnet 5 | Initial version
    - 2026-09-21 | Ticket: N/A | Mateusz Kulesza | Claude Sonnet 5 | Add CustomerKey
*/
CREATE TABLE [dbo].[FactSalesItem]
(
    [FactSalesItemKey] BIGINT          NOT NULL,
    [SalesOrderNo]     NVARCHAR (30)   NOT NULL,
    [SalesLineNo]      INT             NOT NULL,
    [SubItemNo]        INT             NOT NULL,
    [SalesDate]        DATE            NOT NULL,
    [ProductKey]       INT             NOT NULL,
    [StoreKey]         INT             NOT NULL,
    [CustomerKey]      INT             NULL,
    [Quantity]         DECIMAL (18, 4) NOT NULL,
    [UnitPrice]        DECIMAL (18, 4) NOT NULL,
    [DiscountAmount]   DECIMAL (18, 4) NOT NULL CONSTRAINT [DF_FactSalesItem_DiscountAmount] DEFAULT (0),
    [LineTotal]        DECIMAL (18, 4) NOT NULL, -- computed in ETL as (Quantity * UnitPrice) - DiscountAmount
    [VatRate]          DECIMAL (5, 4)  NOT NULL,
    [SourceSystem]     NVARCHAR (20)   NOT NULL,
    [LoadId]           INT             NOT NULL,
    CONSTRAINT [PK_FactSalesItem] PRIMARY KEY CLUSTERED ([FactSalesItemKey] ASC),
    CONSTRAINT [UQ_FactSalesItem_Item] UNIQUE NONCLUSTERED ([SalesOrderNo] ASC, [SalesLineNo] ASC, [SubItemNo] ASC),
    CONSTRAINT [FK_FactSalesItem_DimProduct] FOREIGN KEY ([ProductKey]) REFERENCES [dbo].[DimProduct] ([ProductKey]),
    CONSTRAINT [FK_FactSalesItem_DimStore] FOREIGN KEY ([StoreKey]) REFERENCES [dbo].[DimStore] ([StoreKey]),
    CONSTRAINT [FK_FactSalesItem_DimCustomer] FOREIGN KEY ([CustomerKey]) REFERENCES [dbo].[DimCustomer] ([CustomerKey]),
    CONSTRAINT [FK_FactSalesItem_LoadLog] FOREIGN KEY ([LoadId]) REFERENCES [dbo].[LoadLog] ([LoadId])
);
GO

CREATE NONCLUSTERED INDEX [IX_FactSalesItem_SalesDate]
    ON [dbo].[FactSalesItem] ([SalesDate] ASC)
    INCLUDE ([ProductKey], [StoreKey], [LineTotal]);
