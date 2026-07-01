<template>
  <div class="flex-1 flex flex-col justify-center px-6 py-12 bg-gradient-to-b from-slate-50 to-slate-100">
    <div class="text-center mb-8">
      <div class="inline-flex p-4 bg-primary/10 rounded-full text-primary mb-4 animate-bounce">
        <svg class="w-10 h-10" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z" />
        </svg>
      </div>
      <h2 class="text-2xl font-bold text-slate-800">运营中心登录</h2>
      <p class="text-xs text-slate-500 mt-1">请输入管理员账号和密码以继续</p>
    </div>

    <van-form @submit="onSubmit" class="bg-white p-5 rounded-2xl shadow-md border border-slate-100 space-y-4">
      <van-cell-group inset class="!m-0">
        <van-field
          v-model="username"
          name="username"
          label="账号"
          placeholder="请输入用户名"
          left-icon="user-o"
          :rules="[{ required: true, message: '请填写用户名' }]"
        />
        <van-field
          v-model="password"
          type="password"
          name="password"
          label="密码"
          placeholder="请输入密码"
          left-icon="lock"
          :rules="[{ required: true, message: '请填写密码' }]"
        />
      </van-cell-group>
      
      <div class="pt-4">
        <van-button
          round
          block
          type="primary"
          native-type="submit"
          :loading="loading"
          loading-text="登录中..."
          class="!h-11 !text-sm font-semibold shadow-lg shadow-primary/20"
        >
          立即登录
        </van-button>
      </div>
    </van-form>

    <div class="text-center mt-6 text-xs text-slate-400">
      演示账号：admin / admin
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue';
import { useRouter, useRoute } from 'vue-router';
import { useUserStore } from '@/stores/user';
import { showToast } from 'vant';

const router = useRouter();
const route = useRoute();
const userStore = useUserStore();

const username = ref('admin');
const password = ref('admin');
const loading = ref(false);

const onSubmit = async () => {
  loading.value = true;
  try {
    await userStore.login({ username: username.value, password: password.value });
    showToast({
      type: 'success',
      message: '登录成功',
      duration: 1000
    });
    
    // 重定向到原页面或首页
    const redirectPath = (route.query.redirect as string) || '/';
    router.replace(redirectPath);
  } catch (error: any) {
    showToast(error.message || '登录失败');
  } finally {
    loading.value = false;
  }
};
</script>
