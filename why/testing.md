# Testing

Why, when, and how much to test. Strategy over ceremony.

## The Purpose of Tests

Tests are not proof of correctness. They are:

- **Change detectors** — Catch regressions before users do
- **Design feedback** — Hard-to-test code is usually hard-to-use code
- **Living documentation** — Show how to call the code
- **Confidence generators** — Deploy without dread

If a test doesn't serve at least one of these, question whether it earns its
maintenance cost.

## The Testing Pyramid

```text
         /  E2E  \          Slow, brittle, expensive
        /----------\
       / Integration \      Moderate speed, real boundaries
      /----------------\
     /    Unit Tests     \  Fast, isolated, cheap
    /______________________\
```

| Level           | Scope                      | Speed  | Fragility | Cost to maintain |
| --------------- | -------------------------- | ------ | --------- | ---------------- |
| **Unit**        | Single function or class   | Fast   | Low       | Low              |
| **Integration** | Multiple components wired  | Medium | Medium    | Medium           |
| **E2E**         | Full system, user journeys | Slow   | High      | High             |

**The principle:** Most tests should be unit tests. Fewer integration tests.
Fewest E2E tests. Invert this pyramid and your suite becomes slow, flaky, and
expensive.

## What to Test

### High Value

| Target                    | Why                                         |
| ------------------------- | ------------------------------------------- |
| Business logic            | Core value; most likely to have subtle bugs |
| Edge cases and boundaries | Off-by-one, empty, null, overflow           |
| Bug fixes                 | Prove the fix works; prevent recurrence     |
| Public API contracts      | Callers depend on this behavior             |
| State transitions         | Where systems move between modes            |

### Low Value

| Target                 | Why                                               |
| ---------------------- | ------------------------------------------------- |
| Trivial getters        | No logic to verify                                |
| Framework boilerplate  | Test the framework, not your glue code            |
| Implementation details | Tests break on refactor, catch nothing meaningful |
| Log messages           | Asserting on strings is brittle and low-signal    |

**Heuristic:** Test behavior, not implementation. Ask "what should happen?" not
"how does it happen internally?"

## Test Design Principles

### Follow Your Language's Testing Idioms

Each ecosystem has conventions that make tests readable to others:

- **pytest**: fixtures for setup, plain assertions, parametrize for cases
- **Go**: table-driven tests, `t.Run` for subtests
- **Rust**: `#[cfg(test)]` module in same file, `assert_eq!` macros
- **RSpec**: `let` for lazy setup, `describe`/`context`/`it` nesting
- **Jest**: `beforeEach` for shared setup, `test.each` for cases

Learn what's conventional, not what's universal.

### Tests as Specifications

A good test name describes a requirement:

```text
Bad:  test_discount
      test_order_1
      test_edge_case

Good: test_gold_customers_receive_15_percent_discount
      test_expired_coupons_are_rejected
      test_empty_cart_returns_zero_total
```

Difficulty naming a test signals unclear requirements.

### Isolation

Each test must:

- Run independently of other tests
- Pass in any order
- Not depend on shared mutable state
- Clean up after itself (or use fresh fixtures)

**Why:** Coupled tests produce cascading failures that obscure the real problem.

### Determinism

A test that sometimes passes is worse than no test. It erodes trust in the
entire suite.

**Common sources of flakiness:**

| Source               | Fix                                    |
| -------------------- | -------------------------------------- |
| Time-dependent logic | Inject a clock; freeze time in tests   |
| Random data          | Seed the generator or use fixed inputs |
| Network calls        | Mock external services                 |
| Shared state         | Isolate; fresh setup per test          |
| Race conditions      | Avoid real concurrency in unit tests   |

## Test Doubles

| Type     | What It Does                          | When to Use                          |
| -------- | ------------------------------------- | ------------------------------------ |
| **Stub** | Returns canned answers                | Replace a dependency's output        |
| **Mock** | Records calls; verifies interactions  | When the interaction is the contract |
| **Fake** | Working but simplified implementation | In-memory DB, local filesystem       |
| **Spy**  | Wraps real object, records calls      | Verify calls without replacing logic |

**Mocking heuristic:** Mock at boundaries (network, database, filesystem). Don't
mock the thing you're testing. Don't mock value objects.

**Over-mocking smell:** If a test has more mock setup than assertions, the
design may need work — not more mocks.

## Coverage

Coverage measures lines executed, not correctness verified.

```text
100% coverage + zero assertions = zero value
 60% coverage on critical paths  = high value
```

**Use coverage to find untested code, not to prove tested code works.**

Coverage is a useful heuristic for gaps, not a quality metric. Chasing a number
leads to low-value tests that inflate the score without catching bugs.

## TDD: Test-Driven Development

```text
1. Red    — Write a failing test for the next behavior
2. Green  — Write minimal code to pass
3. Refactor — Clean up while tests protect you
```

**When TDD helps:**

- Well-understood requirements
- Algorithmic or logic-heavy code
- Bug fixes (write the test that catches the bug first)

**When TDD is awkward:**

- Exploratory prototyping (requirements unclear)
- UI layout and visual design
- Heavily integrated code where setup cost dominates

TDD is a design tool, not a religion. Use it where it produces better design.
Skip it where it produces ceremony.

## Testing Strategy

### The Questions That Matter

1. **What could go wrong?** — Test the risky paths, not the obvious ones
2. **What would be expensive to fix in production?** — Test that heavily
3. **What changes often?** — Protect it with regression tests
4. **What's the contract?** — Test the boundary, not the implementation

### Property-Based Testing

Instead of testing specific examples, define properties that must always hold:

```text
Example-based: sort([3,1,2]) == [1,2,3]
Property-based: for any list L, sort(L) has same length as L
                for any list L, sort(L) is ordered
                for any list L, sort(L) contains same elements as L
```

Properties find edge cases humans don't think of. Use for:

- Pure functions with clear invariants
- Serialization round-trips (encode then decode = identity)
- Parsers (parse then format = identity)

### When to Stop Testing

You have enough tests when:

- You can refactor internals without breaking tests
- Bugs that escape are in areas you deliberately chose not to test
- The suite runs fast enough to stay in your workflow
- You deploy with confidence, not hope

## Anti-Patterns

| Anti-Pattern            | Problem                                             |
| ----------------------- | --------------------------------------------------- |
| Testing implementation  | Tests break on every refactor                       |
| Assertion-free tests    | Executes code but verifies nothing                  |
| Test interdependence    | One failure cascades into dozens                    |
| Slow suites             | Developers stop running them                        |
| Copy-paste tests        | Maintenance nightmare; extract shared setup instead |
| Testing private methods | Sign that the public interface is wrong             |
| Ice cream cone          | Many E2E, few unit tests — slow and fragile         |

## See Also

- [Debugging](debugging.md) — When tests catch a failure, systematic debugging
  finds the cause
- [Complexity](complexity.md) — Hard-to-test code is a complexity symptom
- [Thinking](thinking.md) — Testing is hypothesis verification applied to code
