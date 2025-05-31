import { animate } from "motion";

import { Hook, makeHook } from "./typed-hook";

declare global {
	interface HTMLElement {
		order: number;
		targetDestination: string;
	}
}

// time in ms to wait before removal, but after animation
const removalTime = 5;
// animation time in ms
const animationTime = 550;
// whether flashes should be counted in maxItems
const maxItemsIgnoresFlashes = true;
// gap in px between toasts
const gap = 15;

let lastTsGlobal: HTMLElement[] = [];

class LiveToastHook extends Hook {
	private duration: number;
	private maxItems: number;

	public mounted() {
		this.duration = 6000;
		this.maxItems = 3;

		this.el.addEventListener("show-error", async (_event) => {
			const delayTime = Number.parseInt(this.el.dataset.delay || "0");
			await new Promise((resolve) => setTimeout(resolve, delayTime));

			// todo: in the future use this to execute the data-disconnected command
			// https://elixirforum.com/t/can-we-use-liveview-js-commands-inside-a-hook/67324/8

			// const command = this.el.getAttribute('data-disconnected')
			// this.liveSocket.execJS(this.el, command)

			// (don't want to do this quite yet because 1.0 is pretty new)
			// also repeat this on hide.

			this.el.style.display = "flex";
		});

		this.el.addEventListener("hide-error", (_event) => {
			this.el.style.display = "none";
		});

		// for the special flashes, check if they are visible, and if not, return early out of here.
		if (
			["server-error", "client-error"].includes(this.el.id) &&
			isHidden(document.getElementById(this.el.id))
		) {
			return;
		}

		window.addEventListener("phx:clear-flash", (e) => {
			this.pushEvent("lv:clear-flash", {
				key: (e as CustomEvent<{ key: string }>).detail.key,
			});
		});

		window.addEventListener("flash-leave", async (event) => {
			if (event.target === this.el) {
				// animate this flash sliding out
				this.doAnimations(this.duration, this.maxItems, this.el);
				await this.animateOut();
			}
		});

		// begin actually showing the toast through this call to the animation function
		this.doAnimations(this.duration, this.maxItems);

		let durationOverride = this.duration;
		if (this.el.dataset.duration !== undefined) {
			durationOverride = Number.parseInt(this.el.dataset.duration);
		}

		let flashDuration: number | undefined;
		if (this.el.dataset.flashDuration !== undefined) {
			flashDuration = Number.parseInt(this.el.dataset.flashDuration);
		}

		// skip the removal code if this is a flash, if autoHideFlash is nullish
		if (isFlash(this.el) && !flashDuration) {
			return;
		}

		// this could be condensed
		if (flashDuration) {
			// do stuff
			window.setTimeout(async () => {
				// animate this element sliding down, opacity to 0, with delay time
				await this.animateOut();

				const kind = this.el.dataset.kind;

				if (kind) {
					this.pushEvent("lv:clear-flash", { key: kind });
				}
			}, flashDuration + removalTime);
		} else if (durationOverride !== 0) {
			window.setTimeout(async () => {
				// animate this element sliding down, opacity to 0, with delay time
				await this.animateOut();

				this.pushEventTo("#toast-group", "clear", { id: this.el.id });
			}, durationOverride + removalTime);
		}
	}

	public updated() {
		const keyframes = { y: [this.el.targetDestination] };
		animate(this.el, keyframes, { duration: 0 });
	}

	public destroyed() {
		this.doAnimations(this.duration, this.maxItems);
	}

	private doAnimations(
		animationDelayTime: number,
		maxItems: number,
		elToRemove?: HTMLElement
	) {
		const ts: HTMLElement[] = [];
		let toasts = Array.from(
			document.querySelectorAll<HTMLElement>(
				'#toast-group [phx-hook="LiveToast"]'
			)
		)
			.map((t) => {
				if (isHidden(t)) {
					return null;
				}
				return t;
			})
			.filter(Boolean)
			.reverse();

		if (elToRemove) {
			toasts = toasts.filter((t) => t !== elToRemove);
		}

		// Traverse through all toasts, in order they appear in the dom, for which they are NOT hidden, and assign el.order to
		// their index
		for (let i = 0; i < toasts.length; i++) {
			const toast = toasts[i];
			if (toast === null || isHidden(toast)) {
				continue;
			}
			toast.order = i;
			ts[i] = toast;
		}

		for (const toast of ts) {
			const max = maxItemsIgnoresFlashes ? maxItems + flashCount() : maxItems;

			let direction = "";

			if (
				toast.dataset.corner === "bottom_left" ||
				toast.dataset.corner === "bottom_center" ||
				toast.dataset.corner === "bottom_right"
			) {
				direction = "-";
			}

			// Calculate the translateY value with gap
			// now that they can be different heights, we need to actually caluclate the real heights and add them up.
			let val = 0;

			for (let j = 0; j < toast.order; j++) {
				val += ts[j].offsetHeight + gap;
			}

			// Calculate opacity based on position
			const opacity = toast.order > max ? 0 : 1 - (toast.order - max + 1);

			// also if this item moved past the max limit, disable click events on it
			if (toast.order >= max) {
				toast.classList.remove("pointer-events-auto");
			} else {
				toast.classList.add("pointer-events-auto");
			}

			const keyframes = { y: [`${direction}${val}px`], opacity: [opacity] };

			// if element is entering for the first time, start below the fold
			if (toast.order === 0 && lastTsGlobal.includes(toast) === false) {
				const val = toast.offsetHeight + gap;
				const oppositeDirection = direction === "-" ? "" : "-";
				keyframes.y.unshift(`${oppositeDirection}${val}px`);
				keyframes.opacity.unshift(0);
			}

			toast.targetDestination = `${direction}${val}px`;

			const duration = animationTime / 1000;

			// as of right now this is not exposed to end users, but
			// it's 'plumbed out' if we want to make it so in the future
			const delayTime = Number.parseInt(this.el.dataset.delay || "0") / 1000;

			animate(toast, keyframes, {
				duration,
				easing: [0.22, 1.0, 0.36, 1.0],
				delay: delayTime,
			});
			toast.order += 1;

			// decrease z-index
			toast.style.zIndex = (50 - toast.order).toString();

			// if this element moved past the max item limit, send the signal to remove it
			// should this be shorted than delay time?
			// also what about elements moving down when you close one?
			window.setTimeout(() => {
				if (toast.order > max) {
					this.pushEventTo("#toast-group", "clear", { id: toast.id });
				}
			}, animationDelayTime + removalTime);

			lastTsGlobal = ts;
		}
	}

	private async animateOut() {
		const val = (this.el.order - 2) * 100 + (this.el.order - 2) * gap;

		let direction = "";

		if (
			this.el.dataset.corner === "bottom_left" ||
			this.el.dataset.corner === "bottom_center" ||
			this.el.dataset.corner === "bottom_right"
		) {
			direction = "-";
		}

		const animation = animate(
			this.el,
			{ y: `${direction}${val}%`, opacity: 0 },
			{
				opacity: {
					duration: 0.2,
					easing: "ease-out",
				},
				duration: 0.3,
				easing: "ease-out",
			}
		);

		await animation.finished;
	}
}

export default makeHook(LiveToastHook);

function isHidden(el: HTMLElement | null) {
	if (el === null) {
		return true;
	}

	return el.offsetParent === null;
}

function isFlash(el: HTMLElement) {
	return el.dataset.component === "flash";
}

// number of flashes that aren't hidden
function flashCount() {
	let num = 0;

	if (!isHidden(document.getElementById("server-error"))) {
		num += 1;
	}

	if (!isHidden(document.getElementById("client-error"))) {
		num += 1;
	}

	if (!isHidden(document.getElementById("flash-info"))) {
		num += 1;
	}

	if (!isHidden(document.getElementById("flash-error"))) {
		num += 1;
	}

	return num;
}
