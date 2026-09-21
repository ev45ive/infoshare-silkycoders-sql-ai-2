/*
    Author:      Mateusz Kulesza <ev45ive@gmail.com>
    AI model:    Claude Sonnet 5
    Created:     2026-09-21
    Description: Loads validated rows from [stg].[InventorySnapshot] into
                 [dbo].[FactInventorySnapshot] and records the outcome in
                 [dbo].[LoadLog].

    Change log:
    - 2026-09-21 | Ticket: N/A | Mateusz Kulesza | Claude Sonnet 5 | Initial version
*/
CREATE PROCEDURE [etl].[LoadInventorySnapshot]
    @SourceSystem NVARCHAR (20) = N'WMS',
    @LoadId       INT           = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @RowsInserted INT = 0,
            @RowsUpdated  INT = 0,
            @RowsRejected INT = 0;

    INSERT INTO [dbo].[LoadLog] ([PackageName], [SourceSystem])
    VALUES (N'etl.LoadInventorySnapshot', @SourceSystem);

    SET @LoadId = CAST(SCOPE_IDENTITY() AS INT);

    BEGIN TRY
        CREATE TABLE #InvData
        (
            [InventorySnapshotKey] BIGINT          NULL,
            [SnapshotDate]         DATE            NOT NULL,
            [ProductKey]           INT             NOT NULL,
            [StoreKey]             INT             NOT NULL,
            [StockQuantity]        DECIMAL (18, 4) NOT NULL,
            [SourceSystem]         NVARCHAR (20)   NOT NULL,
            PRIMARY KEY CLUSTERED ([SnapshotDate], [ProductKey], [StoreKey])
        );

        -- Validate, resolve dimension keys and de-duplicate staging rows.
        -- The latest staged row per business key wins.
        WITH [Ranked] AS
        (
            SELECT  s.[SnapshotDate],
                    p.[ProductKey],
                    st.[StoreKey],
                    s.[StockQuantity],
                    s.[SourceSystem],
                    ROW_NUMBER() OVER (PARTITION BY s.[SnapshotDate], p.[ProductKey], st.[StoreKey]
                                       ORDER BY s.[LoadedAt] DESC, s.[StagingRowId] DESC) AS [RowRank]
            FROM    [stg].[InventorySnapshot] AS s
            JOIN    [dbo].[DimProduct] AS p  ON p.[ProductCode] = s.[ProductCode]
            JOIN    [dbo].[DimStore]   AS st ON st.[StoreCode]  = s.[StoreCode]
            WHERE   s.[SourceSystem]   = @SourceSystem
                AND s.[SnapshotDate]  IS NOT NULL
                AND s.[StockQuantity] IS NOT NULL
        )
        INSERT INTO #InvData
        (
            [SnapshotDate], [ProductKey], [StoreKey], [StockQuantity], [SourceSystem]
        )
        SELECT  [SnapshotDate], [ProductKey], [StoreKey], [StockQuantity], [SourceSystem]
        FROM    [Ranked]
        WHERE   [RowRank] = 1;

        SELECT @RowsRejected = COUNT(*)
        FROM   [stg].[InventorySnapshot] AS s
        LEFT   JOIN [dbo].[DimProduct] AS p  ON p.[ProductCode] = s.[ProductCode]
        LEFT   JOIN [dbo].[DimStore]   AS st ON st.[StoreCode]  = s.[StoreCode]
        WHERE  s.[SourceSystem] = @SourceSystem
           AND (p.[ProductKey]    IS NULL
             OR st.[StoreKey]     IS NULL
             OR s.[SnapshotDate]  IS NULL
             OR s.[StockQuantity] IS NULL);

        BEGIN TRANSACTION;

        UPDATE  t
        SET     t.[InventorySnapshotKey] = f.[InventorySnapshotKey]
        FROM    #InvData                         AS t
        JOIN    [dbo].[FactInventorySnapshot]     AS f
                ON  f.[SnapshotDate] = t.[SnapshotDate]
                AND f.[ProductKey]   = t.[ProductKey]
                AND f.[StoreKey]     = t.[StoreKey];

        UPDATE  #InvData
        SET     [InventorySnapshotKey] = NEXT VALUE FOR [dbo].[InventorySnapshotKeySequence]
        WHERE   [InventorySnapshotKey] IS NULL;

        DECLARE @MergeActions TABLE ([MergeAction] NVARCHAR (10) NOT NULL);

        MERGE [dbo].[FactInventorySnapshot] WITH (HOLDLOCK) AS tgt
        USING #InvData AS src
            ON  tgt.[SnapshotDate] = src.[SnapshotDate]
            AND tgt.[ProductKey]   = src.[ProductKey]
            AND tgt.[StoreKey]     = src.[StoreKey]
        WHEN MATCHED AND tgt.[StockQuantity] <> src.[StockQuantity]
            THEN UPDATE
                SET tgt.[StockQuantity] = src.[StockQuantity],
                    tgt.[SourceSystem]  = src.[SourceSystem],
                    tgt.[LoadId]        = @LoadId
        WHEN NOT MATCHED BY TARGET
            THEN INSERT ([InventorySnapshotKey], [SnapshotDate], [ProductKey], [StoreKey], [StockQuantity], [SourceSystem], [LoadId])
                 VALUES (src.[InventorySnapshotKey], src.[SnapshotDate], src.[ProductKey], src.[StoreKey], src.[StockQuantity], src.[SourceSystem], @LoadId)
        OUTPUT $action INTO @MergeActions ([MergeAction]);

        COMMIT TRANSACTION;

        SELECT  @RowsInserted = SUM(CASE WHEN [MergeAction] = N'INSERT' THEN 1 ELSE 0 END),
                @RowsUpdated  = SUM(CASE WHEN [MergeAction] = N'UPDATE' THEN 1 ELSE 0 END)
        FROM    @MergeActions;

        UPDATE  [dbo].[LoadLog]
        SET     [FinishedAt]   = SYSUTCDATETIME(),
                [Status]       = N'SUCCEEDED',
                [RowsInserted] = ISNULL(@RowsInserted, 0),
                [RowsUpdated]  = ISNULL(@RowsUpdated, 0),
                [RowsRejected] = ISNULL(@RowsRejected, 0)
        WHERE   [LoadId] = @LoadId;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
            ROLLBACK TRANSACTION;

        UPDATE  [dbo].[LoadLog]
        SET     [FinishedAt]   = SYSUTCDATETIME(),
                [Status]       = N'FAILED',
                [ErrorMessage] = ERROR_MESSAGE()
        WHERE   [LoadId] = @LoadId;

        THROW;
    END CATCH
END
