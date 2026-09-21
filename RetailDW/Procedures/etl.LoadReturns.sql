/*
    Author:      Mateusz Kulesza <ev45ive@gmail.com>
    AI model:    Claude Sonnet 5
    Created:     2026-09-21
    Description: Loads validated rows from [stg].[Returns] into [dbo].[FactReturns]
                 and records the outcome in [dbo].[LoadLog].

    Change log:
    - 2026-09-21 | Ticket: N/A | Mateusz Kulesza | Claude Sonnet 5 | Initial version
*/
CREATE PROCEDURE [etl].[LoadReturns]
    @SourceSystem NVARCHAR (20) = N'POS',
    @LoadId       INT           = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @RowsInserted INT = 0,
            @RowsUpdated  INT = 0,
            @RowsRejected INT = 0;

    DECLARE @AllowedStatus TABLE ([Status] NVARCHAR (20) NOT NULL);

    INSERT INTO @AllowedStatus ([Status])
    VALUES (N'REQUESTED'), (N'APPROVED'), (N'REFUNDED'), (N'REJECTED');

    INSERT INTO [dbo].[LoadLog] ([PackageName], [SourceSystem])
    VALUES (N'etl.LoadReturns', @SourceSystem);

    SET @LoadId = CAST(SCOPE_IDENTITY() AS INT);

    BEGIN TRY
        CREATE TABLE #RetData
        (
            [ReturnKey]    BIGINT          NULL,
            [ReturnNo]     NVARCHAR (30)   NOT NULL,
            [SalesOrderNo] NVARCHAR (30)   NOT NULL,
            [SalesLineNo]  INT             NOT NULL,
            [ReturnDate]   DATE            NOT NULL,
            [ProductKey]   INT             NOT NULL,
            [StoreKey]     INT             NOT NULL,
            [Quantity]     DECIMAL (18, 4) NOT NULL,
            [ReturnAmount] DECIMAL (18, 4) NOT NULL,
            [ReturnReason] NVARCHAR (30)   NULL,
            [Status]       NVARCHAR (20)   NOT NULL,
            [SourceSystem] NVARCHAR (20)   NOT NULL,
            PRIMARY KEY CLUSTERED ([ReturnNo])
        );

        -- Validate, resolve dimension keys and de-duplicate staging rows.
        -- The latest staged row per business key wins.
        WITH [Ranked] AS
        (
            SELECT  s.[ReturnNo],
                    s.[SalesOrderNo],
                    s.[SalesLineNo],
                    s.[ReturnDate],
                    p.[ProductKey],
                    st.[StoreKey],
                    s.[Quantity],
                    s.[ReturnAmount],
                    s.[ReturnReason],
                    ISNULL(s.[Status], N'REQUESTED') AS [Status],
                    s.[SourceSystem],
                    ROW_NUMBER() OVER (PARTITION BY s.[ReturnNo]
                                       ORDER BY s.[LoadedAt] DESC, s.[StagingRowId] DESC) AS [RowRank]
            FROM    [stg].[Returns] AS s
            JOIN    [dbo].[DimProduct] AS p  ON p.[ProductCode] = s.[ProductCode]
            JOIN    [dbo].[DimStore]   AS st ON st.[StoreCode]  = s.[StoreCode]
            JOIN    [dbo].[FactSales]  AS fs ON fs.[SalesOrderNo] = s.[SalesOrderNo] AND fs.[SalesLineNo] = s.[SalesLineNo]
            WHERE   s.[SourceSystem]  = @SourceSystem
                AND s.[ReturnNo]     IS NOT NULL
                AND s.[SalesOrderNo] IS NOT NULL
                AND s.[SalesLineNo]  IS NOT NULL
                AND s.[ReturnDate]   IS NOT NULL
                AND s.[Quantity]     IS NOT NULL
                AND s.[ReturnAmount] IS NOT NULL
                AND ISNULL(s.[Status], N'REQUESTED') IN (SELECT [Status] FROM @AllowedStatus)
        )
        INSERT INTO #RetData
        (
            [ReturnNo], [SalesOrderNo], [SalesLineNo], [ReturnDate], [ProductKey], [StoreKey],
            [Quantity], [ReturnAmount], [ReturnReason], [Status], [SourceSystem]
        )
        SELECT  [ReturnNo], [SalesOrderNo], [SalesLineNo], [ReturnDate], [ProductKey], [StoreKey],
                [Quantity], [ReturnAmount], [ReturnReason], [Status], [SourceSystem]
        FROM    [Ranked]
        WHERE   [RowRank] = 1;

        SELECT @RowsRejected = COUNT(*)
        FROM   [stg].[Returns] AS s
        LEFT   JOIN [dbo].[DimProduct] AS p  ON p.[ProductCode] = s.[ProductCode]
        LEFT   JOIN [dbo].[DimStore]   AS st ON st.[StoreCode]  = s.[StoreCode]
        LEFT   JOIN [dbo].[FactSales]  AS fs ON fs.[SalesOrderNo] = s.[SalesOrderNo] AND fs.[SalesLineNo] = s.[SalesLineNo]
        WHERE  s.[SourceSystem] = @SourceSystem
           AND (p.[ProductKey]   IS NULL
             OR st.[StoreKey]    IS NULL
             OR fs.[SalesKey]    IS NULL
             OR s.[ReturnNo]     IS NULL
             OR s.[SalesOrderNo] IS NULL
             OR s.[SalesLineNo]  IS NULL
             OR s.[ReturnDate]   IS NULL
             OR s.[Quantity]     IS NULL
             OR s.[ReturnAmount] IS NULL
             OR (s.[Status] IS NOT NULL AND s.[Status] NOT IN (SELECT [Status] FROM @AllowedStatus)));

        BEGIN TRANSACTION;

        -- Reuse existing surrogate keys; mint new ones only for new business keys.
        UPDATE  t
        SET     t.[ReturnKey] = f.[ReturnKey]
        FROM    #RetData             AS t
        JOIN    [dbo].[FactReturns]  AS f ON f.[ReturnNo] = t.[ReturnNo];

        UPDATE  #RetData
        SET     [ReturnKey] = NEXT VALUE FOR [dbo].[ReturnKeySequence]
        WHERE   [ReturnKey] IS NULL;

        DECLARE @MergeActions TABLE ([MergeAction] NVARCHAR (10) NOT NULL);

        MERGE [dbo].[FactReturns] WITH (HOLDLOCK) AS tgt
        USING #RetData AS src
            ON  tgt.[ReturnNo] = src.[ReturnNo]
        WHEN MATCHED AND (   tgt.[SalesOrderNo] <> src.[SalesOrderNo]
                          OR tgt.[SalesLineNo]  <> src.[SalesLineNo]
                          OR tgt.[ReturnDate]   <> src.[ReturnDate]
                          OR tgt.[ProductKey]   <> src.[ProductKey]
                          OR tgt.[StoreKey]     <> src.[StoreKey]
                          OR tgt.[Quantity]     <> src.[Quantity]
                          OR tgt.[ReturnAmount] <> src.[ReturnAmount]
                          OR ISNULL(tgt.[ReturnReason], N'') <> ISNULL(src.[ReturnReason], N'')
                          OR tgt.[Status]       <> src.[Status])
            THEN UPDATE
                SET tgt.[SalesOrderNo] = src.[SalesOrderNo],
                    tgt.[SalesLineNo]  = src.[SalesLineNo],
                    tgt.[ReturnDate]   = src.[ReturnDate],
                    tgt.[ProductKey]   = src.[ProductKey],
                    tgt.[StoreKey]     = src.[StoreKey],
                    tgt.[Quantity]     = src.[Quantity],
                    tgt.[ReturnAmount] = src.[ReturnAmount],
                    tgt.[ReturnReason] = src.[ReturnReason],
                    tgt.[Status]       = src.[Status],
                    tgt.[SourceSystem] = src.[SourceSystem],
                    tgt.[LoadId]       = @LoadId
        WHEN NOT MATCHED BY TARGET
            THEN INSERT ([ReturnKey], [ReturnNo], [SalesOrderNo], [SalesLineNo], [ReturnDate],
                         [ProductKey], [StoreKey], [Quantity], [ReturnAmount], [ReturnReason],
                         [Status], [SourceSystem], [LoadId])
                 VALUES (src.[ReturnKey], src.[ReturnNo], src.[SalesOrderNo], src.[SalesLineNo], src.[ReturnDate],
                         src.[ProductKey], src.[StoreKey], src.[Quantity], src.[ReturnAmount], src.[ReturnReason],
                         src.[Status], src.[SourceSystem], @LoadId)
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
