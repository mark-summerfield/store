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
)
