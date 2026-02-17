package tests

import (
	"math"
	"testing"

	"github.com/muskan953/college-Hop/internal/groups"
)

func TestCalculateSimilarity_IdenticalSets(t *testing.T) {
	a := []string{"AI", "Robotics", "ML"}
	b := []string{"AI", "Robotics", "ML"}

	score := groups.CalculateSimilarity(a, b)

	// Jaccard = 3/3 = 1.0, log10(1+3) = 0.602...
	// Score = 1.0 * 0.602 = 0.602
	expected := 1.0 * math.Log10(4.0)
	if math.Abs(score-expected) > 0.001 {
		t.Errorf("identical sets: got %.4f, want %.4f", score, expected)
	}
}

func TestCalculateSimilarity_NoOverlap(t *testing.T) {
	a := []string{"AI", "Robotics"}
	b := []string{"Music", "Art"}

	score := groups.CalculateSimilarity(a, b)

	if score != 0.0 {
		t.Errorf("no overlap: got %.4f, want 0.0", score)
	}
}

func TestCalculateSimilarity_PartialOverlap(t *testing.T) {
	a := []string{"AI", "Robotics", "ML", "Cloud"}
	b := []string{"AI", "Cloud", "DevOps", "Security"}

	score := groups.CalculateSimilarity(a, b)

	// Intersection: {AI, Cloud} = 2
	// Union: {AI, Robotics, ML, Cloud, DevOps, Security} = 6
	// Jaccard = 2/6 = 0.333
	// log10(1+2) = 0.477
	// Score = 0.333 * 0.477 = ~0.159
	jaccard := 2.0 / 6.0
	logWeight := math.Log10(3.0)
	expected := jaccard * logWeight
	if math.Abs(score-expected) > 0.001 {
		t.Errorf("partial overlap: got %.4f, want %.4f", score, expected)
	}
}

func TestCalculateSimilarity_EmptyInput(t *testing.T) {
	score1 := groups.CalculateSimilarity([]string{}, []string{"AI"})
	score2 := groups.CalculateSimilarity([]string{"AI"}, []string{})
	score3 := groups.CalculateSimilarity([]string{}, []string{})

	if score1 != 0 || score2 != 0 || score3 != 0 {
		t.Errorf("empty input should return 0: got %.4f, %.4f, %.4f", score1, score2, score3)
	}
}

func TestCalculateSimilarity_SmallDataBiasResistance(t *testing.T) {
	// 1 match out of 1 (trivially perfect but shallow)
	aSmall := []string{"AI"}
	bSmall := []string{"AI"}
	scoreSmall := groups.CalculateSimilarity(aSmall, bSmall)
	// Jaccard = 1/1 = 1.0, log10(1+1) = 0.301
	// Score = 1.0 * 0.301 = 0.301

	// 5 matches out of 7 union (deep and meaningful)
	aDeep := []string{"AI", "ML", "Robotics", "Cloud", "DevOps"}
	bDeep := []string{"AI", "ML", "Robotics", "Cloud", "DevOps", "IoT", "Security"}
	scoreDeep := groups.CalculateSimilarity(aDeep, bDeep)
	// Jaccard = 5/7 = 0.714, log10(1+5) = 0.778
	// Score = 0.714 * 0.778 = 0.556

	// The log-enhanced version should make the deep match score higher
	// than the trivial 1/1 match, defeating small data bias
	if scoreDeep <= scoreSmall {
		t.Errorf("log-enhanced Jaccard should defeat small data bias: deep=%.4f, small=%.4f", scoreDeep, scoreSmall)
	}
}

func TestFindCommonInterests(t *testing.T) {
	a := []string{"AI", "Robotics", "ML", "Cloud"}
	b := []string{"AI", "Cloud", "DevOps"}

	common := groups.FindCommonInterests(a, b)

	if len(common) != 2 {
		t.Fatalf("expected 2 common interests, got %d", len(common))
	}

	found := make(map[string]bool)
	for _, c := range common {
		found[c] = true
	}
	if !found["AI"] || !found["Cloud"] {
		t.Errorf("expected AI and Cloud, got %v", common)
	}
}

func TestFindCommonInterests_NoCommon(t *testing.T) {
	a := []string{"AI", "Robotics"}
	b := []string{"Music", "Art"}

	common := groups.FindCommonInterests(a, b)

	if len(common) != 0 {
		t.Errorf("expected 0 common interests, got %d: %v", len(common), common)
	}
}
