import Globe, { GlobeInstance } from "globe.gl";

import { Hook, makeHook } from "./typed-hook";

class GlobeHook extends Hook {
  private globe: GlobeInstance | undefined;

  public mounted() {
    const self = this;
    const windowWidth = window.innerWidth;
    const windowHeight = window.innerHeight;

    this.globe = new Globe(this.el)
      .globeImageUrl(
        "//cdn.jsdelivr.net/npm/three-globe/example/img/earth-day.jpg",
      )
      .backgroundColor("rgba(0,0,0,0)")
      .showGlobe(true)
      .showAtmosphere(true)
      .onGlobeReady(() => {
        if (!self.globe) return;
        self.globe.pointOfView({
          lat: 20,
          lng: -36,
          altitude: windowWidth && windowWidth > 768 ? 2 : 3,
        });
      })
      .globeOffset([
        windowWidth && windowWidth > 768 ? -100 : 0,
        windowWidth && windowWidth > 768 ? 0 : 100,
      ])
      .width(windowWidth)
      .height(windowHeight - 50);

    const controls = this.globe.controls();
    controls.autoRotate = true;
    controls.autoRotateSpeed = 0.2;

    window.addEventListener("resize", () => {
      if (!self.globe) return;
      const windowWidth = window.innerWidth;
      self.globe
        .globeOffset([
          windowWidth && windowWidth > 768 ? -100 : 0,
          windowWidth && windowWidth > 768 ? 0 : 100,
        ])
        .width(windowWidth)
        .height(windowHeight - 50);
    });
  }

  public updated() {}
}

export default makeHook(GlobeHook);
