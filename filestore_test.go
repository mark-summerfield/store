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
		t.Errorf("expected version 3.x.y; got: %s", version)
	}
	if fileStore.Filename() != filename {
		t.Errorf("expected filename %q; got: %q", filename,
			fileStore.Filename())
	}
	excludes, err := fileStore.Excludes()
	if err != nil {
		t.Errorf("unexpected error: %s", err)
	}
	patterns := []string{
		"*.bak", "*.class", "*.dll", "*.exe", "*.jar", "*.jpeg", "*.jpg",
		"*.ld", "*.ldx", "*.li", "*.lix", "*.o", "*.obj", "*.png",
		"*.rs.bk", "*.so*", "*.sw[nop]", "*.syso", "*.tmp", "*~",
		"__pycache__", "build", "dist", "moc_*.cpp", "qrc_*.cpp", "tags",
		"target", "test.*", "zOld",
	}
	for i, exclude := range excludes {
		if exclude.folder != "." {
			t.Errorf("expected folder \".\"; got: %q", exclude.folder)
		}
		if exclude.pattern != patterns[i] {
			t.Errorf("expected pattern %q; got: %q", patterns[i],
				exclude.pattern)
		}
	}
	if !fileStore.IsNew("dummy.txt") {
		t.Errorf("expected IsNew == true; got false")
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
