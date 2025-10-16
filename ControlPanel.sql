-- File: ControlPanel.sql
-- Purpose: One-glance health metrics + recent anomalies

-- 1) Throughput snapshot
SELECT 'Sessions' AS metric, COUNT(*) AS value FROM dbo.Sessions
UNION ALL SELECT 'Players', COUNT(*) FROM dbo.Players
UNION ALL SELECT 'Hands', COUNT(*) FROM dbo.Hands
UNION ALL SELECT 'Actions', COUNT(*) FROM dbo.Actions
UNION ALL SELECT 'Results', COUNT(*) FROM dbo.Results
UNION ALL SELECT 'GlobalPlayers', COUNT(*) FROM dbo.PlayersGlobal;

-- 2) Staging backlog across all Lake_* tables
DECLARE @Lake NVARCHAR(MAX) =
  (SELECT STRING_AGG(QUOTENAME(name), ',')
   FROM sys.tables WHERE name LIKE 'Lake_%');
-- If no Lake tables, exit gracefully
IF @Lake IS NULL
    SELECT 'StagingPending' AS metric, 0 AS value;
ELSE
BEGIN
    -- Build dynamic sum of pending across all lakes
    DECLARE @sql NVARCHAR(MAX) = N'SELECT ''StagingPending'' AS metric, ' +
        STRING_AGG(N'(SELECT COUNT(*) FROM ' + QUOTENAME(name) + N' WHERE processed = 0)', N' + ')
        WITHIN GROUP (ORDER BY name)
    FROM sys.tables WHERE name LIKE 'Lake_%';

    EXEC sp_executesql @sql;
END;

-- 3) ETL completeness checks (counts only; details in Validate_ETL)
SELECT 'SessionsWithNoHands' AS check_name, COUNT(*) AS anomaly_count
FROM dbo.Sessions s
LEFT JOIN dbo.Hands h ON s.session_id = h.session_id
GROUP BY s.session_id
HAVING COUNT(h.hand_id) = 0

UNION ALL
SELECT 'HandsWithNoActions', COUNT(*)
FROM dbo.Hands h
LEFT JOIN dbo.Actions a ON h.hand_id = a.hand_id
GROUP BY h.hand_id
HAVING COUNT(a.action_id) = 0

UNION ALL
SELECT 'HandsWithNoResults', COUNT(*)
FROM dbo.Hands h
LEFT JOIN dbo.Results r ON h.hand_id = r.hand_id
WHERE r.result_id IS NULL

UNION ALL
SELECT 'MultipleWinners', COUNT(*)
FROM (
  SELECT h.hand_id
  FROM dbo.Hands h
  JOIN dbo.Results r ON h.hand_id = r.hand_id
  WHERE r.is_winner = 1
  GROUP BY h.hand_id
  HAVING COUNT(*) <> 1
) x

UNION ALL
SELECT 'ActionsMissingPlayer', COUNT(*)
FROM dbo.Actions a
LEFT JOIN dbo.Players p ON a.player_id = p.player_id
WHERE p.player_id IS NULL

UNION ALL
SELECT 'ResultsMissingPlayer', COUNT(*)
FROM dbo.Results r
LEFT JOIN dbo.Players p ON r.player_id = p.player_id
WHERE p.player_id IS NULL

UNION ALL
SELECT 'PlayersWithoutGlobal', COUNT(*)
FROM dbo.Players p
LEFT JOIN dbo.PlayersGlobal g ON p.global_player_id = g.global_player_id
WHERE g.global_player_id IS NULL;

-- 4) Recent anomaly log (last 10 entries)
SELECT TOP 10 run_id, check_name, anomaly_count, log_time
FROM dbo.ETL_ValidationLog
ORDER BY log_time DESC;
