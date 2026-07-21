# Tutor

Personal reference site -- commands, mental models, and lesson plans for
software engineers.

**Live site: [tslateman.github.io/tutor](https://tslateman.github.io/tutor/)**

## Content

| Section       | Directory                 | Count | Description                               |
| ------------- | ------------------------- | ----- | ----------------------------------------- |
| Reference     | `src/content/docs/how/`   | 38    | Commands, syntax, quick reference         |
| Mental Models | `src/content/docs/why/`   | 19    | Principles, frameworks, heuristics        |
| Lesson Plans  | `src/content/docs/learn/` | 28    | Progressive 8-lesson plans with exercises |

## Development

```bash
npm install           # Install dependencies
npm run dev           # Start dev server
npm run build         # Production build
npm run preview       # Preview production build
```

## Linting

```bash
brew install vale lychee
npm install           # Provides pinned prettier and markdownlint
make sync             # Download vale style packages
make setup            # Install git hooks
make lint             # Check style (markdownlint + vale + links)
make format           # Format with prettier
make fix              # Format then lint
```

## Adding content

```bash
make new NAME=foo TYPE=how    # Scaffold new guide
make new NAME=bar TYPE=why    # Scaffold new mental model
```

Built with [Astro Starlight](https://starlight.astro.build/).
