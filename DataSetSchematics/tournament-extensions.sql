CREATE TABLE TournamentSessions (
    session_id     INT PRIMARY KEY FOREIGN KEY REFERENCES Sessions(session_id),
    buy_in         DECIMAL(18,2),
    rake           DECIMAL(18,2),
    starting_stack DECIMAL(18,2),
    total_players  INT
);

CREATE TABLE BlindLevels (
    level_id       INT IDENTITY PRIMARY KEY,
    session_id     INT NOT NULL FOREIGN KEY REFERENCES TournamentSessions(session_id),
    level_number   INT,
    small_blind    DECIMAL(18,2),
    big_blind      DECIMAL(18,2),
    ante           DECIMAL(18,2),
    duration_min   INT
);

CREATE TABLE TournamentResults (
    result_id      INT IDENTITY PRIMARY KEY,
    session_id     INT NOT NULL FOREIGN KEY REFERENCES TournamentSessions(session_id),
    player_id      INT NOT NULL FOREIGN KEY REFERENCES Players(player_id),
    finishing_place INT,
    payout         DECIMAL(18,2)
);
