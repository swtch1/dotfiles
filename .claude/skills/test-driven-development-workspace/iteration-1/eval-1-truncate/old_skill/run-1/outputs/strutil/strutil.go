package strutil

import "strings"

func Truncate(s string, maxLen int) string {
	if maxLen <= 0 {
		return ""
	}

	if len(s) <= maxLen {
		return s
	}

	return s[:maxLen] + "..."
}

func WordWrap(s string, lineWidth int) string {
	if s == "" {
		return ""
	}

	if lineWidth <= 0 {
		return s
	}

	words := strings.Fields(s)
	if len(words) == 0 {
		return ""
	}

	lines := make([]string, 0)
	current := words[0]

	for _, word := range words[1:] {
		if len(current)+1+len(word) <= lineWidth {
			current += " " + word
			continue
		}

		lines = append(lines, current)
		current = word
	}

	lines = append(lines, current)
	return strings.Join(lines, "\n")
}
