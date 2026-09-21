/*
    Author:      Mateusz Kulesza <ev45ive@gmail.com>
    AI model:    Claude Sonnet 5
    Created:     2026-09-21
    Description: Loads validated rows from [stg].[SalesItems] into [dbo].[FactSalesItem]
                 and records the outcome in [dbo].[LoadLog].

    Change log:
    - 2026-09-21 | Ticket: N/A | Mateusz Kulesza | Claude Sonnet 5 | Initial version
    - 2026-09-21 | Ticket: N/A | Mateusz Kulesza | Claude Sonnet 5 | Resolve CustomerKey against the DimCustomer
*/
-- =============================================================================
-- etl.LoadFactSalesItem
--
-- Loads validated rows from [stg].[SalesItems] into [dbo].[FactSalesItem].
--
-- Flow: stg.SalesItems -> #FiData -> MERGE -> dbo.FactSalesItem
-- =============================================================================
CREATE PROCEDURE [etl].[LoadFactSalesItem]
    @SourceSystem NVARCHAR (20) = N'POS',
    @LoadId       INT           = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @RowsInserted INT = 0,
            @RowsUpdated  INT = 0,
            @RowsRejected INT = 0;

    INSERT INTO [dbo].[LoadLog] ([PackageName], [SourceSystem])
    VALUES (N'etl.LoadFactSalesItem', @SourceSystem);

    SET @LoadId = CAST(SCOPE_IDENTITY() AS INT);

    BEGIN TRY
        CREATE TABLE #FiData
        (
            [FactSalesItemKey] BIGINT          NULL,
            [SalesOrderNo]     NVARCHAR (30)   NOT NULL,
            [SalesLineNo]      INT             NOT NULL,
            [SubItemNo]        INT             NOT NULL,
            [SalesDate]        DATE            NOT NULL,
            [ProductKey]       INT             NOT NULL,
            [StoreKey]         INT             NOT NULL,
            [CustomerKey]      INT             NULL,
            [Quantity]         DECIMAL (18, 4) NOT NULL,
            [UnitPrice]        DECIMAL (18, 4) NOT NULL,
            [DiscountAmount]   DECIMAL (18, 4) NOT NULL,
            [LineTotal]        DECIMAL (18, 4) NOT NULL,
            [VatRate]          DECIMAL (5, 4)  NOT NULL,
            [SourceSystem]     NVARCHAR (20)   NOT NULL,
            PRIMARY KEY CLUSTERED ([SalesOrderNo], [SalesLineNo], [SubItemNo])
        );

        -- Validate, resolve dimension keys and de-duplicate staging rows.
        -- The latest staged row per business key wins.
        WITH [Ranked] AS
        (
            SELECT  s.[SalesOrderNo],
                    s.[SalesLineNo],
                    s.[SubItemNo],
                    s.[SalesDate],
                    p.[ProductKey],
                    st.[StoreKey],
                    dc.[CustomerKey],
                    s.[Quantity],
                    s.[UnitPrice],
                    ISNULL(s.[DiscountAmount], 0) AS [DiscountAmount],
                    p.[VatRate],
                    s.[SourceSystem],
                    ROW_NUMBER() OVER (PARTITION BY s.[SalesOrderNo], s.[SalesLineNo], s.[SubItemNo]
                                       ORDER BY s.[LoadedAt] DESC, s.[StagingRowId] DESC) AS [RowRank]
            FROM    [stg].[SalesItems] AS s
            JOIN    [dbo].[DimProduct] AS p  ON p.[ProductCode] = s.[ProductCode]
            JOIN    [dbo].[DimStore]   AS st ON st.[StoreCode]  = s.[StoreCode]
            LEFT JOIN [dbo].[DimCustomer] AS dc
                   ON  dc.[CustomerCode] = s.[CustomerCode]
                   AND dc.[ValidFrom]   <= s.[SalesDate] -- customer version in effect on the sale date, not today's version
                   AND (dc.[ValidTo] IS NULL OR dc.[ValidTo] > s.[SalesDate])
            WHERE   s.[SourceSystem] = @SourceSystem
                AND s.[SalesOrderNo] IS NOT NULL
                AND s.[SalesLineNo]  IS NOT NULL
                AND s.[SubItemNo]    IS NOT NULL
                AND s.[SalesDate]    IS NOT NULL
                AND s.[Quantity]     IS NOT NULL
                AND s.[UnitPrice]    IS NOT NULL
        )
        INSERT INTO #FiData
        (
            [SalesOrderNo], [SalesLineNo], [SubItemNo], [SalesDate], [ProductKey], [StoreKey], [CustomerKey],
            [Quantity], [UnitPrice], [DiscountAmount], [LineTotal], [VatRate], [SourceSystem]
        )
        SELECT  [SalesOrderNo],
                [SalesLineNo],
                [SubItemNo],
                [SalesDate],
                [ProductKey],
                [StoreKey],
                [CustomerKey],
                [Quantity],
                [UnitPrice],
                [DiscountAmount],
                ([Quantity] * [UnitPrice]) - [DiscountAmount] AS [LineTotal],
                [VatRate],
                [SourceSystem]
        FROM    [Ranked]
        WHERE   [RowRank] = 1;

        SELECT @RowsRejected = COUNT(*)
        FROM   [stg].[SalesItems] AS s
        LEFT   JOIN [dbo].[DimProduct] AS p  ON p.[ProductCode] = s.[ProductCode]
        LEFT   JOIN [dbo].[DimStore]   AS st ON st.[StoreCode]  = s.[StoreCode]
        WHERE  s.[SourceSystem] = @SourceSystem
           AND (p.[ProductKey]   IS NULL
             OR st.[StoreKey]    IS NULL
             OR s.[SalesOrderNo] IS NULL
             OR s.[SalesLineNo]  IS NULL
             OR s.[SubItemNo]    IS NULL
             OR s.[SalesDate]    IS NULL
             OR s.[Quantity]     IS NULL
             OR s.[UnitPrice]    IS NULL);

        BEGIN TRANSACTION;

        -- Reuse existing surrogate keys; mint new ones only for new business keys.
        UPDATE  t
        SET     t.[FactSalesItemKey] = f.[FactSalesItemKey]
        FROM    #FiData               AS t
        JOIN    [dbo].[FactSalesItem] AS f
                ON  f.[SalesOrderNo] = t.[SalesOrderNo]
                AND f.[SalesLineNo]  = t.[SalesLineNo]
                AND f.[SubItemNo]    = t.[SubItemNo];

        UPDATE  #FiData
        SET     [FactSalesItemKey] = NEXT VALUE FOR [dbo].[SalesItemKeySequence]
        WHERE   [FactSalesItemKey] IS NULL;

        DECLARE @MergeActions TABLE ([MergeAction] NVARCHAR (10) NOT NULL);

        MERGE [dbo].[FactSalesItem] WITH (HOLDLOCK) AS tgt
        USING #FiData AS src
            ON  tgt.[SalesOrderNo] = src.[SalesOrderNo]
            AND tgt.[SalesLineNo]  = src.[SalesLineNo]
            AND tgt.[SubItemNo]    = src.[SubItemNo]
        WHEN MATCHED AND (   tgt.[SalesDate]      <> src.[SalesDate]
                          OR tgt.[ProductKey]     <> src.[ProductKey]
                          OR tgt.[StoreKey]       <> src.[StoreKey]
                          OR ISNULL(tgt.[CustomerKey], -1) <> ISNULL(src.[CustomerKey], -1)
                          OR tgt.[Quantity]       <> src.[Quantity]
                          OR tgt.[UnitPrice]      <> src.[UnitPrice]
                          OR tgt.[DiscountAmount] <> src.[DiscountAmount]
                          OR tgt.[LineTotal]      <> src.[LineTotal]
                          OR tgt.[VatRate]        <> src.[VatRate])
            THEN UPDATE
                SET tgt.[SalesDate]      = src.[SalesDate],
                    tgt.[ProductKey]     = src.[ProductKey],
                    tgt.[StoreKey]       = src.[StoreKey],
                    tgt.[CustomerKey]    = src.[CustomerKey],
                    tgt.[Quantity]       = src.[Quantity],
                    tgt.[UnitPrice]      = src.[UnitPrice],
                    tgt.[DiscountAmount] = src.[DiscountAmount],
                    tgt.[LineTotal]      = src.[LineTotal],
                    tgt.[VatRate]        = src.[VatRate],
                    tgt.[SourceSystem]   = src.[SourceSystem],
                    tgt.[LoadId]         = @LoadId
        WHEN NOT MATCHED BY TARGET
            THEN INSERT ([FactSalesItemKey], [SalesOrderNo], [SalesLineNo], [SubItemNo], [SalesDate],
                         [ProductKey], [StoreKey], [Quantity], [UnitPrice],
                         [DiscountAmount], [LineTotal], [VatRate], [SourceSystem], [LoadId])
                 VALUES (src.[FactSalesItemKey], src.[SalesOrderNo], src.[SalesLineNo], src.[SubItemNo], src.[SalesDate],
                         src.[ProductKey], src.[StoreKey], src.[Quantity], src.[UnitPrice],
                         src.[DiscountAmount], src.[LineTotal], src.[VatRate], src.[SourceSystem], @LoadId)
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
