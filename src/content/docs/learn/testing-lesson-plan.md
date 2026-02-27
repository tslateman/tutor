---
title: "Testing Lesson Plan"
description:
  Eight lessons from first unit test to integration strategy, covering pytest,
  test doubles, TDD, and anti-patterns.
---

A progressive curriculum to write effective tests and build a testing strategy.

<!-- prettier-ignore -->
:::note[Prerequisites]
Comfortable with [Python](../how/python.md) basics —
functions, classes, imports. Install pytest: `pip install pytest`.
:::

## Lesson 1: First Unit Test

**Goal:** Write, run, and interpret a pytest test.

### Concepts

A unit test calls a function with known inputs and asserts the output matches
expectations. pytest discovers files named `test_*.py` and runs functions named
`test_*`. A passing test prints a green dot; a failing test prints the
assertion, the expected value, and the actual value.

### Exercises

1. **Create a module to test**

   ```bash
   mkdir learn-testing && cd learn-testing
   ```

   ```python
   # calc.py
   def add(a, b):
       return a + b

   def divide(a, b):
       if b == 0:
           raise ValueError("Cannot divide by zero")
       return a / b
   ```

2. **Write your first test**

   ```python
   # test_calc.py
   from calc import add, divide

   def test_add_positive_numbers():
       assert add(2, 3) == 5

   def test_add_negative_numbers():
       assert add(-1, -1) == -2

   def test_add_zero():
       assert add(0, 5) == 5
   ```

3. **Run the test**

   ```bash
   pytest test_calc.py -v    # Verbose: see each test name
   pytest test_calc.py -v -s # Also show print statements
   ```

4. **Write a failing test, then fix it**

   ```python
   def test_add_returns_integer_for_integers():
       result = add(2, 3)
       assert isinstance(result, int)
       assert result == 5
   ```

   ```bash
   pytest test_calc.py -v    # Watch it pass
   ```

5. **Test an exception**

   ```python
   import pytest

   def test_divide_by_zero_raises():
       with pytest.raises(ValueError, match="Cannot divide by zero"):
           divide(1, 0)
   ```

### Checkpoint

Run `pytest -v` and see all tests pass. You can write a test, run it, and read
the failure output.

---

## Lesson 2: Test Structure

**Goal:** Organize tests for readability and maintainability.

### Concepts

The **Arrange-Act-Assert** (AAA) pattern gives every test a consistent
structure: set up inputs, call the function, check results. Good test names
describe the behavior under test, not the implementation. Group related tests in
classes or modules by the unit they exercise.

### Exercises

1. **Apply AAA explicitly**

   ```python
   # test_calc.py
   def test_divide_returns_float():
       # Arrange
       numerator = 10
       denominator = 3

       # Act
       result = divide(numerator, denominator)

       # Assert
       assert isinstance(result, float)
       assert abs(result - 3.333) < 0.01
   ```

2. **Name tests as specifications**

   ```python
   # Bad: vague names
   def test_add_1():
       assert add(1, 1) == 2

   # Good: names describe behavior
   def test_add_returns_sum_of_two_positive_integers():
       assert add(1, 1) == 2

   def test_add_handles_float_inputs():
       assert add(1.5, 2.5) == 4.0

   def test_divide_returns_exact_result_for_even_division():
       assert divide(10, 2) == 5.0
   ```

3. **Group tests with a class**

   ```python
   class TestAdd:
       def test_positive_numbers(self):
           assert add(2, 3) == 5

       def test_negative_numbers(self):
           assert add(-1, -1) == -2

       def test_mixed_signs(self):
           assert add(-1, 1) == 0

   class TestDivide:
       def test_even_division(self):
           assert divide(10, 2) == 5.0

       def test_fractional_result(self):
           assert abs(divide(1, 3) - 0.333) < 0.01

       def test_zero_numerator(self):
           assert divide(0, 5) == 0.0
   ```

4. **Organize files by module**

   ```text
   learn-testing/
   ├── calc.py
   ├── user.py
   ├── tests/
   │   ├── test_calc.py
   │   └── test_user.py
   ```

   ```bash
   pytest tests/ -v          # Run all tests in directory
   pytest tests/test_calc.py # Run one file
   ```

### Checkpoint

Every test follows AAA. Test names read as specifications. Running `pytest -v`
produces output that documents the module's behavior.

---

## Lesson 3: Assertions and Matchers

**Goal:** Move beyond `==` to express precise expectations.

### Concepts

pytest uses plain `assert` statements and rewrites them at import time to
produce rich failure messages. For floating-point comparisons, use
`pytest.approx`. For exceptions, use `pytest.raises`. For warnings, use
`pytest.warns`. Each assertion should test one logical condition.

### Exercises

1. **Floating-point comparison**

   ```python
   from pytest import approx

   def test_divide_with_approx():
       assert divide(1, 3) == approx(0.3333, rel=1e-3)

   def test_sum_of_floats():
       assert 0.1 + 0.2 == approx(0.3)
   ```

2. **Collection assertions**

   ```python
   def test_sorted_output():
       result = sorted([3, 1, 2])
       assert result == [1, 2, 3]

   def test_contains_element():
       result = [1, 2, 3, 4, 5]
       assert 3 in result

   def test_dict_subset():
       user = {"name": "Alice", "age": 30, "role": "admin"}
       assert user["name"] == "Alice"
       assert "role" in user
   ```

3. **Exception assertions with context**

   ```python
   import pytest

   def test_divide_by_zero_message():
       with pytest.raises(ValueError) as exc_info:
           divide(1, 0)
       assert "Cannot divide by zero" in str(exc_info.value)

   def test_invalid_type_raises_type_error():
       with pytest.raises(TypeError):
           add("a", 1)
   ```

4. **String and regex matching**

   ```python
   def test_greeting_format():
       greeting = "Hello, Alice!"
       assert greeting.startswith("Hello")
       assert "Alice" in greeting

   import re

   def test_email_format():
       email = "user@example.com"
       assert re.match(r"^[\w.]+@[\w.]+\.\w+$", email)
   ```

5. **Custom assertion messages**

   ```python
   def test_add_with_message():
       result = add(2, 3)
       assert result == 5, f"Expected 5, got {result}"
   ```

### Checkpoint

Write tests using `approx`, `pytest.raises`, collection membership, and regex
matching. Each test asserts one specific behavior.

---

## Lesson 4: Test Doubles

**Goal:** Isolate the unit under test by replacing dependencies.

### Concepts

Test doubles replace real dependencies so tests run fast, deterministically, and
in isolation. **Stubs** return canned data. **Mocks** verify interactions.
**Fakes** provide a working but simplified implementation. **Spies** wrap real
objects and record calls. Mock at boundaries (network, database, filesystem) --
never mock the thing you are testing.

### Exercises

1. **Create a module with a dependency**

   ```python
   # weather.py
   import requests

   def get_temperature(city):
       response = requests.get(
           f"https://api.weather.com/v1/{city}"
       )
       data = response.json()
       return data["temperature"]

   def is_freezing(city):
       return get_temperature(city) <= 0
   ```

2. **Stub with unittest.mock.patch**

   ```python
   # test_weather.py
   from unittest.mock import patch, MagicMock
   from weather import get_temperature, is_freezing

   @patch("weather.requests.get")
   def test_get_temperature(mock_get):
       # Arrange: stub the HTTP response
       mock_response = MagicMock()
       mock_response.json.return_value = {"temperature": 22}
       mock_get.return_value = mock_response

       # Act
       result = get_temperature("London")

       # Assert
       assert result == 22
       mock_get.assert_called_once_with(
           "https://api.weather.com/v1/London"
       )
   ```

3. **Test with a stub controlling the boundary**

   ```python
   @patch("weather.requests.get")
   def test_is_freezing_below_zero(mock_get):
       mock_response = MagicMock()
       mock_response.json.return_value = {"temperature": -5}
       mock_get.return_value = mock_response

       assert is_freezing("Moscow") is True

   @patch("weather.requests.get")
   def test_is_not_freezing_above_zero(mock_get):
       mock_response = MagicMock()
       mock_response.json.return_value = {"temperature": 25}
       mock_get.return_value = mock_response

       assert is_freezing("Cairo") is False
   ```

4. **Build a fake for complex dependencies**

   ```python
   # A fake in-memory repository replaces a real database
   class FakeUserRepository:
       def __init__(self):
           self.users = {}

       def save(self, user):
           self.users[user["id"]] = user

       def find(self, user_id):
           return self.users.get(user_id)

   def test_save_and_retrieve_user():
       repo = FakeUserRepository()
       repo.save({"id": 1, "name": "Alice"})
       user = repo.find(1)
       assert user["name"] == "Alice"

   def test_find_missing_user_returns_none():
       repo = FakeUserRepository()
       assert repo.find(999) is None
   ```

5. **Detect over-mocking**

   ```python
   # Smell: more mock setup than assertions
   # If you need 10 lines of mock wiring and 1 assert,
   # the design may need work -- not more mocks.

   # Better: inject dependencies explicitly
   def get_temperature_v2(city, http_client):
       response = http_client.get(
           f"https://api.weather.com/v1/{city}"
       )
       return response.json()["temperature"]

   def test_get_temperature_with_injected_client():
       client = MagicMock()
       client.get.return_value.json.return_value = {
           "temperature": 18
       }
       assert get_temperature_v2("Paris", client) == 18
   ```

<!-- prettier-ignore -->
:::tip[Design Signal]
Hard-to-mock code is hard-to-use code. If test setup feels painful,
redesign the interface before adding more mocks.
:::

### Checkpoint

Mock an HTTP call. Build a fake repository. Distinguish when to use stubs,
mocks, and fakes. Identify over-mocking by comparing setup lines to assertion
lines.

---

## Lesson 5: Testing Patterns

**Goal:** Reduce duplication with fixtures, parametrize, and markers.

### Concepts

pytest **fixtures** provide reusable setup and teardown. The `@pytest.fixture`
decorator defines a function whose return value is injected into any test that
requests it by name. **Parametrize** runs the same test with multiple input
sets. **Markers** tag tests for selective execution (e.g., `slow`,
`integration`).

### Exercises

1. **Create a fixture**

   ```python
   # conftest.py
   import pytest
   from calc import add

   @pytest.fixture
   def calculator_inputs():
       return {"a": 10, "b": 5}
   ```

   ```python
   # test_calc.py
   def test_add_with_fixture(calculator_inputs):
       result = add(
           calculator_inputs["a"],
           calculator_inputs["b"]
       )
       assert result == 15
   ```

2. **Fixture with teardown**

   ```python
   import pytest
   import tempfile
   import os

   @pytest.fixture
   def temp_file():
       # Setup
       fd, path = tempfile.mkstemp()
       os.write(fd, b"test data")
       os.close(fd)
       yield path
       # Teardown
       os.unlink(path)

   def test_file_contents(temp_file):
       with open(temp_file) as f:
           assert f.read() == "test data"
   ```

3. **Parametrize to eliminate duplication**

   ```python
   import pytest
   from calc import add, divide

   @pytest.mark.parametrize("a, b, expected", [
       (1, 2, 3),
       (0, 0, 0),
       (-1, 1, 0),
       (100, 200, 300),
   ])
   def test_add_cases(a, b, expected):
       assert add(a, b) == expected

   @pytest.mark.parametrize("a, b, expected", [
       (10, 2, 5.0),
       (7, 2, 3.5),
       (0, 1, 0.0),
   ])
   def test_divide_cases(a, b, expected):
       assert divide(a, b) == expected
   ```

4. **Mark tests for selective execution**

   ```python
   import pytest

   @pytest.mark.slow
   def test_expensive_computation():
       # Simulates a slow test
       result = sum(range(10_000_000))
       assert result > 0

   @pytest.mark.integration
   def test_database_connection():
       pytest.skip("No database in CI")
   ```

   ```bash
   pytest -m "not slow"       # Skip slow tests
   pytest -m "slow"           # Run only slow tests
   pytest -k "add"            # Run tests matching "add"
   ```

5. **Shared fixtures with conftest.py**

   ```text
   tests/
   ├── conftest.py            # Fixtures available to all tests
   ├── test_calc.py
   └── integration/
       ├── conftest.py        # Fixtures for integration tests only
       └── test_api.py
   ```

   ```python
   # tests/conftest.py
   import pytest

   @pytest.fixture(scope="session")
   def app_config():
       return {"debug": True, "db_url": "sqlite:///:memory:"}

   @pytest.fixture(scope="function")
   def clean_state():
       state = {"items": []}
       yield state
       state["items"].clear()
   ```

### Checkpoint

Create a `conftest.py` with two fixtures. Write a parametrized test with at
least four cases. Use markers to run subsets selectively.

---

## Lesson 6: Integration Testing

**Goal:** Test boundaries where components meet -- databases, APIs, filesystems.

### Concepts

Integration tests verify that components work together across boundaries. Unlike
unit tests, they use real (or realistic) infrastructure: an actual database
connection, a real HTTP server, a temporary filesystem. They run slower than
unit tests, so keep the count lower and the scope focused on the boundary
contract.

### Exercises

1. **Test a SQLite repository**

   ```python
   # repository.py
   import sqlite3

   class TodoRepository:
       def __init__(self, db_path):
           self.conn = sqlite3.connect(db_path)
           self.conn.execute(
               "CREATE TABLE IF NOT EXISTS todos "
               "(id INTEGER PRIMARY KEY, title TEXT, done BOOLEAN)"
           )

       def add(self, title):
           self.conn.execute(
               "INSERT INTO todos (title, done) VALUES (?, ?)",
               (title, False),
           )
           self.conn.commit()

       def list_all(self):
           cursor = self.conn.execute("SELECT title, done FROM todos")
           return [{"title": r[0], "done": bool(r[1])} for r in cursor]

       def close(self):
           self.conn.close()
   ```

2. **Write the integration test**

   ```python
   # test_repository.py
   import pytest
   from repository import TodoRepository

   @pytest.fixture
   def repo(tmp_path):
       db_path = tmp_path / "test.db"
       r = TodoRepository(str(db_path))
       yield r
       r.close()

   def test_add_and_list_todos(repo):
       repo.add("Buy milk")
       repo.add("Write tests")
       todos = repo.list_all()
       assert len(todos) == 2
       assert todos[0]["title"] == "Buy milk"
       assert todos[1]["done"] is False

   def test_empty_repository_returns_empty_list(repo):
       assert repo.list_all() == []
   ```

3. **Test a REST API with a test client**

   ```python
   # app.py
   from flask import Flask, jsonify, request

   app = Flask(__name__)
   items = []

   @app.post("/items")
   def create_item():
       item = request.json
       items.append(item)
       return jsonify(item), 201

   @app.get("/items")
   def list_items():
       return jsonify(items)
   ```

   ```python
   # test_app.py
   import pytest
   from app import app, items

   @pytest.fixture
   def client():
       app.config["TESTING"] = True
       with app.test_client() as c:
           yield c
       items.clear()

   def test_create_item(client):
       response = client.post(
           "/items",
           json={"name": "Widget"},
       )
       assert response.status_code == 201
       assert response.json["name"] == "Widget"

   def test_list_items_after_create(client):
       client.post("/items", json={"name": "Gadget"})
       response = client.get("/items")
       assert len(response.json) == 1
   ```

4. **Test filesystem operations**

   ```python
   # file_processor.py
   from pathlib import Path

   def count_lines(file_path):
       return len(Path(file_path).read_text().splitlines())

   def merge_files(paths, output_path):
       content = "\n".join(
           Path(p).read_text() for p in paths
       )
       Path(output_path).write_text(content)
   ```

   ```python
   # test_file_processor.py
   from file_processor import count_lines, merge_files

   def test_count_lines(tmp_path):
       f = tmp_path / "test.txt"
       f.write_text("line1\nline2\nline3")
       assert count_lines(f) == 3

   def test_merge_files(tmp_path):
       a = tmp_path / "a.txt"
       b = tmp_path / "b.txt"
       out = tmp_path / "merged.txt"
       a.write_text("alpha")
       b.write_text("beta")
       merge_files([a, b], out)
       assert out.read_text() == "alpha\nbeta"
   ```

<!-- prettier-ignore -->
:::tip[Boundary Rule]
Integration tests own the boundary. Unit tests own the logic.
If a test needs a real database to be useful, it belongs in integration.
If it tests a calculation, keep it in unit.
:::

### Checkpoint

Write integration tests for a SQLite repository and a Flask endpoint. Use
`tmp_path` for filesystem tests. Each test cleans up after itself via fixtures.

---

## Lesson 7: Test-Driven Development

**Goal:** Use the red-green-refactor cycle to drive design through tests.

### Concepts

TDD inverts the usual workflow: write a failing test first (red), write the
minimum code to pass (green), then clean up (refactor). The test defines the
requirement before any implementation exists. TDD works best for well-understood
requirements and logic-heavy code. It produces minimal implementations and
catches design issues early.

### Exercises

1. **TDD a stack from scratch**

   Start with the simplest behavior: an empty stack.

   ```python
   # test_stack.py — RED: write the test first
   from stack import Stack

   def test_new_stack_is_empty():
       s = Stack()
       assert s.is_empty() is True
   ```

   ```bash
   pytest test_stack.py -v   # RED: ImportError
   ```

2. **Write minimum code to pass**

   ```python
   # stack.py — GREEN: minimal implementation
   class Stack:
       def __init__(self):
           self._items = []

       def is_empty(self):
           return len(self._items) == 0
   ```

   ```bash
   pytest test_stack.py -v   # GREEN
   ```

3. **Next behavior: push and peek**

   ```python
   # test_stack.py — RED
   def test_push_and_peek():
       s = Stack()
       s.push(42)
       assert s.peek() == 42
       assert s.is_empty() is False
   ```

   ```bash
   pytest test_stack.py -v   # RED: AttributeError
   ```

   ```python
   # stack.py — GREEN
   class Stack:
       def __init__(self):
           self._items = []

       def is_empty(self):
           return len(self._items) == 0

       def push(self, item):
           self._items.append(item)

       def peek(self):
           return self._items[-1]
   ```

4. **Continue the cycle: pop**

   ```python
   # test_stack.py — RED
   def test_pop_returns_last_pushed():
       s = Stack()
       s.push(1)
       s.push(2)
       assert s.pop() == 2
       assert s.pop() == 1
       assert s.is_empty() is True

   def test_pop_empty_stack_raises():
       s = Stack()
       with pytest.raises(IndexError, match="empty"):
           s.pop()
   ```

   ```python
   # stack.py — GREEN
   def pop(self):
       if self.is_empty():
           raise IndexError("Pop from empty stack")
       return self._items.pop()
   ```

5. **Refactor with confidence**

   ```python
   # stack.py — REFACTOR: add __len__ and __repr__
   class Stack:
       def __init__(self):
           self._items = []

       def is_empty(self):
           return len(self._items) == 0

       def __len__(self):
           return len(self._items)

       def __repr__(self):
           return f"Stack({self._items})"

       def push(self, item):
           self._items.append(item)

       def peek(self):
           if self.is_empty():
               raise IndexError("Peek at empty stack")
           return self._items[-1]

       def pop(self):
           if self.is_empty():
               raise IndexError("Pop from empty stack")
           return self._items.pop()
   ```

   ```python
   # test_stack.py — verify nothing broke
   def test_stack_length():
       s = Stack()
       assert len(s) == 0
       s.push("a")
       s.push("b")
       assert len(s) == 2
   ```

   ```bash
   pytest test_stack.py -v   # All GREEN
   ```

<!-- prettier-ignore -->
:::tip[When TDD Feels Awkward]
If you cannot name the next test, the requirements are unclear.
Sketch the design first, then return to TDD once you know what
to build. TDD is a design tool, not a rule.
:::

### Checkpoint

Build a complete `Stack` class through TDD. Every method started as a failing
test. Run `pytest -v` and see the full specification in test names.

---

## Lesson 8: Test Strategy

**Goal:** Choose what to test, how much, and what to skip.

### Concepts

Strategy answers the questions that individual techniques cannot: where to
invest testing effort, when coverage numbers mislead, and how to avoid
anti-patterns that make a suite expensive without catching bugs. The test
pyramid guides the ratio. Coverage finds gaps but does not prove quality. Tests
earn their keep by catching regressions, documenting contracts, and enabling
confident refactoring.

### Exercises

1. **Map the pyramid to a real project**

   ```text
   Project: a web app with a REST API and a database

   Unit (70-80%)
   ├── Business logic functions
   ├── Validation rules
   ├── Data transformations
   └── Utility functions

   Integration (15-25%)
   ├── Database queries (real SQLite or test container)
   ├── API endpoints (test client)
   └── File I/O operations

   E2E (5-10%)
   ├── Critical user journeys (login → create → verify)
   └── Smoke tests for deployment
   ```

2. **Identify high-value test targets**

   ```python
   # Given this module, decide what to test:
   class OrderService:
       def __init__(self, repo, payment_client):
           self.repo = repo
           self.payment_client = payment_client

       def place_order(self, user_id, items):
           """Business logic: validate, calculate, charge, save."""
           if not items:
               raise ValueError("Order must have items")
           total = sum(item["price"] * item["qty"] for item in items)
           if total > 10000:
               raise ValueError("Order exceeds limit")
           self.payment_client.charge(user_id, total)
           return self.repo.save(user_id, items, total)

   # High value: test place_order logic
   #   - Empty items → ValueError
   #   - Total exceeds limit → ValueError
   #   - Correct total calculation
   #   - Payment client receives right amount
   #
   # Low value: testing repo.save internals (that's repo's job)
   ```

3. **Use coverage to find gaps, not prove quality**

   ```bash
   pytest --cov=. --cov-report=term-missing -v
   ```

   ```text
   Name              Stmts   Miss  Cover   Missing
   -----------------------------------------------
   calc.py               6      0   100%
   stack.py             15      2    87%   18, 22
   weather.py            8      8     0%
   -----------------------------------------------
   TOTAL                29     10    66%

   # 100% on calc.py — good, logic is covered
   # 87% on stack.py — check lines 18, 22
   # 0% on weather.py — decide: mock test or accept gap?
   ```

4. **Spot anti-patterns in existing tests**

   ```python
   # Anti-pattern: assertion-free test
   def test_process_data():
       process_data([1, 2, 3])  # Runs but verifies nothing

   # Anti-pattern: testing implementation
   def test_uses_sorted():
       with patch("mymodule.sorted") as mock_sorted:
           mock_sorted.return_value = [1, 2, 3]
           result = get_sorted_data()
           mock_sorted.assert_called_once()  # Tests HOW, not WHAT

   # Anti-pattern: test interdependence
   class TestOrdering:
       state = []  # Shared mutable state across tests

       def test_add(self):
           self.state.append(1)

       def test_check(self):
           assert len(self.state) == 1  # Depends on test_add running first
   ```

   ```python
   # Fixed versions:
   def test_process_data_returns_count():
       result = process_data([1, 2, 3])
       assert result == 3  # Assert something meaningful

   def test_returns_sorted_data():
       result = get_sorted_data([3, 1, 2])
       assert result == [1, 2, 3]  # Tests WHAT, not HOW

   def test_independent():
       state = [1]  # Own setup, no shared state
       assert len(state) == 1
   ```

5. **Write a test strategy document**

   ```text
   Test Strategy for: [Your Project]
   ──────────────────────────────────
   Unit tests:
     - All business logic in services/
     - All validation in validators/
     - Parametrized edge cases for parsers

   Integration tests:
     - Database repository methods (SQLite in CI)
     - REST endpoints via test client
     - File export functions via tmp_path

   Not tested (deliberate):
     - Third-party library internals
     - Trivial __repr__ methods
     - Framework boilerplate (Django admin registration)

   Coverage target: 80% on src/, enforced in CI
   Speed target: full suite under 30 seconds
   ```

<!-- prettier-ignore -->
:::caution[Coverage Traps]
100% coverage with zero assertions equals zero value.
60% coverage on critical paths gives high confidence.
Use coverage to find untested code, not to prove tested code works.
:::

### Checkpoint

Run `pytest --cov` on your project. Identify one gap worth testing and one
low-value area to skip. Write a one-page test strategy that names the layers,
targets, and deliberate exclusions.

---

## Practice Projects

### Project 1: Calculator with TDD

Build a calculator that handles `+`, `-`, `*`, `/`, and parentheses. Write every
feature test-first. Aim for 100% coverage on the core logic. Use parametrize for
operator edge cases.

### Project 2: REST API Test Suite

Create a Flask or FastAPI app with three endpoints. Write unit tests for the
business logic (mocked dependencies) and integration tests for the endpoints
(test client with a real SQLite database). Organize into `tests/unit/` and
`tests/integration/` with separate conftest files.

### Project 3: Legacy Code Rescue

Find untested code in a personal project. Add a test for the riskiest function
first. Use the characterization test approach: capture current behavior as
assertions, then refactor with confidence.

---

## Command Reference

| Stage        | Must Know                                               |
| ------------ | ------------------------------------------------------- |
| Running      | `pytest` `pytest -v` `pytest -x` `pytest -k`            |
| Assertions   | `assert` `approx` `pytest.raises` `pytest.warns`        |
| Organization | `conftest.py` `@pytest.fixture` `@pytest.mark`          |
| Parametrize  | `@pytest.mark.parametrize` `-m` marker filtering        |
| Doubles      | `patch` `MagicMock` `MagicMock.return_value`            |
| Coverage     | `--cov` `--cov-report=term-missing` `--cov-report=html` |
| Speed        | `-x` `--lf` `--ff` `-n auto` (pytest-xdist)             |

## See Also

- [Testing Cheat Sheet](../how/testing.md) — pytest, Jest, Go, Rust command
  reference
- [Testing Principles](../why/testing.md) — Pyramid, strategy, doubles, TDD
  tradeoffs
- [Python Cheat Sheet](../how/python.md) — Language fundamentals
- [Debugging](../how/debugging.md) — When tests catch failures, debuggers find
  causes
- [Python Lesson Plan](python-lesson-plan.md) — Python language foundations
- [Specification Lesson Plan](specification-lesson-plan.md) — Property-based
  testing and Design by Contract
