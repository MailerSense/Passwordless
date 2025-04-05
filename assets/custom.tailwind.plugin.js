const fs = require("fs");
const path = require("path");

module.exports = function ({ matchComponents, theme }) {
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
          [`--custom-${name}`]: `url('data:image/svg+xml;utf8,${encodeURIComponent(
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
};
