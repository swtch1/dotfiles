package strutil

import "strings"

func Truncate(s string, maxLen int) string {
	if maxLen <= 0 {
		return ""
	}

	if len(s) <= maxLen {
		return s
	}

	if maxLen <= 3 {
		return s[:maxLen]
	}

	return s[:maxLen-3] + "..."
}

func WordWrap(s string, lineWidth int) string {
	if lineWidth <= 0 {
		return s
	}

	words := strings.Fields(s)
	if len(words) == 0 {
		return ""
	}

	lines := make([]string, 0)
	current := words[0]

	for _, w := range words[1:] {
		if len(current)+1+len(w) <= lineWidth {
			current += " " + w
			continue
		}

		lines = append(lines, current)
		current = w
	}

	lines = append(lines, current)
	return strings.Join(lines, "\n")
}
