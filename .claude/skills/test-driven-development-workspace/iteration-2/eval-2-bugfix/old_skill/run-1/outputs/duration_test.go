package timeutil

import (
	"testing"
	"time"
)

func TestParseDuration_FractionalHours(t *testing.T) {
	got, err := ParseDuration("1.5h")
	if err != nil {
		t.Fatalf("ParseDuration returned unexpected error: %v", err)
	}

	want := time.Hour + 30*time.Minute
	if got != want {
		t.Fatalf("ParseDuration(\"1.5h\") = %v, want %v", got, want)
	}
}
