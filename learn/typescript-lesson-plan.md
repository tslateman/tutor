# TypeScript Lesson Plan

A progressive curriculum to master TypeScript through hands-on practice.

## Lesson 1: First Steps

**Goal:** Set up TypeScript and understand basic types.

### Concepts

TypeScript adds static types to JavaScript. Types catch errors at compile time,
not runtime.

### Exercises

1. **Setup and run**

   ```bash
   npm init -y
   npm install -D typescript
   npx tsc --init
   ```

   ```typescript
   // hello.ts
   const greeting: string = "Hello, TypeScript!";
   console.log(greeting);
   ```

   ```bash
   npx tsc hello.ts
   node hello.js
   ```

2. **Basic types**

   ```typescript
   // Primitives
   let name: string = "Alice";
   let age: number = 30;
   let active: boolean = true;

   // Arrays
   let nums: number[] = [1, 2, 3];
   let names: Array<string> = ["a", "b"];

   // Tuple
   let point: [number, number] = [10, 20];

   // Any (escape hatch)
   let anything: any = "could be anything";
   ```

3. **Type inference**

   ```typescript
   // TypeScript infers types
   let x = 10; // number
   let s = "hello"; // string

   // Function return type inferred
   function add(a: number, b: number) {
     return a + b; // Returns number
   }
   ```

4. **Type annotations**

   ```typescript
   // Variables
   let count: number;
   count = 42;

   // Functions
   function greet(name: string): string {
     return `Hello, ${name}!`;
   }

   // Arrow functions
   const double = (n: number): number => n * 2;
   ```

### Checkpoint

Write a function that takes a name and age and returns a formatted greeting.

---

## Lesson 2: Objects and Interfaces

**Goal:** Define object shapes with interfaces.

### Exercises

1. **Object types**

   ```typescript
   // Inline object type
   let user: { name: string; age: number } = {
     name: "Alice",
     age: 30,
   };

   // Optional properties
   let config: { host: string; port?: number } = {
     host: "localhost",
   };
   ```

2. **Interfaces**

   ```typescript
   interface User {
     name: string;
     age: number;
     email?: string; // Optional
     readonly id: number; // Cannot modify
   }

   const user: User = {
     id: 1,
     name: "Alice",
     age: 30,
   };
   ```

3. **Extending interfaces**

   ```typescript
   interface Animal {
     name: string;
   }

   interface Dog extends Animal {
     breed: string;
   }

   const dog: Dog = {
     name: "Rex",
     breed: "Labrador",
   };
   ```

4. **Index signatures**

   ```typescript
   interface Dictionary {
     [key: string]: string;
   }

   const dict: Dictionary = {
     hello: "world",
     foo: "bar",
   };
   ```

### Checkpoint

Define an interface for a blog post with title, content, author, and optional
tags.

---

## Lesson 3: Union and Literal Types

**Goal:** Create flexible yet precise types.

### Exercises

1. **Union types**

   ```typescript
   let id: string | number;
   id = "abc";
   id = 123;

   function printId(id: string | number) {
     if (typeof id === "string") {
       console.log(id.toUpperCase());
     } else {
       console.log(id);
     }
   }
   ```

2. **Literal types**

   ```typescript
   type Direction = "north" | "south" | "east" | "west";

   function move(dir: Direction) {
     console.log(`Moving ${dir}`);
   }

   move("north"); // OK
   // move("up");  // Error!
   ```

3. **Discriminated unions**

   ```typescript
   interface Circle {
     kind: "circle";
     radius: number;
   }

   interface Square {
     kind: "square";
     size: number;
   }

   type Shape = Circle | Square;

   function area(shape: Shape): number {
     switch (shape.kind) {
       case "circle":
         return Math.PI * shape.radius ** 2;
       case "square":
         return shape.size ** 2;
     }
   }
   ```

4. **Narrowing**

   ```typescript
   function process(value: string | string[] | null) {
     if (value === null) {
       return "nothing";
     }
     if (Array.isArray(value)) {
       return value.join(", ");
     }
     return value.toUpperCase();
   }
   ```

### Checkpoint

Create a type for API responses that can be success (with data) or error (with
message).

---

## Lesson 4: Functions

**Goal:** Type functions precisely.

### Exercises

1. **Function types**

   ```typescript
   // Function type
   type MathOp = (a: number, b: number) => number;

   const add: MathOp = (a, b) => a + b;
   const multiply: MathOp = (a, b) => a * b;
   ```

2. **Optional and default parameters**

   ```typescript
   function greet(name: string, greeting: string = "Hello"): string {
     return `${greeting}, ${name}!`;
   }

   function log(message: string, userId?: number): void {
     console.log(message, userId ?? "anonymous");
   }
   ```

3. **Rest parameters**

   ```typescript
   function sum(...nums: number[]): number {
     return nums.reduce((a, b) => a + b, 0);
   }

   sum(1, 2, 3, 4); // 10
   ```

4. **Overloads**

   ```typescript
   function parse(input: string): string[];
   function parse(input: string[]): string;
   function parse(input: string | string[]): string | string[] {
     if (typeof input === "string") {
       return input.split(",");
     }
     return input.join(",");
   }
   ```

### Checkpoint

Create a typed event handler function that accepts different event types.

---

## Lesson 5: Generics

**Goal:** Write reusable, type-safe code.

### Exercises

1. **Generic functions**

   ```typescript
   function identity<T>(value: T): T {
     return value;
   }

   identity<string>("hello"); // Explicit
   identity(42); // Inferred as number
   ```

2. **Generic interfaces**

   ```typescript
   interface Box<T> {
     value: T;
   }

   const stringBox: Box<string> = { value: "hello" };
   const numberBox: Box<number> = { value: 42 };

   interface Result<T, E> {
     data?: T;
     error?: E;
   }
   ```

3. **Generic constraints**

   ```typescript
   interface HasLength {
     length: number;
   }

   function logLength<T extends HasLength>(item: T): void {
     console.log(item.length);
   }

   logLength("hello"); // OK
   logLength([1, 2, 3]); // OK
   // logLength(42);    // Error: number has no length
   ```

4. **Generic with keyof**

   ```typescript
   function getProperty<T, K extends keyof T>(obj: T, key: K): T[K] {
     return obj[key];
   }

   const user = { name: "Alice", age: 30 };
   getProperty(user, "name"); // string
   getProperty(user, "age"); // number
   // getProperty(user, "email");  // Error!
   ```

### Checkpoint

Create a generic `Stack<T>` class with push, pop, and peek methods.

---

## Lesson 6: Utility Types

**Goal:** Transform types with built-in utilities.

### Exercises

1. **Partial and Required**

   ```typescript
   interface User {
     name: string;
     email: string;
     age?: number;
   }

   // All properties optional
   type PartialUser = Partial<User>;

   // All properties required
   type RequiredUser = Required<User>;

   // Good for updates
   function updateUser(id: number, updates: Partial<User>) {}
   ```

2. **Pick and Omit**

   ```typescript
   interface User {
     id: number;
     name: string;
     email: string;
     password: string;
   }

   // Only specific properties
   type PublicUser = Pick<User, "id" | "name" | "email">;

   // All except specific properties
   type SafeUser = Omit<User, "password">;
   ```

3. **Record**

   ```typescript
   type Status = "pending" | "active" | "completed";

   // Map status to counts
   type StatusCounts = Record<Status, number>;

   const counts: StatusCounts = {
     pending: 5,
     active: 10,
     completed: 25,
   };
   ```

4. **Readonly and NonNullable**

   ```typescript
   interface Config {
     host: string;
     port: number;
   }

   const config: Readonly<Config> = {
     host: "localhost",
     port: 3000,
   };
   // config.port = 8080;  // Error!

   type MaybeString = string | null | undefined;
   type DefiniteString = NonNullable<MaybeString>; // string
   ```

### Checkpoint

Use utility types to create a read-only version of an API response type.

---

## Lesson 7: Advanced Types

**Goal:** Master complex type patterns.

### Exercises

1. **Mapped types**

   ```typescript
   type Flags<T> = {
     [K in keyof T]: boolean;
   };

   interface Features {
     darkMode: string;
     notifications: string;
   }

   type FeatureFlags = Flags<Features>;
   // { darkMode: boolean; notifications: boolean }
   ```

2. **Conditional types**

   ```typescript
   type IsString<T> = T extends string ? true : false;

   type A = IsString<"hello">; // true
   type B = IsString<42>; // false

   // Extract array element type
   type Unwrap<T> = T extends Array<infer U> ? U : T;
   type C = Unwrap<string[]>; // string
   ```

3. **Template literal types**

   ```typescript
   type EventName = "click" | "focus" | "blur";
   type Handler = `on${Capitalize<EventName>}`;
   // "onClick" | "onFocus" | "onBlur"

   type Greeting = `Hello, ${string}!`;
   const g: Greeting = "Hello, World!";
   ```

4. **Type guards**

   ```typescript
   interface Cat {
     meow(): void;
   }

   interface Dog {
     bark(): void;
   }

   function isCat(animal: Cat | Dog): animal is Cat {
     return (animal as Cat).meow !== undefined;
   }

   function speak(animal: Cat | Dog) {
     if (isCat(animal)) {
       animal.meow(); // TypeScript knows it's Cat
     } else {
       animal.bark(); // TypeScript knows it's Dog
     }
   }
   ```

### Checkpoint

Create a type that makes all properties of a nested object optional
(DeepPartial).

---

## Lesson 8: Modules and Declaration Files

**Goal:** Organize code and use external libraries.

### Exercises

1. **ES modules**

   ```typescript
   // math.ts
   export function add(a: number, b: number): number {
     return a + b;
   }

   export const PI = 3.14159;

   export default class Calculator {}

   // main.ts
   import Calculator, { add, PI } from "./math";
   import * as math from "./math";
   ```

2. **Type-only imports**

   ```typescript
   import type { User } from "./types";

   // Only import the type, not the value
   // Removed at compile time
   ```

3. **Declaration files**

   ```typescript
   // types.d.ts
   declare module "untyped-lib" {
     export function doSomething(input: string): string;
     export const version: string;
   }

   // Ambient declarations
   declare global {
     interface Window {
       myApp: {
         version: string;
       };
     }
   }
   ```

4. **tsconfig essentials**

   ```json
   {
     "compilerOptions": {
       "target": "ES2020",
       "module": "ESNext",
       "strict": true,
       "esModuleInterop": true,
       "skipLibCheck": true,
       "outDir": "./dist",
       "rootDir": "./src"
     },
     "include": ["src/**/*"],
     "exclude": ["node_modules"]
   }
   ```

### Checkpoint

Create a module with types, export them, and import in another file.

---

## Practice Projects

### Project 1: Type-Safe API Client

Build an API client:

- Generic request/response types
- Error handling with discriminated unions
- Type-safe query parameters

### Project 2: State Management

Build a simple store:

- Generic state type
- Type-safe actions
- Selector functions with proper return types

### Project 3: CLI Tool

Build a command-line tool:

- Use Commander.js with types
- Validate input with Zod
- Type-safe configuration

---

## Quick Reference

| Stage        | Topics                                       |
| ------------ | -------------------------------------------- |
| Beginner     | Basic types, interfaces, functions           |
| Intermediate | Generics, union types, utility types         |
| Advanced     | Mapped types, conditional types, declaration |

## See Also

- [TypeScript Cheatsheet](../how/typescript.md) — Quick syntax reference
- [Testing](../how/testing.md) — Jest/Vitest with TypeScript
