-- 01_core-schema.sql
-- Core relational schema for Poker Hand History
CREATE TABLE Sessions (
    session_id     INT IDENTITY PRIMARY KEY,
    session_code   VARCHAR(100) NOT NULL UNIQUE,  -- natural key from XML + filename
    game_format    VARCHAR(50) NOT NULL,          -- 'Tournament' or 'Cash'
    start_time     DATETIME2 NULL,
    end_time       DATETIME2 NULL,
    xml_content    XML NOT NULL,                  -- raw XML preserved
    upload_time    DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
);

CREATE TABLE Players (
    player_id      INT IDENTITY PRIMARY KEY,
    session_id     INT NOT NULL FOREIGN KEY REFERENCES Sessions(session_id),
    seat_number    INT,
    player_name    VARCHAR(100),
    starting_chips DECIMAL(18,2)
);

CREATE TABLE Hands (
    hand_id        INT IDENTITY PRIMARY KEY,
    session_id     INT NOT NULL FOREIGN KEY REFERENCES Sessions(session_id),
    hand_number    BIGINT,
    pot_size       DECIMAL(18,2),
    winner_id      INT NULL FOREIGN KEY REFERENCES Players(player_id)
);

CREATE TABLE Actions (
    action_id      INT IDENTITY PRIMARY KEY,
    hand_id        INT NOT NULL FOREIGN KEY REFERENCES Hands(hand_id),
    player_id      INT NOT NULL FOREIGN KEY REFERENCES Players(player_id),
    street         VARCHAR(20),
    action_type    VARCHAR(20),
    amount         DECIMAL(18,2),
    action_order   INT
);

CREATE TABLE Results (
    result_id      INT IDENTITY PRIMARY KEY,
    hand_id        INT NOT NULL FOREIGN KEY REFERENCES Hands(hand_id),
    player_id      INT NOT NULL FOREIGN KEY REFERENCES Players(player_id),
    hand_rank      VARCHAR(50),
    is_winner      BIT,
    winnings       DECIMAL(18,2)
);
