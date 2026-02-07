# Rust Lesson Plan

A progressive curriculum to master Rust through hands-on practice.

## Lesson 1: First Steps

**Goal:** Run Rust and understand basic syntax.

### Concepts

Rust is statically typed with strong safety guarantees. Cargo manages projects,
dependencies, and builds.

### Exercises

1. **Create a project**

   ```bash
   cargo new hello
   cd hello
   cargo run
   ```

   ```rust
   // src/main.rs
   fn main() {
       println!("Hello, World!");
   }
   ```

2. **Variables and mutability**

   ```rust
   let x = 5;          // Immutable
   // x = 6;           // Error!

   let mut y = 5;      // Mutable
   y = 6;              // OK

   let z: i32 = 10;    // Explicit type
   ```

3. **Basic types**

   ```rust
   // Integers
   let i: i32 = 42;    // Signed: i8, i16, i32, i64, i128
   let u: u32 = 42;    // Unsigned: u8, u16, u32, u64, u128

   // Floats
   let f: f64 = 3.14;  // f32, f64

   // Boolean
   let b: bool = true;

   // Character (4 bytes, Unicode)
   let c: char = '🦀';

   // Strings
   let s: &str = "hello";        // String slice
   let s2: String = String::from("hello");  // Owned string
   ```

4. **Printing**

   ```rust
   let name = "Rust";
   println!("Hello, {}!", name);
   println!("Debug: {:?}", (1, 2, 3));
   println!("Pretty: {:#?}", vec![1, 2, 3]);
   ```

### Checkpoint

Write a program that stores your name and age in variables and prints them.

---

## Lesson 2: Control Flow

**Goal:** Use conditionals, loops, and pattern matching.

### Exercises

1. **If expressions**

   ```rust
   let x = 5;

   if x > 0 {
       println!("positive");
   } else if x < 0 {
       println!("negative");
   } else {
       println!("zero");
   }

   // If as expression
   let result = if x > 0 { "positive" } else { "non-positive" };
   ```

2. **Loops**

   ```rust
   // loop (infinite)
   let mut count = 0;
   let result = loop {
       count += 1;
       if count == 10 {
           break count * 2;  // Return value from loop
       }
   };

   // while
   while count > 0 {
       count -= 1;
   }

   // for
   for i in 0..5 {       // 0, 1, 2, 3, 4
       println!("{}", i);
   }

   for i in 0..=5 {      // 0, 1, 2, 3, 4, 5 (inclusive)
       println!("{}", i);
   }

   let nums = vec![1, 2, 3];
   for n in &nums {
       println!("{}", n);
   }
   ```

3. **Match expressions**

   ```rust
   let x = 5;

   match x {
       1 => println!("one"),
       2 | 3 => println!("two or three"),
       4..=10 => println!("four to ten"),
       _ => println!("something else"),
   }

   // Match with binding
   let point = (3, 4);
   match point {
       (0, 0) => println!("origin"),
       (x, 0) => println!("on x-axis at {}", x),
       (0, y) => println!("on y-axis at {}", y),
       (x, y) => println!("at ({}, {})", x, y),
   }
   ```

4. **If let**

   ```rust
   let some_value: Option<i32> = Some(42);

   if let Some(x) = some_value {
       println!("Got: {}", x);
   }
   ```

### Checkpoint

Write a FizzBuzz program using match.

---

## Lesson 3: Ownership

**Goal:** Understand Rust's core memory model.

### Concepts

Each value has one owner. When the owner goes out of scope, the value is
dropped. Ownership can be transferred (moved) or borrowed.

### Exercises

1. **Ownership and moves**

   ```rust
   let s1 = String::from("hello");
   let s2 = s1;      // s1 is moved, now invalid
   // println!("{}", s1);  // Error!
   println!("{}", s2);     // OK

   // Clone for deep copy
   let s3 = s2.clone();
   println!("{} {}", s2, s3);  // Both valid
   ```

2. **References (borrowing)**

   ```rust
   fn length(s: &String) -> usize {
       s.len()
   }

   let s = String::from("hello");
   let len = length(&s);   // Borrow
   println!("{} has {} chars", s, len);  // s still valid
   ```

3. **Mutable references**

   ```rust
   fn append(s: &mut String) {
       s.push_str(" world");
   }

   let mut s = String::from("hello");
   append(&mut s);
   println!("{}", s);  // "hello world"

   // Only one mutable reference at a time
   let r1 = &mut s;
   // let r2 = &mut s;  // Error!
   ```

4. **Slices**

   ```rust
   let s = String::from("hello world");
   let hello = &s[0..5];    // "hello"
   let world = &s[6..];     // "world"

   let arr = [1, 2, 3, 4, 5];
   let slice = &arr[1..3];  // [2, 3]
   ```

### Checkpoint

Write a function that takes a String reference and returns its first word as a
slice.

---

## Lesson 4: Structs

**Goal:** Define and use custom types.

### Exercises

1. **Basic structs**

   ```rust
   struct User {
       name: String,
       age: u32,
       active: bool,
   }

   let user = User {
       name: String::from("Alice"),
       age: 30,
       active: true,
   };

   println!("{} is {} years old", user.name, user.age);
   ```

2. **Methods**

   ```rust
   struct Rectangle {
       width: u32,
       height: u32,
   }

   impl Rectangle {
       // Method
       fn area(&self) -> u32 {
           self.width * self.height
       }

       // Mutating method
       fn scale(&mut self, factor: u32) {
           self.width *= factor;
           self.height *= factor;
       }

       // Associated function (constructor)
       fn square(size: u32) -> Rectangle {
           Rectangle { width: size, height: size }
       }
   }

   let mut rect = Rectangle::square(5);
   rect.scale(2);
   println!("Area: {}", rect.area());
   ```

3. **Tuple structs**

   ```rust
   struct Point(i32, i32, i32);
   struct Color(u8, u8, u8);

   let origin = Point(0, 0, 0);
   let red = Color(255, 0, 0);
   ```

4. **Derive macros**

   ```rust
   #[derive(Debug, Clone, PartialEq)]
   struct Point {
       x: i32,
       y: i32,
   }

   let p1 = Point { x: 1, y: 2 };
   let p2 = p1.clone();
   println!("{:?}", p1);
   assert_eq!(p1, p2);
   ```

### Checkpoint

Create a `Circle` struct with radius and methods for area and circumference.

---

## Lesson 5: Enums and Pattern Matching

**Goal:** Use enums for expressive types.

### Exercises

1. **Basic enums**

   ```rust
   enum Direction {
       North,
       South,
       East,
       West,
   }

   let dir = Direction::North;

   match dir {
       Direction::North => println!("Going up"),
       Direction::South => println!("Going down"),
       _ => println!("Going sideways"),
   }
   ```

2. **Enums with data**

   ```rust
   enum Message {
       Quit,
       Move { x: i32, y: i32 },
       Write(String),
       ChangeColor(u8, u8, u8),
   }

   let msg = Message::Move { x: 10, y: 20 };

   match msg {
       Message::Quit => println!("Quit"),
       Message::Move { x, y } => println!("Move to {}, {}", x, y),
       Message::Write(text) => println!("Write: {}", text),
       Message::ChangeColor(r, g, b) => println!("Color: {},{},{}", r, g, b),
   }
   ```

3. **Option**

   ```rust
   fn find(items: &[i32], target: i32) -> Option<usize> {
       for (i, &item) in items.iter().enumerate() {
           if item == target {
               return Some(i);
           }
       }
       None
   }

   let nums = vec![1, 2, 3];
   match find(&nums, 2) {
       Some(i) => println!("Found at index {}", i),
       None => println!("Not found"),
   }

   // Combinators
   find(&nums, 2).unwrap_or(0);
   find(&nums, 2).map(|i| i * 2);
   ```

4. **Result**

   ```rust
   use std::fs::File;
   use std::io::Read;

   fn read_file(path: &str) -> Result<String, std::io::Error> {
       let mut file = File::open(path)?;  // ? propagates error
       let mut contents = String::new();
       file.read_to_string(&mut contents)?;
       Ok(contents)
   }

   match read_file("config.txt") {
       Ok(contents) => println!("{}", contents),
       Err(e) => eprintln!("Error: {}", e),
   }
   ```

### Checkpoint

Create an enum for HTTP status codes with associated data for error messages.

---

## Lesson 6: Collections

**Goal:** Use Vec, HashMap, and iterators.

### Exercises

1. **Vectors**

   ```rust
   let mut v: Vec<i32> = Vec::new();
   v.push(1);
   v.push(2);

   let v2 = vec![1, 2, 3];

   // Access
   let first = &v2[0];           // Panics if out of bounds
   let maybe = v2.get(10);       // Returns Option

   // Iterate
   for n in &v2 {
       println!("{}", n);
   }

   for n in &mut v {
       *n *= 2;
   }
   ```

2. **HashMap**

   ```rust
   use std::collections::HashMap;

   let mut scores: HashMap<String, i32> = HashMap::new();
   scores.insert(String::from("Alice"), 100);
   scores.insert(String::from("Bob"), 85);

   // Access
   let score = scores.get("Alice");

   // Entry API
   scores.entry(String::from("Charlie")).or_insert(90);

   // Iterate
   for (name, score) in &scores {
       println!("{}: {}", name, score);
   }
   ```

3. **Iterators**

   ```rust
   let nums = vec![1, 2, 3, 4, 5];

   // Map, filter, collect
   let squares: Vec<i32> = nums.iter()
       .map(|x| x * x)
       .collect();

   let evens: Vec<i32> = nums.iter()
       .filter(|x| *x % 2 == 0)
       .copied()
       .collect();

   // Fold
   let sum: i32 = nums.iter().sum();
   let product: i32 = nums.iter().fold(1, |acc, x| acc * x);
   ```

4. **Iterator chains**

   ```rust
   let words = vec!["hello", "world", "rust"];

   let result: String = words.iter()
       .map(|s| s.to_uppercase())
       .filter(|s| s.len() > 4)
       .collect::<Vec<_>>()
       .join(", ");
   ```

### Checkpoint

Create a word frequency counter using HashMap and iterators.

---

## Lesson 7: Traits

**Goal:** Define shared behavior.

### Exercises

1. **Define traits**

   ```rust
   trait Summary {
       fn summarize(&self) -> String;

       // Default implementation
       fn preview(&self) -> String {
           format!("Read more: {}", self.summarize())
       }
   }

   struct Article {
       title: String,
       content: String,
   }

   impl Summary for Article {
       fn summarize(&self) -> String {
           format!("{}", self.title)
       }
   }
   ```

2. **Trait bounds**

   ```rust
   // Function with trait bound
   fn notify<T: Summary>(item: &T) {
       println!("Breaking: {}", item.summarize());
   }

   // Alternative syntax
   fn notify2(item: &impl Summary) {
       println!("Breaking: {}", item.summarize());
   }

   // Multiple bounds
   fn process<T: Summary + Clone>(item: T) { }

   // Where clause
   fn complex<T, U>(t: T, u: U)
   where
       T: Summary + Clone,
       U: Clone + Debug,
   { }
   ```

3. **Returning traits**

   ```rust
   fn make_summary() -> impl Summary {
       Article {
           title: String::from("News"),
           content: String::from("..."),
       }
   }
   ```

4. **Common traits**

   ```rust
   // Display - for user-facing output
   use std::fmt;

   impl fmt::Display for Article {
       fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
           write!(f, "{}", self.title)
       }
   }

   // From/Into - for conversions
   impl From<&str> for Article {
       fn from(s: &str) -> Self {
           Article {
               title: s.to_string(),
               content: String::new(),
           }
       }
   }
   ```

### Checkpoint

Define a `Drawable` trait and implement it for Circle and Rectangle.

---

## Lesson 8: Lifetimes and Error Handling

**Goal:** Understand lifetimes and handle errors idiomatically.

### Exercises

1. **Lifetime annotations**

   ```rust
   // Return reference must live as long as input
   fn longest<'a>(x: &'a str, y: &'a str) -> &'a str {
       if x.len() > y.len() { x } else { y }
   }

   // Struct with references
   struct Excerpt<'a> {
       part: &'a str,
   }
   ```

2. **Static lifetime**

   ```rust
   let s: &'static str = "I live forever";

   // String literals are always 'static
   ```

3. **Custom error types**

   ```rust
   use std::error::Error;
   use std::fmt;

   #[derive(Debug)]
   struct ParseError {
       message: String,
   }

   impl fmt::Display for ParseError {
       fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
           write!(f, "Parse error: {}", self.message)
       }
   }

   impl Error for ParseError {}
   ```

4. **Error handling patterns**

   ```rust
   use anyhow::{Result, Context};  // Popular crate

   fn read_config() -> Result<Config> {
       let content = std::fs::read_to_string("config.toml")
           .context("Failed to read config file")?;

       let config: Config = toml::from_str(&content)
           .context("Failed to parse config")?;

       Ok(config)
   }
   ```

### Checkpoint

Write a function that reads a file, parses JSON, and returns a custom error type
on failure.

---

## Practice Projects

### Project 1: CLI Tool

Build a command-line grep:

- Use clap for argument parsing
- Read files, search patterns
- Handle errors with anyhow

### Project 2: Data Parser

Parse a custom file format:

- Define structs for data
- Implement FromStr trait
- Use iterators for processing

### Project 3: HTTP Client

Build a simple HTTP client:

- Use reqwest crate
- Async/await
- JSON deserialization with serde

---

## Quick Reference

| Stage        | Topics                                    |
| ------------ | ----------------------------------------- |
| Beginner     | Types, control flow, ownership, borrowing |
| Intermediate | Structs, enums, traits, error handling    |
| Advanced     | Lifetimes, generics, async, unsafe        |

## See Also

- [Rust Cheatsheet](../how/rust.md) — Quick syntax reference
- [Testing](../how/testing.md) — Cargo test patterns
