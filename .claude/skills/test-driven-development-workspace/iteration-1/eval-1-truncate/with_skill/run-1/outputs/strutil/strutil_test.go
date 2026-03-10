package strutil

import (
	"testing"

	"github.com/stretchr/testify/assert"
)

// Test list:
// - returns original string when length is within maxLen
// - truncates and adds ellipsis when input exceeds maxLen
// - handles very small maxLen values without exceeding maxLen
// - wraps text at word boundaries
// - returns original string when wrapping is unnecessary
// - handles words longer than lineWidth by placing them on their own line

func TestTruncate_ReturnsOriginalWhenWithinMaxLen(t *testing.T) {
	result := Truncate("hello", 5)

	assert.Equal(t, "hello", result)
}

func TestTruncate_TruncatesAndAddsEllipsis(t *testing.T) {
	result := Truncate("hello world", 8)

	assert.Equal(t, "hello...", result)
}

func TestTruncate_HandlesVerySmallMaxLen(t *testing.T) {
	result := Truncate("hello", 2)

	assert.Equal(t, "he", result)
}

func TestWordWrap_WrapsAtWordBoundaries(t *testing.T) {
	result := WordWrap("The quick brown fox jumps", 10)

	assert.Equal(t, "The quick\nbrown fox\njumps", result)
}

func TestWordWrap_ReturnsOriginalWhenNoWrapNeeded(t *testing.T) {
	result := WordWrap("short text", 20)

	assert.Equal(t, "short text", result)
}

func TestWordWrap_HandlesLongWordOnOwnLine(t *testing.T) {
	result := WordWrap("tiny supercalifragilisticexpialidocious word", 8)

	assert.Equal(t, "tiny\nsupercalifragilisticexpialidocious\nword", result)
}
