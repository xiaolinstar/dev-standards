<template>
  <div class="flex-1 flex flex-col bg-slate-50 min-h-screen">
    <!-- 头部导航及用户信息 -->
    <div class="bg-gradient-to-r from-blue-600 to-indigo-600 px-5 pt-8 pb-16 text-white relative">
      <div class="flex items-center justify-between">
        <div class="flex items-center space-x-3">
          <img :src="userStore.avatar || 'https://fastly.jsdelivr.net/npm/@vant/assets/cat.jpeg'" class="w-10 h-10 rounded-full border-2 border-white/20 shadow-md" alt="Avatar" />
          <div>
            <h3 class="text-sm font-semibold opacity-90">{{ userStore.username }}</h3>
            <span class="text-[10px] bg-white/20 px-2 py-0.5 rounded-full border border-white/10 uppercase">{{ userStore.roles[0] || 'Operator' }}</span>
          </div>
        </div>
        <button @click="handleLogout" class="p-2 rounded-full bg-white/10 active:bg-white/20 transition-all">
          <svg class="w-5 h-5 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1" />
          </svg>
        </button>
      </div>
      
      <!-- 卡片统计浮层 -->
      <div class="absolute left-4 right-4 bottom-[-40px] bg-white rounded-2xl shadow-xl p-4 border border-slate-100 flex justify-between items-center text-slate-800">
        <div class="text-center flex-1">
          <p class="text-[10px] text-slate-400 font-medium uppercase">今日预算 (元)</p>
          <p class="text-lg font-bold text-slate-800 mt-0.5">3,280.00</p>
        </div>
        <div class="w-[1px] h-8 bg-slate-100"></div>
        <div class="text-center flex-1">
          <p class="text-[10px] text-slate-400 font-medium uppercase">总消费 (元)</p>
          <p class="text-lg font-bold text-emerald-600 mt-0.5">1,420.50</p>
        </div>
        <div class="w-[1px] h-8 bg-slate-100"></div>
        <div class="text-center flex-1">
          <p class="text-[10px] text-slate-400 font-medium uppercase">打卡次数</p>
          <p class="text-lg font-bold text-indigo-600 mt-0.5">12</p>
        </div>
      </div>
    </div>

    <!-- 核心业务区 -->
    <div class="px-4 pt-14 pb-20 space-y-4">
      <!-- 快捷操作网格 -->
      <div class="bg-white rounded-2xl shadow-sm p-4 border border-slate-100">
        <h4 class="text-xs font-semibold text-slate-400 mb-3 uppercase tracking-wider">运营管理项</h4>
        <van-grid :column-num="4" :border="false" class="!p-0">
          <van-grid-item icon="balance-o" text="预算管理" @click="handleFeature" class="!text-slate-700" />
          <van-grid-item icon="bill-o" text="账单审计" @click="handleFeature" />
          <van-grid-item icon="setting-o" text="系统配置" @click="handleFeature" />
          <van-grid-item icon="records-o" text="日志查看" @click="handleFeature" />
        </van-grid>
      </div>

      <!-- 数据趋势列表/近况 -->
      <div class="bg-white rounded-2xl shadow-sm p-4 border border-slate-100">
        <div class="flex items-center justify-between mb-3">
          <h4 class="text-xs font-semibold text-slate-400 uppercase tracking-wider">最新审批流程</h4>
          <span class="text-[10px] text-primary font-semibold">查看全部</span>
        </div>
        
        <div class="divide-y divide-slate-50">
          <div v-for="i in 3" :key="i" class="py-3 flex items-center justify-between first:pt-0 last:pb-0">
            <div class="flex items-center space-x-3">
              <span class="w-2 h-2 rounded-full" :class="i === 1 ? 'bg-amber-400' : 'bg-emerald-400'"></span>
              <div>
                <p class="text-xs font-semibold text-slate-800">打卡预算申领 (星巴克)</p>
                <p class="text-[10px] text-slate-400 mt-0.5">申请人: 小林 · 2026-06-28</p>
              </div>
            </div>
            <span class="text-xs font-bold" :class="i === 1 ? 'text-amber-500' : 'text-emerald-500'">
              {{ i === 1 ? '审批中' : '已通过' }}
            </span>
          </div>
        </div>
      </div>
    </div>

    <!-- 底部导航条 -->
    <van-tabbar v-model="activeTab" class="border-t border-slate-100">
      <van-tabbar-item icon="home-o">首页</van-tabbar-item>
      <van-tabbar-item icon="apps-o">运营</van-tabbar-item>
      <van-tabbar-item icon="user-o">我的</van-tabbar-item>
    </van-tabbar>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue';
import { useUserStore } from '@/stores/user';
import { useRouter } from 'vue-router';
import { showToast, showConfirmDialog } from 'vant';

const userStore = useUserStore();
const router = useRouter();

const activeTab = ref(0);

const handleFeature = () => {
  showToast('该模块正在开发中...');
};

const handleLogout = () => {
  showConfirmDialog({
    title: '确认退出',
    message: '确定要退出当前运营账户吗？',
  }).then(() => {
    userStore.clearUserInfo();
    showToast('已安全退出');
    router.replace({ name: 'Login' });
  }).catch(() => {});
};
</script>
