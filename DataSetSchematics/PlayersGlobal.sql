CREATE TABLE PlayersGlobal (
    global_player_id INT IDENTITY PRIMARY KEY,
    player_name      VARCHAR(100) NOT NULL UNIQUE,  -- character-based uniqueness
    first_seen       DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    last_seen        DATETIME2 NULL
);

/*
Linking Local to Global
We then link the session‑scoped Players table to this global identity
*/
ALTER TABLE Players
ADD global_player_id INT NULL
    FOREIGN KEY REFERENCES PlayersGlobal(global_player_id);

/*
⚠️ Risks (which you’ve accepted)
Name collisions: Two different people using the same nickname will be treated as one global identity.

Name changes: If a player changes their nickname, they’ll appear as two separate global identities.
*/