// Copyright © 2025 Mark Summerfield. All rights reserved.
// License: GPL-3

package filestore

type Kind byte

const (
	RawKind   Kind = 'R'
	ZrawKind  Kind = 'r'
	DiffKind  Kind = 'D'
	ZdiffKind Kind = 'd'
	EqualKind Kind = '='
)
