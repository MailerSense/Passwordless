import ApexCharts from "apexcharts";
import { Hook, makeHook } from "phoenix_typed_hook";

class ChartHook extends Hook {
  public mounted() {
    this.run("mounted", this.el);
  }

  public updated() {
    this.run("updated", this.el);
  }

  private run(_lifecycleMethod: "mounted" | "updated", el: HTMLElement) {
    var options = {
      series: [
        {
          name: "series1",
          data: [31, 40, 28, 51, 42, 109, 100],
        },
        {
          name: "series2",
          data: [11, 32, 45, 32, 34, 52, 41],
        },
        {
          name: "series3",
          data: [32, 45, 32, 34, 52, 41, 32],
        },
        {
          name: "series4",
          data: [62, 45, 62, 74, 21, 13, 56],
        },
      ],
      chart: {
        height: 350,
        type: "area",
        toolbar: {
          show: false,
        },
        animations: {
          enabled: true,
          speed: 500,
        },
        stacked: false,
      },
      dataLabels: {
        enabled: false,
      },
      stroke: {
        curve: "smooth",
        width: 4,
      },
      xaxis: {
        type: "datetime",
        categories: [
          "2018-09-19T00:00:00.000Z",
          "2018-09-19T01:30:00.000Z",
          "2018-09-19T02:30:00.000Z",
          "2018-09-19T03:30:00.000Z",
          "2018-09-19T04:30:00.000Z",
          "2018-09-19T05:30:00.000Z",
          "2018-09-19T06:30:00.000Z",
        ],
        labels: {
          show: true,
          style: {
            colors: "#4b5563",
            fontSize: "12px",
          },
        },
      },
      yaxis: {
        labels: {
          show: true,
          style: {
            colors: "#4b5563",
            fontSize: "12px",
          },
        },
      },
      tooltip: {
        x: {
          format: "dd/MM/yy HH:mm",
        },
      },
      legend: {
        show: false,
        position: "top",
        horizontalAlign: "left",
      },
      fill: {
        type: "gradient",
        gradient: {
          shadeIntensity: 1,
          inverseColors: false,
          opacityFrom: 0.25,
          opacityTo: 0.05,
          stops: [25, 100, 100, 100],
        },
      },
      grid: {
        show: true,
        borderColor: "#e5e7eb",
      },
    };

    var chart = new ApexCharts(el, options);
    chart.render();
  }
}

export default makeHook(ChartHook);
