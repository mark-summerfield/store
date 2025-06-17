-- Copyright © 2025 Mark Summerfield. All Rights Reserved.

PRAGMA USER_VERSION = 1;

CREATE TABLE Generations (
    gid INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
    created REAL DEFAULT (JULIANDAY('NOW')) NOT NULL,
    message TEXT
);

CREATE VIEW ViewGenerations AS
    SELECT gid, DATETIME(created) AS created, message FROM Generations
    ORDER BY gid DESC;

CREATE VIEW LastGeneration AS SELECT MAX(gid) FROM Generations;

-- kind
--  R raw bytes (the actual file); usize set; zsize NULL
--  r gzip compressed raw bytes (the actual file); usize & zsize set
--  D diff from record whose gid is pgid; usize set; zsize NULL
--  d diff gzip compressed from record whose gid is pgid; usize & zsize set
--  = unchanged from record whose gid is pgid; usize & zsize & data NULL
CREATE TABLE Files (
    gid INTEGER NOT NULL, -- generation ID
    filename TEXT NOT NULL, -- contains full (relative) path
    kind TEXT NOT NULL,
    usize INTEGER, -- uncompressed size
    zsize INTEGER, -- gzip-compressed size
    pgid INTEGER,
    data BLOB,

    CHECK(kind IN ('R', 'r', 'D', 'd', '=')),
    CHECK(usize IS NULL OR usize > 0),
    CHECK(zsize IS NULL OR zsize > 0),
    FOREIGN KEY(pgid) REFERENCES Generations(gid),
    FOREIGN KEY(gid) REFERENCES Generations(gid),
    PRIMARY KEY(gid, filename)
);

-- hidden files are excluded by default; subdirs are included by default
CREATE TABLE Excludes (
    folder TEXT NOT NULL, -- the (relative) folder to apply the glob to
    pattern TEXT KEY NOT NULL, -- glob or filename to exclude

    PRIMARY KEY(folder, pattern)
);
