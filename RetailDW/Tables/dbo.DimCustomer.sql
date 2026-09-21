/*
    Author:      Mateusz Kulesza <ev45ive@gmail.com>
    AI model:    Claude Sonnet 5
    Created:     2026-09-21
    Description: Customer master data with full history

    Change log:
    - 2026-09-21 | Ticket: N/A | Mateusz Kulesza | Claude Sonnet 5 | Initial version
*/
CREATE TABLE [dbo].[DimCustomer]
(
    [CustomerKey]  INT            IDENTITY (1, 1) NOT NULL,
    [CustomerCode] NVARCHAR (20)  NOT NULL,
    [Name]         NVARCHAR (100) NOT NULL,
    [Tier]         NVARCHAR (20)  NOT NULL,
    [Region]       NVARCHAR (50)  NULL,
    [ValidFrom]    DATETIME2 (3)  NOT NULL,
    [ValidTo]      DATETIME2 (3)  NULL,
    [IsCurrent]    BIT            NOT NULL CONSTRAINT [DF_DimCustomer_IsCurrent] DEFAULT (1),
    CONSTRAINT [PK_DimCustomer] PRIMARY KEY CLUSTERED ([CustomerKey] ASC)
);
GO

CREATE NONCLUSTERED INDEX [IX_DimCustomer_CustomerCode]
    ON [dbo].[DimCustomer] ([CustomerCode] ASC, [ValidFrom] ASC);
GO

CREATE UNIQUE NONCLUSTERED INDEX [UX_DimCustomer_CurrentPerCode]
    ON [dbo].[DimCustomer] ([CustomerCode] ASC)
    WHERE ([IsCurrent] = 1);
