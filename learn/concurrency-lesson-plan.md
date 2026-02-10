# Concurrency Lesson Plan

A progressive curriculum to master concurrency patterns through hands-on
practice.

## Lesson 1: Processes, Threads, and Coroutines

**Goal:** Distinguish concurrency from parallelism and understand the three main
execution models.

### Concepts

Concurrency means dealing with multiple things at once; parallelism means doing
multiple things at once. A web server handling 10,000 connections on one core is
concurrent but not parallel. Three primitives underpin every model: OS threads
(kernel-scheduled, ~8 MB stack), green threads (runtime-scheduled, lightweight),
and coroutines (compiler-transformed state machines that suspend and resume). Go
goroutines are green threads on OS threads. Python `asyncio` uses a
single-threaded event loop. Rust `async` compiles to state machines driven by
tokio.

### Exercises

1. **Spawn threads in Python, Go, and Rust**

   ```python
   import threading, time
   def worker(name):
       print(f"[{name}] started"); time.sleep(0.5); print(f"[{name}] done")
   threads = [threading.Thread(target=worker, args=(f"t-{i}",)) for i in range(4)]
   for t in threads: t.start()
   for t in threads: t.join()
   ```

   ```go
   package main
   import ("fmt"; "sync"; "time")
   func main() {
       var wg sync.WaitGroup
       for i := range 4 {
           wg.Add(1)
           go func() {
               defer wg.Done()
               fmt.Printf("[g-%d] started\n", i)
               time.Sleep(500 * time.Millisecond)
               fmt.Printf("[g-%d] done\n", i)
           }()
       }
       wg.Wait()
   }
   ```

   ```rust
   use std::thread;
   use std::time::Duration;
   fn main() {
       let handles: Vec<_> = (0..4).map(|i| {
           thread::spawn(move || {
               println!("[t-{i}] started");
               thread::sleep(Duration::from_millis(500));
               println!("[t-{i}] done");
           })
       }).collect();
       for h in handles { h.join().unwrap(); }
   }
   ```

2. **Measure thread cost**

   ```python
   import threading, time, resource
   baseline = resource.getrusage(resource.RUSAGE_SELF).ru_maxrss
   ts = [threading.Thread(target=lambda: time.sleep(30)) for _ in range(100)]
   for t in ts: t.start()
   after = resource.getrusage(resource.RUSAGE_SELF).ru_maxrss
   print(f"100 threads: ~{(after - baseline) / 100:.0f} KB each")
   ```

### Checkpoint

Spawn 1,000 concurrent tasks (each sleeping 100ms) in Python and Go. Measure
wall-clock time. Explain why Go finishes easily while Python may struggle.

---

## Lesson 2: Shared State and Mutexes

**Goal:** Understand data races and how mutexes prevent them across languages.

### Concepts

A data race occurs when two threads access the same memory, at least one writes,
and there is no synchronization. A mutex ensures only one thread enters a
critical section at a time. Python's `threading.Lock`, Go's `sync.Mutex`, and
Rust's `Mutex<T>` all serve this purpose. Rust uniquely enforces it at compile
time: you cannot access the inner value without holding the lock.

### Exercises

1. **Demonstrate a data race in Python**

   ```python
   # race.py -- run several times, result varies
   import threading
   counter = 0
   def inc():
       global counter
       for _ in range(100_000): counter += 1  # NOT atomic
   threads = [threading.Thread(target=inc) for _ in range(4)]
   for t in threads: t.start()
   for t in threads: t.join()
   print(f"Expected 400000, got {counter}")
   ```

2. **Fix with a Lock (Python) and Mutex (Go)**

   ```python
   # race_fixed.py
   import threading
   counter, lock = 0, threading.Lock()
   def inc():
       global counter
       for _ in range(100_000):
           with lock: counter += 1
   threads = [threading.Thread(target=inc) for _ in range(4)]
   for t in threads: t.start()
   for t in threads: t.join()
   print(f"Got {counter}")  # Always 400000
   ```

   ```go
   // race.go -- run with: go run -race race.go
   package main
   import ("fmt"; "sync")
   func main() {
       counter := 0
       var mu sync.Mutex
       var wg sync.WaitGroup
       for range 4 {
           wg.Add(1)
           go func() {
               defer wg.Done()
               for range 100_000 { mu.Lock(); counter++; mu.Unlock() }
           }()
       }
       wg.Wait()
       fmt.Println("Got:", counter)
   }
   ```

3. **Rust prevents races at compile time**

   ```rust
   use std::sync::{Arc, Mutex};
   use std::thread;
   fn main() {
       let counter = Arc::new(Mutex::new(0));
       let handles: Vec<_> = (0..4).map(|_| {
           let c = Arc::clone(&counter);
           thread::spawn(move || {
               for _ in 0..100_000 { *c.lock().unwrap() += 1; }
           })
       }).collect();
       for h in handles { h.join().unwrap(); }
       println!("Got: {}", *counter.lock().unwrap());
       // Remove Mutex wrapper -- compiler refuses to compile
   }
   ```

### Checkpoint

Write a Go program with a deliberate data race. Run with `go run -race` and read
the detector output. Fix with `sync.Mutex` and confirm silence.

---

## Lesson 3: Message Passing and Channels

**Goal:** Replace shared memory with message passing -- the model favored by Go
and Rust.

### Concepts

"Don't communicate by sharing memory; share memory by communicating." Channels
create a typed conduit between goroutines or threads. Unbuffered channels
synchronize at each exchange; buffered channels decouple up to the buffer size.
Fan-out/fan-in distributes work through one channel and collects results through
another. Python's `queue.Queue` provides the same semantics. CSP (Communicating
Sequential Processes) guarantees channel-only communication prevents data races.

### Exercises

1. **Go channels and Rust mpsc**

   ```go
   // channels.go
   package main
   import "fmt"
   func main() {
       ch := make(chan string)
       go func() { ch <- "hello from goroutine" }()
       fmt.Println(<-ch)

       buf := make(chan int, 3) // buffered
       buf <- 1; buf <- 2; buf <- 3
       fmt.Println(<-buf, <-buf, <-buf)
   }
   ```

   ```rust
   use std::sync::mpsc;
   use std::thread;
   fn main() {
       let (tx, rx) = mpsc::channel();
       thread::spawn(move || {
           for msg in ["hello", "from", "thread"] {
               tx.send(msg.to_string()).unwrap();
           }
       });
       for received in rx { println!("Got: {received}"); }
   }
   ```

2. **Python queue.Queue for thread communication**

   ```python
   import queue, threading, time
   q = queue.Queue()
   def producer():
       for i in range(5):
           q.put(f"item-{i}"); time.sleep(0.1)
       q.put(None)
   def consumer():
       while (item := q.get()) is not None:
           print(f"Consumed {item}")
   threading.Thread(target=producer).start()
   threading.Thread(target=consumer).start()
   ```

3. **Fan-out / fan-in in Go**

   ```go
   package main
   import ("fmt"; "sync"; "math/rand"; "time")
   func worker(id int, jobs <-chan int, out chan<- string, wg *sync.WaitGroup) {
       defer wg.Done()
       for j := range jobs {
           time.Sleep(time.Duration(rand.Intn(100)) * time.Millisecond)
           out <- fmt.Sprintf("w%d did job %d", id, j)
       }
   }
   func main() {
       jobs, results := make(chan int, 20), make(chan string, 20)
       var wg sync.WaitGroup
       for w := range 3 { wg.Add(1); go worker(w, jobs, results, &wg) }
       for j := range 10 { jobs <- j }
       close(jobs)
       go func() { wg.Wait(); close(results) }()
       for r := range results { fmt.Println(r) }
   }
   ```

### Checkpoint

Rewrite fan-out/fan-in in Rust: three `mpsc::channel` sender clones, five
messages each, one receiver collecting all fifteen.

---

## Lesson 4: Async/Await

**Goal:** Understand cooperative concurrency and know when async beats threads.

### Concepts

Async/await writes concurrent code that looks sequential. When a coroutine hits
`await`, it yields so the event loop can run other tasks -- ideal for I/O-bound
work. CPU-bound work blocks the loop, starving everything else. Python's
`asyncio`, Rust's `tokio`, and JavaScript's event loop all follow this pattern.
The insight: async waits efficiently; it does not compute faster.

### Exercises

1. **Python asyncio -- sequential vs concurrent**

   ```python
   import asyncio, time
   async def fetch(name, delay):
       print(f"[{name}] start"); await asyncio.sleep(delay); return name

   async def main():
       start = time.time()
       await fetch("A", 1); await fetch("B", 2)
       print(f"Sequential: {time.time()-start:.1f}s")

       start = time.time()
       await asyncio.gather(fetch("A", 1), fetch("B", 2))
       print(f"Concurrent: {time.time()-start:.1f}s")  # ~2s, not 3s
   asyncio.run(main())
   ```

2. **Rust tokio -- same pattern**

   ```rust
   // Cargo.toml: tokio = { version = "1", features = ["full"] }
   use tokio::time::{sleep, Duration, Instant};
   async fn fetch(name: &str, ms: u64) -> String {
       println!("[{name}] start");
       sleep(Duration::from_millis(ms)).await;
       format!("{name}-result")
   }
   #[tokio::main]
   async fn main() {
       let s = Instant::now();
       fetch("A", 500).await; fetch("B", 1000).await;
       println!("Sequential: {:?}", s.elapsed());
       let s = Instant::now();
       tokio::join!(fetch("A", 500), fetch("B", 1000));
       println!("Concurrent: {:?}", s.elapsed());
   }
   ```

3. **When async hurts: CPU-bound work**

   ```python
   import asyncio, time
   def fib(n): return n if n < 2 else fib(n-1) + fib(n-2)
   async def main():
       loop = asyncio.get_event_loop()
       # Blocks the loop -- sequential despite concurrent intent
       start = time.time()
       results = [fib(35) for _ in range(3)]
       print(f"Single-threaded: {time.time()-start:.1f}s")
       # Fix: offload to thread pool
       start = time.time()
       await asyncio.gather(*[loop.run_in_executor(None, fib, 35) for _ in range(3)])
       print(f"Executor (parallel): {time.time()-start:.1f}s")
   asyncio.run(main())
   ```

### Checkpoint

Fetch five URLs concurrently with `asyncio` + `run_in_executor`. Print status
codes as they arrive. Compare total time to a sequential version.

---

## Lesson 5: Synchronization Primitives

**Goal:** Master semaphores, barriers, condition variables, and read-write
locks.

### Concepts

A semaphore allows N concurrent holders -- limit parallelism (e.g., 5 DB
connections). A condition variable lets a thread sleep until a predicate is true
-- the backbone of producer-consumer. A read-write lock allows many readers but
exclusive writers. Go's `errgroup` combines WaitGroup with error propagation.
Each primitive solves a specific problem; the wrong one causes contention.

### Exercises

1. **Semaphore in Python**

   ```python
   import threading, time
   sem = threading.Semaphore(3)
   def limited(name):
       with sem:
           print(f"[{name}] working"); time.sleep(1)
   threads = [threading.Thread(target=limited, args=(f"w-{i}",)) for i in range(8)]
   for t in threads: t.start()
   for t in threads: t.join()
   # Only 3 run concurrently
   ```

2. **Producer-consumer with condition variable**

   ```python
   import threading, collections
   buf, cond, done = collections.deque(), threading.Condition(), [False]
   def producer():
       for i in range(10):
           with cond:
               while len(buf) >= 5: cond.wait()
               buf.append(i); print(f"Produced {i}"); cond.notify()
       with cond: done[0] = True; cond.notify_all()
   def consumer(name):
       while True:
           with cond:
               while not buf and not done[0]: cond.wait()
               if not buf and done[0]: break
               print(f"  [{name}] consumed {buf.popleft()}"); cond.notify()
   threading.Thread(target=producer).start()
   for i in range(2): threading.Thread(target=consumer, args=(f"c-{i}",)).start()
   ```

3. **Read-write lock in Rust**

   ```rust
   use std::sync::{Arc, RwLock};
   use std::thread;
   fn main() {
       let data = Arc::new(RwLock::new(vec![1, 2, 3]));
       let mut hs = vec![];
       for i in 0..5 { // 5 concurrent readers
           let d = Arc::clone(&data);
           hs.push(thread::spawn(move || println!("[reader-{i}] {:?}", *d.read().unwrap())));
       }
       let d = Arc::clone(&data); // 1 exclusive writer
       hs.push(thread::spawn(move || { d.write().unwrap().push(4); }));
       for h in hs { h.join().unwrap(); }
   }
   ```

4. **Go errgroup for concurrent error handling**

   ```go
   package main
   import ("fmt"; "math/rand"; "time"; "golang.org/x/sync/errgroup")
   func main() {
       var g errgroup.Group
       for _, u := range []string{"/a", "/b", "/c", "/d"} {
           g.Go(func() error {
               time.Sleep(time.Duration(rand.Intn(500)) * time.Millisecond)
               if rand.Float64() < 0.3 { return fmt.Errorf("failed %s", u) }
               fmt.Printf("Fetched %s\n", u); return nil
           })
       }
       if err := g.Wait(); err != nil { fmt.Println("Error:", err) }
   }
   ```

### Checkpoint

Write a producer-consumer in Go: one producer sends 20 items into a buffered
channel, three consumers read. Use `sync.WaitGroup`. Print which consumer
processed each item.

---

## Lesson 6: Common Bugs

**Goal:** Recognize deadlock, livelock, starvation, and priority inversion.

### Concepts

A deadlock occurs when threads each hold a resource the other needs. A livelock
is similar but threads keep changing state without progress. Starvation means a
thread never runs. Priority inversion: a high-priority thread waits on a lock
held by a low-priority thread preempted by a medium-priority one. Prevention:
consistent lock ordering, timeouts, `try_lock`, or channels instead of locks.

### Exercises

1. **Deadlock in Python -- demonstrate and fix**

   ```python
   import threading, time
   a, b = threading.Lock(), threading.Lock()
   def w1(): a.acquire(); time.sleep(0.1); b.acquire()  # holds a, wants b
   def w2(): b.acquire(); time.sleep(0.1); a.acquire()  # holds b, wants a
   t1, t2 = threading.Thread(target=w1), threading.Thread(target=w2)
   t1.start(); t2.start()
   t1.join(timeout=3); t2.join(timeout=3)
   if t1.is_alive(): print("DEADLOCK -- threads still alive")
   # Fix: both acquire a first, then b -- consistent ordering eliminates the cycle
   ```

2. **Go runtime detects all-goroutine deadlock**

   ```go
   package main
   import ("fmt"; "sync"; "time")
   func main() {
       var muA, muB sync.Mutex
       go func() { muA.Lock(); time.Sleep(100*time.Millisecond); muB.Lock() }()
       go func() { muB.Lock(); time.Sleep(100*time.Millisecond); muA.Lock() }()
       time.Sleep(3 * time.Second)
       fmt.Println("If you see this, no deadlock (unlikely)")
   }
   ```

3. **Try-lock to avoid deadlock (Rust)**

   ```rust
   use std::sync::{Arc, Mutex};
   use std::thread;
   use std::time::Duration;
   fn try_both(first: &Mutex<&str>, second: &Mutex<&str>, id: u8) {
       for attempt in 0..10 {
           let g1 = first.lock().unwrap();
           if let Ok(g2) = second.try_lock() {
               println!("[{id}] got {} and {}", *g1, *g2); return;
           }
           drop(g1); thread::sleep(Duration::from_millis(10));
           println!("[{id}] attempt {attempt}: retry");
       }
   }
   fn main() {
       let a = Arc::new(Mutex::new("A"));
       let b = Arc::new(Mutex::new("B"));
       let (a1, b1) = (Arc::clone(&a), Arc::clone(&b));
       let h1 = thread::spawn(move || try_both(&a1, &b1, 1));
       let (a2, b2) = (Arc::clone(&a), Arc::clone(&b));
       let h2 = thread::spawn(move || try_both(&b2, &a2, 2));
       h1.join().unwrap(); h2.join().unwrap();
   }
   ```

### Checkpoint

Create three threads with three locks where deadlock is possible. Demonstrate
the hang. Apply lock ordering to eliminate the cycle.

---

## Lesson 7: Patterns and Architectures

**Goal:** Learn worker pools, pipelines, actors, and event loops -- and when to
use each.

### Concepts

A worker pool bounds concurrency: fixed goroutines/threads pull from a shared
queue. A pipeline chains stages via channels; backpressure propagates through
bounded buffers. The actor model (Erlang, Akka) gives each entity a private
mailbox -- no shared memory. Thread-per-request is simple but expensive; event
loops multiplex thousands of connections on one thread; Go combines goroutines
with work-stealing across OS threads.

### Exercises

1. **Worker pool in Go** (bounded concurrency via fixed goroutine count)

   ```go
   package main
   import ("fmt"; "sync"; "math/rand"; "time")
   func main() {
       jobs, results := make(chan int, 12), make(chan string, 12)
       var wg sync.WaitGroup
       for w := range 3 {
           wg.Add(1)
           go func() { defer wg.Done()
               for j := range jobs {
                   time.Sleep(time.Duration(rand.Intn(200)) * time.Millisecond)
                   results <- fmt.Sprintf("w%d: job %d", w, j)
               }
           }()
       }
       for j := range 12 { jobs <- j }; close(jobs)
       go func() { wg.Wait(); close(results) }()
       for r := range results { fmt.Println(r) }
   }
   ```

2. **Pipeline in Python with backpressure**

   ```python
   import threading, queue
   def stage(name, in_q, out_q, fn):
       while (item := in_q.get()) is not None:
           out_q.put(fn(item)); print(f"[{name}] {item} -> {fn(item)}")
       out_q.put(None)
   q1, q2, q3 = (queue.Queue(maxsize=3) for _ in range(3))
   threading.Thread(target=stage, args=("upper", q1, q2, str.upper)).start()
   threading.Thread(target=stage, args=("rev", q2, q3, lambda s: s[::-1])).start()
   for w in ["hello", "world", "pipeline"]: q1.put(w)
   q1.put(None)
   while (r := q3.get()) is not None: print(f"[out] {r}")
   ```

3. **Actor pattern in Rust**

   ```rust
   use std::sync::mpsc;
   use std::thread;
   enum Msg { Inc(i32), Get(mpsc::Sender<i32>), Stop }
   fn actor(rx: mpsc::Receiver<Msg>) {
       let mut count = 0;
       for msg in rx { match msg {
           Msg::Inc(n) => count += n,
           Msg::Get(tx) => { tx.send(count).unwrap(); }
           Msg::Stop => break,
       }}
   }
   fn main() {
       let (tx, rx) = mpsc::channel();
       thread::spawn(move || actor(rx));
       // 5 threads each send 100 increments
       let hs: Vec<_> = (0..5).map(|_| {
           let tx = tx.clone();
           thread::spawn(move || (0..100).for_each(|_| { tx.send(Msg::Inc(1)).unwrap(); }))
       }).collect();
       for h in hs { h.join().unwrap(); }
       let (rtx, rrx) = mpsc::channel();
       tx.send(Msg::Get(rtx)).unwrap();
       println!("Count: {}", rrx.recv().unwrap()); // 500
       tx.send(Msg::Stop).unwrap();
   }
   ```

### Checkpoint

Build a three-stage Go pipeline: generate 1-20, square each, sum all squares.
Each stage is a goroutine with channels. Print the final sum (2870).

---

## Lesson 8: Integration -- Building a Concurrent System

**Goal:** Combine channels, mutexes, worker pools, and graceful shutdown into a
complete system with proper testing.

### Concepts

Real systems combine primitives: a crawler needs a worker pool, channels, a
mutex for the visited set, and graceful shutdown. Testing concurrent code is
hard because bugs are non-deterministic. Go's race detector instruments memory
accesses at runtime. Rust catches data races at compile time but logic races
still need testing. Run tests many times, under load, with detectors enabled.

### Exercises

1. **Concurrent crawler with graceful shutdown (Go)**

   ```go
   package main
   import ("context"; "fmt"; "sync"; "time"; "math/rand")
   func main() {
       ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
       defer cancel()
       var mu sync.Mutex
       visited := map[string]bool{}
       urls, results := make(chan string, 20), make(chan string, 50)
       var wg sync.WaitGroup
       for w := range 3 {
           wg.Add(1)
           go func() {
               defer wg.Done()
               for { select {
               case <-ctx.Done(): return
               case url, ok := <-urls:
                   if !ok { return }
                   mu.Lock(); seen := visited[url]; visited[url] = true; mu.Unlock()
                   if !seen {
                       time.Sleep(time.Duration(rand.Intn(100))*time.Millisecond)
                       results <- fmt.Sprintf("w%d: %s", w, url)
                   }
               }}
           }()
       }
       go func() { for i := range 20 { urls <- fmt.Sprintf("/page/%d", i) }; close(urls) }()
       go func() { wg.Wait(); close(results) }()
       for r := range results { fmt.Println(r) }
   }
   // Run: go run -race crawler.go
   ```

2. **Graceful shutdown in Python**

   ```python
   import threading, queue, signal, time
   tasks, stop = queue.Queue(), threading.Event()
   def worker(name):
       while not stop.is_set():
           try: task = tasks.get(timeout=0.5); print(f"[{name}] {task}"); tasks.task_done()
           except queue.Empty: continue
   signal.signal(signal.SIGINT, lambda *_: (print("\nDraining..."), stop.set()))
   for i in range(3): threading.Thread(target=worker, args=(f"w-{i}",), daemon=True).start()
   for i in range(20): tasks.put(f"task-{i}")
   tasks.join(); stop.set(); print("Clean shutdown")
   ```

3. **Testing and stress-testing concurrent code**

   ```go
   // counter_test.go -- run: go test -race -count=100
   package main
   import ("sync"; "testing")
   type SafeCounter struct { mu sync.Mutex; n int }
   func (c *SafeCounter) Inc()       { c.mu.Lock(); c.n++; c.mu.Unlock() }
   func (c *SafeCounter) Value() int { c.mu.Lock(); defer c.mu.Unlock(); return c.n }
   func TestConcurrentInc(t *testing.T) {
       c := &SafeCounter{}
       var wg sync.WaitGroup
       for range 1000 { wg.Add(1); go func() { defer wg.Done(); c.Inc() }() }
       wg.Wait()
       if c.Value() != 1000 { t.Errorf("got %d", c.Value()) }
   }
   ```

   ```bash
   go test -race -count=100 ./...          # Go: repeat with race detector
   for i in $(seq 1 50); do python3 race.py; done | sort | uniq -c  # Python
   cargo test && cargo test --release      # Rust: debug + release
   ```

### Checkpoint

Extend the Go crawler to write results to a file. Handle `SIGINT` to cancel the
context, drain workers, and close the file cleanly. Run with `-race` and confirm
no races.

---

## Practice Projects

### Project 1: Concurrent Web Scraper

Breadth-first crawler in Go or Python: 5 bounded workers, thread-safe visited
set, rate limiting (2 req/s/domain), graceful `SIGINT` shutdown.

### Project 2: Chat Server with Channels

TCP chat server in Go: each client is a goroutine, channels for broadcast.
Support `/nick`, `/list`, `/quit`. Disconnect idle clients after 5 minutes.

### Project 3: Pipeline Processor with Backpressure

Three-stage file pipeline (read, transform, write) with bounded queues. Measure
throughput vs buffer size and worker count. Implement in Python and Go, compare.

---

## Quick Reference

| Pattern             | Go                       | Python                | Rust                      |
| ------------------- | ------------------------ | --------------------- | ------------------------- |
| Spawn thread        | `go func()`              | `threading.Thread`    | `thread::spawn`           |
| Mutex               | `sync.Mutex`             | `threading.Lock`      | `Mutex<T>`                |
| Read-write lock     | `sync.RWMutex`           | N/A (use Lock)        | `RwLock<T>`               |
| Channel             | `chan T`                 | `queue.Queue`         | `mpsc::channel`           |
| Semaphore           | Buffered `chan struct{}` | `threading.Semaphore` | `tokio::sync::Semaphore`  |
| Wait for completion | `sync.WaitGroup`         | `thread.join()`       | `handle.join()`           |
| Async/await         | N/A (goroutines)         | `asyncio`             | `async`/`await` + `tokio` |
| Race detection      | `go run -race`           | N/A (manual)          | Compile-time (ownership)  |
| Graceful shutdown   | `context.WithCancel`     | `threading.Event`     | `tokio::signal` + select  |
| Bounded concurrency | Channel + worker pool    | `concurrent.futures`  | `tokio::sync::Semaphore`  |

## See Also

- [Go Lesson Plan](golang-lesson-plan.md) -- Goroutines, channels, and Go's
  concurrency model in depth
- [Python Lesson Plan](python-lesson-plan.md) -- Threading, asyncio, and the GIL
- [Rust Lesson Plan](rust-lesson-plan.md) -- Ownership model that prevents data
  races at compile time
- [Operating Systems Lesson Plan](operating-systems-lesson-plan.md) --
  Processes, threads, and scheduling at the OS level
- [System Design Lesson Plan](system-design-lesson-plan.md) -- Concurrency
  patterns applied to distributed systems
