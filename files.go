// Copyright © 2025 Mark Summerfield. All rights reserved.
// License: GPL-3

package filestore

import (
	"context"
	"database/sql"
	"errors"
	"fmt"

	_ "modernc.org/sqlite"
)

type File struct {
	gid      int
	filename string
	kind     Kind
	usize    int
	zsize    int
	pgid     int
	data     []byte
}

// IsNew returns true if the filename is not in the database; otherwise
// returns false
func (me *FileStore) IsNew(filename string) bool {
	var gid int
	row := me.db.QueryRow(SQL_GID_FOR_FILENAME, filename)
	err := row.Scan(&gid)
	return errors.Is(err, sql.ErrNoRows)
}

// FindFull finds and returns the highest-gid version of the file for which
// kind is RawKind or ZrawKind
func (me *FileStore) FindFull(filename string) (*File, error) {
	file := &File{}
	row := me.db.QueryRow(SQL_GET_FILE, filename)
	err := row.Scan(file.gid, file.kind, file.usize, file.zsize, file.data)
	return file, err
}

// Add adds the given files and returns the new (i.e., last) gid
func (me *FileStore) AddWithMessage(message string,
	filenames ...string,
) (int, error) {
	gid, err := me.NextGeneration(message)
	if err != nil {
		return 0, err
	}
	return me.add(gid, filenames...)
}

// Add adds the given files and returns the new (i.e., last) gid
func (me *FileStore) Add(filenames ...string) (int, error) {
	gid, err := me.NextGeneration()
	if err != nil {
		return 0, err
	}
	return me.add(gid, filenames...)
}

func (me *FileStore) add(gid int, filenames ...string) (int, error) {
	if tx, err := me.db.BeginTx(context.Background(), nil); err == nil {
		for _, filename := range filenames {
			fmt.Println(filename) // TODO implement Algorithm in MANIFEST
		}
		if err == nil {
			return gid, tx.Commit()
		} else {
			return gid, errors.Join(err, tx.Rollback())
		}
	} else {
		return 0, err
	}
	return gid, nil
}
