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
        mono: ["JetBrains Mono", ...defaultTheme.fontFamily.mono],
        display: ["Sora", ...defaultTheme.fontFamily.sans],
      },
    },
  },
  plugins: [],
};
