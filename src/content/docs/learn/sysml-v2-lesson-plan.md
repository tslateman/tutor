---
title: "SysML v2 Lesson Plan"
description:
  Eight lessons from KerML foundations to the Systems Modeling API, covering
  textual notation, model libraries, and pilot tooling.
---

How to read, write, and reason about systems models in OMG SysML v2 -- from the
kernel language through domain libraries to tool interoperability.

<!-- prettier-ignore -->
:::note[Prerequisites]
Familiarity with basic modeling concepts (classes, relationships, hierarchies).
No SysML v1 experience required -- v2 is a clean break.
:::

## Lesson 1: The SysML v2 Architecture

**Goal:** Understand why SysML v2 exists, how its three specifications relate,
and what changed from v1.

### Concepts

SysML v1 was a UML profile -- it inherited UML's metamodel and bolted systems
engineering concepts on top. SysML v2 starts fresh. It builds on a new kernel
language (KerML) designed from first principles around classification theory.
SysML v2 specializes KerML for systems engineering. A third specification, the
Systems Modeling API, standardizes how tools exchange models over HTTP.

The stack:

```text
┌───────────────────────────────────────┐
│  Systems Modeling API & Services      │  Tool interop (REST, OSLC)
├───────────────────────────────────────┤
│  SysML 2.0                           │  Domain: parts, ports, requirements,
│                                       │  analysis, verification, state machines
├───────────────────────────────────────┤
│  KerML 1.0                           │  Kernel: classifiers, features,
│                                       │  namespaces, behaviors, associations
└───────────────────────────────────────┘
```

Key shifts from v1:

- **Textual notation first.** Models are written in `.kerml` and `.sysml` files
  with a formal grammar. Graphical notation is derived, not primary.
- **Own metamodel.** KerML replaces UML as the foundation.
- **Normative libraries.** Quantities, units, geometry, metadata -- all shipped
  as part of the spec.
- **API-native.** The spec defines how tools share models, including version
  control semantics (branches, commits).

### Exercises

1. **Map the repositories**

   Visit these GitHub repositories and read each README:
   - [SysML-v2-Release](https://github.com/Systems-Modeling/SysML-v2-Release) --
     Spec PDFs, example models, model libraries, installers
   - [SysML-v2-Pilot-Implementation](https://github.com/Systems-Modeling/SysML-v2-Pilot-Implementation)
     -- Reference implementation (Eclipse + Jupyter)
   - [SysML-v2-API-Services](https://github.com/Systems-Modeling/SysML-v2-API-Services)
     -- API server implementation
   - [SysML-v2-API-Cookbook](https://github.com/Systems-Modeling/SysML-v2-API-Cookbook)
     -- API usage examples

   Write down what each repository provides and how they relate.

2. **Inventory the release contents**

   Clone the Release repository and list the contents of each top-level
   directory:

   ```bash
   git clone https://github.com/Systems-Modeling/SysML-v2-Release.git
   cd SysML-v2-Release
   ls -1
   ```

   ```text
   Expected directories:
   bnf/                 # BNF grammars for KerML and SysML
   doc/                 # Spec PDFs and intro presentations
   install/             # Eclipse and Jupyter installers
   kerml/               # Example KerML models
   sysml/               # Example SysML v2 models
   sysml.library/       # Normative model libraries (textual)
   sysml.library.xmi/   # Same libraries in XMI format
   ```

3. **Read the intro presentations**

   Open `doc/Intro to the SysML v2 Language-Textual Notation.pdf`. Read the
   first 20 slides. Write down:
   - Three concepts that have no equivalent in UML/SysML v1
   - The relationship between "definition" and "usage" in SysML v2
   - How namespaces and packages organize a model

4. **Compare v1 and v2 notation**

   ```text
   SysML v1 (block definition diagram):
   «block» Vehicle
     parts:
       engine: Engine [1]
       wheels: Wheel [4]

   SysML v2 (textual notation):
   part def Vehicle {
       part engine : Engine;
       part wheels : Wheel[4];
   }

   Key differences:
   - "block" becomes "part def" (part definition)
   - Multiplicities use array syntax [4] not [4..4]
   - No stereotype brackets «»
   - Semicolons terminate declarations
   - Curly braces scope members
   ```

   Write a SysML v2 part definition for a `Bicycle` with `frame`, `wheels[2]`,
   and `handlebars`. Keep the file as `bicycle.sysml` for later exercises.

### Checkpoint

Explain in your own words: why did OMG build a new kernel language instead of
continuing to extend UML? Name three concrete capabilities that the textual
notation enables that diagram-only notation does not.

---

## Lesson 2: KerML Foundations

**Goal:** Read and write KerML constructs -- the primitives on which SysML is
built.

### Concepts

KerML provides application-independent modeling constructs. Everything in SysML
v2 reduces to KerML elements. The core ideas:

- **Classifiers** define categories of things (like classes, but more general).
- **Features** define properties and roles within classifiers.
- **Specialization** means one classifier is a more specific version of another
  (like inheritance).
- **Feature typing** constrains what values a feature can hold.
- **Namespaces** organize elements into scopes. Every model element lives in a
  namespace.
- **Relationships** connect elements: membership, specialization, feature
  typing, subsetting, redefinition.

KerML also defines **behaviors** (sequences of steps), **functions** (behaviors
that return values), and **associations** (relationships between classifiers).

### Exercises

1. **Read the KerML semantic library**

   ```bash
   cd SysML-v2-Release
   ls sysml.library/Kernel\ Library/
   ```

   Open `Base.kerml`. Identify:
   - The root classifier `Anything`
   - How `Anything` relates to other base types
   - What `Anything` provides that every element inherits

2. **Write basic KerML classifiers**

   ```kerml
   // basic.kerml -- KerML classifier fundamentals

   // A simple classifier with features
   classifier Person {
       feature name : String;
       feature age : Natural;
   }

   // Specialization: Employee is a more specific Person
   classifier Employee specializes Person {
       feature employeeId : String;
       feature department : String;
   }

   // Association: a relationship between classifiers
   assoc Employment {
       end feature employer : Organization;
       end feature employee : Employee;
   }

   classifier Organization {
       feature name : String;
   }
   ```

   Questions to answer:
   - What does `specializes` mean in terms of features?
   - What do the `end` features in an association represent?
   - How would you add a feature `manager : Employee` to `Organization`?

3. **Explore feature subsetting and redefinition**

   ```kerml
   // features.kerml -- subsetting and redefinition

   classifier Vehicle {
       feature passengers : Person[0..*];
       feature driver : Person[1] subsets passengers;
       // driver is always one of the passengers
   }

   classifier Truck specializes Vehicle {
       // Redefinition: replace the general type with a specific one
       feature redefines driver : LicensedDriver;
   }

   classifier LicensedDriver specializes Person {
       feature licenseNumber : String;
   }
   ```

   - `subsets` means every value of `driver` is also a value of `passengers`.
   - `redefines` replaces a feature in a specialization with a more specific
     version.

   Write a `Bus` classifier that specializes `Vehicle` and redefines
   `passengers` to require at least 10.

4. **Trace KerML through the data type library**

   ```bash
   cat sysml.library/Kernel\ Library/ScalarValues.kerml
   ```

   Find:
   - How `Boolean`, `Integer`, `Real`, and `String` are defined
   - What they specialize
   - How `Natural` constrains `Integer`

### Checkpoint

Without looking at examples, write KerML from scratch: a `Shape` classifier with
a `sides : Natural` feature, and two specializations -- `Triangle` (redefines
sides to 3) and `Quadrilateral` (redefines sides to 4). Explain why redefinition
is the right mechanism here instead of subsetting.

---

## Lesson 3: SysML v2 Textual Notation -- Structure

**Goal:** Write structural SysML v2 models: part definitions, usages,
attributes, ports, and connections.

### Concepts

SysML v2 separates **definitions** from **usages**. A definition (like
`part def Engine`) declares a reusable type. A usage (like
`part engine : Engine`) creates an instance of that type within a context. This
is analogous to the distinction between a class and an object, but applied to
physical parts, attributes, ports, and more.

Key structural constructs:

- `part def` / `part` -- physical or logical components
- `attribute def` / `attribute` -- data values (mass, temperature)
- `port def` / `port` -- interaction points on parts
- `connection def` / `connection` -- links between ports
- `item def` / `item` -- things that flow through connections
- `interface def` / `interface` -- typed connections between ports

### Exercises

1. **Part definitions and usages**

   ```sysml
   // vehicle.sysml -- structural modeling

   package VehicleModel {

       // Definitions (reusable types)
       part def Vehicle {
           attribute mass : ISQ::MassValue;

           part engine : Engine;
           part transmission : Transmission;
           part wheels : Wheel[4];

           // Ports: interaction points
           port fuelPort : FuelPort;
       }

       part def Engine {
           attribute displacement : ISQ::VolumeValue;
           attribute horsepower : ScalarValues::Real;

           port driveShaft : TorquePort;
       }

       part def Transmission {
           port inputShaft : TorquePort;
           port outputShaft : TorquePort;
       }

       part def Wheel {
           attribute diameter : ISQ::LengthValue;
       }

       // Port definitions
       port def FuelPort;
       port def TorquePort;

       // Connections: link ports together
       connection engineToTransmission
           connect engine.driveShaft to transmission.inputShaft;
   }
   ```

   Questions:
   - How does `part` differ from `attribute`?
   - Why are ports necessary? What would happen without them?
   - What does `Wheel[4]` mean?

2. **Attributes and value types**

   ```sysml
   // attributes.sysml -- value modeling

   package SensorModel {

       attribute def TemperatureReading {
           attribute value : ISQ::TemperatureValue;
           attribute timestamp : ScalarValues::String;
           attribute sensorId : ScalarValues::String;
       }

       part def TemperatureSensor {
           attribute currentReading : TemperatureReading;
           attribute minRange : ISQ::TemperatureValue;
           attribute maxRange : ISQ::TemperatureValue;

           port dataOut : DataPort;
       }

       port def DataPort;

       part def MonitoringSystem {
           part sensors : TemperatureSensor[1..*];
           part controller : Controller;

           connection sensorLinks
               connect sensors.dataOut to controller.dataIn;
       }

       part def Controller {
           port dataIn : DataPort;
       }
   }
   ```

   Extend this model with a `PressureSensor` that has its own reading type and
   connects to the same controller.

3. **Items and flows**

   ```sysml
   // flows.sysml -- items flowing through connections

   package PipelineModel {

       item def Fuel {
           attribute octaneRating : ScalarValues::Integer;
       }

       item def Exhaust;

       part def FuelTank {
           port fuelOut : FuelPort;
       }

       part def Engine {
           port fuelIn : FuelPort;
           port exhaustOut : ExhaustPort;
       }

       port def FuelPort {
           out item fuelFlow : Fuel;
       }

       port def ExhaustPort {
           out item exhaustFlow : Exhaust;
       }

       part def Car {
           part tank : FuelTank;
           part engine : Engine;

           // Flow: fuel moves from tank to engine
           flow of Fuel from tank.fuelOut to engine.fuelIn;
       }
   }
   ```

   Add a `Catalytic Converter` between the engine and a `Tailpipe`, with exhaust
   flowing through each.

4. **Packages and imports**

   ```sysml
   // Packages scope model elements
   package Chassis {
       part def Frame;
       part def Suspension;
   }

   package Powertrain {
       part def Engine;
       part def Transmission;
   }

   // Import brings elements into scope
   package FullVehicle {
       import Chassis::*;
       import Powertrain::*;

       part def Vehicle {
           part frame : Frame;
           part suspension : Suspension;
           part engine : Engine;
           part transmission : Transmission;
       }
   }
   ```

   Create a three-package model: `Electrical`, `Mechanical`, and `System` (which
   imports from both).

### Checkpoint

Model a coffee machine with at least: a water reservoir, a heating element, a
pump, a brew chamber, and a dispenser. Define ports for water flow and
electrical connections. Establish flows showing water moving from reservoir
through the heater to the brew chamber and out the dispenser.

---

## Lesson 4: SysML v2 Textual Notation -- Behavior

**Goal:** Model what systems _do_: actions, state machines, use cases, and
calculations.

### Concepts

SysML v2 behavioral constructs describe how systems execute over time:

- `action def` / `action` -- activities that transform inputs to outputs
- `state def` / `state` -- lifecycle states and transitions
- `calc def` / `calc` -- mathematical calculations
- `use case def` / `use case` -- user-visible functionality
- Succession (`then`) orders actions in sequence
- `if` / `decide` provides branching
- `merge` / `fork` / `join` handles concurrency

### Exercises

1. **Actions and succession**

   ```sysml
   // brewing.sysml -- action modeling

   package BrewingProcess {

       action def HeatWater {
           in item water;
           out item heatedWater;

           attribute targetTemp : ISQ::TemperatureValue;
       }

       action def Grind {
           in item beans;
           out item grounds;
       }

       action def Brew {
           in item heatedWater;
           in item grounds;
           out item coffee;
       }

       action def MakeCoffee {
           in item water;
           in item beans;

           // Sequential actions connected by succession
           action grind : Grind {
               in item beans = MakeCoffee::beans;
           }

           action heat : HeatWater {
               in item water = MakeCoffee::water;
           }

           action brew : Brew {
               in item heatedWater = heat.heatedWater;
               in item grounds = grind.grounds;
           }

           // Ordering: grind and heat can happen in parallel,
           // but both must complete before brewing
           first start;
           then fork;
               then grind;
               then heat;
           then join;
           then brew;
           then done;
       }
   }
   ```

   Questions:
   - What does `fork` / `join` express that sequential `then` does not?
   - How are inputs and outputs threaded between actions?
   - Add a `ServeCoffee` action after `Brew`.

2. **State machines**

   ```sysml
   // states.sysml -- lifecycle modeling

   package TrafficLight {

       part def Light {
           attribute color : Color;

           state def LightCycle {
               entry; then green;

               state green {
                   entry action { color = Color::green; }
                   then yellow;
               }

               state yellow {
                   entry action { color = Color::yellow; }
                   then red;
               }

               state red {
                   entry action { color = Color::red; }
                   then green;
               }
           }
       }

       enum def Color {
           green;
           yellow;
           red;
       }
   }
   ```

   Extend this with a `flashing` state that the light enters on a `malfunction`
   event, and exits on a `reset` event.

3. **Calculations**

   ```sysml
   // calculations.sysml -- mathematical modeling

   package Physics {

       calc def KineticEnergy {
           in mass : ISQ::MassValue;
           in velocity : ISQ::SpeedValue;
           return : ISQ::EnergyValue;

           // KE = 0.5 * m * v^2
       }

       calc def BrakingDistance {
           in velocity : ISQ::SpeedValue;
           in friction : ScalarValues::Real;
           return : ISQ::LengthValue;

           // d = v^2 / (2 * g * friction)
       }

       part def Vehicle {
           attribute mass : ISQ::MassValue;
           attribute speed : ISQ::SpeedValue;

           calc ke : KineticEnergy {
               in mass = Vehicle::mass;
               in velocity = Vehicle::speed;
           }
       }
   }
   ```

   Add a `StoppingDistance` calculation that composes `BrakingDistance` with a
   `ReactionDistance` (speed times reaction time).

4. **Use cases**

   ```sysml
   // usecases.sysml -- functional scope

   package SmartHome {

       use case def AdjustTemperature {
           subject home : Home;
           actor user : Resident;
           actor system : HVAC;

           objective {
               doc /* Maintain comfortable temperature
                      within user-specified range. */
           }

           include use case readSensors;
           include use case calculateDelta;
           include use case actuateHVAC;
       }

       part def Home;
       part def Resident;
       part def HVAC;
   }
   ```

   Write a use case for `SecurityAlert` with actors `Sensor`, `Homeowner`, and
   `MonitoringService`. Include sub-use-cases for detection, notification, and
   response.

### Checkpoint

Model a vending machine with: an action flow for the purchase process (select
item, insert payment, dispense), a state machine for the machine lifecycle
(idle, selecting, processing, dispensing, error), and a calculation for change
due. Connect them so the action flow triggers state transitions.

---

## Lesson 5: Requirements and Verification

**Goal:** Express requirements as model elements and link them to the design
that satisfies them and the tests that verify them.

### Concepts

SysML v2 treats requirements as first-class model elements, not disconnected
documents. A requirement has a text description and optionally a formal
constraint. Requirements can be:

- **Satisfied by** parts or actions (the design element that fulfills them)
- **Verified by** verification cases (tests that prove satisfaction)
- **Derived from** higher-level requirements
- **Refined by** more specific sub-requirements

Verification cases are structured test definitions that specify how to verify a
requirement, including setup, stimulus, observation, and acceptance criteria.

Analysis cases evaluate system properties under specific conditions.

### Exercises

1. **Define requirements**

   ```sysml
   // requirements.sysml

   package VehicleRequirements {

       requirement def MassRequirement {
           doc /* The total vehicle mass shall not exceed
                  the specified maximum. */
           attribute massLimit : ISQ::MassValue;
       }

       requirement def PerformanceRequirement {
           doc /* The vehicle shall achieve the specified
                  acceleration. */
           attribute zeroToSixty : ISQ::TimeValue;
       }

       requirement def SafetyRequirement {
           doc /* The braking distance from 100 km/h shall
                  not exceed the specified limit. */
           attribute maxBrakingDistance : ISQ::LengthValue;
       }

       // Instantiate with specific values
       requirement vehicleMass : MassRequirement {
           attribute redefines massLimit = 2000 [kg];
       }

       requirement acceleration : PerformanceRequirement {
           attribute redefines zeroToSixty = 6.5 [s];
       }

       requirement brakingDistance : SafetyRequirement {
           attribute redefines maxBrakingDistance = 35 [m];
       }
   }
   ```

2. **Link requirements to design**

   ```sysml
   // satisfaction.sysml

   package VehicleDesign {

       import VehicleRequirements::*;

       part def Vehicle {
           attribute totalMass : ISQ::MassValue;
           part engine : Engine;
           part brakes : BrakingSystem;

           // Satisfy requirements
           satisfy vehicleMass by Vehicle;
           satisfy acceleration by engine;
           satisfy brakingDistance by brakes;
       }

       part def Engine {
           attribute power : ISQ::PowerValue;
           attribute torque : ISQ::ForceValue;
       }

       part def BrakingSystem {
           attribute maxDeceleration : ISQ::AccelerationValue;
       }
   }
   ```

   Question: What does `satisfy` express that a comment does not? Why does it
   matter for traceability?

3. **Verification cases**

   ```sysml
   // verification.sysml

   package VehicleVerification {

       import VehicleRequirements::*;
       import VehicleDesign::*;

       verification def MassVerification {
           subject vehicle : Vehicle;
           objective {
               verify vehicleMass;
           }

           action weighVehicle {
               // Measure the actual mass
               out actualMass : ISQ::MassValue;
           }

           action checkMass {
               in actualMass : ISQ::MassValue;
               // Assert actualMass <= massLimit
           }

           first start;
           then weighVehicle;
           then checkMass;
           then done;
       }

       verification def BrakingVerification {
           subject vehicle : Vehicle;
           objective {
               verify brakingDistance;
           }

           action accelerateTo100 {
               // Bring vehicle to 100 km/h
           }

           action applyBrakes {
               // Full brake application
           }

           action measureDistance {
               out actualDistance : ISQ::LengthValue;
           }

           action checkDistance {
               in actualDistance : ISQ::LengthValue;
               // Assert actualDistance <= maxBrakingDistance
           }

           first start;
           then accelerateTo100;
           then applyBrakes;
           then measureDistance;
           then checkDistance;
           then done;
       }
   }
   ```

4. **Analysis cases**

   ```sysml
   // analysis.sysml

   package VehicleAnalysis {

       import VehicleDesign::*;

       analysis def FuelEfficiencyAnalysis {
           subject vehicle : Vehicle;

           in attribute speed : ISQ::SpeedValue;
           in attribute distance : ISQ::LengthValue;

           return fuelConsumed : ISQ::VolumeValue;

           // The analysis calculates fuel consumed
           // for a given speed and distance
       }

       analysis def SafetyMarginAnalysis {
           subject vehicle : Vehicle;

           in attribute roadCondition : RoadCondition;
           return safetyFactor : ScalarValues::Real;
       }

       enum def RoadCondition {
           dry;
           wet;
           icy;
       }
   }
   ```

   Write an analysis case for `ThermalAnalysis` that takes ambient temperature
   and operating duration as inputs and returns a maximum component temperature.

### Checkpoint

Model a drone with three requirements (flight duration, payload capacity, and
maximum altitude). Write part definitions that satisfy each requirement. Create
at least one verification case that defines a concrete test procedure. Trace the
full chain: requirement -> design element -> verification case.

---

## Lesson 6: Model Libraries and Domain Extensions

**Goal:** Use the normative SysML v2 model libraries and understand how to
create domain-specific extensions.

### Concepts

SysML v2 ships with normative model libraries that define standard concepts.
These libraries are written in SysML/KerML textual notation and live in the
`sysml.library/` directory. Key libraries:

| Library          | Provides                                       |
| ---------------- | ---------------------------------------------- |
| Kernel Library   | Base types, scalar values, data functions      |
| Systems Library  | Parts, ports, connections, items, flows        |
| Quantities (ISQ) | SI quantities: mass, length, time, energy, etc |
| Units (SI)       | SI units: kg, m, s, J, W, etc                  |
| Geometry         | Points, vectors, coordinate frames             |
| Analysis         | Analysis case patterns                         |
| Metadata         | Model annotations and tagging                  |
| Cause and Effect | Causal relationships                           |

Extensions use **metadata definitions** to add domain-specific annotations
without modifying the core language.

### Exercises

1. **Explore the ISQ quantities library**

   ```bash
   cd SysML-v2-Release
   ls sysml.library/Domain\ Libraries/Quantities\ and\ Units/
   ```

   Open `ISQ.sysml`. Find the definitions for:
   - `MassValue`
   - `LengthValue`
   - `TimeValue`
   - `EnergyValue`

   How do they relate to each other? (Hint: energy = mass \* length^2 / time^2)

2. **Use quantities and units in a model**

   ```sysml
   // rocket.sysml -- using the ISQ library

   package RocketModel {

       part def Rocket {
           attribute dryMass : ISQ::MassValue = 22000 [kg];
           attribute fuelMass : ISQ::MassValue = 400000 [kg];
           attribute thrust : ISQ::ForceValue = 7600000 [N];
           attribute burnTime : ISQ::TimeValue = 150 [s];

           part stage1 : RocketStage {
               attribute redefines mass = 180000 [kg];
           }

           part stage2 : RocketStage {
               attribute redefines mass = 40000 [kg];
           }
       }

       part def RocketStage {
           attribute mass : ISQ::MassValue;
           attribute propellantMass : ISQ::MassValue;

           part engine : RocketEngine;
       }

       part def RocketEngine {
           attribute specificImpulse : ISQ::TimeValue;
           attribute thrust : ISQ::ForceValue;
       }
   }
   ```

   Add a calculation for total delta-v using the Tsiolkovsky rocket equation.

3. **Metadata definitions**

   ```sysml
   // metadata.sysml -- domain-specific annotations

   package SafetyMetadata {

       metadata def SafetyLevel {
           attribute level : SafetyCategory;
       }

       enum def SafetyCategory {
           ASIL_A;
           ASIL_B;
           ASIL_C;
           ASIL_D;
       }

       // Apply metadata to model elements
       part def BrakeController {
           @SafetyLevel { level = SafetyCategory::ASIL_D; }

           part processor : Processor;
           part sensor : BrakeSensor;
       }

       part def InfotainmentSystem {
           @SafetyLevel { level = SafetyCategory::ASIL_A; }
       }

       part def Processor;
       part def BrakeSensor;
   }
   ```

   Create a `MaturityLevel` metadata definition with values `concept`,
   `preliminary`, `detailed`, `verified`. Apply it to several parts in a model.

4. **Browse the Systems Library**

   ```bash
   ls sysml.library/Systems\ Library/
   ```

   Open `Parts.sysml` and `Connections.sysml`. Identify:
   - The root `Part` definition that all parts specialize
   - How connections between ports are formally defined
   - What standard features every part inherits

### Checkpoint

Build a satellite model using ISQ quantities for mass, power, and orbital
parameters. Apply metadata annotations for technology readiness level (TRL 1-9).
Structure the model across at least two packages with proper imports.

---

## Lesson 7: Pilot Tooling -- Eclipse and Jupyter

**Goal:** Install and use the SysML v2 pilot implementation to edit, validate,
and visualize models.

### Concepts

The pilot implementation provides two editing environments:

- **Eclipse** with Xtext-based editors for `.kerml` and `.sysml` files. Provides
  syntax highlighting, validation, cross-reference resolution, and PlantUML
  visualization.
- **Jupyter** with a custom SysML language kernel. Provides interactive model
  editing in notebook cells, with `%publish` to send models to a repository.

Both tools parse the textual notation, resolve references against the normative
model libraries, and report errors. Neither is a production modeling tool --
they are pilot implementations for spec validation.

### Exercises

1. **Install the Eclipse environment**

   ```bash
   # Download Eclipse Installer
   # https://www.eclipse.org/downloads/packages/installer

   # Clone the pilot implementation
   git clone https://github.com/Systems-Modeling/SysML-v2-Pilot-Implementation.git

   # In Eclipse Installer (Advanced Mode):
   # 1. Select "Eclipse Modeling Tools"
   # 2. Product Version: 2025-12, Java VM: Java 21
   # 3. Add user project from:
   #    SysML-v2-Pilot-Implementation/org.omg.sysml.installer/SysML2.setup
   # 4. Configure paths and finish
   ```

   After installation:
   - Import `kerml`, `sysml`, and `sysml.library` projects
   - Build `sysml.library` first, then `kerml` and `sysml`
   - Open any `.sysml` file to verify the editor works

2. **Install the Jupyter environment**

   ```bash
   cd SysML-v2-Release/install/jupyter

   # Follow the install instructions in the directory
   # Requires: Python 3, JupyterLab, Java 21

   # After installation, launch JupyterLab:
   jupyter lab
   ```

   Create a new notebook with the SysML kernel. In the first cell:

   ```sysml
   part def Hello {
       attribute greeting : ScalarValues::String = "Hello, SysML v2!";
   }
   ```

   Execute the cell. If it parses without errors, the kernel is working.

3. **Validate models against the library**

   In Eclipse or Jupyter, create a model that references ISQ quantities:

   ```sysml
   package ValidationTest {
       part def Beam {
           attribute length : ISQ::LengthValue;
           attribute width : ISQ::LengthValue;
           attribute height : ISQ::LengthValue;
           attribute material : ScalarValues::String;
       }
   }
   ```

   Intentionally introduce errors:
   - Reference a nonexistent type
   - Use a feature name that conflicts with a keyword
   - Omit a required semicolon

   Observe how the editor reports each error.

4. **Visualize with PlantUML**

   In Eclipse with the PlantUML plugin:
   - Open a `.sysml` file
   - Open Window > Show View > PlantUML
   - Click on different elements in the editor and observe the generated diagram

   Note what the visualization shows and what it omits. Graphical notation is
   derived from the textual model -- the text is the source of truth.

### Checkpoint

Create a multi-file model in Eclipse: one package for definitions, one for
usages, one for requirements. Verify that cross-file references resolve
correctly. Export or screenshot the PlantUML visualization of your model.

---

## Lesson 8: The Systems Modeling API

**Goal:** Understand how the Systems Modeling API enables tool interoperability
and model repository management.

### Concepts

The Systems Modeling API defines a standard REST interface for:

- **Projects** -- top-level containers for models
- **Branches** -- parallel versions of a project (like git branches)
- **Commits** -- immutable snapshots of a project's state
- **Elements** -- individual model elements (parts, requirements, etc.)
- **Queries** -- server-side filtering and selection of elements
- **Relationships** -- navigating connections between elements

The API uses a Platform-Independent Model (PIM) that maps to REST/HTTP via an
OpenAPI specification. OSLC (Open Services for Lifecycle Collaboration)
vocabularies provide RDF/TTL representations for linked data integration.

### Exercises

1. **Read the OpenAPI specification**

   Access the prototype API documentation:

   ```bash
   # The live prototype (if available):
   # http://sysml2.intercax.com:9000/docs/
   #
   # Or download the OpenAPI JSON from OMG:
   # https://www.omg.org/spec/SystemsModelingAPI/20250201/OpenAPI.json
   ```

   Identify the endpoints for:
   - Creating a project
   - Listing commits in a project
   - Getting a specific element by ID
   - Running a query against a project

2. **Explore the API with curl**

   ```bash
   API="http://sysml2.intercax.com:9000"

   # List projects
   curl -s "$API/projects" | python3 -m json.tool | head -30

   # Get a specific project (use an ID from the list)
   curl -s "$API/projects/{project-id}" | python3 -m json.tool

   # List commits for a project
   curl -s "$API/projects/{project-id}/commits" | python3 -m json.tool

   # Get elements from the latest commit
   curl -s "$API/projects/{project-id}/commits/{commit-id}/elements" \
     | python3 -m json.tool | head -50
   ```

   Note the JSON structure: each element has `@type`, `@id`, and typed
   properties that correspond to the KerML/SysML metamodel.

3. **Understand the data model**

   ```text
   API data model hierarchy:

   Project
   ├── Branch (default: "main")
   │   ├── Commit (immutable snapshot)
   │   │   ├── Element (part, requirement, etc.)
   │   │   ├── Element
   │   │   └── ...
   │   ├── Commit
   │   └── ...
   ├── Branch
   └── ...

   Key operations:
   - POST /projects                          → Create project
   - GET  /projects/{id}/branches            → List branches
   - POST /projects/{id}/commits             → Create commit
   - GET  /projects/{id}/commits/{id}/elements → Read elements
   - POST /projects/{id}/queries             → Run a query
   ```

4. **Study the API Cookbook**

   ```bash
   git clone https://github.com/Systems-Modeling/SysML-v2-API-Cookbook.git
   ```

   Read through the example notebooks. Each demonstrates a specific API
   interaction pattern:
   - Creating and populating a project
   - Querying elements by type
   - Navigating relationships between elements
   - Branching and merging models

   Pick one cookbook example and trace the full request-response cycle. Document
   the HTTP methods, endpoints, and JSON payloads involved.

### Checkpoint

Using the prototype API (or the OpenAPI spec if the prototype is unavailable),
write a script that: creates a project, lists its branches, and retrieves the
element types present in the default commit. Explain how the API's branch/commit
model compares to git's.

---

## Practice Projects

### Project 1: Model a Drone System

Build a complete SysML v2 model for a quadcopter drone. Include:

- Structural: frame, motors (4), battery, flight controller, GPS, camera
- Behavioral: takeoff sequence, hover, waypoint navigation, landing
- Requirements: flight time > 30 min, payload > 500g, max altitude 120m
- Verification: test procedures for each requirement
- Use ISQ quantities throughout and apply metadata for component maturity

### Project 2: Domain-Specific Library

Create a reusable model library for a domain you work in (automotive, aerospace,
robotics, or IoT). Define:

- Base part definitions with standard attributes and ports
- Standard interfaces and connection types
- Common requirement patterns
- Metadata definitions for domain-specific annotations
- At least one example model that imports and uses the library

### Project 3: API Integration Script

Write a Python script that interacts with the Systems Modeling API to:

- Create a new project
- Publish a SysML model (parsed from a `.sysml` file)
- Query for all requirements in the model
- Generate a traceability report showing requirement -> design -> verification
  links
- Export the report as JSON and Markdown

---

## Quick Reference

| Topic        | Key Concepts                                                    |
| ------------ | --------------------------------------------------------------- |
| Architecture | KerML -> SysML -> API, three specs, textual notation first      |
| KerML        | Classifiers, features, specialization, subsetting, redefinition |
| Structure    | `part def`/`part`, `port`, `connection`, `item`, `flow`         |
| Behavior     | `action`, `state`, `calc`, `use case`, `then`, `fork`/`join`    |
| Requirements | `requirement`, `satisfy`, `verify`, `derive`, `refine`          |
| Libraries    | ISQ quantities, SI units, geometry, metadata, analysis          |
| Tooling      | Eclipse + Xtext, Jupyter kernel, PlantUML visualization         |
| API          | Projects, branches, commits, elements, queries, OpenAPI         |

## See Also

- [Specification Lesson Plan](specification-lesson-plan.md) -- Formal
  specification techniques that inform SysML v2's design
- [System Design Lesson Plan](system-design-lesson-plan.md) -- The systems that
  SysML v2 models describe
- [Information Architecture Lesson Plan](information-architecture-lesson-plan.md)
  -- Organizing complex knowledge structures
- [Data Models Lesson Plan](data-models-lesson-plan.md) -- How data modeling
  principles apply to metamodels
