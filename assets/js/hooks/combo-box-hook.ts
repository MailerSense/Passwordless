import { Hook, makeHook } from "phoenix_typed_hook";
import TomSelect from "tom-select";
import { TomInput } from "tom-select/dist/cjs/types";

class ComboBoxHook extends Hook {
  private tomSelect: TomSelect | undefined;

  public mounted() {
    this.init(this.el);
  }

  public updated() {
    const el = this.el;

    const latestSelect = el.querySelector(
      "select.combo-box-latest",
    ) as HTMLInputElement;
    const initialSelect = el.querySelector(
      "select.combo-box",
    ) as HTMLInputElement;

    if (!latestSelect || !initialSelect) {
      throw new Error("Could not find the latest or initial select element.");
    }

    initialSelect.value = latestSelect.value;

    const latestOptions = latestSelect.querySelectorAll("option");
    const initialOptions = initialSelect.querySelectorAll("option");

    // Convert latestOptions and initialOptions to arrays
    const latestOptionsArray = Array.from(latestOptions);
    const initialOptionsArray = Array.from(initialOptions);

    // Sort the arrays by their values
    latestOptionsArray.sort((a, b) => a.value.localeCompare(b.value));
    initialOptionsArray.sort((a, b) => a.value.localeCompare(b.value));

    if (latestOptionsArray && initialOptionsArray) {
      // If the options have changed, destroy the TomSelect instance and re-initialize it with the new options.
      if (latestOptionsArray.length !== initialOptionsArray.length) {
        this.reInit(el);
      } else {
        for (let i = 0; i < latestOptionsArray.length; i++) {
          const latestOption = latestOptionsArray[i];
          const initialOption = initialOptionsArray[i];

          if (
            latestOption.label !== initialOption.label ||
            latestOption.value !== initialOption.value
          ) {
            this.reInit(el);
            break;
          }
        }
      }

      for (let i = 0; i < latestOptionsArray.length; i++) {
        const latestOption = latestOptionsArray[i];
        const initialOption = initialOptionsArray[i];

        if (initialOption && latestOption.selected !== initialOption.selected) {
          initialOption.selected = latestOption.selected;
        }
      }
    }
  }

  public destroyed() {
    const el = this.el;
    const wrapper = el.querySelector(".combo-box-wrapper");

    if (wrapper) {
      wrapper.classList.add("hidden");
    }

    if (this.tomSelect) {
      this.tomSelect.destroy();
    }
  }

  private reInit(el: HTMLElement) {
    const latestSelect = el.querySelector("select.combo-box-latest");
    const initialSelect = el.querySelector("select.combo-box");

    if (this.tomSelect) {
      this.tomSelect.destroy();
    }

    if (latestSelect && initialSelect) {
      initialSelect.innerHTML = latestSelect.innerHTML;
    }

    this.init(el);
  }

  private init(el: HTMLElement) {
    const options = JSON.parse(el.dataset.options ?? "{}");
    const plugins = JSON.parse(el.dataset.plugins ?? "{}");
    // @ts-expect-error: This is a global variable that is set in the Phoenix template.
    const globalOpts = window[el.dataset.globalOptions];
    const selectEl = el.querySelector("select.combo-box");
    const wrapper = el.querySelector(".combo-box-wrapper");

    const tomSelectOptions = {
      plugins,
      ...options,
      ...globalOpts,
    };

    if (selectEl) {
      this.tomSelect = new TomSelect(selectEl as TomInput, tomSelectOptions);
    }

    if (wrapper) {
      wrapper.classList.remove("opacity-0");
    }
  }
}

export default makeHook(ComboBoxHook);
