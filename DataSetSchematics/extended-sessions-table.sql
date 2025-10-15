CREATE TABLE Sessions (
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

🎯 Why This Matters
-- Fidelity: Every <general> attribute is transposed into a column.

-- Flexibility: You can query directly (WHERE max_players = 6) without shredding XML each time.

-- Choice: If some attributes aren’t useful now, they still live in the schema for future analysis.

-- Audit: Raw XML is still preserved in xml_content for re‑parsing if needed.