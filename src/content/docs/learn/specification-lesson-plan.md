---
title: "Specification Lesson Plan"
description:
  Eight lessons on defining what software must do — from decision tables to
  Design by Contract to TLA+ model checking to agent constraints.
---

Learn to specify before you implement. Each lesson builds a different
specification skill, progressing from pen-and-paper methods to formal tools.

<!-- prettier-ignore -->
:::note[Prerequisites]
Experience writing or reviewing software requirements.
Familiarity with [Testing](../why/testing.md) concepts.
:::

## Lesson 1: The Cost of Vagueness

**Goal:** Experience specification failure firsthand.

### Concepts

Ambiguous specifications produce divergent implementations. The cost of
discovering ambiguity during coding exceeds the cost of discovering it during
specification. The specification test: give the same spec to three people. If
they build different things, the spec is insufficient.

### Exercises

1. **Implement from a vague spec**

   Read this requirement: "Build a function that applies discounts to orders."
   Implement it in any language. Do not ask clarifying questions — just build
   what seems right.

   ```python
   def apply_discount(order):
       # Your implementation here
       pass
   ```

   Now compare your assumptions: Does "discount" mean percentage or flat amount?
   Does it apply to the subtotal or the total with tax? Can discounts stack? Is
   there a maximum discount? What happens with a $0 order?

2. **Rewrite as a precise specification**

   ```text
   apply_discount(order, discount) -> order

   Preconditions:
   - order.subtotal >= 0
   - 0 < discount.percent <= 50
   - discount is not expired (discount.expires_at > now)

   Postconditions:
   - result.subtotal == order.subtotal * (1 - discount.percent / 100)
   - result.items == order.items (unchanged)
   - result.discount_applied == discount.id

   Invariants:
   - result.subtotal >= 0 (discount cannot produce negative totals)
   - only one discount per order
   ```

3. **Find remaining gaps**

   Read your specification again. What about: currency rounding? Already-
   discounted orders? Discounts on individual items vs. the whole order? List
   every question the specification does not answer.

### Checkpoint

Write a specification for a `transfer(from_account, to_account, amount)`
function. Include preconditions, postconditions, and at least three invariants.
Have someone else read it without explanation — every question they ask reveals
a gap.

---

## Lesson 2: Decision Tables

**Goal:** Use the simplest formal method to eliminate ambiguity.

### Concepts

A decision table lists every combination of conditions and their outcomes. For
_n_ boolean conditions, the table has 2^n rows. Missing rows mean missing
specifications. Decision tables work for business rules, configuration logic,
and access control — anywhere conditions combine.

### Exercises

1. **Build a shipping rate table**

   ```text
   Conditions:
   - Domestic vs International
   - Order weight: Light (<2kg), Heavy (≥2kg)
   - Prime member: Yes/No

   | Domestic? | Heavy? | Prime? | Rate     |
   |-----------|--------|--------|----------|
   | Y         | N      | Y      | Free     |
   | Y         | N      | N      | $5       |
   | Y         | Y      | Y      | $3       |
   | Y         | Y      | N      | $10      |
   | N         | N      | Y      | $8       |
   | N         | N      | N      | $15      |
   | N         | Y      | Y      | $12      |
   | N         | Y      | N      | $25      |
   ```

   Eight rows. No ambiguity about what any combination costs. If product asks
   "what does a heavy international prime order cost?" you point to row 7.

2. **Find missing cases in an existing system**

   Pick a feature with conditional logic in code you work on. List all
   conditions. Build the decision table. Count the rows. Compare to the number
   of code branches. Missing branches = missing specifications.

3. **Convert a decision table to code**

   ```python
   def shipping_rate(domestic: bool, heavy: bool, prime: bool) -> int:
       table = {
           (True,  False, True):  0,
           (True,  False, False): 5,
           (True,  True,  True):  3,
           (True,  True,  False): 10,
           (False, False, True):  8,
           (False, False, False): 15,
           (False, True,  True):  12,
           (False, True,  False): 25,
       }
       return table[(domestic, heavy, prime)]
   ```

   The code _is_ the table. No nested if/else. No missed branches.

### Checkpoint

Build a decision table for a feature you've implemented. Verify every row has a
defined outcome. Identify at least one case the current implementation handles
incorrectly or not at all.

---

## Lesson 3: Design by Contract

**Goal:** Write and enforce function contracts with preconditions,
postconditions, and invariants.

### Concepts

Bertrand Meyer's Design by Contract: every function is a contract between
supplier (the function) and client (the caller). The precondition is the
client's obligation. The postcondition is the supplier's guarantee. The
invariant holds before and after every operation. When a contract violation
occurs, the error message tells you _who_ broke the contract and _what_ was
expected.

### Exercises

1. **Add contracts to a stack**

   ```bash
   pip install deal
   ```

   ```python
   import deal

   class Stack:
       def __init__(self, max_size: int = 10):
           self._items: list = []
           self._max_size = max_size

       @deal.pre(lambda self: len(self._items) < self._max_size,
                 message="stack is full")
       def push(self, item):
           self._items.append(item)

       @deal.pre(lambda self: len(self._items) > 0,
                 message="stack is empty")
       @deal.post(lambda _: True)  # postcondition: always succeeds if pre holds
       def pop(self):
           return self._items.pop()

       @deal.pre(lambda self: len(self._items) > 0,
                 message="stack is empty")
       def peek(self):
           return self._items[-1]

       @property
       def size(self) -> int:
           return len(self._items)
   ```

   Test it:

   ```python
   s = Stack(max_size=2)
   s.push("a")
   s.push("b")
   s.push("c")  # raises PreContractError: stack is full
   ```

2. **Add an invariant**

   ```python
   @deal.inv(lambda self: 0 <= len(self._items) <= self._max_size,
             message="size invariant violated")
   class Stack:
       # ... same as above
   ```

   The invariant is checked after every method call. Try to break it.

3. **Contract-driven test generation**

   ```bash
   pip install deal hypothesis
   ```

   ```python
   # test_stack.py
   import deal

   # deal generates Hypothesis tests from contracts automatically
   test_push = deal.cases(Stack.push)
   test_pop = deal.cases(Stack.pop)
   ```

   ```bash
   pytest test_stack.py -v
   ```

   `deal.cases` generates random inputs and verifies contracts hold. No hand-
   written test cases needed.

### Checkpoint

Add contracts to a function you've written at work. Include at least one
precondition, one postcondition, and one class invariant. Run `deal.cases` to
generate tests. Fix any contract violations discovered.

---

## Lesson 4: Property-Based Testing

**Goal:** Specify invariants that hold across all inputs, not just handpicked
examples.

### Concepts

Example-based tests verify specific cases. Property-based tests verify
invariants across thousands of generated inputs. The framework generates inputs
(including edge cases humans miss), checks properties, and when a property
fails, _shrinks_ the failing input to the smallest reproducible case.

### Exercises

1. **Properties of a sort function**

   ```python
   from hypothesis import given
   from hypothesis import strategies as st

   @given(st.lists(st.integers()))
   def test_sort_preserves_length(xs):
       assert len(sorted(xs)) == len(xs)

   @given(st.lists(st.integers()))
   def test_sort_is_ordered(xs):
       result = sorted(xs)
       for i in range(len(result) - 1):
           assert result[i] <= result[i + 1]

   @given(st.lists(st.integers()))
   def test_sort_preserves_elements(xs):
       assert sorted(sorted(xs)) == sorted(xs)  # idempotent
   ```

   ```bash
   pytest -v  # Hypothesis runs 100+ cases per property
   ```

2. **Round-trip properties (encode/decode)**

   ```python
   import json
   from hypothesis import given
   from hypothesis import strategies as st

   @given(st.dictionaries(st.text(), st.integers()))
   def test_json_roundtrip(d):
       assert json.loads(json.dumps(d)) == d

   # This WILL fail — find out why
   @given(st.dictionaries(st.integers(), st.text()))
   def test_json_roundtrip_int_keys(d):
       assert json.loads(json.dumps(d)) == d
   ```

   The second test fails because JSON keys must be strings. Hypothesis finds
   this immediately. The failing input is shrunk to `{0: ""}` — the minimal case
   that triggers the bug.

3. **Properties of your own code**

   Pick a pure function from your codebase. Identify three properties it must
   satisfy. Write Hypothesis tests for each. Run them. Fix any failures.

### Checkpoint

Write property-based tests for a `parse`/`format` pair (e.g., date parsing, URL
parsing, configuration parsing). The round-trip property:
`parse(format(x)) == x` for all valid `x`. Discover at least one edge case
Hypothesis finds that you did not anticipate.

---

## Lesson 5: Schema as Specification

**Goal:** Define API boundaries with machine-readable schemas before writing
code.

### Concepts

An API schema is a specification that both humans and machines read. OpenAPI for
REST, Protocol Buffers for gRPC, JSON Schema for data validation. Writing the
schema first forces you to decide on inputs, outputs, error shapes, and
versioning before writing implementation code. Codegen tools produce clients,
servers, and documentation from the same source.

### Exercises

1. **Write an OpenAPI spec first**

   ```yaml
   # bookstore.yaml
   openapi: "3.1.0"
   info:
     title: Bookstore API
     version: "1.0.0"
   paths:
     /books:
       get:
         summary: List books
         parameters:
           - name: genre
             in: query
             schema:
               type: string
               enum: [fiction, nonfiction, technical]
         responses:
           "200":
             description: List of books
             content:
               application/json:
                 schema:
                   type: array
                   items:
                     $ref: "#/components/schemas/Book"
     /books/{id}:
       get:
         summary: Get a book by ID
         parameters:
           - name: id
             in: path
             required: true
             schema:
               type: string
               format: uuid
         responses:
           "200":
             description: Book details
             content:
               application/json:
                 schema:
                   $ref: "#/components/schemas/Book"
           "404":
             description: Book not found
   components:
     schemas:
       Book:
         type: object
         required: [id, title, author]
         properties:
           id:
             type: string
             format: uuid
           title:
             type: string
             maxLength: 500
           author:
             type: string
           genre:
             type: string
             enum: [fiction, nonfiction, technical]
           price_cents:
             type: integer
             minimum: 0
   ```

2. **Validate the spec**

   ```bash
   npx @redocly/cli lint bookstore.yaml
   ```

3. **Evolve the schema without breaking clients**

   Add a `published_year` field. Verify it's backward-compatible (new field is
   optional, no existing fields removed or renamed). This is the specification
   discipline: the schema constrains what changes are safe.

### Checkpoint

Write an OpenAPI spec for a service you maintain. Validate it with a linter.
Identify one breaking change someone made in the past that the schema would have
caught.

---

## Lesson 6: Type Systems as Specification

**Goal:** Use the compiler as a specification checker via TypeScript's type
system.

### Concepts

A type system is a specification language. `string` specifies "any text."
`"admin" | "user" | "guest"` specifies exactly three values. Discriminated
unions specify all variants a value can take. The compiler verifies the
specification at build time — free, exhaustive, zero runtime cost.

### Exercises

1. **Model a domain with discriminated unions**

   ```typescript
   // Specification: an order is in exactly one of these states
   type Order =
     | { status: "draft"; items: Item[] }
     | { status: "submitted"; items: Item[]; submittedAt: Date }
     | { status: "shipped"; items: Item[]; trackingId: string }
     | { status: "cancelled"; reason: string };

   // The compiler forces you to handle every state
   function describe(order: Order): string {
     switch (order.status) {
       case "draft":
         return `Draft with ${order.items.length} items`;
       case "submitted":
         return `Submitted at ${order.submittedAt}`;
       case "shipped":
         return `Tracking: ${order.trackingId}`;
       case "cancelled":
         return `Cancelled: ${order.reason}`;
     }
   }
   ```

   Remove one case from the switch. The compiler reports the error.

2. **Branded types for domain primitives**

   ```typescript
   // Specification: these are different things, even though both are strings
   type UserId = string & { readonly __brand: "UserId" };
   type OrderId = string & { readonly __brand: "OrderId" };

   function getUser(id: UserId): User {
     /* ... */
   }
   function getOrder(id: OrderId): Order {
     /* ... */
   }

   const userId = "abc" as UserId;
   const orderId = "xyz" as OrderId;

   getUser(orderId); // Compiler error — can't pass OrderId as UserId
   ```

3. **Exhaustiveness checking with `never`**

   ```typescript
   function assertNever(x: never): never {
     throw new Error(`Unexpected value: ${x}`);
   }

   function handleOrder(order: Order): void {
     switch (order.status) {
       case "draft":
         /* ... */ break;
       case "submitted":
         /* ... */ break;
       case "shipped":
         /* ... */ break;
       case "cancelled":
         /* ... */ break;
       default:
         assertNever(order); // Compiler error if a case is missing
     }
   }
   ```

   Add a new status to the `Order` type. Every switch statement that doesn't
   handle it becomes a compile error. The type system propagates specification
   changes through the codebase automatically.

### Checkpoint

Model a state machine from your domain using discriminated unions. Add a new
state. Count the compile errors — each one is a place the specification change
must propagate. Fix them all.

---

## Lesson 7: TLA+ for State Machines

**Goal:** Model a concurrent system and find bugs with a model checker.

### Concepts

TLA+ specifies _what_ a system does (not how). PlusCal is a pseudocode language
that compiles to TLA+. The TLC model checker explores every reachable state.
When an invariant fails, it produces a trace — the exact sequence of steps that
leads to the violation. Use TLA+ for concurrency, distributed protocols, and any
system with interleaving state transitions.

### Exercises

1. **Install the tools**

   ```bash
   # VS Code extension (recommended)
   code --install-extension alygin.vscode-tlaplus

   # Or standalone: download TLA+ Toolbox from
   # https://github.com/tlaplus/tlaplus/releases
   ```

2. **Model a bank transfer in PlusCal**

   Create `Transfer.tla`:

   ```text
   ---- MODULE Transfer ----
   EXTENDS Integers

   (* --algorithm Transfer
   variables
       alice = 100,
       bob = 50,
       total = alice + bob;

   process transfer = "T1"
   begin
       Check:
           if alice >= 30 then
               Withdraw:
                   alice := alice - 30;
               Deposit:
                   bob := bob + 30;
           end if;
   end process;

   end algorithm; *)

   MoneyConserved == alice + bob = total
   NoOverdraft == alice >= 0 /\ bob >= 0
   ====
   ```

   Run the model checker. It verifies `MoneyConserved` and `NoOverdraft` across
   all states.

3. **Add a second concurrent transfer and find a bug**

   ```text
   (* --algorithm Transfer
   variables
       alice = 100,
       bob = 50,
       total = alice + bob;

   process transfer \in {"T1", "T2"}
   begin
       Check:
           if alice >= 30 then
               Withdraw:
                   alice := alice - 30;
               Deposit:
                   bob := bob + 30;
           end if;
   end process;

   end algorithm; *)
   ```

   Run the model checker again. `NoOverdraft` fails — both transfers check
   Alice's balance (100 >= 30), then both withdraw 30, leaving Alice at 40 after
   the first but the second still proceeds because it already passed the check.
   The model checker shows the exact interleaving.

4. **Fix the specification**

   Make the check-and-withdraw atomic:

   ```text
   process transfer \in {"T1", "T2"}
   begin
       TransferAtomic:
           if alice >= 30 then
               alice := alice - 30;
               bob := bob + 30;
           end if;
   end process;
   ```

   Run the model checker. Both invariants pass. The specification tells you the
   implementation needs an atomic operation (a transaction, a lock, or CAS).

### Checkpoint

Model a system from your work that has concurrent access to shared state. Define
the invariants that must hold. Run TLC. If it finds a violation, analyze the
counterexample trace and propose a fix.

---

## Lesson 8: Specifying Agent Behavior

**Goal:** Apply specification discipline to AI agent systems — constraints,
contracts, and verification.

### Concepts

Agent specifications define what an agent must do, must not do, and what success
looks like. Unlike compiler-enforced contracts, agent contracts are
probabilistic — the agent might violate them. This makes precise specification
more important, not less. A CLAUDE.md file is a behavioral specification. An
output schema is a structural specification. Token budgets and timeouts are
resource specifications.

### Exercises

1. **Write a behavioral specification**

   ```markdown
   ## Agent: Code Reviewer

   ### Input contract

   - Receives: git diff (unified format), file paths, PR description
   - Maximum context: 50,000 tokens

   ### Output contract

   - Returns: JSON array of findings
   - Each finding: {file, line, severity, message, suggestion}
   - severity ∈ {"critical", "warning", "info"}
   - At least one finding per file changed, or explicit "no issues found"

   ### Behavioral constraints

   - MUST flag security vulnerabilities as critical
   - MUST NOT approve changes to CI/CD pipelines without noting the risk
   - MUST NOT hallucinate line numbers — verify against the diff

   ### Resource bounds

   - Response within 60 seconds
   - Budget: 10,000 output tokens maximum

   ### Success criteria

   - Critical findings have zero false positives (precision > 99%)
   - All OWASP Top 10 vulnerabilities detected (recall > 90%)
   ```

2. **Test the specification**

   Feed the agent three known-bad diffs:
   - A SQL injection vulnerability
   - A hardcoded secret
   - A race condition in concurrent code

   Verify the output matches the contract: correct JSON shape, severity levels
   applied correctly, line numbers match the diff.

3. **Evolve the specification**

   Add a new requirement: "MUST flag dependency version changes and check for
   known vulnerabilities." Update the input contract (needs access to
   vulnerability database), output contract (new finding type), and success
   criteria. Trace every change through the specification — what else must
   change?

4. **Compare specification levels**

   ```text
   Informal:    "Review code for issues"
   Structured:  Decision table of severity × category
   Schema:      JSON Schema for output format
   Behavioral:  MUST/MUST NOT constraint list
   Formal:      State machine of review workflow
   ```

   Each level catches different failures. The informal spec misses edge cases.
   The schema catches malformed output. The behavioral constraints catch wrong
   judgments. The state machine catches workflow deadlocks.

### Checkpoint

Write a complete specification for an agent you use or build. Include input
contracts, output contracts, behavioral constraints, resource bounds, and
success criteria. Have the agent perform five tasks. Score its adherence to the
specification. Where it fails, determine whether the fault lies in the
specification (ambiguous) or the agent (non-compliant).

---

## See Also

- [Specification](../why/specification.md) — Mental models and the
  specification-execution spectrum
- [Testing](../why/testing.md) — Property-based testing as executable
  specification
- [API Design](../why/api-design.md) — Schema design and evolution
- [Agentic Workflows](agentic-workflows-lesson-plan.md) — Agent orchestration
  and CLAUDE.md as configuration
- [Context & Complexity](context-complexity-lesson-plan.md) — Contracts as
  boundary definitions
