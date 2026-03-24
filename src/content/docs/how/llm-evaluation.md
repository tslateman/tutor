---
title: "LLM Evaluation Cheat Sheet"
description:
  Eval types, metrics, LLM-as-judge patterns, regression testing, CI
  integration, and tooling for testing non-deterministic AI systems.
---

Testing LLM applications differs from traditional software testing. Outputs are
non-deterministic, quality is subjective, and no single "correct" answer exists
for most tasks. Evaluation bridges this gap with grading strategies designed for
probabilistic systems.

## Quick Reference

| I need to...                         | Approach                     | Tool / Method                                     |
| ------------------------------------ | ---------------------------- | ------------------------------------------------- |
| Check exact output format            | Deterministic assertion      | String match, regex, JSON schema                  |
| Grade subjective quality             | LLM-as-judge                 | Rubric prompt with stronger model                 |
| Measure factual accuracy             | Golden set + scoring         | Exact match, F1, ROUGE-L                          |
| Detect regressions from prompt edits | Regression eval suite        | promptfoo / Braintrust experiment diff            |
| Compare two models or prompts        | Side-by-side eval            | promptfoo matrix view, Braintrust experiments     |
| Measure consistency                  | Cosine similarity            | Sentence embeddings across paraphrased inputs     |
| Test safety and toxicity             | Red-teaming + classification | promptfoo red-team, LLM binary classifier         |
| Monitor production quality           | Online eval                  | Braintrust online scoring, sampled human review   |
| Run evals in CI                      | GitHub Actions integration   | promptfoo `--fail-on-error`, threshold scripts    |
| Control eval costs                   | Sampling + caching           | Subset runs, prompt caching, smaller judge models |

## Why LLM Evaluation Differs

Traditional tests assert deterministic outcomes: `f(x) == y`. LLM evaluation
handles three problems traditional testing avoids:

| Problem            | Traditional test          | LLM eval                                        |
| ------------------ | ------------------------- | ----------------------------------------------- |
| Non-determinism    | Same input, same output   | Same input, different outputs each run          |
| Subjective quality | Binary pass/fail          | Graded on rubrics, similarity, human judgement  |
| No ground truth    | Known correct answer      | Multiple valid answers; "best" is contextual    |
| Prompt sensitivity | Code is the specification | Small wording changes cause large output swings |

This means evaluation must combine deterministic checks (where possible),
statistical scoring (for quality), and human review (for edge cases).

## Eval Types

### Deterministic Assertions

Use when output format is constrained and verifiable by code. Fastest and most
reliable.

```python
# Exact match
def eval_exact(output: str, expected: str) -> bool:
    return output.strip().lower() == expected.lower()

# Contains required content
def eval_contains(output: str, required: list[str]) -> bool:
    return all(phrase in output for phrase in required)

# JSON structure validation
import json
def eval_json_schema(output: str) -> bool:
    try:
        data = json.loads(output)
        return "answer" in data and "confidence" in data
    except json.JSONDecodeError:
        return False
```

Promptfoo YAML equivalents:

```yaml
assert:
  - type: equals
    value: "expected output"
  - type: contains-all
    value: ["required phrase", "another phrase"]
  - type: is-json
  - type: regex
    value: '^\d{4}-\d{2}-\d{2}$'
  - type: cost
    threshold: 0.01
  - type: latency
    threshold: 500
```

### Scoring Evals (LLM-as-Judge)

Use when quality is subjective or multi-dimensional. A stronger model grades the
output of the model under test.

```python
import anthropic

client = anthropic.Anthropic()

def llm_judge(output: str, rubric: str) -> dict:
    """Grade output against a rubric using a stronger model."""
    response = client.messages.create(
        model="claude-sonnet-4-20250514",
        max_tokens=1024,
        messages=[{
            "role": "user",
            "content": f"""Grade this output against the rubric.

<rubric>{rubric}</rubric>
<output>{output}</output>

Think step by step in <thinking> tags.
Then output a JSON object with "score" (1-5) and "reason" (one sentence).
"""
        }]
    )
    return parse_json(response.content[0].text)
```

Promptfoo YAML:

```yaml
assert:
  - type: llm-rubric
    value: "Response mentions the return policy and provides a timeframe"
    provider: openai:gpt-4o
  - type: similar
    value: "reference answer text"
    threshold: 0.8
```

**Rubric design principles:**

- Be specific: "mentions Acme Inc. in the first sentence" beats "good response"
- Use scales: Likert 1-5, binary correct/incorrect, or ordinal categories
- Require reasoning before scoring to improve judge accuracy
- Use a different (ideally stronger) model than the one being evaluated

### Human Evals

Use for final validation, calibrating automated judges, and edge cases where
automated grading fails. Expensive and slow -- reserve for high-stakes
decisions.

| Human eval method     | When to use                              | Scale  |
| --------------------- | ---------------------------------------- | ------ |
| Side-by-side ranking  | Comparing two prompt variants            | Low    |
| Likert rating         | Measuring tone, helpfulness, coherence   | Medium |
| Correctness labeling  | Building golden datasets                 | Low    |
| Error categorization  | Understanding failure modes              | Low    |
| Spot-check production | Validating automated scoring calibration | Medium |

**Calibration loop:** Run human evals on a sample, then train LLM-as-judge
rubrics to match human scores. Periodically re-calibrate.

## Eval Datasets

### Golden Sets

Curated input-output pairs with verified correct answers. The foundation of
regression testing.

```python
# golden_set.jsonl — one case per line
# {"input": "What is the capital of France?", "expected": "Paris"}
# {"input": "Summarize photosynthesis in one sentence.", "expected": "..."}

import json

def load_golden_set(path: str) -> list[dict]:
    with open(path) as f:
        return [json.loads(line) for line in f]
```

**Building golden sets:**

1. Start with 20-50 hand-crafted cases covering core behaviors and edge cases
2. Add cases from production failures (every bug becomes a test case)
3. Include adversarial inputs: jailbreaks, prompt injections, ambiguous queries
4. Label expected output, acceptable variations, and unacceptable outputs

### Synthetic Generation

Use an LLM to expand a small seed set into a larger eval dataset.

```python
def generate_test_cases(seed_examples: list[dict], n: int = 100) -> list[dict]:
    """Generate synthetic eval cases from seed examples."""
    response = client.messages.create(
        model="claude-sonnet-4-20250514",
        max_tokens=4096,
        messages=[{
            "role": "user",
            "content": f"""Generate {n} test cases similar to these examples.
Include edge cases, adversarial inputs, and boundary conditions.
Output as JSON array with "input" and "expected" fields.

Examples:
{json.dumps(seed_examples, indent=2)}"""
        }]
    )
    return json.loads(response.content[0].text)
```

**Caution:** Verify synthetic cases. LLM-generated test data can encode the
model's own biases, creating a self-reinforcing loop.

### Production Sampling

Sample real user interactions to build eval sets that reflect actual usage
patterns, not imagined ones.

```python
# Sample strategy: log interactions, then filter
def sample_production_data(logs: list, n: int = 200) -> list:
    """Stratified sample: common cases + edge cases + failures."""
    failures = [l for l in logs if l["user_rating"] < 3]
    normal = [l for l in logs if l["user_rating"] >= 3]

    # Over-sample failures to catch regressions
    sample = (
        random.sample(failures, min(n // 4, len(failures)))
        + random.sample(normal, min(3 * n // 4, len(normal)))
    )
    return sample
```

## Metrics

### Quality Metrics

| Metric            | What it measures                                       | Method                            |
| ----------------- | ------------------------------------------------------ | --------------------------------- |
| Accuracy          | Correct answers / total answers                        | Exact match against golden set    |
| F1 Score          | Precision-recall balance for classification            | Compare predicted vs. true labels |
| ROUGE-L           | Summary quality (longest common subsequence)           | Compare against reference summary |
| Cosine similarity | Semantic consistency across paraphrased inputs         | Sentence embeddings comparison    |
| Faithfulness      | Output grounded in provided context (no hallucination) | LLM-as-judge with source docs     |
| Relevance         | Output addresses the question asked                    | LLM-as-judge with rubric          |
| Toxicity          | Harmful or inappropriate content                       | Classifier or LLM binary judge    |

### Operational Metrics

| Metric        | What it measures         | Target example |
| ------------- | ------------------------ | -------------- |
| Latency (p50) | Median response time     | < 500ms        |
| Latency (p99) | Tail response time       | < 2000ms       |
| Cost per call | API spend per invocation | < $0.01        |
| Token usage   | Input + output tokens    | < 4096 total   |
| Error rate    | Failed API calls         | < 0.1%         |

Track both. A model that scores well on quality but costs 10x more or adds 5
seconds of latency may lose to a "worse" model in production.

## LLM-as-Judge Patterns

### Stronger Model Judges Weaker Model

The most common pattern. Use a frontier model to evaluate a smaller, cheaper
model's output.

```python
def judge_with_rubric(question: str, output: str, rubric: str) -> int:
    """Returns score 1-5."""
    response = client.messages.create(
        model="claude-sonnet-4-20250514",  # Judge: stronger model
        max_tokens=512,
        messages=[{
            "role": "user",
            "content": f"""You are an evaluation judge. Score this output 1-5.

<question>{question}</question>
<output>{output}</output>
<rubric>{rubric}</rubric>

Think step by step, then output only the integer score on the last line."""
        }]
    )
    # Parse the last line as the score
    return int(response.content[0].text.strip().split('\n')[-1])
```

### Self-Consistency Check

Run the same prompt multiple times. If the model gives conflicting answers, the
output is unreliable.

```python
def self_consistency(prompt: str, n: int = 5, threshold: float = 0.7) -> dict:
    """Run n times, check agreement."""
    responses = [get_completion(prompt) for _ in range(n)]
    # For classification: majority vote
    from collections import Counter
    votes = Counter(r.strip().lower() for r in responses)
    most_common, count = votes.most_common(1)[0]
    return {
        "answer": most_common,
        "agreement": count / n,
        "reliable": count / n >= threshold,
    }
```

### Pairwise Comparison

Ask the judge to choose the better output from two candidates. More reliable
than absolute scoring for comparing variants.

```python
def pairwise_judge(question: str, output_a: str, output_b: str) -> str:
    """Returns 'A', 'B', or 'tie'."""
    response = client.messages.create(
        model="claude-sonnet-4-20250514",
        max_tokens=512,
        messages=[{
            "role": "user",
            "content": f"""Which response better answers the question?

<question>{question}</question>
<response_a>{output_a}</response_a>
<response_b>{output_b}</response_b>

Think step by step, then output exactly one of: A, B, tie"""
        }]
    )
    result = response.content[0].text.strip().split('\n')[-1].upper()
    if "A" in result: return "A"
    if "B" in result: return "B"
    return "tie"
```

**Position bias:** LLM judges favor the first response shown. Mitigate by
running each comparison twice with swapped order.

## Regression Testing for Prompts

Prompt changes break existing behavior more often than they improve it. Treat
prompt edits like code changes: test before deploying.

### Workflow

```text
1. Baseline    — Run eval suite on current prompt, save scores
2. Edit        — Change the prompt
3. Re-evaluate — Run same eval suite on new prompt
4. Compare     — Diff scores against baseline
5. Ship/revert — Accept if no regressions, or fix and re-test
```

### Promptfoo Configuration for Regression Testing

```yaml
# promptfooconfig.yaml
description: "Summarization prompt regression test"

prompts:
  - file://prompts/summarize_v1.txt
  - file://prompts/summarize_v2.txt

providers:
  - anthropic:messages:claude-sonnet-4-20250514

defaultTest:
  assert:
    - type: llm-rubric
      value: "Summary captures the main point in 1-2 sentences"
    - type: latency
      threshold: 3000

tests:
  - vars:
      article: "In a groundbreaking study, researchers at MIT..."
    assert:
      - type: contains
        value: "MIT"
      - type: similar
        value: "MIT researchers discovered a new antibiotic compound"
        threshold: 0.7
  - vars:
      article: "The quarterly earnings report showed..."
    assert:
      - type: not-contains
        value: "I don't know"
```

```bash
# Run eval and view matrix comparison
npx promptfoo eval
npx promptfoo view
```

### Braintrust Experiment Comparison

```python
from braintrust import Eval
from autoevals import Factuality, ClosedQA

Eval(
    "Summarizer",
    data=lambda: load_golden_set("golden_set.jsonl"),
    task=lambda input: summarize(input, prompt_version="v2"),
    scores=[Factuality, ClosedQA],
)
# Braintrust UI shows diff against previous experiment run
```

## A/B Testing and Canary Evaluation

### A/B Testing

Split production traffic between prompt variants and measure user-facing
metrics.

```python
import random

def route_prompt(user_id: str, variants: dict, split: float = 0.5) -> str:
    """Deterministic routing based on user ID."""
    bucket = hash(user_id) % 100
    variant = "B" if bucket < split * 100 else "A"
    return variants[variant]
```

**Measure:** Task completion rate, user satisfaction, error escalations -- not
just automated scores.

### Canary Evaluation

Deploy the new prompt to a small slice of traffic (1-5%). Monitor automated
scores and error rates before full rollout.

```text
1. Deploy new prompt to 2% of traffic
2. Run automated evals on canary outputs for 24-48 hours
3. Compare canary scores against baseline (control group)
4. If canary scores match or exceed baseline → increase to 100%
5. If canary shows regressions → roll back immediately
```

## CI Integration

### GitHub Actions with Promptfoo

```yaml
# .github/workflows/llm-eval.yml
name: LLM Eval
on:
  pull_request:
    paths:
      - "prompts/**"
      - "promptfooconfig.yaml"

jobs:
  eval:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-node@v4
        with:
          node-version: 20

      - name: Cache promptfoo
        uses: actions/cache@v4
        with:
          path: ~/.cache/promptfoo
          key: promptfoo-${{ hashFiles('promptfooconfig.yaml') }}

      - name: Run evals
        env:
          ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
          PROMPTFOO_CACHE_PATH: ~/.cache/promptfoo
        run: |
          npx promptfoo eval --output results.json

      - name: Check pass rate
        run: |
          PASS_RATE=$(jq '.results.stats.successes / .results.stats.total' results.json)
          echo "Pass rate: $PASS_RATE"
          if (( $(echo "$PASS_RATE < 0.95" | bc -l) )); then
            echo "::error::Eval pass rate $PASS_RATE below 95% threshold"
            exit 1
          fi

      - name: Upload results
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: eval-results
          path: results.json
```

### Setting Thresholds

| Strategy          | When to use                | Example                          |
| ----------------- | -------------------------- | -------------------------------- |
| Zero failures     | Safety-critical assertions | `--fail-on-error`                |
| Pass rate         | Probabilistic quality      | Fail if < 95% of cases pass      |
| Score regression  | Comparing against baseline | Fail if avg score drops > 5%     |
| Per-metric floors | Multi-dimensional quality  | Accuracy > 90% AND toxicity < 1% |

## Cost Management

LLM evals call APIs for every test case and (for LLM-as-judge) again for every
grading step. Costs compound fast.

| Strategy                   | Savings  | Tradeoff                               |
| -------------------------- | -------- | -------------------------------------- |
| Cache responses            | 50-90%   | Stale on model updates                 |
| Sample eval set (20-30%)   | 70-80%   | Lower statistical confidence           |
| Smaller judge model        | 60-80%   | Less nuanced grading                   |
| Deterministic checks first | Variable | Only works for structured output       |
| Batch API                  | 50%      | Higher latency (hours, not seconds)    |
| Run full suite nightly     | N/A      | CI gets fast subset; nightly gets full |

### Tiered Eval Strategy

```text
PR-level (every push):
  → 50 critical cases, deterministic assertions only
  → Cost: ~$0.50 per run

Merge-level (on merge to main):
  → 200 cases, deterministic + LLM-as-judge
  → Cost: ~$5 per run

Nightly (scheduled):
  → Full golden set (1000+ cases), all metrics
  → Cost: ~$25 per run
```

## Eval-Driven Development

Write evals first, then iterate on prompts. Analogous to TDD for
non-deterministic systems.

```text
1. Red    — Write eval cases that define desired behavior
2. Red    — Run against initial prompt (expect many failures)
3. Green  — Iterate on prompt until eval suite passes
4. Refine — Add edge cases to eval set, tighten thresholds
5. Ship   — Baseline scores become the regression floor
```

**The key insight:** Prompts without evals drift silently. The eval suite is the
specification. Without it, you are guessing.

## Tools

| Tool                | Strengths                                             | Best for                              |
| ------------------- | ----------------------------------------------------- | ------------------------------------- |
| **promptfoo**       | Open-source, YAML config, matrix comparison, red-team | Prompt comparison, CI integration     |
| **Braintrust**      | Experiment tracking, online scoring, dataset mgmt     | Production monitoring, team workflows |
| **Anthropic Evals** | Native Claude integration, grading examples           | Claude-specific applications          |
| **Custom harness**  | Full control, no vendor lock-in                       | Unique eval logic, internal tooling   |
| **autoevals** (lib) | Pre-built scorers (Factuality, ClosedQA, Relevance)   | Quick scoring without writing rubrics |

### Promptfoo Quickstart

```bash
# Install and initialize
npx promptfoo init

# Edit promptfooconfig.yaml, then run
npx promptfoo eval

# View results in browser
npx promptfoo view

# Compare two prompts side by side
npx promptfoo eval --output results.json
```

### Braintrust Quickstart

```bash
# Install
pip install braintrust autoevals
```

```python
from braintrust import Eval
from autoevals import Factuality

Eval(
    "My App",
    data=lambda: [
        {"input": "What is 2+2?", "expected": "4"},
        {"input": "Capital of France?", "expected": "Paris"},
    ],
    task=lambda input: get_completion(input),
    scores=[Factuality],
)
```

### Custom Eval Harness

```python
import json
from dataclasses import dataclass

@dataclass
class EvalResult:
    case_id: str
    passed: bool
    score: float
    reason: str

def run_eval_suite(
    cases: list[dict],
    task_fn,
    graders: list,
    threshold: float = 0.9,
) -> dict:
    """Run eval suite and return summary."""
    results = []
    for case in cases:
        output = task_fn(case["input"])
        scores = [g(output, case.get("expected", "")) for g in graders]
        avg_score = sum(s for s in scores) / len(scores)
        results.append(EvalResult(
            case_id=case.get("id", ""),
            passed=avg_score >= threshold,
            score=avg_score,
            reason=f"Avg score {avg_score:.2f}",
        ))

    passed = sum(1 for r in results if r.passed)
    return {
        "total": len(results),
        "passed": passed,
        "pass_rate": passed / len(results),
        "results": results,
    }
```

## Anti-Patterns

| Anti-Pattern                  | Problem                                                                 | Fix                                                             |
| ----------------------------- | ----------------------------------------------------------------------- | --------------------------------------------------------------- |
| Vibes-based evaluation        | "It looks good" catches nothing at scale                                | Define rubrics, measure scores, track over time                 |
| Testing on training data      | Model memorizes answers; eval scores inflate artificially               | Use held-out test sets; rotate eval data                        |
| Single-metric optimization    | Optimizing accuracy alone tanks safety, tone, or latency                | Track multiple metrics; set floors for each                     |
| Eval gaming                   | Tuning prompts to pass specific test cases rather than general behavior | Use large, diverse eval sets; add new cases regularly           |
| No baseline                   | Cannot tell if changes improved or regressed quality                    | Save baseline scores; diff every prompt change                  |
| Judge model = tested model    | Model grades itself favorably; biases go undetected                     | Use a different (stronger) model as judge                       |
| Static eval set               | Production inputs drift; eval set becomes unrepresentative              | Refresh eval data from production samples quarterly             |
| Asserting on exact LLM output | Non-deterministic outputs make exact-match flaky                        | Use semantic similarity, contains checks, or LLM-as-judge       |
| Skipping operational metrics  | Model quality is high but latency or cost makes it unusable             | Always measure latency, cost, and token usage alongside quality |

## See Also

- [Testing](testing.md) — Test runner commands and patterns for deterministic
  software
- [Testing Principles](../why/testing.md) — Strategy, pyramid, TDD — the
  foundations eval-driven development builds on
- [Performance Profiling](performance.md) — Benchmarking and latency
  measurement, analogous to operational eval metrics
- [Prompt Engineering](prompt-engineering.md) — The prompts these evals validate
