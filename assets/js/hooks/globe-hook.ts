import { scaleSequentialSqrt } from "d3-scale";
import { interpolateYlOrRd } from "d3-scale-chromatic";
import Globe, { GlobeInstance } from "globe.gl";

import { Hook, makeHook } from "./typed-hook";

interface GeoData {
  lat: number;
  lon: number;
  count: number;
  city: string;
}

interface GeoPayload {
  geo_data: GeoData[];
}

interface Countries {
  features: object[];
}

class GlobeHook extends Hook {
  private globe: GlobeInstance | undefined;

  public mounted() {
    const self = this;
    const windowWidth = window.innerWidth;
    const windowHeight = window.innerHeight;
    const randomShader = `rgba(120, 140, 110, ${Math.random() / 2 + 0.5})`;
    const highest = 1;
    const normalized = 5 / 30;
    const weightColor = scaleSequentialSqrt(interpolateYlOrRd).domain([
      0,
      highest * normalized * 15,
    ]);

    this.globe = new Globe(this.el)
      .globeImageUrl(
        "//cdn.jsdelivr.net/npm/three-globe/example/img/earth-day.jpg",
      )
      .backgroundColor("rgba(0,0,0,0)")
      .showGlobe(true)
      .showAtmosphere(true)
      .hexPolygonResolution(3)
      .hexPolygonMargin(0.2)
      .hexBinResolution(3)
      .hexPolygonAltitude(0.001)
      .hexBinMerge(true)
      .hexBinPointWeight("count")
      .hexPolygonColor((e: any) => {
        return randomShader;
      })
      .hexTopColor((d) => weightColor(d.sumWeight))
      .hexSideColor((d) => weightColor(d.sumWeight))
      .onGlobeReady(() => {
        if (!self.globe) return;
        self.globe.pointOfView({
          lat: 20,
          lng: -36,
          altitude: windowWidth && windowWidth > 768 ? 2 : 3,
        });
      })
      .globeOffset([
        windowWidth && windowWidth > 768 ? -200 : 0,
        windowWidth && windowWidth > 768 ? 0 : 100,
      ])
      .width(windowWidth)
      .height(windowHeight - 50);

    const controls = this.globe.controls();
    controls.autoRotate = true;
    controls.autoRotateSpeed = 0.2;

    const countriesSource =
      this.el.dataset.countriesSource ?? "/json/countries.geojson";

    fetch(countriesSource)
      .then((res) => {
        if (!res.ok) {
          throw new Error(`HTTP ${res.status}`);
        }
        return res.json();
      })
      .then((data: Countries) => {
        this.globe?.hexPolygonsData(data.features);
      })
      .catch((err) => {
        console.error("Failed to load countries.geojson", err);
      });

    window.addEventListener("resize", () => {
      if (!self.globe) return;
      const windowWidth = window.innerWidth;
      self.globe
        .globeOffset([
          windowWidth && windowWidth > 768 ? -200 : 0,
          windowWidth && windowWidth > 768 ? 0 : 100,
        ])
        .width(windowWidth)
        .height(windowHeight - 50);
    });

    this.handleEvent("get_geo_data", (data: GeoPayload) => {
      if (this.globe) {
        this.globe.hexBinPointsData(data.geo_data);
      }
    });

    this.pushEvent("send_geo_data", {});
  }

  public updated() {}
}

export default makeHook(GlobeHook);
