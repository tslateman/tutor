# Debugging Cheat Sheet

## The Scientific Method for Bugs

1. **Observe** — What actually happened vs. what you expected?
2. **Hypothesize** — What could cause this difference?
3. **Predict** — If my hypothesis is correct, what else should be true?
4. **Test** — Run an experiment to confirm or refute
5. **Iterate** — Refine hypothesis based on results

The goal: systematically eliminate possibilities until only the truth remains.

## First Principles

### Reproduce First

Don't guess. Get a reliable reproduction case before changing anything.

```text
✗ "It sometimes fails"
✓ "It fails when input > 1000 AND user is not admin"
```

### Change One Thing

Test one hypothesis at a time. Multiple changes obscure which one worked.

### Trust Nothing, Verify Everything

> "It can't be X, I already checked that."

Check again. The bug lives in the gap between what you assume and what's true.

## Binary Search (Bisection)

Cut the problem space in half with each test.

**In code:**

```text
If bug appears somewhere in 1000 lines:
  1. Test at line 500 → bug present
  2. Test at line 250 → bug absent
  3. Test at line 375 → bug present
  4. ...narrows to exact line in ~10 tests
```

**In time (git bisect):**

```bash
git bisect start
git bisect bad                 # Current commit has bug
git bisect good abc123         # This old commit was fine
# Git checks out middle commit
# Test and mark good/bad
git bisect good  # or bad
# Repeat until found
git bisect reset
```

**In data:**

```text
1000 records fail:
  First 500 → fail
  First 250 → pass
  Records 251-500 → fail
  ...find the problematic record
```

## Isolation Techniques

### Minimal Reproduction

Strip away everything that isn't essential to the bug.

```text
Original: 500-line function with bug
  ↓ Remove unrelated code paths
  ↓ Replace complex inputs with simple ones
  ↓ Remove dependencies where possible
Result: 10 lines that reproduce the issue
```

The smaller the reproduction, the easier the fix.

### Rubber Duck Debugging

Explain the code line-by-line to someone (or something) that can't help.

The act of explanation forces you to articulate assumptions. Bugs hide in the
gaps between what you think the code does and what it actually does.

### Change the Environment

| What to Change    | What It Reveals             |
| ----------------- | --------------------------- |
| Different machine | Environment-specific issues |
| Different user    | Permission/config issues    |
| Different data    | Data-dependent bugs         |
| Different time    | Race conditions, timeouts   |
| Fresh install     | Corrupted state             |

## Common Bug Categories

### State Bugs

Something is in an unexpected state.

**Symptoms:** Works sometimes, fails other times. Order matters.

**Debug:** Log state at each step. Find where actual diverges from expected.

### Timing Bugs

Race conditions, deadlocks, timeouts.

**Symptoms:** Works in debugger, fails in production. Intermittent failures.

**Debug:** Add delays, change timing, run under load. Make the race more likely
to lose.

### Boundary Bugs

Off-by-one, edge cases, null handling.

**Symptoms:** Fails on empty, first, last, or extreme values.

**Debug:** Test boundaries explicitly: 0, 1, n-1, n, n+1, empty, null, max.

### Integration Bugs

Components work alone but fail together.

**Symptoms:** Unit tests pass, integration tests fail.

**Debug:** Verify contracts at boundaries. Log inputs/outputs at interfaces.

## Reading Error Messages

```text
TypeError: Cannot read property 'name' of undefined
           ^^^^^^^^^^^^^^^^^^^^^^^^^    ^^^^^^^^^
           What failed                  Why it failed
```

Work backward from the error:

1. What variable is undefined?
2. Where should it have been set?
3. Why wasn't it?

### Stack Traces

Read bottom-to-top for the call chain, but focus on your code—not library code.

```text
Error: Connection refused
  at Socket.connect (net.js:940)      ← Library
  at net.js:787                        ← Library
  at Database.connect (db.js:45)      ← Yours ← Start here
  at Server.start (server.js:23)      ← Yours
  at main (index.js:10)               ← Yours
```

## Print Debugging Done Right

```python
# Bad: No context
print(x)

# Good: Context + value
print(f"DEBUG: x={x} after processing user {user_id}")

# Better: Structured logging
logger.debug("Processing complete", extra={
    "user_id": user_id,
    "result": x,
    "duration_ms": elapsed
})
```

### Strategic Print Points

| Location         | What to Log                    |
| ---------------- | ------------------------------ |
| Function entry   | Input parameters               |
| Function exit    | Return value                   |
| Before condition | Variables being tested         |
| Inside loops     | Iteration count, current value |
| Catch blocks     | Exception details              |

## Debugger Techniques

### Breakpoint Strategies

| Type            | When to Use                       |
| --------------- | --------------------------------- |
| Line breakpoint | Stop at specific location         |
| Conditional     | Stop only when expression is true |
| Exception       | Stop when error is thrown         |
| Data/watchpoint | Stop when variable changes        |

### Questions to Answer in Debugger

1. What's the current call stack?
2. What are the local variables?
3. What's the value of `this`/`self`?
4. What did this function receive?
5. What will this function return?

## After Fixing

1. **Write a test** — Ensure this specific bug can't recur
2. **Look for siblings** — Same mistake elsewhere in codebase?
3. **Consider the root cause** — Why did this bug happen? Confusing API? Missing
   validation? Copy-paste error?
4. **Update documentation** — If the fix wasn't obvious, explain it

## Anti-Patterns

| Anti-Pattern            | Why It Fails                               |
| ----------------------- | ------------------------------------------ |
| Shotgun debugging       | Random changes don't build understanding   |
| Debugging in production | High stakes, limited tools                 |
| Ignoring warnings       | Warnings often predict errors              |
| Assuming causation      | "It worked after I changed X" ≠ X fixed it |
| Debugging while tired   | Bugs exploit cognitive blind spots         |

## See Also

- [Thinking](thinking.md) — Mental models for problem-solving
- [Complexity](complexity.md) — Why bugs hide in complex code
- [Git](../how/git.md) — Using git bisect
