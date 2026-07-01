<template>
  <div class="flex-1 flex flex-col items-center justify-center p-6 text-center bg-slate-50">
    <div class="text-red-500 mb-6">
      <svg class="w-20 h-20 mx-auto" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z" />
      </svg>
    </div>
    <h3 class="text-xl font-bold text-slate-800 mb-2">访问受限 (403)</h3>
    <p class="text-sm text-slate-500 mb-8 max-w-xs">您的账户没有查看此页面或执行此操作的权限。请联系管理员进行授权。</p>
    <van-button round type="primary" class="!px-8" @click="goHome">返回首页</van-button>
  </div>
</template>

<script setup lang="ts">
import { useRouter } from 'vue-router';

const router = useRouter();
const goHome = () => {
  router.replace('/');
};
</script>
