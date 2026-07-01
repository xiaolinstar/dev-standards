<template>
  <div class="min-h-screen bg-slate-900 flex items-center justify-center p-0 sm:p-6 font-sans antialiased text-slate-900">
    <!-- PC 端左侧展示介绍，仅在 lg 宽屏及以上展示 -->
    <div class="hidden lg:flex flex-col w-96 mr-12 text-slate-200">
      <div class="mb-6 bg-slate-800/80 backdrop-blur-sm border border-slate-700 p-3 rounded-2xl w-fit">
        <svg class="w-8 h-8 text-primary" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 18h.01M8 21h8a2 2 0 002-2V5a2 2 0 00-2-2H8a2 2 0 00-2 2v14a2 2 0 002 2z" />
        </svg>
      </div>
      <h1 class="text-3xl font-extrabold tracking-tight text-white mb-3">
        运营管理后台 <span class="text-primary text-sm font-semibold px-2 py-1 bg-primary/10 border border-primary/20 rounded-full ml-1 vertical-middle">H5 H5-Mobile</span>
      </h1>
      <p class="text-slate-400 text-sm leading-relaxed mb-6">
        当前为移动端优化版的运营控制台，在大屏浏览器中已激活居中沙盒（Sandbox）预览模式。所有数据与操作和手机端 100% 对齐。
      </p>
      
      <div class="space-y-3 border-t border-slate-800 pt-6">
        <div class="flex items-center text-xs text-slate-500">
          <span class="w-2 h-2 rounded-full bg-emerald-500 mr-2"></span>
          适配宿主：手机微信 / 钉钉 / 移动浏览器
        </div>
        <div class="flex items-center text-xs text-slate-500">
          <span class="w-2 h-2 rounded-full bg-emerald-500 mr-2"></span>
          尺寸基准：375px (自动转换视口比例)
        </div>
      </div>
    </div>

    <!-- 手机沙盒容器（模拟手机外壳） -->
    <div class="w-full min-h-screen sm:min-h-[812px] sm:w-[375px] sm:rounded-[36px] sm:shadow-[0_25px_60px_-15px_rgba(0,0,0,0.7)] bg-white overflow-hidden flex flex-col relative sm:border-[8px] sm:border-slate-800 transition-all duration-300">
      <!-- 手机顶部摄像头凹槽刘海模拟（仅在 PC/sm 宽度以上模拟） -->
      <div class="hidden sm:block absolute top-0 left-1/2 -translate-x-1/2 w-40 h-6 bg-slate-800 rounded-b-2xl z-50"></div>
      
      <!-- 主内容区 -->
      <div class="flex-1 flex flex-col overflow-y-auto sm:pt-6 pb-[safe-area-inset-bottom] bg-slate-50">
        <router-view v-slot="{ Component }">
          <transition name="fade-slide" mode="out-in">
            <component :is="Component" />
          </transition>
        </router-view>
      </div>
    </div>
  </div>
</template>

<style>
/* 全局路由转换动效 */
.fade-slide-enter-active,
.fade-slide-leave-active {
  transition: all 0.25s ease-out;
}

.fade-slide-enter-from {
  opacity: 0;
  transform: translateX(20px);
}

.fade-slide-leave-to {
  opacity: 0;
  transform: translateX(-20px);
}

/* 忽略 VW 视口转换的沙盒外壳，确保在 PC 上大小固定 */
@media (min-width: 640px) {
  .sandbox-container {
    width: 375px !important;
    height: 812px !important;
  }
}
</style>
