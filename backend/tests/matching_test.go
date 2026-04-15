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

	// Score = intersection(a,b) / len(a) = 3/3 = 1.0
	expected := 1.0
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
	// len(a) = 4
	// Score = 2/4 = 0.5
	expected := 2.0 / 4.0
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
	// a covers all of b's interests (perfect coverage of a)
	aFull := []string{"AI"}
	bFull := []string{"AI"}
	scoreFull := groups.CalculateSimilarity(aFull, bFull)
	// intersection/len(a) = 1/1 = 1.0

	// a has interests b doesn't fully share — score should be less than 1.0
	aPartial := []string{"AI", "ML", "Robotics"}
	bPartial := []string{"AI", "ML"}
	scorePartial := groups.CalculateSimilarity(aPartial, bPartial)
	// intersection/len(a) = 2/3 = 0.667

	if scorePartial >= scoreFull {
		t.Errorf("partial match should score lower than full match: partial=%.4f, full=%.4f", scorePartial, scoreFull)
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


