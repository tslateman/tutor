# Go Lesson Plan

A progressive curriculum to master Go through hands-on practice.

## Lesson 1: First Steps

**Goal:** Run Go and understand basic types.

### Concepts

Go is statically typed, compiled, and emphasizes simplicity. Every Go file
belongs to a package. `main` is the entry point.

### Exercises

1. **Create and run a program**

   ```go
   // main.go
   package main

   import "fmt"

   func main() {
       fmt.Println("Hello, World!")
   }
   ```

   ```bash
   go run main.go
   go build main.go && ./main
   ```

2. **Variables and types**

   ```go
   // Explicit type
   var name string = "Go"
   var age int = 10

   // Type inference
   count := 42
   pi := 3.14

   // Constants
   const MaxSize = 100
   ```

3. **Basic types**

   ```go
   // Numbers
   var i int = 42
   var f float64 = 3.14
   var c complex128 = 1 + 2i

   // Strings
   s := "hello"
   len(s)          // 5
   s[0]            // 104 (byte value of 'h')
   s + " world"    // "hello world"

   // Booleans
   var flag bool = true
   ```

4. **Zero values**

   ```go
   var i int       // 0
   var f float64   // 0.0
   var s string    // ""
   var b bool      // false
   var p *int      // nil
   ```

### Checkpoint

Write a program that declares variables of different types and prints them.

---

## Lesson 2: Control Flow

**Goal:** Use conditionals and loops.

### Concepts

Go has only one loop construct: `for`. No parentheses around conditions. Braces
are required.

### Exercises

1. **If statements**

   ```go
   x := 10

   if x > 0 {
       fmt.Println("positive")
   } else if x < 0 {
       fmt.Println("negative")
   } else {
       fmt.Println("zero")
   }

   // With initialization
   if err := doSomething(); err != nil {
       fmt.Println(err)
   }
   ```

2. **For loops**

   ```go
   // Traditional
   for i := 0; i < 5; i++ {
       fmt.Println(i)
   }

   // While-style
   n := 0
   for n < 5 {
       fmt.Println(n)
       n++
   }

   // Infinite
   for {
       break // Exit
   }

   // Range
   nums := []int{1, 2, 3}
   for i, v := range nums {
       fmt.Printf("%d: %d\n", i, v)
   }
   ```

3. **Switch**

   ```go
   day := "Monday"

   switch day {
   case "Monday":
       fmt.Println("Start of week")
   case "Friday":
       fmt.Println("Almost weekend")
   default:
       fmt.Println("Regular day")
   }

   // No condition (like if-else chain)
   switch {
   case x < 0:
       fmt.Println("negative")
   case x > 0:
       fmt.Println("positive")
   default:
       fmt.Println("zero")
   }
   ```

4. **Defer**

   ```go
   func main() {
       defer fmt.Println("cleanup")  // Runs at function exit
       fmt.Println("working")
   }
   // Output: working, cleanup
   ```

### Checkpoint

Write a FizzBuzz program using a for loop and switch.

---

## Lesson 3: Collections

**Goal:** Work with arrays, slices, and maps.

### Exercises

1. **Arrays (fixed size)**

   ```go
   var arr [3]int           // [0, 0, 0]
   arr[0] = 1
   len(arr)                  // 3

   arr2 := [3]int{1, 2, 3}
   arr3 := [...]int{1, 2, 3} // Size inferred
   ```

2. **Slices (dynamic)**

   ```go
   // Create
   s := []int{1, 2, 3}
   s2 := make([]int, 3)     // [0, 0, 0]
   s3 := make([]int, 0, 10) // len=0, cap=10

   // Append
   s = append(s, 4, 5)

   // Slice operations
   s[1:3]    // [2, 3]
   s[:2]     // [1, 2]
   s[2:]     // [3, 4, 5]

   // Copy
   dst := make([]int, len(s))
   copy(dst, s)
   ```

3. **Maps**

   ```go
   // Create
   m := map[string]int{
       "alice": 30,
       "bob":   25,
   }
   m2 := make(map[string]int)

   // Access
   age := m["alice"]
   age, ok := m["unknown"] // ok = false if missing

   // Modify
   m["charlie"] = 35
   delete(m, "bob")

   // Iterate
   for key, value := range m {
       fmt.Printf("%s: %d\n", key, value)
   }
   ```

4. **Nil slices and maps**

   ```go
   var s []int          // nil, len=0, can append
   var m map[string]int // nil, cannot write (panic)

   m = make(map[string]int) // Now safe to write
   ```

### Checkpoint

Create a word frequency counter using a map.

---

## Lesson 4: Functions

**Goal:** Define functions and understand multiple returns.

### Exercises

1. **Basic functions**

   ```go
   func add(a int, b int) int {
       return a + b
   }

   // Same-type parameters
   func add2(a, b int) int {
       return a + b
   }
   ```

2. **Multiple return values**

   ```go
   func divide(a, b float64) (float64, error) {
       if b == 0 {
           return 0, errors.New("division by zero")
       }
       return a / b, nil
   }

   result, err := divide(10, 2)
   if err != nil {
       log.Fatal(err)
   }
   ```

3. **Named returns**

   ```go
   func split(sum int) (x, y int) {
       x = sum * 4 / 9
       y = sum - x
       return // Returns x and y
   }
   ```

4. **Variadic and closures**

   ```go
   // Variadic
   func sum(nums ...int) int {
       total := 0
       for _, n := range nums {
           total += n
       }
       return total
   }
   sum(1, 2, 3, 4) // 10

   // Closure
   func counter() func() int {
       count := 0
       return func() int {
           count++
           return count
       }
   }
   ```

### Checkpoint

Write a function that returns both the min and max of a slice.

---

## Lesson 5: Structs and Methods

**Goal:** Define types with methods.

### Exercises

1. **Structs**

   ```go
   type Person struct {
       Name string
       Age  int
   }

   // Create
   p1 := Person{Name: "Alice", Age: 30}
   p2 := Person{"Bob", 25}  // Positional
   p3 := new(Person)        // *Person, zero values

   // Access
   p1.Name = "Alicia"
   ```

2. **Methods**

   ```go
   type Rectangle struct {
       Width, Height float64
   }

   // Value receiver (copy)
   func (r Rectangle) Area() float64 {
       return r.Width * r.Height
   }

   // Pointer receiver (mutate)
   func (r *Rectangle) Scale(factor float64) {
       r.Width *= factor
       r.Height *= factor
   }

   rect := Rectangle{10, 5}
   rect.Area()        // 50
   rect.Scale(2)      // Now 20x10
   ```

3. **Embedding**

   ```go
   type Animal struct {
       Name string
   }

   func (a Animal) Speak() string {
       return "..."
   }

   type Dog struct {
       Animal  // Embedded
       Breed string
   }

   d := Dog{Animal{"Rex"}, "Labrador"}
   d.Name       // "Rex" (promoted field)
   d.Speak()    // "..." (promoted method)
   ```

4. **Struct tags**

   ```go
   type User struct {
       Name  string `json:"name"`
       Email string `json:"email,omitempty"`
   }
   ```

### Checkpoint

Create a `Stack` struct with Push and Pop methods.

---

## Lesson 6: Interfaces

**Goal:** Define behavior with interfaces.

### Concepts

Interfaces are satisfied implicitly. A type implements an interface by
implementing its methods.

### Exercises

1. **Define and implement**

   ```go
   type Speaker interface {
       Speak() string
   }

   type Dog struct{ Name string }

   func (d Dog) Speak() string {
       return "Woof!"
   }

   var s Speaker = Dog{"Rex"}
   s.Speak() // "Woof!"
   ```

2. **Empty interface**

   ```go
   func printAny(v interface{}) {
       fmt.Println(v)
   }

   // Or with any (Go 1.18+)
   func printAny2(v any) {
       fmt.Println(v)
   }
   ```

3. **Type assertions**

   ```go
   var i interface{} = "hello"

   s := i.(string)       // Panics if wrong type
   s, ok := i.(string)   // ok = false if wrong

   // Type switch
   switch v := i.(type) {
   case string:
       fmt.Println("string:", v)
   case int:
       fmt.Println("int:", v)
   default:
       fmt.Println("unknown")
   }
   ```

4. **Common interfaces**

   ```go
   // io.Reader
   type Reader interface {
       Read(p []byte) (n int, err error)
   }

   // io.Writer
   type Writer interface {
       Write(p []byte) (n int, err error)
   }

   // error
   type error interface {
       Error() string
   }
   ```

### Checkpoint

Define a `Shape` interface with `Area()` method. Implement for Circle and
Rectangle.

---

## Lesson 7: Concurrency

**Goal:** Use goroutines and channels.

### Exercises

1. **Goroutines**

   ```go
   func say(s string) {
       for i := 0; i < 3; i++ {
           fmt.Println(s)
           time.Sleep(100 * time.Millisecond)
       }
   }

   go say("hello")  // Runs concurrently
   say("world")     // Runs in main
   ```

2. **Channels**

   ```go
   ch := make(chan int)

   go func() {
       ch <- 42  // Send
   }()

   value := <-ch  // Receive (blocks)
   fmt.Println(value)

   // Buffered channel
   ch2 := make(chan int, 3)
   ```

3. **Select**

   ```go
   ch1 := make(chan string)
   ch2 := make(chan string)

   go func() { ch1 <- "one" }()
   go func() { ch2 <- "two" }()

   select {
   case msg := <-ch1:
       fmt.Println(msg)
   case msg := <-ch2:
       fmt.Println(msg)
   case <-time.After(1 * time.Second):
       fmt.Println("timeout")
   }
   ```

4. **WaitGroup**

   ```go
   var wg sync.WaitGroup

   for i := 0; i < 5; i++ {
       wg.Add(1)
       go func(n int) {
           defer wg.Done()
           fmt.Println(n)
       }(i)
   }

   wg.Wait()  // Block until all done
   ```

### Checkpoint

Create a worker pool with 3 workers processing jobs from a channel.

---

## Lesson 8: Error Handling and Testing

**Goal:** Handle errors idiomatically and write tests.

### Exercises

1. **Error handling**

   ```go
   func readFile(path string) ([]byte, error) {
       data, err := os.ReadFile(path)
       if err != nil {
           return nil, fmt.Errorf("reading %s: %w", path, err)
       }
       return data, nil
   }

   // Check error
   data, err := readFile("config.json")
   if err != nil {
       log.Fatal(err)
   }
   ```

2. **Custom errors**

   ```go
   type ValidationError struct {
       Field   string
       Message string
   }

   func (e ValidationError) Error() string {
       return fmt.Sprintf("%s: %s", e.Field, e.Message)
   }

   // errors.Is and errors.As
   if errors.Is(err, os.ErrNotExist) {
       // Handle missing file
   }

   var valErr ValidationError
   if errors.As(err, &valErr) {
       fmt.Println(valErr.Field)
   }
   ```

3. **Writing tests**

   ```go
   // add_test.go
   package main

   import "testing"

   func TestAdd(t *testing.T) {
       got := add(2, 3)
       want := 5
       if got != want {
           t.Errorf("add(2, 3) = %d; want %d", got, want)
       }
   }

   // Run: go test
   ```

4. **Table-driven tests**

   ```go
   func TestAdd(t *testing.T) {
       tests := []struct {
           a, b, want int
       }{
           {1, 2, 3},
           {0, 0, 0},
           {-1, 1, 0},
       }

       for _, tt := range tests {
           t.Run(fmt.Sprintf("%d+%d", tt.a, tt.b), func(t *testing.T) {
               got := add(tt.a, tt.b)
               if got != tt.want {
                   t.Errorf("got %d, want %d", got, tt.want)
               }
           })
       }
   }
   ```

### Checkpoint

Write a function with custom error type and table-driven tests.

---

## Practice Projects

### Project 1: CLI Tool

Build a command-line file utility:

- Use flag package for arguments
- Read/write files
- Handle errors gracefully

### Project 2: HTTP Server

Build a REST API:

- Use net/http
- JSON encoding/decoding
- Middleware pattern

### Project 3: Concurrent Fetcher

Fetch multiple URLs concurrently:

- Use goroutines and channels
- Implement timeout
- Aggregate results

---

## Quick Reference

| Stage        | Topics                                       |
| ------------ | -------------------------------------------- |
| Beginner     | Types, control flow, functions, collections  |
| Intermediate | Structs, methods, interfaces, error handling |
| Advanced     | Goroutines, channels, testing, reflection    |

## See Also

- [Testing](../how/testing.md) — Go test patterns
- [Problem Solving](../why/problem-solving.md) — Debugging techniques
