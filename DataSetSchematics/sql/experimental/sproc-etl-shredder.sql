-- experimental/sproc-etl-shredder.sql
-- Archive of a more dynamic ETL shredder; kept for reference
CREATE OR ALTER PROCEDURE dbo.Etl_ProcessLakeTable
    @LakeTable NVARCHAR(128),
    @BatchSize INT = 500
AS
BEGIN
    SET NOCOUNT ON;
    -- This variant mirrors the main proc but kept separate to iterate without affecting mainline
END
