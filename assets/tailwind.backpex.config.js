const colors = require("tailwindcss/colors");
const plugin = require("tailwindcss/plugin");
const fs = require("fs");
const path = require("path");

const lasPalmas = {
  50: "#fafee7",
  100: "#f3fdca",
  200: "#e8fb9b",
  300: "#cdf348",
  400: "#bee932",
  500: "#a0cf13",
  600: "#7ba60a",
  700: "#5d7e0d",
  800: "#4b6311",
  900: "#3f5413",
  950: "#202f04",
};

module.exports = {
  content: [
    "../lib/*_web.ex",
    "../lib/*_web/**/*.*ex",
    "../deps/backpex/**/*.*ex",
  ],
  darkMode: "class",
  daisyui: {
    themes: [
      {
        light: {
          ...require("daisyui/src/theming/themes").light,
          primary: lasPalmas[500],
          "primary-content": "white",
          secondary: "#f39325",
          "secondary-content": "white",
          "--rounded-box": "0.5rem",
        },
        dark: {
          ...require("daisyui/src/theming/themes").dracula,
          primary: lasPalmas[500],
          "base-100": colors.gray[800],
          "--rounded-box": "0.5rem",
        },
      },
    ],
  },
  plugins: [
    require("daisyui"),

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
