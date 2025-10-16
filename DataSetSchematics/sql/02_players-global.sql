-- 02_players-global.sql
-- PlayersGlobal table and linking to Players
CREATE TABLE PlayersGlobal (
    global_player_id INT IDENTITY PRIMARY KEY,
    player_name      VARCHAR(100) NOT NULL UNIQUE,  -- character-based uniqueness
    first_seen       DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    last_seen        DATETIME2 NULL
);

ALTER TABLE Players
ADD global_player_id INT NULL
    FOREIGN KEY REFERENCES PlayersGlobal(global_player_id);

-- Note: Name collisions and aliasing are accepted trade-offs for simple global identity.
