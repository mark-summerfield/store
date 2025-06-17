// Copyright © 2025 Mark Summerfield. All rights reserved.
// License: GPL-3

package filestore

import (
	"database/sql"
	"errors"

	"github.com/mark-summerfield/ufile"
	_ "modernc.org/sqlite"
)

type FileStore struct {
	filename string
	db       *sql.DB
}

func NewFileStore(filename string) (*FileStore, error) {
	exists := ufile.FileExists(filename)
	db, err := sql.Open(DRIVER, filename)
	if err != nil {
		return nil, err
	}
	_, err = db.Exec(SQL_PREPARE)
	if err != nil {
		return nil, errors.Join(err, db.Close())
	}
	if !exists {
		_, err = db.Exec(SQL_CREATE)
		if err != nil {
			return nil, errors.Join(err, db.Close())
		}
		_, err = db.Exec(SQL_INSERT)
		if err != nil {
			return nil, errors.Join(err, db.Close())
		}
	}
	return &FileStore{filename, db}, nil
}

func (me *FileStore) Close() error {
	if me.db != nil {
		err := me.db.Close()
		me.db = nil
		return err
	}
	return nil
}

func (me *FileStore) Filename() string { return me.filename }
