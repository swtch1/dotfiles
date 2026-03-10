---
name: stock-screen
description: Comprehensive stock analysis with actionable BUY/SELL/CALL/PUT recommendations. Use this skill whenever the user mentions a stock ticker (like AAPL, TSLA, NVDA), asks "should I buy/sell X", wants due diligence or a "DD" on a stock, requests a stock screen, asks about options plays on a specific stock, or wants analysis of any publicly traded company. Also triggers on patterns like "analyze [ticker]", "what do you think about [stock]", "screen [ticker]", and any investment-related query about a specific company.
---

# Stock Analysis

Perform a comprehensive analysis of the requested stock covering price action, market context, sector dynamics, valuation, fundamentals, quality metrics, and options — culminating in an actionable recommendation.

Save the final report to `~/doc/market_research/YYYY-MM-DD-TICKER.md` using the structure in [template.md](template.md).

## Step 1: Classify the Stock

Before diving into research, identify the stock type. This determines which metrics matter most and where to focus analytical effort — applying growth metrics to a gold miner wastes everyone's time.

| Type | Primary Drivers | Focus On | De-prioritize |
|------|----------------|----------|---------------|
| **Commodity Producer** (miners, oil/gas, ag) | Underlying commodity price (80-90% of the story) | AISC/breakeven vs spot, production volumes, reserves, commodity trend | Traditional P/E, revenue growth |
| **Growth Tech** | Revenue growth, TAM expansion, user metrics | P/S, revenue acceleration, net retention, rule of 40 | Dividend yield, book value |
| **Cyclical Industrial** | Economic cycle, capacity utilization | P/E vs cycle position, order backlog, inventory levels | Absolute P/E (misleading at peaks/troughs) |
| **Financials** | Interest rates, credit quality | NIM, book value, loan growth, provision trends | EV/EBITDA (doesn't apply), revenue multiples |
| **Defensive/Dividend** | Yield sustainability, inflation protection | Dividend yield, payout ratio, FCF coverage, consecutive increase years | High-growth metrics |
| **Biotech/Pharma** | Pipeline catalysts, FDA decisions | Pipeline stage, cash runway, binary event calendar | Traditional earnings (often pre-revenue) |

**Commodity producers deserve special treatment:** Get the underlying commodity price and recent trend FIRST. Create a dedicated commodity price section before the company analysis. Calculate the explicit per-unit margin: (spot price - AISC) = profit per ounce/barrel/unit. Then quantify the leverage: a 5% move in the commodity changes the per-unit margin by X%, which amplifies into Y% moves in the producer's stock. Show the math — the reader should see exactly how commodity price changes flow through to the miner's economics.

## Step 2: Gather Data (Parallel Web Searches)

Speed matters. Fire multiple web searches simultaneously rather than sequentially. Use whichever search tools are available.

### Search Strategy

Run these in parallel, tailored to the stock type from Step 1:

**Always run (all stock types):**
1. `[TICKER] stock price today volume 52-week range` — Current price, volume vs average, range position
2. `[TICKER] earnings revenue quarterly results [current year]` — Recent financial performance
3. `[TICKER] analyst rating target price consensus [current year]` — Street consensus and recent changes
4. `[TICKER] news catalyst insider trading short interest` — Developments and sentiment signals

**Add based on stock type:**
- **Commodity producers**: `[commodity] price forecast AISC production cost` — The commodity IS the thesis
- **Growth**: `[TICKER] revenue growth TAM addressable market net retention` — Growth trajectory
- **Cyclical**: `[TICKER] backlog orders capacity utilization economic cycle` — Cycle positioning
- **Financials**: `[TICKER] NIM net interest margin loan growth credit quality provisions` — Bank metrics
- **Options-focused requests**: `[TICKER] options IV rank IV percentile implied volatility` and `[TICKER] options chain put call open interest` — Search specifically for IV Rank and IV Percentile as numeric values. Try sites like AlphaQuery, Barchart, or MarketChameleon which typically display these. "N/A" for IV data when the user asked about options is a significant gap.

**Run last (needs other data for context):**
5. `[TICKER] PE ratio EV/EBITDA valuation peers comparison` — Valuation relative to quality

### Data Source Quality

Weight sources in this order:
- **Primary**: SEC filings (10-K, 10-Q, 8-K), company investor relations, exchange data
- **Strong secondary**: Major financial aggregators (Yahoo Finance, Google Finance, Finviz), earnings transcripts
- **Tertiary**: Analyst commentary, financial news articles
- **Use cautiously**: Social media sentiment, blog posts, forums — label as "market sentiment" not "analysis"

### When Data Is Missing

Mark unavailable metrics as "N/A" and move on. A complete analysis with some gaps is vastly more useful than an incomplete analysis that tried to find everything. Note data gaps so the user knows what's missing.

**Once data gathering is done, stop researching and start writing.** Resist the urge to do "one more search" — diminishing returns kick in fast.

## Step 3: Analyze

Work through each section below. Write the analytical sections FIRST, then write the Recommendation and Executive Summary last — this prevents anchoring on a premature conclusion before the evidence is assembled.

### Price Action & Market Context
- Current price, daily/weekly change, volume relative to average
- Compare to benchmarks: S&P 500, Nasdaq, relevant sector ETF
- Relative performance is the real signal: a stock down 2% when the sector is down 5% is actually showing strength

### Recent Performance
- Performance across 1W, 1M, 3M, 6M, 1Y timeframes
- 52-week range position — near the high could mean momentum or overextension; near the low could mean opportunity or falling knife
- Context is everything: a 5% drop after a 200% run is not the same as a 5% drop at 52-week lows

### Sector & Peer Analysis
- Direct competitor performance — is this a company story or a sector-wide move?
- Sector ETF trend and momentum
- Relative valuation vs peers — paying a premium? Getting a discount? Is the delta justified?

### Company-Specific Catalysts
- Upcoming earnings date and expectations
- Recent news, management changes, product launches, regulatory developments
- Insider trading patterns — clustered selling is more concerning than isolated transactions
- Short interest level and trend — high and rising suggests an active short thesis; high and declining suggests potential squeeze

### Quantitative Quality Metrics
Calculate where data permits, estimate where it doesn't, mark N/A where impossible:
- **Piotroski F-Score** (0-9): Fundamental strength composite. 8-9 = strong, 0-2 = weak. Built from: positive net income, positive operating cash flow, rising ROA, CFO > net income, declining leverage, improving current ratio, no dilution, improving gross margin, improving asset turnover.
- **Altman Z-Score**: Bankruptcy probability. >2.99 = safe, 1.81-2.99 = grey zone, <1.81 = distress. (Note: designed for manufacturing companies; less reliable for financials and tech.)
- **ROIC**: How efficiently does management deploy capital? >15% = excellent, 10-15% = good, <10% = question the moat.
- **FCF Yield**: Free cash flow / market cap. >5% generally attractive. Negative means cash burn.

### Valuation Analysis
- **Multiples**: P/E (trailing + forward), EV/EBITDA, P/S, P/B — compare to own 5-year historical averages, direct peers, and sector medians. Search specifically for `[TICKER] historical PE ratio 5 year average` — returning N/A for historical comparisons defeats the purpose of relative valuation.
- **Intrinsic value estimate**: Use the most appropriate method for the stock type. DCF for stable cash flows, EPV for cyclicals, revenue multiples for high-growth. State assumptions clearly — the estimate is only as good as the inputs.
- **Margin of safety**: (Intrinsic value - current price) / intrinsic value. Lower-quality companies need a larger margin because the estimate has wider error bars.
- **Scenario analysis**: Bull/base/bear cases with probability weights. Calculate expected return as the probability-weighted average.

### Fundamental Health Check
- Revenue and earnings trends — growing, stable, or declining?
- Balance sheet: debt/equity, interest coverage, cash position, maturity schedule
- Cash flow quality: does operating cash flow support or contradict reported earnings?
- Operational risks: margin compression, customer concentration, regulatory exposure, competitive threats

### Options Analysis
Skip this section for stocks with thin options markets (most small caps). Include when options are liquid.
- **IV environment**: IV Rank and IV Percentile tell you whether options are cheap or expensive relative to history. High IV (>50th percentile) favors selling premium; low IV favors buying premium. Get actual numeric values — search AlphaQuery, Barchart, or MarketChameleon if general financial sites don't surface them. If exact IV Rank/Percentile data is unavailable from these sources, estimate from context (recent price action, VIX level, earnings proximity, historical patterns) with clear caveats — e.g., "IV Rank estimated ~60-70% based on recent 9.4% weekly drop and elevated VIX." A labeled estimate is far more useful than N/A.
- **Flow signals**: Put/call ratio, unusual activity at specific strikes, open interest concentration
- **Strategy alternatives**: Present 2-3 named strategies (e.g., cash-secured puts at different strikes, put spreads, covered calls) with specific strike/expiry suggestions and expected risk/reward. Match strategy to IV + directional thesis. The reader should walk away knowing not just "sell puts" but which puts, at what strike, and why.

**Keep the full options analysis in this section.** All IV discussion, strategy evaluation, strike/expiry details, and risk/reward math belongs here — not distributed across the Recommendation or bonus sections. The Recommendation can reference the options conclusion, but the analytical substance stays here so the reader finds everything in one place.

### Technical vs Fundamental Assessment
When price action contradicts fundamentals, flag it explicitly. Use this causation hierarchy to avoid forcing narratives:
1. **Direct causation**: Earnings miss → stock drops (clear link)
2. **Strong correlation with mechanism**: Commodity falls → producer falls (obvious economic channel)
3. **Weak correlation**: Market up → stock down (suggests company-specific factors dominating)
4. **Spurious**: Macro event → unrelated stock moves days later while its sector goes opposite (don't fabricate a connection)

### Recommendation Synthesis
Pull everything together:
- **Action**: BUY / SELL / HOLD / specific options strategy
- **Conviction**: High (strong evidence + clear catalyst + adequate margin of safety) / Medium (reasonable thesis with some uncertainty) / Low (mixed signals, limited data)
- **Time horizon**: Tied to the nearest catalyst or valuation realization window
- **Position sizing guidance**: Higher conviction = larger position. Lower quality = smaller position regardless of conviction.
- **Invalidation**: What specific event or price level proves this thesis wrong? This is not optional — every recommendation needs a kill switch. "If gold drops below $X" or "If next quarter revenue misses by >10%" — concrete, measurable conditions.

If the numbers don't clearly support a direction, say HOLD and explain what would tip the balance. An honest HOLD is more valuable than a forced BUY.

## Output

Use the template in [template.md](template.md). Write analysis sections first, then circle back to write the Recommendation and Executive Summary at the top so they reflect the actual analysis.

**Tailor to the user's question.** After completing all template sections, consider whether the user's specific question warrants a bonus section. If they asked about selling puts, add a "Put-Selling Checklist" or "Risk Summary for Put Sellers." If they're comparing miners, add a "Miner Comparison Matrix." The template is the floor, not the ceiling — the most useful reports go beyond it when the user's context demands it.

## Quality Standards

**Recommendation rigor** — analysis without these gates is just opinion dressed as research:
- No BUY without a margin of safety calculation — you need to know how much room for error exists
- No options play without checking IV rank — buying expensive options is the most common retail trap
- Every recommendation needs an invalidation thesis — knowing when you're wrong is as important as the thesis
- Price targets need methodology, not just round numbers — show the work
- Conviction should honestly reflect evidence quality — high conviction on thin data is a red flag

**Intellectual honesty** — the most useful analysis acknowledges what it doesn't know:
- Distinguish correlation from causation using the hierarchy above
- Label evidence as strong vs speculative — don't present guesswork with the same confidence as hard data
- When sources conflict, show the range and explain the discrepancy rather than cherry-picking
- Probability estimates beat false certainty

**Handling conflicting data:**
- When sources give different numbers, note the range explicitly
- Explain the discrepancy if possible (TTM vs forward, different share counts, data staleness)
- Don't pretend precision where it doesn't exist

## Edge Cases

- **Ticker not found / OTC / pre-IPO**: Note limited data availability, skip sections requiring public financials, focus on what IS available
- **International stocks**: Note exchange, currency considerations. Some US-centric metrics may not apply.
- **ETFs/Funds**: Skip company-specific sections (fundamentals, insider trading). Focus on holdings, expense ratio, sector exposure, flow data.
- **Recent IPO (<1 year)**: Limited history — weight prospectus and early earnings heavily. Reduce confidence in valuation estimates.
- **Stale data**: If price-sensitive data is more than a few days old, flag it in the report. Markets move fast.
- **Dual-class / complex structures**: Note share class and governance implications for the investment thesis.
