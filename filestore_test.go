package filestore

import (
    "testing"
)

func Test001(t *testing.T) {
    expected := "Hello filestore"
    actual := Hello()
    if actual != expected {
        t.Errorf("expected %q, got %q", expected, actual)
    }
}
