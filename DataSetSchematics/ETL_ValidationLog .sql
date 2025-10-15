CREATE TABLE dbo.ETL_ValidationLog (
    log_id        INT IDENTITY PRIMARY KEY,
    run_id        UNIQUEIDENTIFIER NOT NULL,
    check_name    NVARCHAR(100) NOT NULL,
    anomaly_count INT NOT NULL,
    sample_data   NVARCHAR(MAX) NULL,
    log_time      DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
);
