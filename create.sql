-- Copyright © 2025 Mark Summerfield. All Rights Reserved.

PRAGMA USER_VERSION = 1;

CREATE TABLE Generations (
    gid INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
    created REAL DEFAULT (JULIANDAY('NOW')) NOT NULL,
    message TEXT
);

CREATE VIEW ViewGenerations AS
    SELECT gid, DATETIME(created) AS created, message FROM Generations;

-- kind
--  R raw bytes (the actual file)
--  Z gzip compressed raw bytes (the actual file)
--  = the pgid is the gid of the record which contains the file's data
--      (the data field should be empty)
--  P the pgid (previous gid) is the gid of the record which contains the
--      original file's data and to which when this record's data is applied
--      as a patch will produce this record's file data
CREATE TABLE Files (
    gid INTEGER NOT NULL, -- generation ID
    filename TEXT NOT NULL, -- contains full (relative) path
    kind TEXT NOT NULL,
    pgid INTEGER,
    data BLOB,

    CHECK(kind IN ('R', 'Z', '=', 'P')),
    FOREIGN KEY(pgid) REFERENCES Generations(gid),
    FOREIGN KEY(gid) REFERENCES Generations(gid),
    PRIMARY KEY(gid, filename)
);

-- For specific filenames, includes take priority over excludes
-- To include subdirs add suitable patterns, e.g., ('images', '*.svg')
CREATE TABLE Patterns (
    folder TEXT NOT NULL, -- the (relative) folder to apply the glob to
    pattern TEXT KEY NOT NULL, -- glob or filename to include
    include BOOL DEFAULT TRUE NOT NULL,

    CHECK(include IN (TRUE, FALSE)),
    PRIMARY KEY(folder, pattern, include)
);
