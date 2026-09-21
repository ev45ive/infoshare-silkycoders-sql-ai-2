/*
    Author:      Mateusz Kulesza <ev45ive@gmail.com>
    AI model:    Claude Sonnet 5
    Created:     2026-09-21
    Description: Loads validated rows from [stg].[Customers] into the
                 slowly-changing [dbo].[DimCustomer]

    Change log:
    - 2026-09-21 | Ticket: N/A | Mateusz Kulesza | Claude Sonnet 5 | Initial version
*/
CREATE PROCEDURE [etl].[LoadCustomers]
    @SourceSystem NVARCHAR (20) = N'CRM',
    @LoadId       INT           = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @RowsInserted     INT = 0,
            @RowsUpdated      INT = 0,
            @RowsRejected     INT = 0,
            @NewCustomerEpoch DATE = '2020-01-01'; -- ValidFrom for a customer's first-ever version

    INSERT INTO [dbo].[LoadLog] ([PackageName], [SourceSystem])
    VALUES (N'etl.LoadCustomers', @SourceSystem);

    SET @LoadId = CAST(SCOPE_IDENTITY() AS INT);

    BEGIN TRY
        CREATE TABLE #CustData
        (
            [CustomerCode] NVARCHAR (20)  NOT NULL,
            [Name]         NVARCHAR (100) NOT NULL,
            [Tier]         NVARCHAR (20)  NOT NULL,
            [Region]       NVARCHAR (50)  NULL,
            PRIMARY KEY CLUSTERED ([CustomerCode])
        );

        -- De-duplicate staging rows; the latest staged row per business key wins.
        WITH [Ranked] AS
        (
            SELECT  s.[CustomerCode],
                    s.[Name],
                    s.[Tier],
                    s.[Region],
                    ROW_NUMBER() OVER (PARTITION BY s.[CustomerCode]
                                       ORDER BY s.[LoadedAt] DESC, s.[StagingRowId] DESC) AS [RowRank]
            FROM    [stg].[Customers] AS s
            WHERE   s.[SourceSystem]  = @SourceSystem
                AND s.[CustomerCode] IS NOT NULL
                AND s.[Name]         IS NOT NULL
                AND s.[Tier]         IS NOT NULL
        )
        INSERT INTO #CustData ([CustomerCode], [Name], [Tier], [Region])
        SELECT [CustomerCode], [Name], [Tier], [Region]
        FROM   [Ranked]
        WHERE  [RowRank] = 1;

        SELECT @RowsRejected = COUNT(*)
        FROM   [stg].[Customers] AS s
        WHERE  s.[SourceSystem] = @SourceSystem
           AND (s.[CustomerCode] IS NULL OR s.[Name] IS NULL OR s.[Tier] IS NULL);

        BEGIN TRANSACTION;

        -- Close current rows whose tracked attributes changed.
        UPDATE  dc
        SET     dc.[ValidTo]   = SYSUTCDATETIME(),
                dc.[IsCurrent] = 0
        FROM    [dbo].[DimCustomer] AS dc
        JOIN    #CustData           AS src ON src.[CustomerCode] = dc.[CustomerCode]
        WHERE   dc.[IsCurrent] = 1
            AND (   dc.[Name] <> src.[Name]
                 OR dc.[Tier] <> src.[Tier]
                 OR ISNULL(dc.[Region], N'') <> ISNULL(src.[Region], N''));

        SET @RowsUpdated = @@ROWCOUNT;

        -- Insert the current version for new customers and for customers whose
        -- previous version was just closed above.
        INSERT INTO [dbo].[DimCustomer] ([CustomerCode], [Name], [Tier], [Region], [ValidFrom], [ValidTo], [IsCurrent])
        SELECT  src.[CustomerCode],
                src.[Name],
                src.[Tier],
                src.[Region],
                CASE WHEN EXISTS (SELECT 1 FROM [dbo].[DimCustomer] AS dc WHERE dc.[CustomerCode] = src.[CustomerCode])
                     THEN SYSUTCDATETIME()
                     ELSE CAST(@NewCustomerEpoch AS DATETIME2(3))
                END,
                NULL,
                1
        FROM    #CustData AS src
        WHERE   NOT EXISTS (
                    SELECT 1
                    FROM   [dbo].[DimCustomer] AS dc
                    WHERE  dc.[CustomerCode] = src.[CustomerCode]
                       AND dc.[IsCurrent]    = 1
                );

        SET @RowsInserted = @@ROWCOUNT;

        COMMIT TRANSACTION;

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
