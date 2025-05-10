import { GlobeInstance } from "globe.gl";
import Sortable from "sortablejs";

import { Hook, makeHook } from "./typed-hook";

class SortableHook extends Hook {
  private globe: GlobeInstance | undefined;

  public mounted() {
    const sorter = new Sortable(this.el, {
      animation: 150,
      delay: 100,
      handle: ".drag-handle",
      dragClass: "drag-item",
      ghostClass: "drag-ghost",
      forceFallback: true,
      onEnd: (e) => {
        const params = { old: e.oldIndex, new: e.newIndex, ...e.item.dataset };
        this.pushEventTo(this.el, "reposition", params);
      },
    });
  }

  public updated() {}
}

export default makeHook(SortableHook);
