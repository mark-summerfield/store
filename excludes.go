// Copyright © 2025 Mark Summerfield. All rights reserved.
// License: GPL-3

package filestore

import _ "modernc.org/sqlite"

type Exclude struct{ folder, pattern string }

func (me *FileStore) Excludes() ([]Exclude, error) {
	rows, err := me.db.Query(SQL_EXCLUDES)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var excludes []Exclude
	for rows.Next() {
		var exclude Exclude
		if err = rows.Scan(&exclude.folder, &exclude.pattern); err != nil {
			return nil, err
		}
		excludes = append(excludes, exclude)
	}
	return excludes, nil
}
