/*
Data quality check log entry for RetailDW.

Change log:
- 2026-09-21 | Ticket: N/A | Mateusz Kulesza | Claude Sonnet 5 | Initial version
*/
SET NOCOUNT ON;

INSERT INTO [dbo].[DataQualityCheck]
    ([TableName], [CheckName], [ExpectedValue], [ActualValue], [Status], [Notes])
VALUES
    (N'FactInventorySnapshot', N'Store coverage per snapshot date', N'5 stores (2026-02-09)', N'2 stores (2026-02-09)', N'FAIL',
     N'S-WAW-02, S-GDA-01 and S-WRO-01 did not send a stock feed for this date.');

PRINT N'dbo.DataQualityCheck loaded with ' + CAST(@@ROWCOUNT AS NVARCHAR(10)) + N' rows (last statement).';
