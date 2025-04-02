import ApexCharts from "apexcharts";

import { Hook, makeHook } from "./typed-hook";

class ChartHook extends Hook {
  public mounted() {
    this.run("mounted", this.el);
  }

  public updated() {
    this.run("updated", this.el);
  }

  private run(_lifecycleMethod: "mounted" | "updated", el: HTMLElement) {
    const options = {
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
      ],
      chart: {
        height: 200,
        type: "bar",
        toolbar: {
          show: false,
        },
        animations: {
          enabled: false,
          speed: 500,
        },
        stacked: false,
      },
      dataLabels: {
        enabled: false,
      },
      stroke: {
        show: true,
        width: 2,
        colors: ["transparent"],
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
      plotOptions: {
        bar: {
          horizontal: false,
          borderRadius: 10,
          borderRadiusApplication: "end", // 'around', 'end'
          borderRadiusWhenStacked: "last", // 'all', 'last'
          dataLabels: {
            total: {
              enabled: true,
              style: {
                fontSize: "13px",
                fontWeight: 900,
              },
            },
          },
        },
      },
      grid: {
        show: true,
        borderColor: "#e5e7eb",
      },
    };

    const chart = new ApexCharts(el, options);
    chart.render();
  }
}

export default makeHook(ChartHook);
