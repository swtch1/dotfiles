package strutil

import (
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestTruncate_NoTruncationWhenWithinMaxLen(t *testing.T) {
	assert.Equal(t, "hello", Truncate("hello", 10))
	assert.Equal(t, "hello", Truncate("hello", 5))
}

func TestTruncate_TruncatesAndAddsEllipsis(t *testing.T) {
	assert.Equal(t, "hello...", Truncate("hello world", 5))
}

func TestTruncate_ZeroOrNegativeMaxLenReturnsEmptyString(t *testing.T) {
	assert.Equal(t, "", Truncate("hello", 0))
	assert.Equal(t, "", Truncate("hello", -1))
}

func TestWordWrap_WrapsAtWordBoundaries(t *testing.T) {
	input := "The quick brown fox jumps over the lazy dog"
	expected := "The quick\nbrown fox\njumps over\nthe lazy\ndog"

	assert.Equal(t, expected, WordWrap(input, 10))
}

func TestWordWrap_DoesNotSplitSingleLongWord(t *testing.T) {
	assert.Equal(t, "supercalifragilistic", WordWrap("supercalifragilistic", 5))
}

func TestWordWrap_EmptyInputReturnsEmptyString(t *testing.T) {
	assert.Equal(t, "", WordWrap("", 10))
}
