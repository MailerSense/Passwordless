const colors = require("tailwindcss/colors");
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
          primary: scienceBlue[500],
          "primary-content": "white",
          secondary: "#f39325",
          "secondary-content": "white",
          "--rounded-box": "0.5rem",
        },
        dark: {
          ...require("daisyui/src/theming/themes").dracula,
          primary: scienceBlue[500],
          "base-100": colors.slate[800],
          "--rounded-box": "0.5rem",
        },
      },
    ],
  },
  plugins: [require("daisyui")],
};
