const fs = require("fs");
const path = require("path");

module.exports = function ({ matchComponents, theme }) {
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
};
