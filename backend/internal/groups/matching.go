package groups


// CalculateSimilarity computes an intuitive match percentage.
// Score = (|Intersection| / |User Interests|)
// This tells the user "What percentage of YOUR interests does this person/group satisfy?"
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

	return float64(intersectionCount) / float64(len(setA))
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
