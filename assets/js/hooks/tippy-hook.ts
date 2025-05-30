import tippy, { Instance, Props } from "tippy.js";

import { Hook, makeHook } from "./typed-hook";

class TippyHook extends Hook {
	public mounted() {
		this.run("mounted", this.el);
	}

	public updated() {
		this.run("updated", this.el);
	}

	private run(lifecycleMethod: "mounted" | "updated", el: HTMLElement) {
		let tippyInstance: Instance<Props>;

		const templateSelector = this.el.dataset.templateSelector;
		if (templateSelector) {
			const template = el.querySelector(templateSelector);

			if (template !== null) {
				tippyInstance = tippy(el, {
					theme: "light",
					content: template.innerHTML,
					allowHTML: true,
				});
			}
		} else {
			const disableOnMount = el.dataset.disableTippyOnMount === "true";

			tippyInstance = tippy(el, {
				theme: "tomato",
				maxWidth: 350,
			});

			if (lifecycleMethod === "mounted" && disableOnMount) {
				tippyInstance.disable();
			}
		}
	}
}

export default makeHook(TippyHook);
