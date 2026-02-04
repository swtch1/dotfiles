---
description: Comprehensive stock analysis with actionable BUY/SELL/CALL/PUT recommendations
model: sonnet
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

### 1. Price Action & Market Context

**Execute these searches in parallel:**
- Current price, % change, volume for $ARGUMENTS
- S&P 500, Nasdaq performance
- Relevant sector ETF performance (identify based on company)

**Key Questions:**
- Is this stock moving WITH the market or AGAINST it?
- Is volume heavy (>2x average), normal, or light?
- If moving against the market, that's a strong signal of stock/sector-specific drivers

### 2. Recent Performance Context

**Research:**
- Price performance: 1 week, 1 month, 3 months, YTD, 1 year
- Recent run-up or selloff trajectory
- Distance from 52-week high/low
- YTD percentage gain/loss

**Analysis:**
- After massive runs (>50% in 6 months), consider profit-taking as driver
- Near 52-week highs = momentum, near lows = distress or value
- Context shapes interpretation of current price

### 3. Sector & Peer Analysis

**Research:**
- Identify 3-5 direct competitors
- Check their recent performance and trends
- Search for sector-wide news or trends
- Find relevant sector ETF performance

**Key Question:**
- Is this company-specific or sector-wide?
- If peers are flat/up while target is down = company-specific problem
- If whole sector moving together = industry trend or rotation

### 4. Company-Specific Catalysts

**Search for (recent):**
- Earnings reports or guidance changes
- Analyst rating changes or price target adjustments
- New contracts, partnerships, or customer announcements
- Regulatory news or legal issues
- Management changes or insider trading
- Product launches or delays
- M&A rumors or announcements

**Insider Trading (past 6 months):**
- Recent insider buying (bullish) or selling (bearish)
- Pattern: many insiders selling = warning signal
- Single transaction = less meaningful

**Upcoming Catalysts:**
- Next earnings date
- Product launches, FDA decisions, contract deadlines
- Industry conferences or events

**Short Interest & Technical Data:**
- Short interest % of float (>10% = elevated, >20% = squeeze candidate)
- Days to cover
- Recent changes in short interest (increasing/decreasing)
- Unusual options activity if relevant

### 5. Quantitative Quality Screens

**Piotroski F-Score (0-9):**
Measures financial strength. Calculate or find:
- Profitability: Positive ROA (1pt), Positive Operating CF (1pt), CF > Net Income (1pt), Improving ROA YoY (1pt)
- Leverage/Liquidity: Decreasing debt ratio (1pt), Improving current ratio (1pt), No new shares issued (1pt)
- Operating Efficiency: Improving gross margin (1pt), Improving asset turnover (1pt)

| Score | Interpretation |
|-------|---------------|
| 8-9 | Strong fundamentals, quality company |
| 5-7 | Average, needs deeper analysis |
| 0-4 | Weak fundamentals, high risk |

**Altman Z-Score (Bankruptcy Risk):**
For manufacturing companies: Z = 1.2A + 1.4B + 3.3C + 0.6D + 1.0E
- A = Working Capital / Total Assets
- B = Retained Earnings / Total Assets
- C = EBIT / Total Assets
- D = Market Value Equity / Total Liabilities
- E = Sales / Total Assets

| Score | Interpretation |
|-------|---------------|
| >2.99 | Safe zone - low bankruptcy risk |
| 1.8-2.99 | Grey zone - moderate risk |
| <1.8 | Distress zone - high bankruptcy risk |

**Return on Invested Capital (ROIC):**
ROIC = NOPAT / Invested Capital

| ROIC | Interpretation |
|------|---------------|
| >15% | Very strong, creating significant value |
| 12-15% | Quality business, beats cost of capital |
| 8-12% | Average, marginal value creation |
| <8% | Weak, likely destroying value |

**Free Cash Flow Yield:**
FCF Yield = FCF per share / Stock Price

| FCF Yield | Interpretation |
|-----------|---------------|
| >8% | Very attractive, potential value trap check needed |
| 4-8% | Reasonable valuation |
| 2-4% | Fully valued or growth priced in |
| <2% or negative | Expensive or cash-burning |

### 6. Valuation Analysis

**Current Metrics:**
- P/E (TTM and Forward), P/S, EV/Sales, EV/EBITDA (sector-appropriate)
- How valuation compares to:
  - Historical average (3-year)
  - Peer group median
  - Growth rate (PEG ratio)

**Intrinsic Value Estimation:**
Use appropriate method for stock type:
- DCF: For stable cash flow businesses
- Earnings Power Value: For mature companies
- Revenue multiple: For high-growth/unprofitable
- Asset-based: For financials, REITs, commodity producers

**Margin of Safety Calculation:**
```
Margin of Safety = (Intrinsic Value - Current Price) / Intrinsic Value
```

| Stock Quality | Minimum Margin of Safety |
|--------------|-------------------------|
| High quality (F-Score 8-9, dominant position) | 10-15% |
| Average quality | 20-25% |
| Speculative / turnaround | 30-50% |

**Scenario Analysis:**

| Scenario | Probability | Target Price | Return |
|----------|-------------|--------------|--------|
| Bull | X% | $XXX | +XX% |
| Base | X% | $XXX | +/-X% |
| Bear | X% | $XXX | -XX% |
| **Expected Value** | 100% | $XXX | +/-X% |

**Upside/Downside Ratio:**
```
Ratio = (Target Price - Current) / (Current - Bear Case)
```
- Require >2:1 for BUY recommendation
- 1:1 to 2:1 = HOLD territory
- <1:1 = Risk exceeds reward

**Analyst Consensus:**
- Recent price target changes (past 30 days)
- Average analyst price target vs current price
- Consensus rating (Strong Buy to Sell)

### 7. Fundamental Health Check

**Financial Performance:**
- Revenue growth trend (accelerating/stable/decelerating)
- Profitability: Current and trajectory
  - If unprofitable: path to profitability clear?
  - If profitable: margin trends (expanding/compressing)
- Recent earnings surprises (beats vs misses)
- Guidance: raised, maintained, lowered?

**Balance Sheet Strength:**
- Current ratio and quick ratio
- Debt/Equity and Net Debt/EBITDA
- Interest coverage ratio
- Cash runway (for unprofitable companies)

**Operational Issues:**
- Customer concentration risk
- Competition intensifying?
- Supply chain or cost pressures
- Market share trends

**Business Model Changes:**
- Any strategic pivots
- Success/failure of new initiatives
- Revenue mix shifts

### 8. Options Analysis

**Implied Volatility Context:**
- Current IV Rank (0-100): Where is IV relative to past year?
- Current IV Percentile: % of days IV was lower
- Compare IV to Historical Volatility (HV)

| IV Rank | Interpretation | Strategy Implication |
|---------|---------------|---------------------|
| >50 | Options expensive | Prefer stock or sell premium |
| 30-50 | Neutral | Either approach works |
| <30 | Options cheap | Good for buying options |

**Options Flow & Sentiment:**
- Put/Call Ratio (PCR): >1.0 bearish, <0.7 bullish
- Unusual options activity (large block trades, sweeps)
- Max pain level vs current price
- Open interest at key strikes

**When to Recommend Options vs Stock:**

| Condition | Recommendation |
|-----------|----------------|
| Bullish + IV Rank <30 + Catalyst in 45-90 days | **CALL** (0.30-0.40 delta, 45-60 DTE) |
| Bullish + IV Rank >50 | **STOCK** (options too expensive) |
| Bullish + no specific catalyst | **STOCK** (time decay hurts) |
| Bearish + IV Rank <30 + Catalyst | **PUT** (0.30-0.40 delta, 45-60 DTE) |
| Bearish + IV Rank >50 | **SHORT STOCK** or avoid |
| Long-term thesis (6+ months) | **STOCK** regardless of IV |
| High conviction + defined risk wanted | **OPTIONS** (debit spreads if IV high) |

### 9. Technical vs Fundamental Assessment

**Determine if recent moves are:**

**Technical (sentiment/trading patterns):**
- Oversold bounce after sharp drop
- Profit-taking after parabolic run
- Options expiration-related
- Short squeeze or margin calls
- No news, just following market

**Fundamental (real business changes):**
- Earnings beat/miss
- Guidance change
- New contract or lost customer
- Regulatory approval/rejection
- Analyst downgrade with thesis change

### 10. Recommendation Framework

**BUY Criteria (all should be met):**
- [ ] Margin of safety >15-20% (or >30% for speculative)
- [ ] Upside to base case target >20%
- [ ] Upside/downside ratio >2:1
- [ ] F-Score ≥7 (or improving trend if 5-6)
- [ ] Z-Score >2.5 (safe or grey zone upper half)
- [ ] ROIC >10% (or clear path to it)
- [ ] At least one identifiable catalyst within 6 months

**SELL Criteria (any significant one):**
- Trading significantly above intrinsic value (negative margin of safety)
- Deteriorating fundamentals (F-Score <4 and declining)
- Z-Score <1.8 (distress zone)
- Negative catalysts identified with high probability
- Upside/downside ratio <1:1
- ROIC consistently <8% with no improvement path
- Competitive position eroding

**HOLD Criteria:**
- Fairly valued (small margin of safety)
- Fundamentals stable but not improving
- No clear catalyst either direction
- Upside/downside ratio 1:1 to 2:1

**Conviction Levels:**

| Level | Criteria |
|-------|----------|
| **High** | Multiple quality metrics strong, clear catalyst, >30% margin of safety |
| **Medium** | Most metrics acceptable, some uncertainty, 15-30% margin of safety |
| **Low** | Mixed signals, thesis dependent on specific outcomes, <15% margin of safety |

**Position Sizing Guidelines:**

| Conviction | Stock Quality | Max Position |
|------------|--------------|--------------|
| High | High | 5-8% |
| High | Average | 3-5% |
| Medium | High | 3-5% |
| Medium | Average | 2-3% |
| Low | Any | 1-2% |

## Research Execution

**Use parallel research agents for speed:**

1. **Price & Market Agent**: Current prices, market indices, volume data, recent performance
2. **Sector & Peer Agent**: Competitor performance, sector ETF, industry trends
3. **News & Catalyst Agent**: Recent news, analyst changes, insider trading, upcoming events
4. **Valuation Agent**: Multiples, analyst targets, historical comparison, intrinsic value estimates, margin of safety calculation, scenario analysis (bull/base/bear cases with probability weighting)
5. **Fundamentals Agent**: Recent earnings, revenue trends, operational metrics, F-Score components, Z-Score calculation, ROIC, FCF yield, balance sheet strength
6. **Options Agent**: IV rank/percentile, put-call ratio, unusual activity, max pain, open interest at key strikes, recommended strategy based on IV environment

## Output Format

**Save the analysis to:** `~/doc/market_research/YYYY-MM-DD-TICKER.md`

Structure your analysis as follows:

```markdown
# Stock Analysis: [TICKER] - [Date]

**Current Price**: $X.XX ([+/-]X.XX%)
**Market Context**: S&P [+/-]X%, Nasdaq [+/-]X%, [Sector ETF] [+/-]X%
**Volume**: X.XXM (XXX% of average)

---

## Recommendation

**Action**: [BUY / SELL / HOLD / CALL / PUT]
**Conviction**: [High / Medium / Low]
**Time Horizon**: [X months]
**Position Size**: [X% of portfolio max]

### Rationale
- [Primary reason with specific evidence]
- [Secondary supporting factor]
- [Key risk that could invalidate thesis]

### If Options Recommended
- **Strategy**: [e.g., Long Call, Put Spread]
- **Strike**: $XXX ([delta])
- **Expiration**: [Date] ([X] DTE)
- **IV Rank**: [X]% (options [cheap/fair/expensive])

---

## Executive Summary

[2-3 sentences explaining the investment thesis. Be direct and definitive.]

---

## Quality Metrics Dashboard

| Metric | Value | Rating |
|--------|-------|--------|
| Piotroski F-Score | X/9 | [Strong/Average/Weak] |
| Altman Z-Score | X.XX | [Safe/Grey/Distress] |
| ROIC | X.X% | [Excellent/Good/Average/Poor] |
| FCF Yield | X.X% | [Attractive/Fair/Expensive] |

---

## Valuation Summary

| Metric | Current | Historical Avg | Peer Median |
|--------|---------|---------------|-------------|
| P/E (FWD) | XX.Xx | XX.Xx | XX.Xx |
| EV/EBITDA | XX.Xx | XX.Xx | XX.Xx |
| P/S | XX.Xx | XX.Xx | XX.Xx |

**Intrinsic Value Estimate**: $XXX (Method: [DCF/EPV/Multiple])
**Current Price**: $XXX
**Margin of Safety**: XX%

### Scenario Analysis

| Scenario | Probability | Target | Return |
|----------|-------------|--------|--------|
| Bull | XX% | $XXX | +XX% |
| Base | XX% | $XXX | +/-X% |
| Bear | XX% | $XXX | -XX% |
| **Expected** | | $XXX | +/-X% |

**Upside/Downside Ratio**: X.X:1

---

## Catalysts

### Bullish Catalysts
1. [Catalyst with timeline and probability]
2. [Catalyst]

### Bearish Catalysts / Risks
1. [Risk with impact assessment]
2. [Risk]

### Upcoming Events
- [Date]: [Event]
- [Date]: [Event]

---

## Options Analysis

**IV Environment:**
- IV Rank: XX% | IV Percentile: XX%
- Current IV: XX% vs HV: XX%
- Options are: [Cheap / Fair / Expensive]

**Flow Analysis:**
- Put/Call Ratio: X.XX ([Bullish/Neutral/Bearish])
- Notable activity: [Unusual trades if any]

**Recommendation**: [Stock / Calls / Puts / Spreads] because [IV rationale + catalyst timing]

---

## Fundamental Analysis

### Financial Strength
[Key metrics and trends]

### Competitive Position
[Moat assessment, market share, competitive dynamics]

### Management & Governance
[Quality assessment, insider activity, capital allocation]

---

## Sector & Peer Comparison

| Company | Performance | P/E | Notes |
|---------|------------|-----|-------|
| [Peer 1] | [+/-]X% | XXx | [Context] |
| [Peer 2] | [+/-]X% | XXx | [Context] |
| [Sector ETF] | [+/-]X% | - | [Context] |

---

## Technical Levels

- **Support**: $XXX, $XXX
- **Resistance**: $XXX, $XXX
- **52-Week Range**: $XXX - $XXX

---

## Investment Checklist

- [ ] Margin of safety adequate for stock quality
- [ ] Upside/downside >2:1
- [ ] Quality metrics acceptable (F-Score, Z-Score, ROIC)
- [ ] Clear catalyst identified
- [ ] Position size appropriate for conviction
- [ ] Understand what would invalidate thesis

---

## Sources

[List all sources with markdown hyperlinks]
```

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
