// Copyright © 2025 Mark Summerfield. All rights reserved.
// License: GPL-3

package filestore

import _ "embed"

//go:embed Version.dat
var Version string

func Hello() string {
    return "Hello filestore"
}
