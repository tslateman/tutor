# Python Cheat Sheet

## Data Structures

### Lists

```python
lst = [1, 2, 3]
lst.append(4)           # Add to end
lst.insert(0, 0)        # Insert at index
lst.extend([5, 6])      # Add multiple
lst.pop()               # Remove last
lst.pop(0)              # Remove at index
lst.remove(3)           # Remove first occurrence
lst[1:3]                # Slice [2, 3]
lst[::-1]               # Reverse
sorted(lst, key=len)    # Sort with key
```

### Dictionaries

```python
d = {'a': 1, 'b': 2}
d.get('c', 0)           # Get with default
d.setdefault('c', 3)    # Set if missing
d.update({'d': 4})      # Merge
d.pop('a')              # Remove and return
d.keys(), d.values(), d.items()
{k: v for k, v in d.items() if v > 1}  # Comprehension
```

### Sets

```python
s = {1, 2, 3}
s.add(4)
s.discard(2)            # Remove if present (no error)
s.remove(3)             # Remove (raises KeyError if missing)
s1 | s2                 # Union
s1 & s2                 # Intersection
s1 - s2                 # Difference
s1 ^ s2                 # Symmetric difference
```

## Comprehensions

```python
[x**2 for x in range(10)]                    # List
{x: x**2 for x in range(10)}                 # Dict
{x for x in range(10)}                       # Set
(x**2 for x in range(10))                    # Generator
[x for x in items if x > 0]                  # Filter
[x if x > 0 else 0 for x in items]           # Conditional
```

## String Operations

```python
s = "hello world"
s.split()               # ['hello', 'world']
s.split(',')            # Split on delimiter
'-'.join(['a', 'b'])    # 'a-b'
s.strip()               # Remove whitespace
s.replace('o', '0')     # Replace
s.startswith('hello')
s.endswith('world')
f"value: {x:.2f}"       # f-string formatting
```

## File Operations

```python
# Reading
with open('file.txt', 'r') as f:
    content = f.read()          # Entire file
    lines = f.readlines()       # List of lines

# Writing
with open('file.txt', 'w') as f:
    f.write('text')
    f.writelines(['a\n', 'b\n'])

# JSON
import json
data = json.load(open('file.json'))
json.dump(data, open('out.json', 'w'), indent=2)
```

## Functions

```python
def func(a, b, *args, **kwargs):
    """Docstring"""
    return a + b

# Lambda
fn = lambda x, y: x + y

# Decorators
def decorator(func):
    def wrapper(*args, **kwargs):
        return func(*args, **kwargs)
    return wrapper

@decorator
def my_func():
    pass
```

## Classes

```python
class MyClass:
    class_var = 0

    def __init__(self, value):
        self.value = value

    def method(self):
        return self.value

    @classmethod
    def from_string(cls, s):
        return cls(int(s))

    @staticmethod
    def utility():
        pass

    @property
    def computed(self):
        return self.value * 2

# Dataclasses
from dataclasses import dataclass

@dataclass
class Point:
    x: float
    y: float
    z: float = 0.0
```

## Error Handling

```python
try:
    risky_operation()
except ValueError as e:
    print(f"Error: {e}")
except (TypeError, KeyError):
    pass
except Exception as e:
    raise RuntimeError("Failed") from e
else:
    print("Success")
finally:
    cleanup()
```

## Itertools & Functools

```python
from itertools import chain, groupby, islice, cycle, permutations, combinations
from functools import reduce, partial, lru_cache

chain([1,2], [3,4])                    # Flatten iterables
groupby(items, key=lambda x: x[0])     # Group by key
islice(iterable, 5, 10)                # Slice iterator
combinations('ABC', 2)                  # ('A','B'), ('A','C'), ('B','C')
permutations('ABC', 2)                  # All orderings

@lru_cache(maxsize=128)
def expensive(n):
    return n ** 2
```

## Collections

```python
from collections import defaultdict, Counter, deque, namedtuple

dd = defaultdict(list)
dd['key'].append(1)

counter = Counter(['a', 'a', 'b'])
counter.most_common(2)

dq = deque([1, 2, 3])
dq.appendleft(0)
dq.popleft()

Point = namedtuple('Point', ['x', 'y'])
```

## Type Hints

```python
from typing import List, Dict, Optional, Union, Callable, TypeVar, Generic

def greet(name: str) -> str:
    return f"Hello, {name}"

def process(items: List[int]) -> Dict[str, int]:
    pass

def maybe(x: Optional[str] = None) -> Union[str, int]:
    pass

T = TypeVar('T')
def first(items: List[T]) -> T:
    return items[0]
```

## Context Managers

```python
from contextlib import contextmanager

@contextmanager
def managed_resource():
    resource = acquire()
    try:
        yield resource
    finally:
        release(resource)

with managed_resource() as r:
    use(r)
```

## Async/Await

```python
import asyncio

async def fetch(url):
    await asyncio.sleep(1)
    return "data"

async def main():
    results = await asyncio.gather(
        fetch("url1"),
        fetch("url2"),
    )

asyncio.run(main())
```

## Common Patterns

```python
# Enumerate with index
for i, item in enumerate(items):
    print(i, item)

# Zip parallel iteration
for a, b in zip(list1, list2):
    print(a, b)

# Dict from two lists
dict(zip(keys, values))

# Flatten nested list
[x for sublist in nested for x in sublist]

# Get or create pattern
value = cache.setdefault(key, compute_value())

# Safe dictionary access
value = data.get('key', {}).get('nested', default)
```
