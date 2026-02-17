package groups

import "math"

// CalculateSimilarity computes Log-Enhanced Jaccard Similarity
// Score = (|Intersection| / |Union|) * log10(1 + |Intersection|)
// This mitigates "Small Data Bias" where 1/1 match would beat 5/10 match.
func CalculateSimilarity(a []string, b []string) float64 {
	if len(a) == 0 || len(b) == 0 {
		return 0.0
	}

	setA := make(map[string]bool, len(a))
	for _, v := range a {
		setA[v] = true
	}

	setB := make(map[string]bool, len(b))
	for _, v := range b {
		setB[v] = true
	}

	// Intersection
	intersectionCount := 0
	for k := range setA {
		if setB[k] {
			intersectionCount++
		}
	}

	// Union
	unionSet := make(map[string]bool)
	for k := range setA {
		unionSet[k] = true
	}
	for k := range setB {
		unionSet[k] = true
	}
	unionCount := len(unionSet)

	if unionCount == 0 {
		return 0.0
	}

	jaccard := float64(intersectionCount) / float64(unionCount)
	weight := math.Log10(1.0 + float64(intersectionCount))

	return jaccard * weight
}

// FindCommonInterests returns the intersection of two interest lists
func FindCommonInterests(a []string, b []string) []string {
	setA := make(map[string]bool, len(a))
	for _, v := range a {
		setA[v] = true
	}

	var common []string
	for _, v := range b {
		if setA[v] {
			common = append(common, v)
		}
	}
	return common
}
