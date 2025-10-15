CREATE OR ALTER PROCEDURE dbo.Etl_ProcessLakeTable
    @LakeTable NVARCHAR(128),
    @BatchSize INT = 500
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @sql NVARCHAR(MAX);

    -- Dynamic SQL to pull a batch of unprocessed rows
    SET @sql = N'
    ;WITH cte AS (
        SELECT TOP (' + CAST(@BatchSize AS NVARCHAR(10)) + N')
               Id, FileName, XmlContent, Sha256Hash
        FROM ' + QUOTENAME(@LakeTable) + N'
        WHERE processed = 0
        ORDER BY Id
    )
    UPDATE cte
    SET processed = 1
    OUTPUT inserted.Id, inserted.FileName, inserted.XmlContent, inserted.Sha256Hash
    INTO #Batch(Id, FileName, XmlContent, Sha256Hash);';

    -- Temp table to hold batch
    IF OBJECT_ID('tempdb..#Batch') IS NOT NULL DROP TABLE #Batch;
    CREATE TABLE #Batch (
        Id INT,
        FileName NVARCHAR(260),
        XmlContent XML,
        Sha256Hash CHAR(64)
    );

    EXEC sp_executesql @sql;

    -- Now shred each XML row into relational schema
    DECLARE @Id INT, @FileName NVARCHAR(260), @Xml XML, @Hash CHAR(64);

    DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
        SELECT Id, FileName, XmlContent, Sha256Hash FROM #Batch;

    OPEN cur;
    FETCH NEXT FROM cur INTO @Id, @FileName, @Xml, @Hash;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        DECLARE @session_code NVARCHAR(100) = @Xml.value('(/session/@sessioncode)[1]', 'NVARCHAR(100)');
        DECLARE @game_format NVARCHAR(50)   = @Xml.value('(/session/general/gametype)[1]', 'NVARCHAR(50)');
        DECLARE @start_time  DATETIME2      = @Xml.value('(/session/general/startdate)[1]', 'DATETIME2');
        DECLARE @end_time    DATETIME2      = @Xml.value('(/session/general/enddate)[1]', 'DATETIME2');

        -- Insert Session if not exists
        IF NOT EXISTS (SELECT 1 FROM dbo.Sessions WHERE session_code = @session_code)
        BEGIN
            INSERT INTO dbo.Sessions (session_code, game_format, start_time, end_time, xml_content)
            VALUES (@session_code, @game_format, @start_time, @end_time, @Xml);
        END

        DECLARE @session_id INT = (SELECT session_id FROM dbo.Sessions WHERE session_code = @session_code);

        -- Insert Players
        INSERT INTO dbo.Players (session_id, seat_number, player_name, starting_chips, global_player_id)
        SELECT @session_id,
               p.value('@seat','INT'),
               p.value('@name','NVARCHAR(100)'),
               p.value('@chips','DECIMAL(18,2)'),
               g.global_player_id
        FROM @Xml.nodes('/session/players/player') AS t(p)
        OUTER APPLY (
            SELECT global_player_id
            FROM dbo.PlayersGlobal g
            WHERE g.player_name = p.value('@name','NVARCHAR(100)')
        ) g
        WHERE NOT EXISTS (
            SELECT 1 FROM dbo.Players pl
            WHERE pl.session_id = @session_id
              AND pl.player_name = p.value('@name','NVARCHAR(100)')
        );

        -- Upsert into PlayersGlobal
        MERGE dbo.PlayersGlobal AS target
        USING (
            SELECT DISTINCT p.value('@name','NVARCHAR(100)') AS player_name
            FROM @Xml.nodes('/session/players/player') AS t(p)
        ) AS src
        ON target.player_name = src.player_name
        WHEN MATCHED THEN
            UPDATE SET last_seen = SYSUTCDATETIME()
        WHEN NOT MATCHED THEN
            INSERT (player_name, first_seen, last_seen)
            VALUES (src.player_name, SYSUTCDATETIME(), SYSUTCDATETIME());

        -- TODO: Similar inserts for Hands, Actions, Results
        -- (shred from @Xml into dbo.Hands, dbo.Actions, dbo.Results)

        FETCH NEXT FROM cur INTO @Id, @FileName, @Xml, @Hash;
    END

    CLOSE cur;
    DEALLOCATE cur;
/*
END
🔑 Key Points
Batching: Processes a limited number of rows per run (@BatchSize), so you can loop until staging is empty.

Idempotency: Checks session_code and player_name before inserting, so no duplicates.

Global identity: MERGE maintains PlayersGlobal automatically.

Extensible: You can add shredding logic for Hands, Actions, and Results in the same loop.
*/