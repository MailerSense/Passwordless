const fs = require("fs");
const path = require("path");

module.exports = function ({ matchComponents, theme }) {
  let iconsDir = path.join(__dirname, "./vendor/flag");
  let values = {};
  let names = [];

  const outputFile = path.join(__dirname, "icon-flags.txt");

  fs.readdirSync(iconsDir).map((file) => {
    if (path.extname(file) !== ".svg") {
      return;
    }

    let name = path.basename(file, ".svg");
    names.push("flag-" + name);
    values[name] = { name, fullPath: path.join(iconsDir, file) };
  });

  fs.writeFileSync(outputFile, names.join("\n"), "utf-8");

  matchComponents(
    {
      flag: ({ name, fullPath }) => {
        let content = fs
          .readFileSync(fullPath)
          .toString()
          .replace(/\r?\n|\r/g, "");

        return {
          [`--flag-${name}`]: `url('data:image/svg+xml;utf8,${encodeURIComponent(
            content,
          )}')`,
          background: `var(--flag-${name}) no-repeat`,
          display: "inline-block",
        };
      },
    },
    { values },
  );
};
