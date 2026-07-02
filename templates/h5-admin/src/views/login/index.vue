<template>
  <!-- 登录页：移动端铺满、PC 端居中卡片（继承 web.md §5.2） -->
  <div class="login-page min-h-full flex items-center justify-center px-4 py-12 bg-slate-50">
    <div class="login-card w-full max-w-md bg-white rounded-md shadow-md border border-slate-200 p-6 md:p-8">
      <div class="text-center mb-6">
        <div class="inline-flex p-3 bg-primary/10 rounded-full text-primary mb-3">
          <van-icon name="manager-o" size="28" />
        </div>
        <h1 class="text-xl font-bold text-slate-900">{{ projectName }}</h1>
        <p class="text-sm text-neutral mt-1">运营管理后台登录</p>
      </div>

      <van-form @submit="onSubmit" class="login-form">
        <van-cell-group inset class="!m-0">
          <van-field
            v-model="username"
            name="username"
            label="账号"
            placeholder="请输入用户名"
            left-icon="user-o"
            :rules="[{ required: true, message: '请填写用户名' }]"
            @blur="handleInputBlur"
          />
          <van-field
            v-model="password"
            type="password"
            name="password"
            label="密码"
            placeholder="请输入密码"
            left-icon="lock"
            :rules="[{ required: true, message: '请填写密码' }]"
            @blur="handleInputBlur"
            @keyup.enter="onSubmit"
          />
        </van-cell-group>

        <div class="mt-5">
          <van-button
            block
            type="primary"
            native-type="submit"
            :loading="loading"
            loading-text="登录中..."
          >
            立即登录
          </van-button>
        </div>
      </van-form>

      <p class="text-center mt-6 text-xs text-neutral">
        演示账号：admin / admin
      </p>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { useUserStore } from '@/stores/user'
import { showToast } from 'vant'
import { handleInputBlur } from '@/utils/h5'

const router = useRouter()
const route = useRoute()
const userStore = useUserStore()

const projectName = computed(() => import.meta.env.VITE_PROJECT_NAME || '运营后台')
const username = ref('admin')
const password = ref('admin')
const loading = ref(false)

const onSubmit = async () => {
  loading.value = true
  try {
    await userStore.login({ username: username.value, password: password.value })
    showToast({ type: 'success', message: '登录成功', duration: 1000 })
    const redirectPath = (route.query.redirect as string) || '/'
    router.replace(redirectPath)
  } catch (error: any) {
    showToast(error.message || '登录失败')
  } finally {
    loading.value = false
  }
}
</script>

<style scoped>
.login-page {
  min-height: calc(100vh - 56px);
}

.login-card {
  border-radius: var(--project-radius-md);
}
</style>