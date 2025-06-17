package filestore

import (
	"os"
	"runtime"
	"strings"
	"testing"
)

func Test_Empty(t *testing.T) {
	filename := os.TempDir() + "/empty.str"
	os.Remove(filename)
	fileStore, err := NewFileStore(filename)
	checkErr(t, err)
	defer fileStore.Close()
	version, err := SqliteVersion()
	checkErr(t, err)
	if !strings.HasPrefix(version, "3.") {
		t.Errorf("expected version 3.x.y; got : %s", version)
	}
	if fileStore.Filename() != filename {
		t.Errorf("expected filename %q; got: %q", filename,
			fileStore.Filename())
	}
}

func checkErr(t *testing.T, err error) {
	if err != nil {
		_, _, lino, ok := runtime.Caller(1)
		if !ok {
			lino = 0
		}
		t.Errorf("unexpected error @%d: %s", lino, err)
	}
}
