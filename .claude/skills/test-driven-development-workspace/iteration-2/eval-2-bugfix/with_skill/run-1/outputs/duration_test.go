package timeutil

import (
	"testing"
	"time"
)

func TestParseDuration_FractionalAndRegressionCases(t *testing.T) {
	tests := []struct {
		name  string
		input string
		want  time.Duration
	}{
		{name: "fractional hours bug reproduction", input: "1.5h", want: time.Hour + 30*time.Minute},
		{name: "fractional minutes", input: "0.5m", want: 30 * time.Second},
		{name: "different fractional hours", input: "2.25h", want: 2*time.Hour + 15*time.Minute},
		{name: "integer regression", input: "2h", want: 2 * time.Hour},
	}

	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			got, err := ParseDuration(tc.input)
			if err != nil {
				t.Fatalf("ParseDuration returned error: %v", err)
			}

			if got != tc.want {
				t.Fatalf("ParseDuration(%q) = %v, want %v", tc.input, got, tc.want)
			}
		})
	}
}
