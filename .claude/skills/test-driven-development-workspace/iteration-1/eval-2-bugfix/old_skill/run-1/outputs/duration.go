package timeutil

import (
	"fmt"
	"strconv"
	"strings"
	"time"
)

// ParseDuration parses human-friendly duration strings like "1h", "30m", "2h15m".
// Supports fractional values like "1.5h" = 1 hour 30 minutes.
func ParseDuration(s string) (time.Duration, error) {
	s = strings.TrimSpace(s)
	if s == "" {
		return 0, fmt.Errorf("empty duration string")
	}

	var total time.Duration
	remaining := s

	for len(remaining) > 0 {
		// Find the next unit suffix
		i := 0
		for i < len(remaining) && (remaining[i] == '.' || (remaining[i] >= '0' && remaining[i] <= '9')) {
			i++
		}

		if i == 0 {
			return 0, fmt.Errorf("invalid duration: %q", s)
		}
		if i >= len(remaining) {
			return 0, fmt.Errorf("missing unit in duration: %q", s)
		}

		numStr := remaining[:i]
		unit := remaining[i]
		remaining = remaining[i+1:]

		num, err := strconv.ParseFloat(numStr, 64)
		if err != nil {
			return 0, fmt.Errorf("invalid number in duration %q: %w", s, err)
		}

		switch unit {
		case 'h':
			total += time.Duration(num * float64(time.Hour))
		case 'm':
			total += time.Duration(num * float64(time.Minute))
		case 's':
			total += time.Duration(num * float64(time.Second))
		default:
			return 0, fmt.Errorf("unknown unit %q in duration: %q", string(unit), s)
		}
	}

	return total, nil
}
