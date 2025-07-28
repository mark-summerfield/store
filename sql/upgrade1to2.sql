DROP VIEW ViewGenerations;
DROP VIEW HistoryByGeneration;

ALTER TABLE Generations RENAME COLUMN message TO tag;

CREATE VIEW ViewGenerations AS
  SELECT gid, DATETIME(created) AS created, tag FROM Generations
        ORDER BY gid DESC;

CREATE VIEW HistoryByGeneration AS
   SELECT Generations.gid, DATETIME(created) AS created, filename, tag
       FROM Generations, Files
       WHERE Generations.gid = Files.gid AND kind != 'S'
       ORDER BY Generations.gid DESC, LOWER(filename);

PRAGMA USER_VERSION = 2;
