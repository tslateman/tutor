# Rust Cheat Sheet

## Quick Reference

| Concept             | Syntax/Example                      |
| ------------------- | ----------------------------------- |
| Immutable binding   | `let x = 5;`                        |
| Mutable binding     | `let mut x = 5;`                    |
| Borrow (immutable)  | `&x`                                |
| Borrow (mutable)    | `&mut x`                            |
| Lifetime annotation | `'a`                                |
| Option handling     | `Some(x)`, `None`, `.unwrap()`, `?` |
| Result handling     | `Ok(x)`, `Err(e)`, `.unwrap()`, `?` |
| Pattern match       | `match x { ... }`                   |
| If let              | `if let Some(v) = opt { ... }`      |
| Derive traits       | `#[derive(Debug, Clone)]`           |
| Module declaration  | `mod name;`                         |
| Public visibility   | `pub fn`, `pub struct`, `pub mod`   |
| Build project       | `cargo build`                       |
| Run project         | `cargo run`                         |
| Run tests           | `cargo test`                        |

## Ownership and Borrowing

### Ownership Rules

```rust
// 1. Each value has exactly one owner
let s1 = String::from("hello");

// 2. Value is dropped when owner goes out of scope
{
    let s2 = String::from("world");
} // s2 dropped here

// 3. Ownership transfers on assignment (move)
let s3 = s1;              // s1 moved to s3, s1 no longer valid
// println!("{}", s1);    // ERROR: value borrowed after move

// Clone to create a deep copy
let s4 = s3.clone();      // s3 still valid
```

### Borrowing Rules

```rust
let mut s = String::from("hello");

// Immutable borrows: unlimited simultaneous readers
let r1 = &s;
let r2 = &s;
println!("{} {}", r1, r2);  // OK: multiple immutable borrows

// Mutable borrow: exclusive access
let r3 = &mut s;
r3.push_str(" world");

// Cannot mix mutable and immutable borrows
let r4 = &s;
// let r5 = &mut s;        // ERROR: cannot borrow as mutable
```

### References in Functions

```rust
// Borrow instead of taking ownership
fn calculate_length(s: &String) -> usize {
    s.len()
}

// Mutable borrow to modify
fn append(s: &mut String) {
    s.push_str(" world");
}

let mut s = String::from("hello");
let len = calculate_length(&s);   // Immutable borrow
append(&mut s);                   // Mutable borrow
```

## Lifetimes

### Basic Syntax

```rust
// Lifetime annotation on references
fn longest<'a>(x: &'a str, y: &'a str) -> &'a str {
    if x.len() > y.len() { x } else { y }
}

// Multiple lifetimes
fn first_word<'a, 'b>(s: &'a str, prefix: &'b str) -> &'a str {
    &s[..s.find(' ').unwrap_or(s.len())]
}
```

### Struct Lifetimes

```rust
// Struct holding a reference needs lifetime
struct Excerpt<'a> {
    part: &'a str,
}

impl<'a> Excerpt<'a> {
    fn level(&self) -> i32 {
        3
    }

    // Return type lifetime tied to self
    fn announce(&self, announcement: &str) -> &'a str {
        println!("Attention: {}", announcement);
        self.part
    }
}
```

### Lifetime Elision

```rust
// Compiler infers lifetimes in common cases

// These are equivalent:
fn first(s: &str) -> &str { &s[..1] }
fn first_explicit<'a>(s: &'a str) -> &'a str { &s[..1] }

// Elision rules:
// 1. Each input reference gets its own lifetime
// 2. If one input lifetime, output gets that lifetime
// 3. If &self or &mut self, output gets self's lifetime
```

### Static Lifetime

```rust
// 'static: lives for entire program duration
let s: &'static str = "I live forever";

// String literals are always 'static
const GREETING: &str = "Hello";  // Implicitly 'static
```

## Error Handling

### Option

```rust
let some_value: Option<i32> = Some(5);
let no_value: Option<i32> = None;

// Pattern matching
match some_value {
    Some(v) => println!("Got: {}", v),
    None => println!("Nothing"),
}

// Common methods
some_value.unwrap();              // Panic if None
some_value.unwrap_or(0);          // Default if None
some_value.unwrap_or_default();   // Type's default if None
some_value.expect("msg");         // Panic with message if None
some_value.is_some();             // Returns bool
some_value.is_none();             // Returns bool

// Transform
some_value.map(|v| v * 2);        // Some(10) or None
some_value.and_then(|v| Some(v * 2));  // Chainable
some_value.filter(|v| *v > 3);    // Some if predicate true

// Convert to Result
some_value.ok_or("error");        // Option -> Result
```

### Result

```rust
use std::fs::File;
use std::io::{self, Read};

fn read_file(path: &str) -> Result<String, io::Error> {
    let mut file = File::open(path)?;  // ? propagates error
    let mut contents = String::new();
    file.read_to_string(&mut contents)?;
    Ok(contents)
}

// Pattern matching
match read_file("test.txt") {
    Ok(contents) => println!("{}", contents),
    Err(e) => eprintln!("Error: {}", e),
}

// Common methods
result.unwrap();                  // Panic if Err
result.unwrap_or(default);        // Default if Err
result.expect("msg");             // Panic with message if Err
result.is_ok();                   // Returns bool
result.is_err();                  // Returns bool
result.ok();                      // Result -> Option (discards Err)
result.err();                     // Get Err as Option

// Transform
result.map(|v| v.len());          // Transform Ok value
result.map_err(|e| CustomError::from(e));  // Transform Err
```

### The ? Operator

```rust
// ? returns early on Err/None, unwraps on Ok/Some
fn process() -> Result<i32, String> {
    let x = may_fail()?;          // Returns Err early if failed
    let y = may_fail()?;
    Ok(x + y)
}

// Works with Option in functions returning Option
fn first_even(nums: &[i32]) -> Option<i32> {
    let first = nums.first()?;    // Returns None if empty
    if first % 2 == 0 { Some(*first) } else { None }
}

// Convert between Option and Result with ?
fn combined() -> Result<i32, &'static str> {
    let opt: Option<i32> = Some(5);
    let val = opt.ok_or("was none")?;  // Convert then propagate
    Ok(val)
}
```

## Pattern Matching

### Match Expressions

```rust
let x = 5;

match x {
    1 => println!("one"),
    2 | 3 => println!("two or three"),    // Multiple patterns
    4..=6 => println!("four through six"), // Range
    n if n > 10 => println!("big: {}", n), // Guard
    _ => println!("other"),                // Wildcard
}

// Match returns a value
let description = match x {
    1 => "one",
    2 => "two",
    _ => "many",
};
```

### Destructuring

```rust
// Tuples
let point = (3, 5);
match point {
    (0, 0) => println!("origin"),
    (x, 0) => println!("on x-axis at {}", x),
    (0, y) => println!("on y-axis at {}", y),
    (x, y) => println!("at ({}, {})", x, y),
}

// Structs
struct Point { x: i32, y: i32 }
let p = Point { x: 0, y: 7 };

match p {
    Point { x: 0, y } => println!("on y-axis at {}", y),
    Point { x, y: 0 } => println!("on x-axis at {}", x),
    Point { x, y } => println!("at ({}, {})", x, y),
}

// Enums
enum Message {
    Quit,
    Move { x: i32, y: i32 },
    Write(String),
    Color(i32, i32, i32),
}

match msg {
    Message::Quit => println!("quit"),
    Message::Move { x, y } => println!("move to {},{}", x, y),
    Message::Write(text) => println!("text: {}", text),
    Message::Color(r, g, b) => println!("rgb({},{},{})", r, g, b),
}
```

### If Let and While Let

```rust
// if let: match single pattern
let opt = Some(5);
if let Some(value) = opt {
    println!("Got {}", value);
}

// With else
if let Some(v) = opt {
    println!("value: {}", v);
} else {
    println!("no value");
}

// while let: loop while pattern matches
let mut stack = vec![1, 2, 3];
while let Some(top) = stack.pop() {
    println!("{}", top);
}

// let else: bind or diverge
fn process(opt: Option<i32>) -> i32 {
    let Some(value) = opt else {
        return 0;  // Must diverge (return, panic, break, etc.)
    };
    value * 2
}
```

## Common Traits

### Derivable Traits

```rust
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Default)]
struct Point {
    x: i32,
    y: i32,
}

// Debug: {:?} formatting
println!("{:?}", point);          // Point { x: 1, y: 2 }
println!("{:#?}", point);         // Pretty print

// Clone: explicit duplication
let p2 = point.clone();

// Copy: implicit bitwise copy (requires Clone)
let p3 = point;                   // point still valid

// PartialEq/Eq: == and != comparison
point == p2;

// Hash: use in HashMap/HashSet
use std::collections::HashMap;
let mut map: HashMap<Point, &str> = HashMap::new();

// Default: default value
let p4 = Point::default();        // Point { x: 0, y: 0 }
```

### Display and Debug

```rust
use std::fmt;

struct Point { x: i32, y: i32 }

// Debug: programmer-facing output
impl fmt::Debug for Point {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "Point {{ x: {}, y: {} }}", self.x, self.y)
    }
}

// Display: user-facing output
impl fmt::Display for Point {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "({}, {})", self.x, self.y)
    }
}

let p = Point { x: 1, y: 2 };
println!("{:?}", p);  // Debug: Point { x: 1, y: 2 }
println!("{}", p);    // Display: (1, 2)
```

### From and Into

```rust
struct Meters(f64);
struct Feet(f64);

// Implement From, get Into for free
impl From<Feet> for Meters {
    fn from(feet: Feet) -> Self {
        Meters(feet.0 * 0.3048)
    }
}

let feet = Feet(10.0);
let meters: Meters = feet.into();         // Uses Into
let meters2 = Meters::from(Feet(10.0));   // Uses From

// From for error conversion
impl From<std::io::Error> for MyError {
    fn from(err: std::io::Error) -> Self {
        MyError::Io(err)
    }
}
// Now ? automatically converts io::Error to MyError
```

### Clone vs Copy

```rust
// Copy: implicit, bitwise, stack-only
// - Primitives (i32, f64, bool, char)
// - Tuples/arrays of Copy types
// - Immutable references (&T)

// Clone: explicit, potentially expensive
// - Heap-allocated types (String, Vec, Box)
// - Types with custom duplication logic

#[derive(Clone)]       // Only Clone
struct Heap { data: Vec<i32> }

#[derive(Clone, Copy)] // Both (requires all fields be Copy)
struct Stack { x: i32, y: i32 }
```

## Iterators and Closures

### Iterator Basics

```rust
let v = vec![1, 2, 3, 4, 5];

// Three ways to iterate
for x in v.iter() { }         // Borrow: &T
for x in v.iter_mut() { }     // Mutable borrow: &mut T
for x in v.into_iter() { }    // Ownership: T (consumes v)

// for loop uses into_iter by default
for x in &v { }               // Same as v.iter()
for x in &mut v { }           // Same as v.iter_mut()
for x in v { }                // Same as v.into_iter()
```

### Iterator Adaptors

```rust
let v = vec![1, 2, 3, 4, 5];

// Transform
v.iter().map(|x| x * 2);              // [2, 4, 6, 8, 10]
v.iter().filter(|x| *x % 2 == 0);     // [2, 4]
v.iter().filter_map(|x| {             // Filter and map combined
    if *x > 2 { Some(x * 2) } else { None }
});

// Flatten
let nested = vec![vec![1, 2], vec![3, 4]];
nested.into_iter().flatten();          // [1, 2, 3, 4]
v.iter().flat_map(|x| vec![*x, x * 2]); // Flatten after map

// Take/Skip
v.iter().take(3);                      // First 3 elements
v.iter().skip(2);                      // Skip first 2
v.iter().take_while(|x| **x < 4);      // Take while predicate
v.iter().skip_while(|x| **x < 3);      // Skip while predicate

// Enumerate/Zip
v.iter().enumerate();                  // (index, value) pairs
v.iter().zip(other.iter());            // Pair elements
```

### Consuming Iterators

```rust
let v = vec![1, 2, 3, 4, 5];

// Collect into collection
let doubled: Vec<i32> = v.iter().map(|x| x * 2).collect();
let set: HashSet<_> = v.iter().collect();

// Reduce
v.iter().sum::<i32>();                 // 15
v.iter().product::<i32>();             // 120
v.iter().fold(0, |acc, x| acc + x);    // Custom reduction
v.iter().reduce(|a, b| a.max(b));      // Returns Option

// Find
v.iter().find(|x| **x > 3);            // Some(&4)
v.iter().position(|x| *x > 3);         // Some(3) (index)
v.iter().any(|x| *x > 3);              // true
v.iter().all(|x| *x > 0);              // true

// Count/Min/Max
v.iter().count();                      // 5
v.iter().min();                        // Some(&1)
v.iter().max();                        // Some(&5)
```

### Closures

```rust
// Type inference
let add = |a, b| a + b;
let add_explicit = |a: i32, b: i32| -> i32 { a + b };

// Capture modes (inferred by compiler)
let x = 5;
let borrow = || println!("{}", x);     // Borrows x
let mut y = 5;
let mut mutate = || y += 1;            // Mutably borrows y
let z = String::from("hi");
let consume = || drop(z);              // Takes ownership of z

// Force move with move keyword
let s = String::from("hello");
let closure = move || println!("{}", s);
// s no longer accessible here

// Closure traits
// Fn: borrows immutably, can call multiple times
// FnMut: borrows mutably, can call multiple times
// FnOnce: takes ownership, can call only once

fn apply<F: Fn(i32) -> i32>(f: F, x: i32) -> i32 {
    f(x)
}
```

## Cargo Basics

### Common Commands

```bash
cargo new project_name        # Create new binary project
cargo new --lib lib_name      # Create new library
cargo build                   # Build debug
cargo build --release         # Build optimized
cargo run                     # Build and run
cargo run -- arg1 arg2        # Pass args to program
cargo test                    # Run tests
cargo test test_name          # Run specific test
cargo test -- --nocapture     # Show println output
cargo check                   # Fast syntax/type check
cargo fmt                     # Format code
cargo clippy                  # Lint code
cargo doc --open              # Generate and view docs
cargo update                  # Update dependencies
cargo add crate_name          # Add dependency
cargo remove crate_name       # Remove dependency
```

### Cargo.toml

```toml
[package]
name = "my_project"
version = "0.1.0"
edition = "2021"
authors = ["Name <email@example.com>"]
description = "A brief description"
license = "MIT"

[dependencies]
serde = "1.0"                         # Latest 1.x
serde_json = "1.0.108"                # Exact version
tokio = { version = "1", features = ["full"] }
local_crate = { path = "../local" }   # Local path
git_crate = { git = "https://..." }   # Git repo

[dev-dependencies]
criterion = "0.5"                     # Only for tests/benches

[build-dependencies]
cc = "1.0"                            # Only for build.rs

[features]
default = ["std"]
std = []
extra = ["dep:optional_crate"]

[[bin]]
name = "my_binary"
path = "src/bin/main.rs"
```

## Crate Structure

### Module System

```rust
// src/lib.rs or src/main.rs

// Declare modules (looks for file or directory)
mod utils;           // src/utils.rs or src/utils/mod.rs
mod network;         // src/network.rs or src/network/mod.rs

// Inline module
mod helpers {
    pub fn help() {}
}

// Re-export for cleaner API
pub use utils::parse;
pub use network::Client;
```

### File Organization

```text
src/
├── main.rs           # Binary entry point
├── lib.rs            # Library entry point
├── utils.rs          # mod utils;
├── network/          # mod network;
│   ├── mod.rs        # Module root
│   ├── client.rs     # network::client
│   └── server.rs     # network::server
└── bin/
    └── tool.rs       # Additional binary
```

### Visibility

```rust
mod outer {
    pub mod inner {
        pub fn public() {}        // Visible everywhere
        pub(crate) fn crate_only() {}   // Visible in crate
        pub(super) fn parent_only() {}  // Visible to parent
        pub(in crate::outer) fn limited() {} // Specific path
        fn private() {}           // Only this module
    }
}

// Struct field visibility
pub struct Config {
    pub name: String,           // Public field
    pub(crate) debug: bool,     // Crate-visible field
    secret: String,             // Private field
}
```

### Use and Paths

```rust
// Absolute path (from crate root)
use crate::utils::parse;
use crate::network::Client;

// Relative path
use self::helpers::help;    // Current module
use super::something;       // Parent module

// External crate
use std::collections::HashMap;
use serde::{Serialize, Deserialize};

// Glob import (use sparingly)
use std::io::*;

// Rename imports
use std::fmt::Result as FmtResult;
use std::io::Result as IoResult;

// Nested paths
use std::{
    collections::{HashMap, HashSet},
    io::{self, Read, Write},
};
```

### Prelude Pattern

```rust
// src/prelude.rs
pub use crate::error::Error;
pub use crate::config::Config;
pub use crate::traits::{Parse, Validate};

// In other modules
use crate::prelude::*;
```
