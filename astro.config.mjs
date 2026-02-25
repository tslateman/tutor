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
      sidebar: [
        {
          label: "Reference",
          autogenerate: { directory: "how" },
        },
        {
          label: "Mental Models",
          autogenerate: { directory: "why" },
        },
        {
          label: "Lesson Plans",
          autogenerate: { directory: "learn" },
        },
      ],
    }),
  ],
});
