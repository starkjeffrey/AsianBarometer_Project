# Cross-Wave Question Discovery - Summary Report

## Overview

This tool systematically identifies questions that appear across multiple waves using four methods:

1. **Exact label matching** - Questions with identical text
2. **Keyword matching** - Questions containing key concepts (trust, democracy, etc.)
3. **Value label matching** - Questions with identical response scales
4. **Question number patterns** - Same q-number across waves

## Key Findings

### Questions in 3+ Waves (High Priority for Cross-Wave Analysis)

**16 questions found in 3 waves** (W4, W5, W6):

#### Trust in Institutions Series
- **q7**: Trust in executive/president
- **q8**: Trust in courts
- **q9**: Trust in national government
- **q11**: Trust in parliament
- **q12**: Trust in civil service
- **q14**: Trust in police
- **q15**: Trust in local government

#### Economic Evaluations Series
- **q3**: Country economic condition future
- **q4**: Family economic situation current
- **q5**: Family economic condition past
- **q6**: Family economic condition future

#### Political Participation
- **q32**: Political discussion comfort
- **q34**: Vote choice
- **q34a**: Winning/losing camp
- **q37**: Campaign participation
- **q38**: Election freedom and fairness

### Questions in 2 Waves (Additional Candidates)

**51 questions found in 2 waves** - primarily W5 & W6:

#### Notable Examples:
- **q1**: Overall country economic condition (W5, W6)
- **q10**: Trust in political parties (W5, W6)
- **q16**: Trust in election commission (W5, W6)
- **q161**: Family income security concerns (W5, W6)
- **q163**: Fairness of family income (W5, W6)
- **q165**: Intergenerational prospects (W5, W6)

## Analysis by Method

### Method 1: Exact Label Matching
- **Total matches**: 67 questions
- **3+ waves**: 16 questions
- **2 waves**: 51 questions
- **Confidence**: HIGH - These are ready to add to concept_mappings.csv

### Method 2: Keyword Matching
- **Total matches**: 39 questions
- **Top keywords**: trust (7 questions), economic (6), election (5), vote (4)
- **Confidence**: MEDIUM - Requires manual review of question intent

### Method 3: Value Label Matching
- **Total patterns**: 125 response scale patterns
- **Use case**: Identify question batteries using same scale structure
- **Confidence**: LOW - Same scale doesn't guarantee same concept

### Method 4: Same Question Number
- **Total matches**: 172 question numbers appear in 3+ waves
- **Caution**: Question numbers may be reused for different questions
- **Confidence**: LOW - Always verify label text matches

## Recommended Actions

### Priority 1: Add Trust & Economic Questions (3-wave matches)
These 16 questions (q3-q15, q32, q34, q34a, q37, q38) should be added to `concept_mappings.csv` immediately:

```csv
concept,domain,description,w2_var,w3_var,w4_var,w5_var,w6_var,scale_type,direction,notes
trust_parliament,trust,Trust in parliament,,,q11,q11,q11,4-point,higher_more,W4/W5/W6 available
econ_country_future,economic,Country economic condition future,,,q3,q3,q3,5-point,higher_better,W4/W5/W6 available
political_discussion,politics,Comfort discussing politics with opposing views,,,q32,q32,q32,4-point,higher_easier,W4/W5/W6 available
```

### Priority 2: Extend W5-W6 Concepts
Add important concepts that exist in W5 & W6:
- Income security (q161)
- Income fairness (q163)
- Intergenerational prospects (q165)
- Trust in election commission (q16)

### Priority 3: Review Keyword Matches
File: `docs/cross_wave_keyword_matches.csv`
- Manual review needed to confirm concept equivalence
- Look for questions where wording differs but intent is the same

### Priority 4: Investigate Value Pattern Matches
File: `docs/cross_wave_value_patterns.csv`
- Useful for finding question batteries (e.g., all trust questions use same 4-point scale)
- Can help identify missed matches where labels differ but structure is identical

## Output Files

All discovery results saved to `docs/`:

1. **cross_wave_exact_matches.csv** - 67 questions with identical labels (HIGH CONFIDENCE)
2. **cross_wave_keyword_matches.csv** - 39 questions by keyword (MEDIUM CONFIDENCE)
3. **cross_wave_value_patterns.csv** - 125 scale patterns (LOW CONFIDENCE)
4. **cross_wave_same_qnumber.csv** - 172 question number patterns (LOW CONFIDENCE)

## Usage Instructions

### To re-run the discovery tool:
```r
source("scripts/discover_cross_wave_questions.R")
```

### To add discoveries to concept_mappings.csv:
1. Open `docs/cross_wave_exact_matches.csv`
2. Filter to questions with `n_waves >= 3`
3. For each question:
   - Assign a concept name (e.g., `trust_parliament`)
   - Assign domain (trust, economic, politics, democracy)
   - Add to `docs/concept_mappings.csv` with wave-specific variable names
4. Test extraction: `source("functions/concept_functions.R")` then `get_concept(data, "new_concept", "W4")`

## Limitations

1. **No 5-wave matches found** - No questions appear with identical labels in all 5 waves
   - Likely due to question wording evolution over time
   - Consider fuzzy matching for future enhancements

2. **W2-W3 coverage limited** - Most matches are W4-W5-W6 or W5-W6
   - Earlier waves may have different questionnaire structure
   - Manual review of W2-W3 needed for more complete mapping

3. **Cambodia-only analysis** - All waves filtered to Cambodia (country==12)
   - Results specific to Cambodian questionnaire versions
   - Other countries may have different question availability

## Next Steps

1. ✅ Add 16 high-confidence 3-wave questions to concept_mappings.csv
2. ⏳ Review keyword matches for additional concepts
3. ⏳ Investigate W2-W3 coverage gaps manually
4. ⏳ Consider fuzzy text matching for evolved question wording
5. ⏳ Validate all new concepts with `test_concept_system.R`

---

**Generated by**: scripts/discover_cross_wave_questions.R
**Date**: 2025-01-04
**Total questions analyzed**: 1,003 (q### variables across 5 waves)
**High-confidence cross-wave matches**: 16 questions in 3+ waves
