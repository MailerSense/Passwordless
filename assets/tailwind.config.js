const colors = require("tailwindcss/colors");
const plugin = require("tailwindcss/plugin");
const defaultTheme = require("tailwindcss/defaultTheme");
const fs = require("fs");
const path = require("path");

const scienceBlue = {
  50: "#EFF8FF",
  100: "#D1E9FF",
  200: "#B2DDFF",
  300: "#84CAFF",
  400: "#53B1FD",
  500: "#2E90FA",
  600: "#1570EF",
  700: "#175CD3",
  800: "#1849A9",
  900: "#194185",
  950: "#162a55",
};

const streetlight = {
  100: "#31d585",
  110: "#12B76A",
  120: "#A6F4C5",
  200: "#f79009",
  210: "#F79009",
  220: "#FEDF89",
  300: "#f04437",
  310: "#F04438",
  320: "#FECDCA",
  400: "#2E90FA",
  410: "#2E90FA",
  420: "#B2DDFF",
};

const emerald = {
  50: "#f0fdf6",
  100: "#ddfbeb",
  200: "#bdf5d9",
  300: "#89ecbb",
  400: "#4fd995",
  500: "#31d585",
  600: "#1a9f5e",
  700: "#187d4d",
  800: "#186340",
  900: "#165136",
  950: "#062d1c",
};

const pizazz = {
  50: "#fffbed",
  100: "#fff7d4",
  200: "#ffeba8",
  300: "#ffda71",
  400: "#ffbf38",
  500: "#fda712",
  600: "#f79009",
  700: "#c56a09",
  800: "#9d530f",
  900: "#7e4510",
  950: "#442106",
};

const murder = {
  50: "#fff0f0",
  100: "#ffdddd",
  200: "#ffc0c0",
  300: "#ff9494",
  400: "#ff5757",
  500: "#ff2323",
  600: "#ff0000",
  700: "#d70000",
  800: "#b10303",
  900: "#920a0a",
  950: "#500000",
};

module.exports = {
  safelist: [
    { pattern: /^flag-.+/ },
    { pattern: /^bg-streetlight-\d+/ },
    { pattern: /^from-streetlight-\d+/ },
    { pattern: /^to-streetlight-\d+/ },
  ],
  content: [
    "../lib/*_web.ex",
    "../lib/*_web/**/*.*ex",
    "./js/**/*.js",
    "../deps/live_toast/lib/**/*.*ex",
    "../deps/backpex/**/*.*ex",
  ],
  darkMode: "class",
  theme: {
    extend: {
      boxShadow: {
        m2: "0 1px 2px 0 rgb(16 24 40 / 0.05)",
        m3: "0 1px 2px 0 rgb(16 24 40 / 0.05)",
        0: "0 1px 3px 0 rgb(16 24 40 / 0.1), 0 1px 2px 0px rgb(16 24 40 / 0.06)",
        1: "0 4px 8px -2px rgb(16 24 40 / 0.1), 0 2px 4px -2px rgb(16 24 40 / 0.06)",
        2: "0 12px 16px -4px rgb(16 24 40 / 0.08), 0 4px 6px -2px rgb(16 24 40 / 0.03)",
        3: "0 20px 24px -4px rgb(16 24 40 / 0.08), 0 8px 8px -4px rgb(16 24 40 / 0.03)",
        4: "0 24px 48px -12px rgb(16 24 40 / 0.18)",
      },
      animation: {
        blob: "blob 10s infinite",
      },
      colors: {
        ...colors,
        primary: scienceBlue,
        blue: scienceBlue,
        info: scienceBlue,
        danger: murder,
        warning: pizazz,
        success: emerald,
        streetlight: streetlight,
      },
      fontFamily: {
        sans: ["Inter var", ...defaultTheme.fontFamily.sans],
        display: ["Sora", ...defaultTheme.fontFamily.sans],
      },
    },
  },
  plugins: [
    require("@tailwindcss/forms"),
    require("@tailwindcss/typography"),
    require("@tailwindcss/aspect-ratio"),

    // If you have used `phx-feedback-for` this plugin allows you to do something like `phx-no-feedback:border-zinc-300` on an input. The input border will be zinc-300 unless it has been touched (clicked on). Clicking on the form input removes the `phx-no-feedback` on the element which has the `phx-feedback-for` attribute - usually a parent of the input.
    // Docs: https://hexdocs.pm/phoenix_live_view/form-bindings.html#phx-feedback-for
    plugin(({ addVariant }) =>
      addVariant("phx-no-feedback", [
        ".phx-no-feedback&",
        ".phx-no-feedback &",
      ]),
    ),

    // When you use `phx-click` on an element and click it, the class "phx-click-loading" is applied.
    // With this plugin we can do things like show a spinner when loading.
    // Example usage:
    //     <.button phx-click="x">
    //       <div class="phx-click-loading:hidden">Click me!</div>
    //       <.spinner class="hidden phx-click-loading:!block" />
    //     </.button>
    // Docs: https://hexdocs.pm/phoenix_live_view/bindings.html#loading-states-and-errors
    plugin(({ addVariant }) =>
      addVariant("phx-click-loading", [
        ".phx-click-loading&",
        ".phx-click-loading &",
      ]),
    ),

    // When you use `phx-submit` on a form and submit the form, the 'phx-submit-loading` class is applied to the form.
    // Example usage:
    //     <.form :let={f} for={:user} phx-submit="x">
    //       <div class="hidden phx-submit-loading:!block">
    //         Please wait while we save our content...
    //       </div>
    //       <div class="phx-submit-loading:hidden">
    //         <.text_input form={f} field={:name} />
    //         <button>Submit</button>
    //       </div>
    //     </.form>
    plugin(({ addVariant }) =>
      addVariant("phx-submit-loading", [
        ".phx-submit-loading&",
        ".phx-submit-loading &",
      ]),
    ),

    // When you use `phx-change` on a form and change the form, the 'phx-change-loading` class is applied to the form.
    // Example usage:
    //     <.form :let={f} for={:user} phx-change="x">
    //       <div class="hidden phx-change-loading:!block">
    //         Please wait while we save our content...
    //       </div>
    //       <div class="phx-change-loading:hidden">
    //         <.text_input form={f} field={:name} />
    //         <button>Submit</button>
    //       </div>
    //     </.form>
    plugin(({ addVariant }) =>
      addVariant("phx-change-loading", [
        ".phx-change-loading&",
        ".phx-change-loading &",
      ]),
    ),

    // Embed new iconset
    plugin(function ({ matchComponents, theme }) {
      let iconsDir = path.join(__dirname, "./vendor/remix");
      let values = {};

      fs.readdirSync(iconsDir).map((file) => {
        if (path.extname(file) !== ".svg") {
          return;
        }

        let name = path.basename(file, ".svg");
        values[name] = { name, fullPath: path.join(iconsDir, file) };
      });

      matchComponents(
        {
          remix: ({ name, fullPath }) => {
            let content = fs
              .readFileSync(fullPath)
              .toString()
              .replace(/\r?\n|\r/g, "");
            return {
              [`--remix-${name}`]: `url('data:image/svg+xml;utf8,${content}')`,
              "-webkit-mask": `var(--remix-${name})`,
              mask: `var(--remix-${name})`,
              "background-color": "currentColor",
              "vertical-align": "middle",
              display: "inline-block",
              width: theme("spacing.5"),
              height: theme("spacing.5"),
            };
          },
        },
        { values },
      );
    }),

    // Embed custom iconset
    plugin(function ({ matchComponents, theme }) {
      let iconsDir = path.join(__dirname, "./vendor/custom");
      let values = {};

      fs.readdirSync(iconsDir).map((file) => {
        if (path.extname(file) !== ".svg") {
          return;
        }

        let name = path.basename(file, ".svg");
        values[name] = { name, fullPath: path.join(iconsDir, file) };
      });

      matchComponents(
        {
          custom: ({ name, fullPath }) => {
            let content = fs
              .readFileSync(fullPath)
              .toString()
              .replace(/\r?\n|\r/g, "");

            return {
              [`--custom-${name}`]: `url('data:image/svg+xml;base64,${btoa(
                content,
              )}')`,
              "-webkit-mask": `var(--custom-${name})`,
              mask: `var(--custom-${name})`,
              "background-color": "currentColor",
              "vertical-align": "middle",
              display: "inline-block",
              width: theme("spacing.5"),
              height: theme("spacing.5"),
            };
          },
        },
        { values },
      );
    }),

    // Embed flag iconset
    plugin(function ({ matchComponents, theme }) {
      let iconsDir = path.join(__dirname, "./vendor/flag");
      let values = {};

      fs.readdirSync(iconsDir).map((file) => {
        if (path.extname(file) !== ".svg") {
          return;
        }

        let name = path.basename(file, ".svg");
        values[name] = { name, fullPath: path.join(iconsDir, file) };
      });

      matchComponents(
        {
          flag: ({ name, fullPath }) => {
            let content = fs
              .readFileSync(fullPath)
              .toString()
              .replace(/\r?\n|\r/g, "");

            return {
              [`--flag-${name}`]: `url('data:image/svg+xml;base64,${btoa(
                content,
              )}')`,
              background: `var(--flag-${name}) no-repeat`,
              display: "inline-block",
              width: theme("spacing.5"),
              height: theme("spacing.5"),
            };
          },
        },
        { values },
      );
    }),

    // Embed heroicon iconset
    plugin(function ({ matchComponents, theme }) {
      let iconsDir = path.join(__dirname, "../deps/heroicons/optimized");
      let values = {};
      let icons = [
        ["", "/24/outline"],
        ["-solid", "/24/solid"],
        ["-mini", "/20/solid"],
        ["-micro", "/16/solid"],
      ];
      icons.forEach(([suffix, dir]) => {
        fs.readdirSync(path.join(iconsDir, dir)).forEach((file) => {
          if (path.extname(file) !== ".svg") {
            return;
          }

          let name = path.basename(file, ".svg") + suffix;
          values[name] = { name, fullPath: path.join(iconsDir, dir, file) };
        });
      });
      matchComponents(
        {
          hero: ({ name, fullPath }) => {
            let content = fs
              .readFileSync(fullPath)
              .toString()
              .replace(/\r?\n|\r/g, "");
            let size = theme("spacing.6");
            if (name.endsWith("-mini")) {
              size = theme("spacing.5");
            } else if (name.endsWith("-micro")) {
              size = theme("spacing.4");
            }
            return {
              [`--hero-${name}`]: `url('data:image/svg+xml;utf8,${content}')`,
              "-webkit-mask": `var(--hero-${name})`,
              mask: `var(--hero-${name})`,
              "mask-repeat": "no-repeat",
              "background-color": "currentColor",
              "vertical-align": "middle",
              display: "inline-block",
              width: size,
              height: size,
            };
          },
        },
        { values },
      );
    }),
  ],
};
