---
title: "Python CLI"
description:
  "Building command-line tools with Typer, Click, and argparse. Django
  management command wrappers. Packaging and distribution."
---

## Quick Reference

| Framework        | Best For                             | Style      | Dependencies   |
| ---------------- | ------------------------------------ | ---------- | -------------- |
| **Typer**        | New projects, type-hint codebases    | Type hints | Click + Typer  |
| **Click**        | Complex CLIs, decorator preference   | Decorators | Click          |
| **argparse**     | Zero-dependency scripts              | Imperative | stdlib         |
| **django-typer** | Django commands needing rich output  | Type hints | Typer + Django |
| **django-click** | Django commands, minimal boilerplate | Decorators | Click + Django |

## Typer

The recommended default for new CLI projects. Uses Python type hints for
argument definitions, builds on Click underneath.

### Minimal App

```python
import typer

app = typer.Typer()

@app.command()
def greet(name: str, count: int = 1):
    """Greet someone COUNT times."""
    for _ in range(count):
        typer.echo(f"Hello, {name}!")

if __name__ == "__main__":
    app()
```

```bash
python greet.py Alice --count 3
```

### Arguments and Options

```python
import typer
from pathlib import Path
from typing import Optional

app = typer.Typer()

@app.command()
def process(
    # Positional argument (required)
    path: Path,
    # Option with short flag
    output: Path = typer.Option("out.json", "--output", "-o"),
    # Boolean flag
    verbose: bool = typer.Option(False, "--verbose", "-v"),
    # Optional with default None
    tag: Optional[str] = typer.Option(None, help="Tag the run"),
    # Multiple values
    exclude: list[str] = typer.Option([], "--exclude", "-e"),
):
    if verbose:
        typer.echo(f"Processing {path}")
```

### Subcommands

```python
import typer

app = typer.Typer()
db_app = typer.Typer(help="Database operations")
app.add_typer(db_app, name="db")

@db_app.command()
def migrate():
    """Run pending migrations."""
    typer.echo("Migrating...")

@db_app.command()
def seed(count: int = 100):
    """Seed sample data."""
    typer.echo(f"Seeding {count} records")

@app.command()
def version():
    """Print version."""
    typer.echo("1.0.0")
```

```bash
mycli db migrate
mycli db seed --count 50
mycli version
```

### Rich Output

Install with `pip install typer[all]` or `pip install rich` separately.

```python
from rich.console import Console
from rich.table import Table

console = Console()

def show_results(results: list[dict]):
    table = Table(title="Results")
    table.add_column("Name")
    table.add_column("Status", style="green")
    for r in results:
        table.add_row(r["name"], r["status"])
    console.print(table)
```

### Progress Bars

```python
import typer
from rich.progress import track

@app.command()
def process(items: int = 100):
    for _ in track(range(items), description="Processing..."):
        do_work()
```

## Click

Use when you prefer decorators over type hints, or when you need Click's
advanced features directly (custom parameter types, shell completion plugins,
lazy-loaded groups).

### Minimal App

```python
import click

@click.command()
@click.argument("name")
@click.option("--count", "-c", default=1, help="Number of times.")
def greet(name, count):
    """Greet someone COUNT times."""
    for _ in range(count):
        click.echo(f"Hello, {name}!")

if __name__ == "__main__":
    greet()
```

### Groups and Subcommands

```python
import click

@click.group()
def cli():
    """My CLI tool."""

@cli.command()
@click.argument("path", type=click.Path(exists=True))
@click.option("--format", type=click.Choice(["json", "csv"]))
def convert(path, format):
    """Convert a file."""
    click.echo(f"Converting {path} to {format}")

@cli.command()
def status():
    """Show status."""
    click.secho("OK", fg="green")
```

### File Arguments

```python
@click.command()
@click.argument("input", type=click.File("r"))
@click.argument("output", type=click.File("w"))
def transform(input, output):
    """Read INPUT, write to OUTPUT. Use '-' for stdin/stdout."""
    data = input.read()
    output.write(data.upper())
```

## argparse

Use for zero-dependency scripts, stdlib-only environments, or when extending
existing argparse-based tools.

```python
import argparse

parser = argparse.ArgumentParser(description="Process files")
parser.add_argument("path", help="Input file path")
parser.add_argument("-o", "--output", default="out.json")
parser.add_argument("-v", "--verbose", action="store_true")
parser.add_argument("--format", choices=["json", "csv"], default="json")

# Subcommands
subparsers = parser.add_subparsers(dest="command")
sub = subparsers.add_parser("convert")
sub.add_argument("file")

args = parser.parse_args()
```

## Django Integration

If your project uses Django, lean into management commands rather than building
a standalone CLI. Management commands get the ORM, settings, and app registry
for free. Use `django-typer` or `django-click` to remove the boilerplate.

### When to Use Management Commands

| Situation                            | Approach                     |
| ------------------------------------ | ---------------------------- |
| Needs ORM, models, or settings       | Management command           |
| Cron job or scheduled task           | Management command           |
| Data import/export                   | Management command           |
| No Django dependencies at all        | Standalone CLI (Typer/Click) |
| Tool may be extracted to own package | Standalone CLI               |

### Standard Django Command (Verbose)

```python
# myapp/management/commands/import_data.py
from django.core.management.base import BaseCommand

class Command(BaseCommand):
    help = "Import data from a JSON file"

    def add_arguments(self, parser):
        parser.add_argument("file", type=str)
        parser.add_argument("--clear", action="store_true")

    def handle(self, *args, **options):
        file = options["file"]
        clear = options["clear"]
        self.stdout.write(f"Importing from {file}")
```

### django-typer (Recommended)

`pip install django-typer[rich]`

```python
# myapp/management/commands/import_data.py
from django_typer.management import TyperCommand
import typer

class Command(TyperCommand):
    help = "Import data from a JSON file"

    def handle(
        self,
        file: str = typer.Argument(..., help="Path to JSON file"),
        clear: bool = typer.Option(False, help="Clear existing data first"),
    ):
        if clear:
            MyModel.objects.all().delete()
        self.stdout.write(f"Importing from {file}")
```

### django-click

`pip install django-click`

```python
# myapp/management/commands/import_data.py
import djclick as click

@click.command()
@click.argument("file")
@click.option("--clear", is_flag=True, help="Clear existing data first")
def command(file, clear):
    """Import data from a JSON file."""
    if clear:
        MyModel.objects.all().delete()
    click.echo(f"Importing from {file}")
```

## Packaging and Distribution

### Entry Point via pyproject.toml

```toml
[project.scripts]
mycli = "mypackage.cli:app"
```

After `pip install .` or `pip install -e .`, the command `mycli` is available
system-wide.

### Project Layout

```text
mypackage/
  __init__.py
  cli.py          # Typer app, entry point
  commands/       # Subcommand modules (optional)
    db.py
    export.py
  core.py         # Business logic (keep CLI-free)
```

Separate CLI wiring from business logic. `cli.py` handles arguments, output
formatting, and exit codes. `core.py` handles the actual work and is importable
without Typer/Click.

### Version from Package Metadata

```python
from importlib.metadata import version

app = typer.Typer()

def version_callback(value: bool):
    if value:
        typer.echo(version("mypackage"))
        raise typer.Exit()

@app.callback()
def main(
    version: bool = typer.Option(False, "--version", callback=version_callback,
                                  is_eager=True),
):
    """My CLI tool."""
```

## Common Patterns

### Exit Codes

```python
import sys

@app.command()
def check(path: Path):
    errors = validate(path)
    if errors:
        for e in errors:
            typer.echo(e, err=True)
        raise typer.Exit(code=1)
```

### Confirmation Prompts

```python
@app.command()
def delete(name: str, force: bool = typer.Option(False, "--force")):
    if not force:
        typer.confirm(f"Delete {name}?", abort=True)
    do_delete(name)
```

### Configuration Files

```python
from pathlib import Path
import tomllib

CONFIG_DIR = Path.home() / ".config" / "mycli"
CONFIG_FILE = CONFIG_DIR / "config.toml"

def load_config() -> dict:
    if CONFIG_FILE.exists():
        return tomllib.loads(CONFIG_FILE.read_text())
    return {}
```

Follow XDG conventions: config in `~/.config/appname/`, data in
`~/.local/share/appname/`, cache in `~/.cache/appname/`.

### stderr for Diagnostics

```python
@app.command()
def export(path: Path, verbose: bool = False):
    if verbose:
        typer.echo("Loading data...", err=True)
    data = load()
    # stdout carries data; stderr carries diagnostics
    typer.echo(json.dumps(data))
```

This keeps stdout pipeable: `mycli export data.json | jq '.items'`.

## Anti-Patterns

| Pattern                         | Problem                                        | Fix                                                |
| ------------------------------- | ---------------------------------------------- | -------------------------------------------------- |
| Business logic in CLI functions | Can't test without invoking CLI                | Extract to importable module                       |
| `sys.exit()` deep in library    | Kills the process; caller can't handle errors  | Raise exceptions, let CLI layer call `sys.exit`    |
| Print to stdout for diagnostics | Breaks piping to `jq`, `grep`, other tools     | Use stderr for status messages                     |
| Global state for config         | Hard to test, surprising side effects          | Pass config explicitly or use dependency injection |
| Catching all exceptions         | Hides bugs, produces misleading error messages | Catch specific exceptions at the CLI boundary      |

## See Also

- [Python](python.md) — Data structures, typing, async
- [CLI Pipelines](cli-pipelines.md) — Pipes, xargs, composing shell commands
- [Shell Scripting](shell.md) — Bash patterns, loops, error handling
- [Testing](testing.md) — pytest commands and patterns
