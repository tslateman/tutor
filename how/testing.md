# Testing Cheat Sheet

Commands, flags, and patterns for test runners across languages.

## pytest (Python)

```bash
pytest                          # Run all tests
pytest tests/                   # Run directory
pytest test_file.py             # Run file
pytest test_file.py::test_func  # Run specific test
pytest -k "pattern"             # Run tests matching pattern
pytest -x                       # Stop on first failure
pytest -v                       # Verbose output
pytest -s                       # Show print statements
pytest --lf                     # Rerun last failed
pytest --ff                     # Failed first, then rest
pytest -n auto                  # Parallel (pytest-xdist)
pytest --cov=src                # Coverage report
pytest --cov-report=html        # HTML coverage
pytest -m "slow"                # Run marked tests
pytest -m "not slow"            # Skip marked tests
```

### Fixtures

```python
import pytest

@pytest.fixture
def db():
    conn = create_connection()
    yield conn
    conn.close()

@pytest.fixture(scope="module")
def shared_resource():
    return expensive_setup()

def test_query(db):
    result = db.execute("SELECT 1")
    assert result == 1
```

### Parametrize

```python
@pytest.mark.parametrize("input,expected", [
    (1, 2),
    (2, 4),
    (3, 6),
])
def test_double(input, expected):
    assert double(input) == expected
```

### Markers

```python
@pytest.mark.slow
def test_integration():
    pass

@pytest.mark.skip(reason="Not implemented")
def test_future():
    pass

@pytest.mark.xfail
def test_known_bug():
    pass
```

## Jest / Vitest (JavaScript/TypeScript)

```bash
jest                            # Run all tests
jest path/to/test               # Run specific file
jest -t "pattern"               # Run tests matching name
jest --watch                    # Watch mode
jest --watchAll                 # Watch all files
jest --coverage                 # Coverage report
jest --runInBand                # Serial execution
jest --bail                     # Stop on first failure
jest --verbose                  # Verbose output
jest --detectOpenHandles        # Debug hanging tests
jest --testPathPattern="api"    # Filter by path
```

### Structure

```typescript
describe("Calculator", () => {
  let calc: Calculator;

  beforeEach(() => {
    calc = new Calculator();
  });

  afterEach(() => {
    calc.reset();
  });

  it("adds numbers", () => {
    expect(calc.add(1, 2)).toBe(3);
  });

  it.each([
    [1, 2, 3],
    [0, 0, 0],
    [-1, 1, 0],
  ])("adds %i + %i = %i", (a, b, expected) => {
    expect(calc.add(a, b)).toBe(expected);
  });

  it.skip("not implemented yet", () => {});

  it.todo("add multiplication");
});
```

### Matchers

```typescript
expect(value).toBe(exact);
expect(value).toEqual(deepEqual);
expect(value).toBeTruthy();
expect(value).toBeNull();
expect(value).toContain(item);
expect(value).toHaveLength(n);
expect(value).toMatch(/regex/);
expect(value).toThrow(Error);
expect(fn).toHaveBeenCalled();
expect(fn).toHaveBeenCalledWith(arg);
```

### Mocking

```typescript
// Mock module
jest.mock("./api");

// Mock implementation
const mockFn = jest.fn().mockReturnValue(42);
const mockAsync = jest.fn().mockResolvedValue(data);

// Spy on method
jest.spyOn(object, "method").mockImplementation(() => {});

// Clear mocks
jest.clearAllMocks();
jest.resetAllMocks();
```

## Go

```bash
go test                         # Run package tests
go test ./...                   # Run all tests
go test -v                      # Verbose
go test -run TestName           # Run specific test
go test -run "Test.*Pattern"    # Pattern match
go test -count=1                # Disable cache
go test -race                   # Race detector
go test -cover                  # Coverage summary
go test -coverprofile=c.out     # Coverage file
go tool cover -html=c.out       # HTML report
go test -bench=.                # Run benchmarks
go test -short                  # Skip long tests
go test -timeout 30s            # Set timeout
```

### Table-Driven Tests

```go
func TestAdd(t *testing.T) {
    tests := []struct {
        name     string
        a, b     int
        expected int
    }{
        {"positive", 1, 2, 3},
        {"zero", 0, 0, 0},
        {"negative", -1, 1, 0},
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            got := Add(tt.a, tt.b)
            if got != tt.expected {
                t.Errorf("Add(%d, %d) = %d; want %d",
                    tt.a, tt.b, got, tt.expected)
            }
        })
    }
}
```

### Setup/Teardown

```go
func TestMain(m *testing.M) {
    setup()
    code := m.Run()
    teardown()
    os.Exit(code)
}

func TestWithCleanup(t *testing.T) {
    f := createTempFile(t)
    t.Cleanup(func() { os.Remove(f) })
    // test using f
}
```

## Rust

```bash
cargo test                      # Run all tests
cargo test test_name            # Run specific test
cargo test module::             # Run module tests
cargo test -- --nocapture       # Show println!
cargo test -- --test-threads=1  # Serial execution
cargo test -- --ignored         # Run ignored tests
cargo test --release            # Release mode
cargo test --doc                # Doctest only
cargo test --lib                # Library only
cargo test --bins               # Binaries only
```

### Test Module

```rust
#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_add() {
        assert_eq!(add(1, 2), 3);
    }

    #[test]
    #[should_panic(expected = "divide by zero")]
    fn test_divide_zero() {
        divide(1, 0);
    }

    #[test]
    #[ignore]
    fn expensive_test() {
        // Only runs with --ignored
    }

    #[test]
    fn test_result() -> Result<(), String> {
        if add(1, 2) == 3 {
            Ok(())
        } else {
            Err("math is broken".into())
        }
    }
}
```

### Assertions

```rust
assert!(condition);
assert_eq!(left, right);
assert_ne!(left, right);
assert!(result.is_ok());
assert!(result.is_err());
debug_assert!(condition);  // Debug builds only
```

## Common Patterns

### Watch Mode

```bash
# Python
ptw                             # pytest-watch
pytest-watch --onpass "say passed"

# JavaScript
jest --watch
vitest

# Rust
cargo watch -x test
```

### Filtering

```bash
# Run only fast tests
pytest -m "not slow"
jest --testPathIgnorePatterns="e2e"
go test -short ./...

# Run only integration tests
pytest -m integration
jest --testPathPattern="integration"
```

### Coverage Thresholds

```bash
# Python (pytest-cov)
pytest --cov=src --cov-fail-under=80

# JavaScript (jest.config.js)
# coverageThreshold: { global: { lines: 80 } }

# Go
go test -coverprofile=c.out && go tool cover -func=c.out
```

### CI Commands

```bash
# Python
pytest --junitxml=results.xml --cov=src --cov-report=xml

# JavaScript
jest --ci --coverage --reporters=default --reporters=jest-junit

# Go
go test -v -race -coverprofile=coverage.out ./... 2>&1 | go-junit-report > report.xml
```

## See Also

- [Testing Principles](../why/testing.md) — Strategy, pyramid, what to test
- [Python](python.md) — pytest fixtures and assertions
- [TypeScript](typescript.md) — Type-safe test patterns
