# TypeScript Cheat Sheet

## Basic Types

```typescript
let isDone: boolean = false;
let count: number = 42;
let name: string = "hello";
let list: number[] = [1, 2, 3];
let tuple: [string, number] = ["hello", 10];
let anything: any = 4;
let unknown: unknown = 4; // Safer than any
let nothing: void = undefined;
let n: null = null;
let u: undefined = undefined;
let never: never; // Function that never returns
```

## Type Inference

```typescript
let x = 3; // inferred as number
const y = "hello"; // inferred as "hello" (literal type)
let arr = [1, 2, 3]; // inferred as number[]
```

## Interfaces & Types

```typescript
// Interface
interface User {
  readonly id: number;
  name: string;
  email?: string; // Optional
  [key: string]: unknown; // Index signature
}

// Type alias
type Point = {
  x: number;
  y: number;
};

// Union types
type Status = "pending" | "success" | "error";
type Result = string | number;

// Intersection types
type Admin = User & { permissions: string[] };

// Extending interfaces
interface Employee extends User {
  department: string;
}
```

## Functions

```typescript
// Typed function
function greet(name: string): string {
  return `Hello, ${name}`;
}

// Arrow function
const add = (a: number, b: number): number => a + b;

// Optional and default parameters
function log(msg: string, level: string = "info"): void {}

// Rest parameters
function sum(...numbers: number[]): number {
  return numbers.reduce((a, b) => a + b, 0);
}

// Function types
type Callback = (data: string) => void;
type AsyncFn = (id: number) => Promise<User>;

// Overloads
function parse(input: string): number;
function parse(input: number): string;
function parse(input: string | number): string | number {
  return typeof input === "string" ? parseInt(input) : input.toString();
}
```

## Generics

```typescript
// Generic function
function identity<T>(arg: T): T {
  return arg;
}

// Generic interface
interface Container<T> {
  value: T;
}

// Generic class
class Queue<T> {
  private items: T[] = [];
  enqueue(item: T): void {
    this.items.push(item);
  }
  dequeue(): T | undefined {
    return this.items.shift();
  }
}

// Generic constraints
function getLength<T extends { length: number }>(arg: T): number {
  return arg.length;
}

// Multiple type parameters
function map<T, U>(arr: T[], fn: (item: T) => U): U[] {
  return arr.map(fn);
}

// Default type parameters
interface Response<T = any> {
  data: T;
  status: number;
}
```

## Utility Types

```typescript
interface User {
  id: number;
  name: string;
  email: string;
}

Partial<User>; // All properties optional
Required<User>; // All properties required
Readonly<User>; // All properties readonly
Pick<User, "id" | "name">; // Only id and name
Omit<User, "email">; // Everything except email
Record<string, number>; // { [key: string]: number }
Exclude<"a" | "b", "a">; // "b"
Extract<"a" | "b", "a" | "c">; // "a"
NonNullable<string | null>; // string
ReturnType<typeof fn>; // Return type of function
Parameters<typeof fn>; // Tuple of parameter types
Awaited<Promise<string>>; // string
```

## Type Guards

```typescript
// typeof
function process(x: string | number) {
  if (typeof x === "string") {
    return x.toUpperCase();
  }
  return x * 2;
}

// instanceof
function handle(err: Error | string) {
  if (err instanceof Error) {
    return err.message;
  }
  return err;
}

// in operator
interface Cat {
  meow(): void;
}
interface Dog {
  bark(): void;
}

function speak(pet: Cat | Dog) {
  if ("meow" in pet) {
    pet.meow();
  } else {
    pet.bark();
  }
}

// Custom type guard
function isString(x: unknown): x is string {
  return typeof x === "string";
}
```

## Classes

```typescript
class Animal {
  private _name: string;
  protected age: number;
  public readonly species: string;
  static count = 0;

  constructor(name: string, age: number, species: string) {
    this._name = name;
    this.age = age;
    this.species = species;
    Animal.count++;
  }

  get name(): string {
    return this._name;
  }

  set name(value: string) {
    this._name = value;
  }

  speak(): void {
    console.log(`${this._name} makes a sound`);
  }
}

// Inheritance
class Dog extends Animal {
  constructor(name: string, age: number) {
    super(name, age, "dog");
  }

  override speak(): void {
    console.log(`${this.name} barks`);
  }
}

// Abstract class
abstract class Shape {
  abstract area(): number;
  describe(): string {
    return `Area: ${this.area()}`;
  }
}
```

## Enums

```typescript
// Numeric enum
enum Direction {
  Up, // 0
  Down, // 1
  Left, // 2
  Right, // 3
}

// String enum
enum Status {
  Pending = "PENDING",
  Success = "SUCCESS",
  Error = "ERROR",
}

// Const enum (inlined at compile time)
const enum Color {
  Red,
  Green,
  Blue,
}
```

## Mapped Types

```typescript
// Make all properties optional
type Optional<T> = {
  [P in keyof T]?: T[P];
};

// Make all properties nullable
type Nullable<T> = {
  [P in keyof T]: T[P] | null;
};

// Template literal types
type EventName<T extends string> = `on${Capitalize<T>}`;
type ClickEvent = EventName<"click">; // "onClick"
```

## Conditional Types

```typescript
type IsString<T> = T extends string ? true : false;

type Flatten<T> = T extends Array<infer U> ? U : T;
type Str = Flatten<string[]>; // string
type Num = Flatten<number>; // number

// Distributive conditional types
type ToArray<T> = T extends any ? T[] : never;
type StrOrNumArray = ToArray<string | number>; // string[] | number[]
```

## Module Patterns

```typescript
// Named exports
export const PI = 3.14;
export function add(a: number, b: number): number {
  return a + b;
}
export interface User {
  name: string;
}

// Default export
export default class MyClass {}

// Re-export
export { something } from "./module";
export * from "./module";
export * as utils from "./utils";

// Import types only
import type { User } from "./types";
```

## Assertion & Casting

```typescript
// Type assertion
const el = document.getElementById("app") as HTMLDivElement;
const el2 = <HTMLDivElement>document.getElementById("app");

// Non-null assertion
const value = maybeNull!;

// Const assertion
const config = { url: "/api", method: "GET" } as const;

// Satisfies (TS 4.9+)
const palette = {
  red: [255, 0, 0],
  green: "#00ff00",
} satisfies Record<string, string | number[]>;
```

## Common Patterns

```typescript
// Discriminated unions
type Result<T> = { success: true; data: T } | { success: false; error: string };

function handle<T>(result: Result<T>) {
  if (result.success) {
    return result.data;
  }
  throw new Error(result.error);
}

// Builder pattern with method chaining
class QueryBuilder {
  select(fields: string[]): this {
    return this;
  }
  where(condition: string): this {
    return this;
  }
  build(): string {
    return "";
  }
}

// Branded types
type UserId = string & { readonly brand: unique symbol };
function createUserId(id: string): UserId {
  return id as UserId;
}
```

## See Also

- [TypeScript Lesson Plan](../learn/typescript-lesson-plan.md) — 8 lessons from
  types to advanced patterns
- [Testing](testing.md) — Jest commands and patterns
- [Learning a Language](learning-a-language.md) — Phases, techniques,
  anti-patterns
