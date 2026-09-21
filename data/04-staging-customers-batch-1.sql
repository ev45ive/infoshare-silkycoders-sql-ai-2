/*
Sample customer master batch #1 for RetailDW - initial tiers.

Change log:
- 2026-09-21 | Ticket: N/A | Mateusz Kulesza | Claude Sonnet 5 | Initial version
*/
SET NOCOUNT ON;

DELETE FROM [stg].[Customers];

INSERT INTO [stg].[Customers]
    ([CustomerCode], [Name], [Tier], [Region], [SourceSystem])
VALUES
    (N'C-0001', N'Jan Kowalski',        N'Bronze', N'Mazowieckie',   N'CRM'),
    (N'C-0002', N'Anna Nowak',          N'Silver', N'Malopolskie',   N'CRM'),
    (N'C-0003', N'Piotr Wisniewski',    N'Gold',   N'Pomorskie',     N'CRM'),
    (N'C-0004', N'Katarzyna Wojcik',    N'Bronze', N'Dolnoslaskie',  N'CRM'),
    (N'C-0005', N'Marek Kaminski',      N'Silver', N'Mazowieckie',   N'CRM');

PRINT N'stg.Customers loaded with ' + CAST(@@ROWCOUNT AS NVARCHAR(10)) + N' rows (last statement).';
SELECT [TotalStagedRows] = COUNT(*) FROM [stg].[Customers];
