const fs = require("fs");
const path = require("path");

module.exports = function ({ matchComponents, theme }) {
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
};
