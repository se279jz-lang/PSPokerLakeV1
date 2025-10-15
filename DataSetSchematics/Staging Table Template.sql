CREATE TABLE dbo.XmlStaging (
    id INT IDENTITY(1,1) PRIMARY KEY,          -- surrogate key for joins
    session_code VARCHAR(100) NOT NULL,        -- extracted from <session sessioncode="...">
    file_name NVARCHAR(260) NOT NULL,          -- original filename
    file_size BIGINT NOT NULL,
    sha256_hash CHAR(64) NOT NULL,             -- hash of file content
    xml_content XML NOT NULL,                  -- full XML document
    original_creation_time DATETIME2 NULL,
    original_last_write_time DATETIME2 NULL,
    upload_time DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),

    CONSTRAINT UQ_XmlStaging_Session UNIQUE (session_code),
    CONSTRAINT UQ_XmlStaging_Hash UNIQUE (sha256_hash)
);
