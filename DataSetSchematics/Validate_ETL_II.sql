CREATE OR ALTER PROCEDURE dbo.Validate_ETL
    @RunId UNIQUEIDENTIFIER = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF @RunId IS NULL SET @RunId = NEWID();

    PRINT '=== ETL Validation Report ===';

    -- Example check: Sessions with no hands
    DECLARE @cnt INT;
    SELECT @cnt = COUNT(*)
    FROM dbo.Sessions s
    LEFT JOIN dbo.Hands h ON s.session_id = h.session_id
    GROUP BY s.session_id, s.session_code
    HAVING COUNT(h.hand_id) = 0;

    INSERT INTO dbo.ETL_ValidationLog (run_id, check_name, anomaly_count)
    VALUES (@RunId, 'SessionsWithNoHands', ISNULL(@cnt,0));

    PRINT CONCAT('Sessions with no hands: ', ISNULL(@cnt,0));

    -- Repeat same pattern for each check:
    -- HandsWithNoActions, HandsWithNoResults, MultipleWinners, MissingPlayerRefs, etc.
    -- Each inserts a row into ETL_ValidationLog with anomaly_count.

    PRINT '=== End of Validation Report ===';
END
