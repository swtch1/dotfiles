---
name: stock-screen
description: Comprehensive stock analysis with actionable BUY/SELL/CALL/PUT recommendations
model: sonnet
disable-model-invocation: true
---

# Stock Analysis

Perform comprehensive analysis of **$ARGUMENTS** covering price action, market context, sector dynamics, valuation, fundamentals, quality metrics, and options - culminating in an actionable recommendation.

## Analysis Framework

### 0. Stock Type Classification (Do This First)

Before deep research, classify the stock to focus analysis appropriately:

| Type | Primary Drivers | Key Metrics |
|------|----------------|-------------|
| **Commodity Producer** (miners, oil/gas, ag) | Underlying commodity price (this is 80-90% of the story) | AISC/breakeven vs spot price, production volumes, reserves |
| **Growth Tech** | Revenue growth, TAM expansion, user metrics | P/S, revenue acceleration, net retention |
| **Cyclical Industrial** | Economic cycle, capacity utilization | P/E vs cycle, order backlog, inventory levels |
| **Financials** | Interest rates, credit quality | NIM, book value, loan growth |
| **Defensive/Dividend** | Yield, payout sustainability | Dividend yield, payout ratio, FCF coverage |

**For commodity producers specifically:**
- Get the underlying commodity price and % change FIRST - this often explains everything
- Calculate margin: (spot price - AISC) = profit per unit
- These stocks are leveraged bets on the commodity - a 5% move in gold can mean 15%+ move in miners

### Framework Sections

The complete analysis framework includes:

1. **Price Action & Market Context** - Current price, volume, market comparison
2. **Recent Performance Context** - Historical performance, 52-week range
3. **Sector & Peer Analysis** - Competitor performance, industry trends
4. **Company-Specific Catalysts** - Earnings, news, insider trading, short interest
5. **Quantitative Quality Screens** - Piotroski F-Score, Altman Z-Score, ROIC, FCF Yield
6. **Valuation Analysis** - Multiples, intrinsic value, margin of safety, scenario analysis
7. **Fundamental Health Check** - Financial performance, balance sheet, operational issues
8. **Options Analysis** - IV context, options flow, when to use options vs stock
9. **Technical vs Fundamental Assessment** - Distinguish price moves from business changes
10. **Recommendation Framework** - BUY/SELL/HOLD criteria with conviction levels

See the original command for complete details on each section.

## Research Execution

**Use parallel research agents for speed:**

1. **Price & Market Agent**: Current prices, market indices, volume data, recent performance
2. **Sector & Peer Agent**: Competitor performance, sector ETF, industry trends
3. **News & Catalyst Agent**: Recent news, analyst changes, insider trading, upcoming events
4. **Valuation Agent**: Multiples, analyst targets, historical comparison, intrinsic value estimates, margin of safety calculation, scenario analysis (bull/base/bear cases with probability weighting)
5. **Fundamentals Agent**: Recent earnings, revenue trends, operational metrics, F-Score components, Z-Score calculation, ROIC, FCF yield, balance sheet strength
6. **Options Agent**: IV rank/percentile, put-call ratio, unusual activity, max pain, open interest at key strikes, recommended strategy based on IV environment

**CRITICAL: Once agents return with data, STOP researching immediately and proceed to write the analysis. Use available data even if incomplete - mark missing metrics as "N/A" rather than pursuing perfect data. The goal is a complete analysis document, not exhaustive research.**

## Output Format

**Save the analysis to:** `~/doc/market_research/YYYY-MM-DD-TICKER.md`

For the complete output structure and format, see [template.md](template.md).

## Quality Standards

**Recommendation Rigor:**
- NEVER recommend BUY without calculating margin of safety
- NEVER recommend options without checking IV rank
- ALWAYS state what would invalidate the thesis
- ALWAYS provide specific price targets with methodology
- Conviction level must match evidence quality

**Intellectual Honesty:**
- Distinguish correlation from causation
- Note where evidence is strong vs speculative
- Acknowledge uncertainty with probability estimates
- Don't cherry-pick data to fit a narrative

**Causation Hierarchy:**
1. **Direct causation**: Earnings miss → stock drops
2. **Strong correlation with mechanism**: Bitcoin falls → bitcoin miners fall (clear economic link)
3. **Weak correlation**: Market up → stock down (suggests other factors)
4. **Spurious**: Tariff announcement → uranium stock drops 2 days later while uranium sector rises (not causal)

**Evidence Quality:**
- Primary sources > secondary sources
- Recent data > old data
- Company filings > analyst speculation
- Quantitative > qualitative when both available

**Handling Conflicting Data:**
- When sources give different numbers, note the range explicitly
- Explain discrepancy if possible (TTM vs forward, different share counts, data staleness)
- Don't pretend precision exists when it doesn't

## Important Notes

- **Don't just describe WHAT** - explain WHY with evidence and provide actionable recommendation
- **Compare to market/sector** - absolute vs relative performance reveals true story
- **Context matters** - 5% drop after 200% run ≠ 5% drop at 52-week low
- **Quality gates matter** - weak fundamentals need larger margin of safety
- **Options aren't always better** - high IV makes stock preferable
- **Time horizon matters** - match recommendation to catalyst timeline
- **Position size is risk management** - lower conviction = smaller position

---

$ARGUMENTS
