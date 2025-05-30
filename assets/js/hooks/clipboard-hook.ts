import { Hook, makeHook } from "./typed-hook";

class ClipboardHook extends Hook {
	public mounted() {
		this.run("mounted", this.el);
	}

	public updated() {
		this.run("updated", this.el);
	}

	private run(_lifecycleMethod: "mounted" | "updated", el: HTMLElement) {
		if (navigator.clipboard) {
			el.addEventListener("click", () => {
				this.copyToClipboard(el);
				this.toggleState(el);
				setTimeout(() => {
					this.toggleState(el);
				}, 1500);
			});
		}
	}

	private toggleState(el: HTMLElement) {
		el.querySelector(".before-copied")?.classList.toggle("hidden");
		el.querySelector(".after-copied")?.classList.toggle("hidden");
	}

	private copyToClipboard(el: HTMLElement) {
		const textToCopy = el.dataset.content;
		if (!textToCopy || textToCopy == null) {
			throw new Error("No content to copy.");
		}

		if (navigator.clipboard) {
			navigator.clipboard.writeText(textToCopy);
		} else {
			alert(
				"Sorry, your browser does not support clipboard copy. Please upgrade it."
			);
		}
	}
}

export default makeHook(ClipboardHook);
