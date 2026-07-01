<template>
  <div class="flex-1 flex flex-col items-center justify-center p-6 text-center bg-slate-50">
    <div class="text-slate-400 mb-6">
      <svg class="w-20 h-20 mx-auto" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9.172 16.172a4 4 0 015.656 0M9 10h.01M15 10h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
      </svg>
    </div>
    <h3 class="text-xl font-bold text-slate-800 mb-2">页面未找到 (404)</h3>
    <p class="text-sm text-slate-500 mb-8 max-w-xs">您请求的页面不存在或已被移除。</p>
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
