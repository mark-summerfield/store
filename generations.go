// Copyright © 2025 Mark Summerfield. All rights reserved.
// License: GPL-3

package filestore

import (
	"database/sql"
	"strings"
	"time"

	_ "modernc.org/sqlite"
)

type Generation struct {
	gid     int
	created time.Time
	message string
}

func (me *FileStore) LastGeneration() (int, error) {
	return 0, nil // TODO
}

func (me *FileStore) Generations() ([]Generation, error) {
	return nil, nil // TODO
}

func (me *FileStore) NextGeneration(words ...string) (int, error) {
	var value any = sql.NullString{}
	if len(words) > 0 {
		value = strings.Join(words, " ")
	}
	reply, err := me.db.Exec(SQL_NEW_GEN, value)
	if err == nil {
		gid, err := reply.LastInsertId()
		return int(gid), err
	}
	return 0, err
}
