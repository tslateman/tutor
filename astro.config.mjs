// @ts-check
import { defineConfig } from "astro/config";
import starlight from "@astrojs/starlight";

// https://astro.build/config
export default defineConfig({
  site: "https://tslateman.github.io",
  base: "/tutor",
  integrations: [
    starlight({
      title: "Tutor",
      editLink: {
        baseUrl: "https://github.com/tslateman/tutor/edit/main/",
      },
      lastUpdated: true,
      tableOfContents: { maxHeadingLevel: 3 },
      sidebar: [
        {
          label: "Reference",
          items: [
            {
              label: "Languages",
              items: [
                { label: "Python", slug: "how/python" },
                { label: "TypeScript", slug: "how/typescript" },
                { label: "Rust", slug: "how/rust" },
                { label: "SQL", slug: "how/sql" },
                { label: "Regex", slug: "how/regex" },
                { label: "Shell Scripting", slug: "how/shell" },
                { label: "Python CLI", slug: "how/python-cli" },
              ],
            },
            {
              label: "Developer Tools",
              items: [
                { label: "Git", slug: "how/git" },
                { label: "Docker", slug: "how/docker" },
                { label: "tmux", slug: "how/tmux" },
                { label: "Neovim", slug: "how/neovim" },
                { label: "Testing", slug: "how/testing" },
                { label: "CI/CD", slug: "how/ci-cd" },
                { label: "Debugging", slug: "how/debugging" },
                { label: "Terminal Emulators", slug: "how/terminal-emulators" },
                {
                  label: "Learning a Language",
                  slug: "how/learning-a-language",
                },
              ],
            },
            {
              label: "Systems",
              items: [
                { label: "Unix CLI", slug: "how/unix" },
                { label: "macOS", slug: "how/macos" },
                { label: "Filesystem", slug: "how/filesystem" },
                {
                  label: "Filesystem (Advanced)",
                  slug: "how/filesystem-advanced",
                },
                { label: "HTTP", slug: "how/http" },
                { label: "PostgreSQL", slug: "how/postgres" },
                { label: "Kubernetes", slug: "how/k8s" },
                { label: "System Design", slug: "how/system-design" },
                { label: "Performance", slug: "how/performance" },
                { label: "jq", slug: "how/jq" },
              ],
            },
            {
              label: "AI & Workflows",
              items: [
                { label: "AI CLI", slug: "how/ai-cli" },
                { label: "Claude Code", slug: "how/claude-code" },
                {
                  label: "Agent Orchestration",
                  slug: "how/agent-orchestration",
                },
                { label: "CLI Pipelines", slug: "how/cli-pipelines" },
                { label: "Diagramming", slug: "how/diagramming" },
              ],
            },
            {
              label: "Security",
              items: [
                { label: "Cryptography", slug: "how/cryptography" },
                { label: "Security Scanning", slug: "how/security-scanning" },
              ],
            },
          ],
        },
        {
          label: "Mental Models",
          items: [
            {
              label: "Thinking",
              items: [
                { label: "Thinking", slug: "why/thinking" },
                { label: "Reasoning", slug: "why/reasoning" },
                { label: "Problem Solving", slug: "why/problem-solving" },
                { label: "Learning", slug: "why/learning" },
                { label: "Debugging", slug: "why/debugging" },
              ],
            },
            {
              label: "Design",
              items: [
                { label: "Complexity", slug: "why/complexity" },
                { label: "Testing", slug: "why/testing" },
                { label: "API Design", slug: "why/api-design" },
                {
                  label: "Information Architecture",
                  slug: "why/information-architecture",
                },
                { label: "Knowledge Design", slug: "why/knowledge-design" },
                { label: "Specification", slug: "why/specification" },
              ],
            },
            {
              label: "AI & Systems",
              items: [
                { label: "Agent Memory", slug: "why/agent-memory" },
                { label: "Orchestration", slug: "why/orchestration" },
                { label: "CLI-First", slug: "why/cli-first" },
                { label: "AI Adoption", slug: "why/ai-adoption" },
              ],
            },
          ],
        },
        {
          label: "Lesson Plans",
          items: [
            {
              label: "Languages",
              items: [
                { label: "Python", slug: "learn/python-lesson-plan" },
                { label: "TypeScript", slug: "learn/typescript-lesson-plan" },
                { label: "Rust", slug: "learn/rust-lesson-plan" },
                { label: "Go", slug: "learn/golang-lesson-plan" },
              ],
            },
            {
              label: "Tools & Systems",
              items: [
                { label: "Git", slug: "learn/git-lesson-plan" },
                { label: "GitHub", slug: "learn/github-lesson-plan" },
                { label: "tmux", slug: "learn/tmux-lesson-plan" },
                { label: "Ghostty", slug: "learn/ghostty-lesson-plan" },
                {
                  label: "Operating Systems",
                  slug: "learn/operating-systems-lesson-plan",
                },
                { label: "Networking", slug: "learn/networking-lesson-plan" },
              ],
            },
            {
              label: "Engineering",
              items: [
                {
                  label: "System Design",
                  slug: "learn/system-design-lesson-plan",
                },
                { label: "Data Models", slug: "learn/data-models-lesson-plan" },
                { label: "Concurrency", slug: "learn/concurrency-lesson-plan" },
                { label: "Security", slug: "learn/security-lesson-plan" },
                {
                  label: "Cryptography",
                  slug: "learn/cryptography-lesson-plan",
                },
                {
                  label: "Specification",
                  slug: "learn/specification-lesson-plan",
                },
              ],
            },
            {
              label: "Thinking & Communication",
              items: [
                {
                  label: "Technical Writing",
                  slug: "learn/technical-writing-lesson-plan",
                },
                { label: "Reasoning", slug: "learn/reasoning-lesson-plan" },
                {
                  label: "Information Architecture",
                  slug: "learn/information-architecture-lesson-plan",
                },
              ],
            },
            {
              label: "AI & Context",
              items: [
                {
                  label: "Agentic Workflows",
                  slug: "learn/agentic-workflows-lesson-plan",
                },
                {
                  label: "Context & Complexity",
                  slug: "learn/context-complexity-lesson-plan",
                },
              ],
            },
          ],
        },
      ],
    }),
  ],
});
