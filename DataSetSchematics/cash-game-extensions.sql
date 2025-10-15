CREATE TABLE CashSessions (
    session_id     INT PRIMARY KEY FOREIGN KEY REFERENCES Sessions(session_id),
    stake_level    VARCHAR(50),
    min_buy_in     DECIMAL(18,2),
    max_buy_in     DECIMAL(18,2)
);

CREATE TABLE CashRebuys (
    rebuy_id       INT IDENTITY PRIMARY KEY,
    session_id     INT NOT NULL FOREIGN KEY REFERENCES CashSessions(session_id),
    player_id      INT NOT NULL FOREIGN KEY REFERENCES Players(player_id),
    rebuy_amount   DECIMAL(18,2),
    rebuy_time     DATETIME2
);
