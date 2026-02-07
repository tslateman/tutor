# Python Lesson Plan

A progressive curriculum to master Python through hands-on practice.

## Lesson 1: First Steps

**Goal:** Run Python and understand basic types.

### Concepts

Python is dynamically typed and emphasizes readability. Indentation matters.

### Exercises

1. **Run Python interactively**

   ```bash
   python3
   >>> 2 + 2
   4
   >>> print("Hello, World!")
   Hello, World!
   >>> exit()
   ```

2. **Create and run a script**

   ```python
   # hello.py
   name = "Python"
   print(f"Hello, {name}!")
   ```

   ```bash
   python3 hello.py
   ```

3. **Explore basic types**

   ```python
   # Numbers
   x = 42          # int
   y = 3.14        # float
   z = 1 + 2j      # complex

   # Strings
   s = "hello"
   s.upper()       # 'HELLO'
   len(s)          # 5

   # Booleans
   flag = True
   not flag        # False
   ```

4. **Type checking**

   ```python
   type(42)        # <class 'int'>
   type("hello")   # <class 'str'>
   isinstance(42, int)  # True
   ```

### Checkpoint

Write a script that prints your name and age using f-strings.

---

## Lesson 2: Collections

**Goal:** Work with lists, dicts, sets, and tuples.

### Exercises

1. **Lists (ordered, mutable)**

   ```python
   nums = [1, 2, 3]
   nums.append(4)        # [1, 2, 3, 4]
   nums.insert(0, 0)     # [0, 1, 2, 3, 4]
   nums.pop()            # 4, list is now [0, 1, 2, 3]
   nums[1:3]             # [1, 2] (slicing)
   nums[-1]              # 3 (last element)
   ```

2. **Dictionaries (key-value)**

   ```python
   user = {"name": "Alice", "age": 30}
   user["name"]          # "Alice"
   user.get("email", "N/A")  # "N/A" (default)
   user["email"] = "a@b.com"
   "name" in user        # True

   for key, value in user.items():
       print(f"{key}: {value}")
   ```

3. **Sets (unique, unordered)**

   ```python
   a = {1, 2, 3}
   b = {2, 3, 4}
   a | b    # {1, 2, 3, 4} union
   a & b    # {2, 3} intersection
   a - b    # {1} difference
   ```

4. **Tuples (immutable)**

   ```python
   point = (3, 4)
   x, y = point          # Unpacking
   point[0]              # 3
   # point[0] = 5        # Error! Tuples are immutable
   ```

### Checkpoint

Create a dict of 3 people with names and ages. Print each person's info.

---

## Lesson 3: Control Flow

**Goal:** Use conditionals, loops, and comprehensions.

### Exercises

1. **Conditionals**

   ```python
   x = 10

   if x > 0:
       print("positive")
   elif x < 0:
       print("negative")
   else:
       print("zero")

   # Ternary
   result = "even" if x % 2 == 0 else "odd"
   ```

2. **Loops**

   ```python
   # For loop
   for i in range(5):      # 0, 1, 2, 3, 4
       print(i)

   for item in ["a", "b", "c"]:
       print(item)

   for i, item in enumerate(["a", "b", "c"]):
       print(f"{i}: {item}")

   # While loop
   n = 0
   while n < 5:
       print(n)
       n += 1
   ```

3. **List comprehensions**

   ```python
   # Basic
   squares = [x**2 for x in range(10)]

   # With filter
   evens = [x for x in range(10) if x % 2 == 0]

   # Dict comprehension
   square_map = {x: x**2 for x in range(5)}

   # Set comprehension
   unique_lengths = {len(word) for word in ["a", "bb", "ccc"]}
   ```

4. **Loop control**

   ```python
   for i in range(10):
       if i == 3:
           continue      # Skip this iteration
       if i == 7:
           break         # Exit loop
       print(i)
   ```

### Checkpoint

Use a list comprehension to create a list of squares of even numbers from 1-20.

---

## Lesson 4: Functions

**Goal:** Define and use functions effectively.

### Exercises

1. **Basic functions**

   ```python
   def greet(name):
       """Return a greeting string."""
       return f"Hello, {name}!"

   greet("Alice")        # "Hello, Alice!"
   ```

2. **Default and keyword arguments**

   ```python
   def greet(name, greeting="Hello"):
       return f"{greeting}, {name}!"

   greet("Bob")                    # "Hello, Bob!"
   greet("Bob", greeting="Hi")     # "Hi, Bob!"
   ```

3. **\*args and \*\*kwargs**

   ```python
   def sum_all(*args):
       return sum(args)

   sum_all(1, 2, 3, 4)   # 10

   def print_info(**kwargs):
       for key, value in kwargs.items():
           print(f"{key}: {value}")

   print_info(name="Alice", age=30)
   ```

4. **Lambda functions**

   ```python
   double = lambda x: x * 2
   double(5)             # 10

   # Common with sorted, map, filter
   names = ["Alice", "Bob", "Charlie"]
   sorted(names, key=lambda x: len(x))
   # ['Bob', 'Alice', 'Charlie']
   ```

### Checkpoint

Write a function that takes a list of numbers and returns only the positive
ones.

---

## Lesson 5: Classes

**Goal:** Define classes and understand OOP basics.

### Exercises

1. **Basic class**

   ```python
   class Dog:
       def __init__(self, name, age):
           self.name = name
           self.age = age

       def bark(self):
           return f"{self.name} says woof!"

   dog = Dog("Rex", 3)
   dog.bark()            # "Rex says woof!"
   ```

2. **Class methods and properties**

   ```python
   class Circle:
       def __init__(self, radius):
           self._radius = radius

       @property
       def radius(self):
           return self._radius

       @radius.setter
       def radius(self, value):
           if value < 0:
               raise ValueError("Radius must be positive")
           self._radius = value

       @property
       def area(self):
           return 3.14159 * self._radius ** 2
   ```

3. **Inheritance**

   ```python
   class Animal:
       def __init__(self, name):
           self.name = name

       def speak(self):
           raise NotImplementedError

   class Cat(Animal):
       def speak(self):
           return f"{self.name} says meow!"
   ```

4. **Dataclasses (Python 3.7+)**

   ```python
   from dataclasses import dataclass

   @dataclass
   class Point:
       x: float
       y: float

       def distance_from_origin(self):
           return (self.x**2 + self.y**2) ** 0.5

   p = Point(3, 4)
   p.distance_from_origin()  # 5.0
   ```

### Checkpoint

Create a `BankAccount` class with deposit, withdraw, and balance methods.

---

## Lesson 6: Error Handling

**Goal:** Handle exceptions gracefully.

### Exercises

1. **Try/except**

   ```python
   try:
       result = 10 / 0
   except ZeroDivisionError:
       print("Cannot divide by zero")
   ```

2. **Multiple exceptions**

   ```python
   try:
       value = int("abc")
   except ValueError:
       print("Invalid integer")
   except TypeError:
       print("Wrong type")
   except Exception as e:
       print(f"Unexpected error: {e}")
   ```

3. **Finally and else**

   ```python
   try:
       f = open("file.txt")
       data = f.read()
   except FileNotFoundError:
       print("File not found")
   else:
       print("File read successfully")
   finally:
       print("Cleanup here")
   ```

4. **Raising exceptions**

   ```python
   def divide(a, b):
       if b == 0:
           raise ValueError("Divisor cannot be zero")
       return a / b

   # Custom exceptions
   class ValidationError(Exception):
       pass
   ```

### Checkpoint

Write a function that reads a file and handles FileNotFoundError gracefully.

---

## Lesson 7: Modules and Packages

**Goal:** Organize code into modules.

### Exercises

1. **Import modules**

   ```python
   import math
   math.sqrt(16)         # 4.0

   from math import sqrt, pi
   sqrt(16)              # 4.0

   from math import sqrt as square_root
   square_root(16)       # 4.0
   ```

2. **Create a module**

   ```python
   # mymodule.py
   def greet(name):
       return f"Hello, {name}!"

   PI = 3.14159

   # main.py
   from mymodule import greet, PI
   ```

3. **Package structure**

   ```text
   mypackage/
   ├── __init__.py
   ├── utils.py
   └── models/
       ├── __init__.py
       └── user.py
   ```

   ```python
   from mypackage.utils import helper
   from mypackage.models.user import User
   ```

4. **Virtual environments**

   ```bash
   python3 -m venv venv
   source venv/bin/activate    # Unix
   venv\Scripts\activate       # Windows
   pip install requests
   pip freeze > requirements.txt
   ```

### Checkpoint

Create a package with two modules. Import functions from both in a main script.

---

## Lesson 8: Modern Python

**Goal:** Use type hints, context managers, and generators.

### Exercises

1. **Type hints**

   ```python
   def greet(name: str) -> str:
       return f"Hello, {name}!"

   from typing import List, Dict, Optional

   def process(items: List[int]) -> Dict[str, int]:
       return {"sum": sum(items), "count": len(items)}

   def find_user(id: int) -> Optional[str]:
       return None  # or a string
   ```

2. **Context managers**

   ```python
   # Using with statement
   with open("file.txt", "w") as f:
       f.write("Hello")

   # Custom context manager
   from contextlib import contextmanager

   @contextmanager
   def timer():
       import time
       start = time.time()
       yield
       print(f"Elapsed: {time.time() - start:.2f}s")

   with timer():
       # do work
       pass
   ```

3. **Generators**

   ```python
   def count_up(n):
       i = 0
       while i < n:
           yield i
           i += 1

   for num in count_up(5):
       print(num)

   # Generator expression
   squares = (x**2 for x in range(1000000))  # Lazy evaluation
   ```

4. **Async/await**

   ```python
   import asyncio

   async def fetch_data(url):
       await asyncio.sleep(1)  # Simulate network
       return f"Data from {url}"

   async def main():
       results = await asyncio.gather(
           fetch_data("url1"),
           fetch_data("url2"),
       )
       print(results)

   asyncio.run(main())
   ```

### Checkpoint

Write a generator that yields Fibonacci numbers. Use type hints.

---

## Practice Projects

### Project 1: CLI Tool

Build a command-line todo list:

- Add, remove, list tasks
- Save to JSON file
- Use argparse for commands

### Project 2: Web Scraper

Scrape a website:

- Use requests and BeautifulSoup
- Handle errors gracefully
- Save results to CSV

### Project 3: REST API

Build a simple API with FastAPI:

- CRUD operations
- Type hints and validation
- Async endpoints

---

## Quick Reference

| Stage        | Topics                                      |
| ------------ | ------------------------------------------- |
| Beginner     | Types, collections, control flow, functions |
| Intermediate | Classes, exceptions, modules, file I/O      |
| Advanced     | Type hints, generators, async, decorators   |

## See Also

- [Python Cheatsheet](../how/python.md) — Quick syntax reference
- [Testing](../how/testing.md) — pytest patterns
