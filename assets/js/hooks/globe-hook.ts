import { scaleSequentialSqrt } from "d3-scale";
import { interpolateSpectral } from "d3-scale-chromatic";
import Globe, { GlobeInstance } from "globe.gl";
import { MeshPhongMaterial } from "three";
import { Hook, makeHook } from "./typed-hook";

interface GeoData {
	lat: number;
	lon: number;
	city: string;
	count: number;
	absolute: number;
}

interface GeoPayload {
	geo_data: GeoData[];
	resolution: number;
}

interface Countries {
	features: object[];
}

class GlobeHook extends Hook {
	private globe: GlobeInstance | undefined;

	public mounted() {
		const windowWidth = window.innerWidth;
		const windowHeight = window.innerHeight;
		const randomShader = "rgba(120, 140, 110, 0.5)";
		const material = new MeshPhongMaterial({
			color: "hsl(221, 59%, 21%)",
			transparent: false,
			opacity: 1,
		});

		this.globe = new Globe(this.el)
			.globeMaterial(material)
			.backgroundColor("rgba(0,0,0,0)")
			.showGlobe(true)
			.showAtmosphere(true)
			.hexPolygonResolution(3)
			.hexPolygonMargin(0.2)
			.hexBinResolution(3)
			.hexPolygonAltitude(0.001)
			.hexBinMerge(true)
			.hexBinPointWeight("count")
			.hexPolygonColor((_e: any) => {
				return randomShader;
			})
			.onGlobeReady(() => {
				if (!this.globe) {
					return;
				}
				this.globe.pointOfView({
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
			});

		window.addEventListener("resize", () => {
			if (!this.globe) {
				return;
			}
			const windowWidth = window.innerWidth;
			this.globe
				.globeOffset([
					windowWidth && windowWidth > 768 ? -200 : 0,
					windowWidth && windowWidth > 768 ? 0 : 100,
				])
				.width(windowWidth)
				.height(windowHeight - 50);
		});

		this.handleEvent("get_geo_data", (data: GeoPayload) => {
			if (this.globe) {
				const { geo_data, resolution } = data;
				const highest =
					geo_data.reduce((acc, curr) => Math.max(acc, curr.absolute), 0) ?? 1;
				const normalized = 5 / resolution;
				const weightColor = scaleSequentialSqrt(interpolateSpectral).domain([
					0,
					highest * normalized * 15,
				]);

				this.globe
					.hexBinPointsData(geo_data)
					.hexTopColor((d) => weightColor(d.sumWeight))
					.hexSideColor((d) => weightColor(d.sumWeight));
			}
		});

		this.pushEvent("send_geo_data", {});
	}
}

export default makeHook(GlobeHook);
