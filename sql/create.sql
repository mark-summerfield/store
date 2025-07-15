-- Copyright © 2025 Mark Summerfield. All Rights Reserved.

PRAGMA USER_VERSION = 1;

CREATE TABLE Generations (
    gid INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
    created REAL DEFAULT (JULIANDAY('NOW')) NOT NULL,
    message TEXT,

    CHECK(gid > 0)
);

-- kind
--  U uncompressed raw bytes (the actual file); usize set; zsize NULL
--  Z zlib deflated raw bytes (the actual file); usize & zsize set
--  S same as record whose gid is pgid; usize & zsize & data NULL
CREATE TABLE Files (
    gid INTEGER NOT NULL, -- generation ID
    filename TEXT NOT NULL, -- contains full (relative) path
    kind TEXT NOT NULL,
    usize INTEGER, -- uncompressed size
    zsize INTEGER, -- zlib-deflated size; 0 means not compressed
    pgid INTEGER NOT NULL, -- set to gid if 'U' or 'Z' or to parent if 'S'
    data BLOB,

    CHECK(kind IN ('U', 'Z', 'S')),
    CHECK((kind = 'S' AND usize IS NULL) OR (kind != 'S' AND usize > 0)),
    CHECK((kind = 'S' AND zsize IS NULL) OR (kind != 'S' AND zsize >= 0)),
    FOREIGN KEY(pgid) REFERENCES Generations(gid),
    FOREIGN KEY(gid) REFERENCES Generations(gid),
    PRIMARY KEY(gid, filename)
);

CREATE TABLE Ignores (pattern TEXT PRIMARY KEY NOT NULL) WITHOUT ROWID;

CREATE VIEW ViewGenerations AS
    SELECT gid, DATETIME(created) AS created, message FROM Generations
        ORDER BY gid DESC;

CREATE VIEW CurrentGeneration AS SELECT COALESCE(MAX(gid), 0) AS gid
    FROM Generations;

CREATE VIEW EmptyGenerations AS
    SELECT DISTINCT gid FROM Files WHERE kind = 'S' AND gid NOT IN (
        SELECT gid FROM Files WHERE kind != 'S');

CREATE VIEW HistoryByFilename AS
    SELECT filename, gid FROM Files WHERE kind != 'S'
        ORDER BY LOWER(filename), gid DESC;

CREATE VIEW HistoryByGeneration AS
    SELECT Generations.gid, DATETIME(created) AS created, message, filename
        FROM Generations, Files
        WHERE Generations.gid = Files.gid AND kind != 'S'
        ORDER BY Generations.gid DESC, LOWER(filename);

CREATE VIEW Untracked AS
    SELECT DISTINCT filename FROM Files WHERE filename NOT IN (
        SELECT filename FROM Files WHERE gid IN (
            SELECT MAX(gid) FROM Generations)) ORDER BY LOWER(filename);
