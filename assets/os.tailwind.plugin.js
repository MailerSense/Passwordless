const fs = require("node:fs");
const path = require("node:path");

module.exports = ({ matchComponents, theme }) => {
	const iconsDir = path.join(__dirname, "./vendor/os");
	const values = {};

	fs.readdirSync(iconsDir).map((file) => {
		if (path.extname(file) !== ".svg") {
			return;
		}

		const name = path.basename(file, ".svg");
		values[name] = { name, fullPath: path.join(iconsDir, file) };
	});

	matchComponents(
		{
			os: ({ name, fullPath }) => {
				const content = fs
					.readFileSync(fullPath)
					.toString()
					.replace(/\r?\n|\r/g, "");

				return {
					[`--os-${name}`]: `url('data:image/svg+xml;utf8,${encodeURIComponent(
						content
					)}')`,
					background: `var(--os-${name}) no-repeat`,
					display: "inline-block",
					width: theme("spacing.5"),
					height: theme("spacing.5"),
				};
			},
		},
		{ values }
	);
};
