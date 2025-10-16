-- 001_Validate_ETL.sql
-- Migration: validation stored procedure
CREATE OR ALTER PROCEDURE dbo.Validate_ETL
AS
BEGIN
    SET NOCOUNT ON;

    PRINT '=== ETL Validation Report ===';

    -- 1. Sessions with no hands
    PRINT 'Sessions with no hands:';
    SELECT s.session_id, s.session_code
    FROM dbo.Sessions s
    LEFT JOIN dbo.Hands h ON s.session_id = h.session_id
    GROUP BY s.session_id, s.session_code
    HAVING COUNT(h.hand_id) = 0;

    -- 2. Hands with no actions
    PRINT 'Hands with no actions:';
    SELECT h.hand_id, h.hand_number
    FROM dbo.Hands h
    LEFT JOIN dbo.Actions a ON h.hand_id = a.hand_id
    GROUP BY h.hand_id, h.hand_number
    HAVING COUNT(a.action_id) = 0;

    -- 3. Hands with no results
    PRINT 'Hands with no results:';
    SELECT h.hand_id, h.hand_number
    FROM dbo.Hands h
    LEFT JOIN dbo.Results r ON h.hand_id = r.hand_id
    WHERE r.result_id IS NULL;

    -- 4. Hands with multiple winners
    PRINT 'Hands with multiple winners:';
    SELECT h.hand_id, COUNT(*) AS winners
    FROM dbo.Hands h
    JOIN dbo.Results r ON h.hand_id = r.hand_id
    WHERE r.is_winner = 1
    GROUP BY h.hand_id
    HAVING COUNT(*) <> 1;

    -- 5. Actions with missing player reference
    PRINT 'Actions with missing player reference:';
    SELECT a.action_id, a.hand_id
    FROM dbo.Actions a
    LEFT JOIN dbo.Players p ON a.player_id = p.player_id
    WHERE p.player_id IS NULL;

    -- 6. Results with missing player reference
    PRINT 'Results with missing player reference:';
    SELECT r.result_id, r.hand_id
    FROM dbo.Results r
    LEFT JOIN dbo.Players p ON r.player_id = p.player_id
    WHERE p.player_id IS NULL;

    -- 7. Players without global identity
    PRINT 'Players without global identity:';
    SELECT p.player_id, p.player_name
    FROM dbo.Players p
    LEFT JOIN dbo.PlayersGlobal g ON p.global_player_id = g.global_player_id
    WHERE g.global_player_id IS NULL;

    -- 8. Duplicate session codes
    PRINT 'Duplicate session codes:';
    SELECT session_code, COUNT(*) AS cnt
    FROM dbo.Sessions
    GROUP BY session_code
    HAVING COUNT(*) > 1;

    -- 9. Duplicate file hashes in staging (example checks Lake_Tournament)
    PRINT 'Duplicate file hashes in staging:';
    SELECT Sha256Hash, COUNT(*) AS cnt
    FROM dbo.Lake_Tournament
    GROUP BY Sha256Hash
    HAVING COUNT(*) > 1;

    PRINT '=== End of Validation Report ===';
END
