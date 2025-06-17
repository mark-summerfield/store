// Copyright © 2025 Mark Summerfield. All rights reserved.
// License: GPL-3

package filestore

import _ "embed"

//go:embed Version.dat
var Version string

//go:embed sql/prepare.sql
var SQL_PREPARE string

//go:embed sql/create.sql
var SQL_CREATE string

//go:embed sql/insert.sql
var SQL_INSERT string

const (
	DRIVER = "sqlite"

	SQL_EXCLUDES = `SELECT folder, pattern FROM Excludes
					ORDER BY folder, pattern;`
	SQL_GID_FOR_FILENAME = `SELECT gid FROM Files WHERE filename = ?
							LIMIT 1;`
	SQL_GET_FILE = `SELECT gid, kind, usize, zsize, data FROM Files
					WHERE kind IN ('R', 'r') AND filename = ?
					ORDER BY gid DESC LIMIT 1;`
	SQL_NEW_GEN = "INSERT INTO Generations (message) VALUES (?);"
)
