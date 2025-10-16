-- 01_core-schema.sql
-- Core relational schema for Poker Hand History (extended Sessions)
IF OBJECT_ID('dbo.Sessions','U') IS NULL
BEGIN
CREATE TABLE dbo.Sessions (
    session_id        INT IDENTITY PRIMARY KEY,
    session_code      VARCHAR(100) NOT NULL UNIQUE,   -- natural key
    game_format       VARCHAR(50) NOT NULL,           -- 'Tournament' or 'Cash'
    gametype          VARCHAR(50) NULL,               -- e.g. NLHE, PLO
    limit_type        VARCHAR(50) NULL,               -- No Limit, Pot Limit, etc.
    stakes            VARCHAR(50) NULL,               -- e.g. 0.01/0.02
    currency          VARCHAR(10) NULL,               -- USD, EUR, etc.
    tablename         VARCHAR(100) NULL,
    max_players       INT NULL,
    seats             INT NULL,
    buy_in            DECIMAL(18,2) NULL,             -- tournaments
    rake              DECIMAL(18,2) NULL,             -- tournaments
    starting_stack    DECIMAL(18,2) NULL,             -- tournaments
    start_time        DATETIME2 NULL,
    end_time          DATETIME2 NULL,
    xml_content       XML NOT NULL,                   -- raw XML preserved
    upload_time       DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
);
END

IF OBJECT_ID('dbo.Players','U') IS NULL
BEGIN
CREATE TABLE dbo.Players (
    player_id      INT IDENTITY PRIMARY KEY,
    session_id     INT NOT NULL,
    seat_number    INT NULL,
    player_name    VARCHAR(100) NULL,
    starting_chips DECIMAL(18,2) NULL,
    global_player_id INT NULL
);
ALTER TABLE dbo.Players
ADD CONSTRAINT FK_Players_Sessions FOREIGN KEY (session_id) REFERENCES dbo.Sessions(session_id);
END

IF OBJECT_ID('dbo.Hands','U') IS NULL
BEGIN
CREATE TABLE dbo.Hands (
    hand_id        INT IDENTITY PRIMARY KEY,
    session_id     INT NOT NULL,
    hand_number    BIGINT NULL,
    pot_size       DECIMAL(18,2) NULL,
    winner_id      INT NULL
);
ALTER TABLE dbo.Hands
ADD CONSTRAINT FK_Hands_Sessions FOREIGN KEY (session_id) REFERENCES dbo.Sessions(session_id);
END

IF OBJECT_ID('dbo.Actions','U') IS NULL
BEGIN
CREATE TABLE dbo.Actions (
    action_id      INT IDENTITY PRIMARY KEY,
    hand_id        INT NOT NULL,
    player_id      INT NOT NULL,
    street         VARCHAR(20) NULL,
    action_type    VARCHAR(50) NULL,
    amount         DECIMAL(18,2) NULL,
    action_order   INT NULL
);
ALTER TABLE dbo.Actions
ADD CONSTRAINT FK_Actions_Hands FOREIGN KEY (hand_id) REFERENCES dbo.Hands(hand_id);
END

IF OBJECT_ID('dbo.Results','U') IS NULL
BEGIN
CREATE TABLE dbo.Results (
    result_id      INT IDENTITY PRIMARY KEY,
    hand_id        INT NOT NULL,
    player_id      INT NOT NULL,
    hand_rank      VARCHAR(50) NULL,
    is_winner      BIT NULL,
    winnings       DECIMAL(18,2) NULL
);
ALTER TABLE dbo.Results
ADD CONSTRAINT FK_Results_Hands FOREIGN KEY (hand_id) REFERENCES dbo.Hands(hand_id);
END

-- PlayersGlobal table may be created by the players-global migration (02_players-global.sql)
