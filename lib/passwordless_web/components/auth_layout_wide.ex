defmodule PasswordlessWeb.Components.AuthLayoutWide do
  @moduledoc false
  use Phoenix.Component
  use PasswordlessWeb, :verified_routes

  import PasswordlessWeb.Components.Typography

  attr :title, :string
  slot :inner_block
  slot :logo
  slot :top_links
  slot :bottom_links

  def auth_layout_wide(assigns) do
    ~H"""
    <div class="fixed w-full h-full">
      <div class="grid grid-cols-1 lg:grid-cols-2 h-full">
        <div class="relative flex md:items-center md:justify-between overflow-x-auto">
          <.link class="absolute hidden md:flex left-0 top-0 py-5 px-5 lg:p-8" href="/">
            {render_slot(@logo)}
          </.link>

          <div class="flex flex-col w-full md:max-w-sm md:mx-auto px-5 py-4 md:py-0 gap-8">
            <div class="flex flex-col gap-3">
              <.h2 no_margin>
                {@title}
              </.h2>

              <.p :if={Util.present?(@top_links)}>
                {render_slot(@top_links)}
              </.p>
            </div>

            <div>
              {render_slot(@inner_block)}
            </div>

            <div class="flex flex-col items-center">
              <.p :if={Util.present?(@bottom_links)}>
                {render_slot(@bottom_links)}
              </.p>
            </div>
          </div>

          <div class="absolute left-0 bottom-0 hidden md:flex items-center py-4 px-5 lg:p-8 text-slate-600 dark:text-slate-300 text-sm font-normal leading-tight">
            Copyright © {Timex.now().year} {Passwordless.config(:business_name)}
          </div>
        </div>

        <div class="flex-col justify-center bg-slate-100 dark:bg-slate-800 hidden lg:flex overflow-x-hidden">
          <img
            src={~p"/images/auth-layout-promo.webp"}
            alt={Passwordless.config(:app_name)}
            title={Passwordless.config(:app_name)}
            class="rounded-xl shadow-2 translate-x-32 z-10 dark:border dark:border-slate-700"
          />

          <div class="absolute w-[298px] h-[152px] bottom-0">
            <div class="relative">
              <div class="w-[12.46px] h-[0px] left-[204.18px] top-[13.07px] absolute origin-top-left rotate-[-70deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[230.73px] top-[12.68px] absolute origin-top-left rotate-[-60deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[257.42px] top-[12.29px] absolute origin-top-left rotate-[-50deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[284.29px] top-[11.51px] absolute origin-top-left rotate-[-40deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[18.35px] top-[11.51px] absolute origin-top-left rotate-[-140deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[45.23px] top-[12.29px] absolute origin-top-left rotate-[-130deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[71.92px] top-[12.68px] absolute origin-top-left rotate-[-120deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[98.47px] top-[13.07px] absolute origin-top-left rotate-[-110deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[124.92px] top-[13.46px] absolute origin-top-left rotate-[-100deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[151.32px] top-[13.46px] absolute origin-top-left -rotate-90 border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[177.73px] top-[13.46px] absolute origin-top-left rotate-[-80deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[176.16px] top-[34.86px] absolute origin-top-left rotate-[-70deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[202.70px] top-[34.47px] absolute origin-top-left rotate-[-60deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[229.39px] top-[34.09px] absolute origin-top-left rotate-[-50deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[256.27px] top-[33.31px] absolute origin-top-left rotate-[-40deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[283.36px] top-[32.14px] absolute origin-top-left rotate-[-30deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[17.20px] top-[34.09px] absolute origin-top-left rotate-[-130deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[43.89px] top-[34.47px] absolute origin-top-left rotate-[-120deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[70.44px] top-[34.86px] absolute origin-top-left rotate-[-110deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[96.89px] top-[35.25px] absolute origin-top-left rotate-[-100deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[123.30px] top-[35.25px] absolute origin-top-left -rotate-90 border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[149.70px] top-[35.25px] absolute origin-top-left rotate-[-80deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[148.13px] top-[56.66px] absolute origin-top-left rotate-[-70deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[174.68px] top-[56.27px] absolute origin-top-left rotate-[-60deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[201.37px] top-[55.88px] absolute origin-top-left rotate-[-50deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[228.25px] top-[55.10px] absolute origin-top-left rotate-[-40deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[255.34px] top-[53.94px] absolute origin-top-left rotate-[-30deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[282.67px] top-[53.16px] absolute origin-top-left rotate-[-20deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[15.87px] top-[56.27px] absolute origin-top-left rotate-[-120deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[42.42px] top-[56.66px] absolute origin-top-left rotate-[-110deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[68.87px] top-[57.05px] absolute origin-top-left rotate-[-100deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[95.27px] top-[57.05px] absolute origin-top-left -rotate-90 border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[121.68px] top-[57.05px] absolute origin-top-left rotate-[-80deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[120.11px] top-[78.46px] absolute origin-top-left rotate-[-70deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[146.65px] top-[78.07px] absolute origin-top-left rotate-[-60deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[173.34px] top-[77.68px] absolute origin-top-left rotate-[-50deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[200.22px] top-[76.90px] absolute origin-top-left rotate-[-40deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[227.31px] top-[75.73px] absolute origin-top-left rotate-[-30deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[254.65px] top-[74.96px] absolute origin-top-left rotate-[-20deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[282.25px] top-[73.79px] absolute origin-top-left rotate-[-10deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[14.39px] top-[78.46px] absolute origin-top-left rotate-[-110deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[40.84px] top-[78.85px] absolute origin-top-left rotate-[-100deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[67.25px] top-[78.85px] absolute origin-top-left -rotate-90 border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[93.65px] top-[78.85px] absolute origin-top-left rotate-[-80deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[92.08px] top-[100.26px] absolute origin-top-left rotate-[-70deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[118.63px] top-[99.87px] absolute origin-top-left rotate-[-60deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[145.32px] top-[99.48px] absolute origin-top-left rotate-[-50deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[172.20px] top-[98.70px] absolute origin-top-left rotate-[-40deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[199.29px] top-[97.53px] absolute origin-top-left rotate-[-30deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[226.62px] top-[96.75px] absolute origin-top-left rotate-[-20deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[254.23px] top-[95.59px] absolute origin-top-left rotate-[-10deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[12.82px] top-[100.65px] absolute origin-top-left rotate-[-100deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[39.22px] top-[100.65px] absolute origin-top-left -rotate-90 border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[65.62px] top-[100.65px] absolute origin-top-left rotate-[-80deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[297.68px] top-[94.42px] absolute origin-top-left -rotate-180 border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[64.05px] top-[122.05px] absolute origin-top-left rotate-[-70deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[90.60px] top-[121.67px] absolute origin-top-left rotate-[-60deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[117.29px] top-[121.28px] absolute origin-top-left rotate-[-50deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[144.17px] top-[120.50px] absolute origin-top-left rotate-[-40deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[171.26px] top-[119.33px] absolute origin-top-left rotate-[-30deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[198.60px] top-[118.55px] absolute origin-top-left rotate-[-20deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[226.20px] top-[117.38px] absolute origin-top-left rotate-[-10deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[11.20px] top-[122.44px] absolute origin-top-left -rotate-90 border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[37.60px] top-[122.44px] absolute origin-top-left rotate-[-80deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[269.65px] top-[116.22px] absolute origin-top-left -rotate-180 border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[297.54px] top-[117.38px] absolute origin-top-left rotate-[-170deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[36.03px] top-[143.85px] absolute origin-top-left rotate-[-70deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[62.58px] top-[143.46px] absolute origin-top-left rotate-[-60deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[89.27px] top-[143.07px] absolute origin-top-left rotate-[-50deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[116.14px] top-[142.29px] absolute origin-top-left rotate-[-40deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[143.23px] top-[141.13px] absolute origin-top-left rotate-[-30deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[170.57px] top-[140.35px] absolute origin-top-left rotate-[-20deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[198.18px] top-[139.18px] absolute origin-top-left rotate-[-10deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[9.57px] top-[144.24px] absolute origin-top-left rotate-[-80deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[241.63px] top-[138.01px] absolute origin-top-left -rotate-180 border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[269.51px] top-[139.18px] absolute origin-top-left rotate-[-170deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[297.12px] top-[140.35px] absolute origin-top-left rotate-[-160deg] border border-white dark:border-slate-700">
              </div>
            </div>
          </div>

          <div class="absolute w-[298px] h-[152px] right-0 top-0">
            <div class="relative">
              <div class="w-[12.46px] h-[0px] left-[204.18px] top-[13.07px] absolute origin-top-left rotate-[-70deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[230.73px] top-[12.68px] absolute origin-top-left rotate-[-60deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[257.42px] top-[12.29px] absolute origin-top-left rotate-[-50deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[284.29px] top-[11.51px] absolute origin-top-left rotate-[-40deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[18.35px] top-[11.51px] absolute origin-top-left rotate-[-140deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[45.23px] top-[12.29px] absolute origin-top-left rotate-[-130deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[71.92px] top-[12.68px] absolute origin-top-left rotate-[-120deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[98.47px] top-[13.07px] absolute origin-top-left rotate-[-110deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[124.92px] top-[13.46px] absolute origin-top-left rotate-[-100deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[151.32px] top-[13.46px] absolute origin-top-left -rotate-90 border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[177.73px] top-[13.46px] absolute origin-top-left rotate-[-80deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[176.16px] top-[34.86px] absolute origin-top-left rotate-[-70deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[202.70px] top-[34.47px] absolute origin-top-left rotate-[-60deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[229.39px] top-[34.09px] absolute origin-top-left rotate-[-50deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[256.27px] top-[33.31px] absolute origin-top-left rotate-[-40deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[283.36px] top-[32.14px] absolute origin-top-left rotate-[-30deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[17.20px] top-[34.09px] absolute origin-top-left rotate-[-130deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[43.89px] top-[34.47px] absolute origin-top-left rotate-[-120deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[70.44px] top-[34.86px] absolute origin-top-left rotate-[-110deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[96.89px] top-[35.25px] absolute origin-top-left rotate-[-100deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[123.30px] top-[35.25px] absolute origin-top-left -rotate-90 border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[149.70px] top-[35.25px] absolute origin-top-left rotate-[-80deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[148.13px] top-[56.66px] absolute origin-top-left rotate-[-70deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[174.68px] top-[56.27px] absolute origin-top-left rotate-[-60deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[201.37px] top-[55.88px] absolute origin-top-left rotate-[-50deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[228.25px] top-[55.10px] absolute origin-top-left rotate-[-40deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[255.34px] top-[53.94px] absolute origin-top-left rotate-[-30deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[282.67px] top-[53.16px] absolute origin-top-left rotate-[-20deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[15.87px] top-[56.27px] absolute origin-top-left rotate-[-120deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[42.42px] top-[56.66px] absolute origin-top-left rotate-[-110deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[68.87px] top-[57.05px] absolute origin-top-left rotate-[-100deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[95.27px] top-[57.05px] absolute origin-top-left -rotate-90 border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[121.68px] top-[57.05px] absolute origin-top-left rotate-[-80deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[120.11px] top-[78.46px] absolute origin-top-left rotate-[-70deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[146.65px] top-[78.07px] absolute origin-top-left rotate-[-60deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[173.34px] top-[77.68px] absolute origin-top-left rotate-[-50deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[200.22px] top-[76.90px] absolute origin-top-left rotate-[-40deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[227.31px] top-[75.73px] absolute origin-top-left rotate-[-30deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[254.65px] top-[74.96px] absolute origin-top-left rotate-[-20deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[282.25px] top-[73.79px] absolute origin-top-left rotate-[-10deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[14.39px] top-[78.46px] absolute origin-top-left rotate-[-110deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[40.84px] top-[78.85px] absolute origin-top-left rotate-[-100deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[67.25px] top-[78.85px] absolute origin-top-left -rotate-90 border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[93.65px] top-[78.85px] absolute origin-top-left rotate-[-80deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[92.08px] top-[100.26px] absolute origin-top-left rotate-[-70deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[118.63px] top-[99.87px] absolute origin-top-left rotate-[-60deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[145.32px] top-[99.48px] absolute origin-top-left rotate-[-50deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[172.20px] top-[98.70px] absolute origin-top-left rotate-[-40deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[199.29px] top-[97.53px] absolute origin-top-left rotate-[-30deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[226.62px] top-[96.75px] absolute origin-top-left rotate-[-20deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[254.23px] top-[95.59px] absolute origin-top-left rotate-[-10deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[12.82px] top-[100.65px] absolute origin-top-left rotate-[-100deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[39.22px] top-[100.65px] absolute origin-top-left -rotate-90 border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[65.62px] top-[100.65px] absolute origin-top-left rotate-[-80deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[297.68px] top-[94.42px] absolute origin-top-left -rotate-180 border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[64.05px] top-[122.05px] absolute origin-top-left rotate-[-70deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[90.60px] top-[121.67px] absolute origin-top-left rotate-[-60deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[117.29px] top-[121.28px] absolute origin-top-left rotate-[-50deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[144.17px] top-[120.50px] absolute origin-top-left rotate-[-40deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[171.26px] top-[119.33px] absolute origin-top-left rotate-[-30deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[198.60px] top-[118.55px] absolute origin-top-left rotate-[-20deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[226.20px] top-[117.38px] absolute origin-top-left rotate-[-10deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[11.20px] top-[122.44px] absolute origin-top-left -rotate-90 border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[37.60px] top-[122.44px] absolute origin-top-left rotate-[-80deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[269.65px] top-[116.22px] absolute origin-top-left -rotate-180 border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[297.54px] top-[117.38px] absolute origin-top-left rotate-[-170deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[36.03px] top-[143.85px] absolute origin-top-left rotate-[-70deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[62.58px] top-[143.46px] absolute origin-top-left rotate-[-60deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[89.27px] top-[143.07px] absolute origin-top-left rotate-[-50deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[116.14px] top-[142.29px] absolute origin-top-left rotate-[-40deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[143.23px] top-[141.13px] absolute origin-top-left rotate-[-30deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[170.57px] top-[140.35px] absolute origin-top-left rotate-[-20deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[198.18px] top-[139.18px] absolute origin-top-left rotate-[-10deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[9.57px] top-[144.24px] absolute origin-top-left rotate-[-80deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[241.63px] top-[138.01px] absolute origin-top-left -rotate-180 border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[269.51px] top-[139.18px] absolute origin-top-left rotate-[-170deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[297.12px] top-[140.35px] absolute origin-top-left rotate-[-160deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[8px] top-[165.65px] absolute origin-top-left rotate-[-70deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[34.55px] top-[165.26px] absolute origin-top-left rotate-[-60deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[61.24px] top-[164.87px] absolute origin-top-left rotate-[-50deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[88.12px] top-[164.09px] absolute origin-top-left rotate-[-40deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[115.21px] top-[162.92px] absolute origin-top-left rotate-[-30deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[142.55px] top-[162.15px] absolute origin-top-left rotate-[-20deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[170.15px] top-[160.98px] absolute origin-top-left rotate-[-10deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[296.43px] top-[162.92px] absolute origin-top-left rotate-[-150deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[213.61px] top-[159.81px] absolute origin-top-left -rotate-180 border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[241.49px] top-[160.98px] absolute origin-top-left rotate-[-170deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[269.09px] top-[162.15px] absolute origin-top-left rotate-[-160deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[6.53px] top-[187.06px] absolute origin-top-left rotate-[-60deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[33.22px] top-[186.67px] absolute origin-top-left rotate-[-50deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[60.09px] top-[185.89px] absolute origin-top-left rotate-[-40deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[87.18px] top-[184.72px] absolute origin-top-left rotate-[-30deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[114.52px] top-[183.94px] absolute origin-top-left rotate-[-20deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[142.12px] top-[182.78px] absolute origin-top-left rotate-[-10deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[268.40px] top-[184.72px] absolute origin-top-left rotate-[-150deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[295.50px] top-[185.89px] absolute origin-top-left rotate-[-140deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[185.58px] top-[181.61px] absolute origin-top-left -rotate-180 border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[213.46px] top-[182.78px] absolute origin-top-left rotate-[-170deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[241.07px] top-[183.94px] absolute origin-top-left rotate-[-160deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[5.19px] top-[208.47px] absolute origin-top-left rotate-[-50deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[32.07px] top-[207.69px] absolute origin-top-left rotate-[-40deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[59.16px] top-[206.52px] absolute origin-top-left rotate-[-30deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[86.50px] top-[205.74px] absolute origin-top-left rotate-[-20deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[114.10px] top-[204.57px] absolute origin-top-left rotate-[-10deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[240.38px] top-[206.52px] absolute origin-top-left rotate-[-150deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[267.47px] top-[207.69px] absolute origin-top-left rotate-[-140deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[294.34px] top-[208.47px] absolute origin-top-left rotate-[-130deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[157.55px] top-[203.41px] absolute origin-top-left -rotate-180 border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[185.44px] top-[204.57px] absolute origin-top-left rotate-[-170deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[213.04px] top-[205.74px] absolute origin-top-left rotate-[-160deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[4.04px] top-[229.48px] absolute origin-top-left rotate-[-40deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[31.13px] top-[228.32px] absolute origin-top-left rotate-[-30deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[58.47px] top-[227.54px] absolute origin-top-left rotate-[-20deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[86.07px] top-[226.37px] absolute origin-top-left rotate-[-10deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[212.35px] top-[228.32px] absolute origin-top-left rotate-[-150deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[239.45px] top-[229.48px] absolute origin-top-left rotate-[-140deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[266.32px] top-[230.26px] absolute origin-top-left rotate-[-130deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[293.01px] top-[230.65px] absolute origin-top-left rotate-[-120deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[129.53px] top-[225.20px] absolute origin-top-left -rotate-180 border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[157.41px] top-[226.37px] absolute origin-top-left rotate-[-170deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[185.02px] top-[227.54px] absolute origin-top-left rotate-[-160deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[3.11px] top-[250.11px] absolute origin-top-left rotate-[-30deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[30.45px] top-[249.34px] absolute origin-top-left rotate-[-20deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[58.05px] top-[248.17px] absolute origin-top-left rotate-[-10deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[184.33px] top-[250.11px] absolute origin-top-left rotate-[-150deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[211.42px] top-[251.28px] absolute origin-top-left rotate-[-140deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[238.29px] top-[252.06px] absolute origin-top-left rotate-[-130deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[264.98px] top-[252.45px] absolute origin-top-left rotate-[-120deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[291.54px] top-[252.84px] absolute origin-top-left rotate-[-110deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[101.50px] top-[247px] absolute origin-top-left -rotate-180 border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[129.39px] top-[248.17px] absolute origin-top-left rotate-[-170deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[156.99px] top-[249.34px] absolute origin-top-left rotate-[-160deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[2.42px] top-[271.13px] absolute origin-top-left rotate-[-20deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[30.02px] top-[269.97px] absolute origin-top-left rotate-[-10deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[156.30px] top-[271.91px] absolute origin-top-left rotate-[-150deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[183.39px] top-[273.08px] absolute origin-top-left rotate-[-140deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[210.27px] top-[273.86px] absolute origin-top-left rotate-[-130deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[236.96px] top-[274.25px] absolute origin-top-left rotate-[-120deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[263.51px] top-[274.64px] absolute origin-top-left rotate-[-110deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[289.96px] top-[275.03px] absolute origin-top-left rotate-[-100deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[73.48px] top-[268.80px] absolute origin-top-left -rotate-180 border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[101.36px] top-[269.97px] absolute origin-top-left rotate-[-170deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[128.96px] top-[271.13px] absolute origin-top-left rotate-[-160deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[2px] top-[291.76px] absolute origin-top-left rotate-[-10deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[128.28px] top-[293.71px] absolute origin-top-left rotate-[-150deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[155.37px] top-[294.88px] absolute origin-top-left rotate-[-140deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[182.24px] top-[295.66px] absolute origin-top-left rotate-[-130deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[208.93px] top-[296.04px] absolute origin-top-left rotate-[-120deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[235.48px] top-[296.43px] absolute origin-top-left rotate-[-110deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[261.94px] top-[296.82px] absolute origin-top-left rotate-[-100deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[288.34px] top-[296.82px] absolute origin-top-left -rotate-90 border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[45.45px] top-[290.59px] absolute origin-top-left -rotate-180 border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[73.34px] top-[291.76px] absolute origin-top-left rotate-[-170deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[100.94px] top-[292.93px] absolute origin-top-left rotate-[-160deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[100.25px] top-[315.51px] absolute origin-top-left rotate-[-150deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[127.34px] top-[316.67px] absolute origin-top-left rotate-[-140deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[154.22px] top-[317.45px] absolute origin-top-left rotate-[-130deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[180.91px] top-[317.84px] absolute origin-top-left rotate-[-120deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[207.46px] top-[318.23px] absolute origin-top-left rotate-[-110deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[233.91px] top-[318.62px] absolute origin-top-left rotate-[-100deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[260.31px] top-[318.62px] absolute origin-top-left -rotate-90 border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[286.72px] top-[318.62px] absolute origin-top-left rotate-[-80deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[17.43px] top-[312.39px] absolute origin-top-left -rotate-180 border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[45.31px] top-[313.56px] absolute origin-top-left rotate-[-170deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[72.91px] top-[314.73px] absolute origin-top-left rotate-[-160deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[285.14px] top-[340.03px] absolute origin-top-left rotate-[-70deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[72.23px] top-[337.30px] absolute origin-top-left rotate-[-150deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[99.32px] top-[338.47px] absolute origin-top-left rotate-[-140deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[126.19px] top-[339.25px] absolute origin-top-left rotate-[-130deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[152.88px] top-[339.64px] absolute origin-top-left rotate-[-120deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[179.43px] top-[340.03px] absolute origin-top-left rotate-[-110deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[205.89px] top-[340.42px] absolute origin-top-left rotate-[-100deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[232.29px] top-[340.42px] absolute origin-top-left -rotate-90 border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[258.69px] top-[340.42px] absolute origin-top-left rotate-[-80deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[17.29px] top-[335.36px] absolute origin-top-left rotate-[-170deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[44.89px] top-[336.53px] absolute origin-top-left rotate-[-160deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[257.12px] top-[361.83px] absolute origin-top-left rotate-[-70deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[283.67px] top-[361.44px] absolute origin-top-left rotate-[-60deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[44.20px] top-[359.10px] absolute origin-top-left rotate-[-150deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[71.29px] top-[360.27px] absolute origin-top-left rotate-[-140deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[98.17px] top-[361.05px] absolute origin-top-left rotate-[-130deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[124.86px] top-[361.44px] absolute origin-top-left rotate-[-120deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[151.41px] top-[361.83px] absolute origin-top-left rotate-[-110deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[177.86px] top-[362.22px] absolute origin-top-left rotate-[-100deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[204.26px] top-[362.22px] absolute origin-top-left -rotate-90 border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[230.67px] top-[362.22px] absolute origin-top-left rotate-[-80deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[16.86px] top-[358.32px] absolute origin-top-left rotate-[-160deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[229.09px] top-[383.62px] absolute origin-top-left rotate-[-70deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[255.64px] top-[383.23px] absolute origin-top-left rotate-[-60deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[282.34px] top-[382.84px] absolute origin-top-left rotate-[-50deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[16.18px] top-[380.90px] absolute origin-top-left rotate-[-150deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[43.27px] top-[382.07px] absolute origin-top-left rotate-[-140deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[70.14px] top-[382.84px] absolute origin-top-left rotate-[-130deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[96.83px] top-[383.23px] absolute origin-top-left rotate-[-120deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[123.38px] top-[383.62px] absolute origin-top-left rotate-[-110deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[149.84px] top-[384.01px] absolute origin-top-left rotate-[-100deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[176.24px] top-[384.01px] absolute origin-top-left -rotate-90 border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[202.64px] top-[384.01px] absolute origin-top-left rotate-[-80deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[201.07px] top-[405.42px] absolute origin-top-left rotate-[-70deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[227.62px] top-[405.03px] absolute origin-top-left rotate-[-60deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[254.31px] top-[404.64px] absolute origin-top-left rotate-[-50deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[281.18px] top-[403.86px] absolute origin-top-left rotate-[-40deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[15.24px] top-[403.86px] absolute origin-top-left rotate-[-140deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[42.12px] top-[404.64px] absolute origin-top-left rotate-[-130deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[68.81px] top-[405.03px] absolute origin-top-left rotate-[-120deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[95.36px] top-[405.42px] absolute origin-top-left rotate-[-110deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[121.81px] top-[405.81px] absolute origin-top-left rotate-[-100deg] border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[148.21px] top-[405.81px] absolute origin-top-left -rotate-90 border border-white dark:border-slate-700">
              </div>
              <div class="w-[12.46px] h-[0px] left-[174.62px] top-[405.81px] absolute origin-top-left rotate-[-80deg] border border-white dark:border-slate-700">
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
