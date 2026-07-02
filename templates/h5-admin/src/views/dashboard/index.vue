<template>
  <!-- 概览页：PC 优先自适应栅格（继承 web.md §5.1） -->
  <div class="dashboard">
    <header class="page-header mb-6">
      <div>
        <h1 class="text-xl font-bold text-slate-900">运营概览</h1>
        <p class="text-sm text-neutral mt-1">实时掌握核心指标和最新动态</p>
      </div>
      <button class="refresh-btn" :disabled="loading" @click="refresh">
        <van-icon name="replay" size="16" />
        <span>{{ loading ? '刷新中...' : '刷新数据' }}</span>
      </button>
    </header>

    <!-- 统计卡片：移动端 1 列 / 中屏 2 列 / 大屏 3 列 -->
    <section class="metric-grid">
      <article class="metric-card">
        <span>今日预算 (元)</span>
        <strong>3,280.00</strong>
      </article>
      <article class="metric-card">
        <span>总消费 (元)</span>
        <strong class="text-success">1,420.50</strong>
      </article>
      <article class="metric-card">
        <span>打卡次数</span>
        <strong class="text-primary">12</strong>
      </article>
    </section>

    <!-- 快捷操作 + 最近审批：PC 端双列 / 移动端单列 -->
    <div class="dashboard-grid">
      <section class="panel">
        <div class="panel-header">
          <h2>运营管理项</h2>
          <span class="panel-meta">4 个模块</span>
        </div>
        <div class="quick-grid">
          <button
            v-for="item in quickItems"
            :key="item.label"
            class="quick-item"
            @click="handleFeature(item.label)"
          >
            <van-icon :name="item.icon" size="24" />
            <span>{{ item.label }}</span>
          </button>
        </div>
      </section>

      <section class="panel">
        <div class="panel-header">
          <h2>最新审批流程</h2>
          <span class="panel-meta">最近 3 条</span>
        </div>
        <div class="approval-list">
          <article
            v-for="item in approvalItems"
            :key="item.id"
            class="approval-row"
          >
            <div class="approval-meta">
              <span class="status-dot" :class="item.dotClass"></span>
              <div>
                <p class="approval-title">{{ item.title }}</p>
                <p class="approval-sub">{{ item.subtitle }}</p>
              </div>
            </div>
            <van-tag :type="item.tagType">{{ item.status }}</van-tag>
          </article>
        </div>
      </section>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { showToast } from 'vant'

const loading = ref(false)

const quickItems = [
  { label: '预算管理', icon: 'balance-o' },
  { label: '账单审计', icon: 'bill-o' },
  { label: '系统配置', icon: 'setting-o' },
  { label: '日志查看', icon: 'records-o' },
]

const approvalItems = [
  {
    id: 1,
    title: '打卡预算申领 (星巴克)',
    subtitle: '申请人: 小林 · 2026-06-28',
    status: '审批中',
    tagType: 'warning' as const,
    dotClass: 'bg-warning',
  },
  {
    id: 2,
    title: '营养数据库校对',
    subtitle: '提交人: Alex · 2026-06-27',
    status: '已通过',
    tagType: 'success' as const,
    dotClass: 'bg-success',
  },
  {
    id: 3,
    title: '新品发布预审',
    subtitle: '提交人: Linda · 2026-06-26',
    status: '已通过',
    tagType: 'success' as const,
    dotClass: 'bg-success',
  },
]

const refresh = async () => {
  loading.value = true
  try {
    await new Promise((r) => setTimeout(r, 400))
  } finally {
    loading.value = false
  }
}

const handleFeature = (label: string) => {
  showToast(`${label}模块正在开发中`)
}
</script>

<style scoped>
.dashboard {
  width: 100%;
}

.page-header {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 16px;
}

.refresh-btn {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  padding: 8px 14px;
  border: 1px solid #cbd5e1;
  border-radius: var(--project-radius-sm);
  background: #ffffff;
  color: var(--project-neutral-color);
  font-size: var(--project-text-sm);
  font-weight: 600;
  cursor: pointer;
  transition: all 0.15s ease;
}

.refresh-btn:hover:not(:disabled) {
  background: #f8fafc;
  color: #0f172a;
}

.refresh-btn:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.metric-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
  gap: 12px;
  margin-bottom: 16px;
}

.metric-card {
  padding: 16px;
  border: 1px solid #e2e8f0;
  border-radius: var(--project-radius-md);
  background: #ffffff;
  box-shadow: var(--project-shadow-sm);
}

.metric-card span {
  display: block;
  color: var(--project-neutral-color);
  font-size: var(--project-text-xs);
  line-height: 1.4;
}

.metric-card strong {
  display: block;
  margin-top: 6px;
  color: #0f172a;
  font-size: var(--project-text-xl);
  line-height: 1.2;
}

.dashboard-grid {
  display: grid;
  grid-template-columns: 1fr;
  gap: 16px;
}

@media (min-width: 1024px) {
  .dashboard-grid {
    grid-template-columns: 1fr 1fr;
  }
}

.panel {
  padding: 16px;
  border: 1px solid #e2e8f0;
  border-radius: var(--project-radius-md);
  background: #ffffff;
  box-shadow: var(--project-shadow-sm);
}

.panel-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 12px;
}

.panel-header h2 {
  margin: 0;
  font-size: var(--project-text-md);
  font-weight: 600;
  color: #0f172a;
}

.panel-meta {
  color: var(--project-neutral-color);
  font-size: var(--project-text-xs);
}

.quick-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(120px, 1fr));
  gap: 10px;
}

.quick-item {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 8px;
  padding: 16px 12px;
  border: 1px solid #e2e8f0;
  border-radius: var(--project-radius-sm);
  background: #f8fafc;
  color: var(--project-neutral-color);
  font-size: var(--project-text-sm);
  cursor: pointer;
  transition: all 0.15s ease;
}

.quick-item:hover {
  border-color: var(--project-primary-color);
  background: rgba(37, 99, 235, 0.05);
  color: var(--project-primary-color);
}

.approval-list {
  display: flex;
  flex-direction: column;
}

.approval-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  padding: 10px 0;
  border-top: 1px solid #f1f5f9;
}

.approval-row:first-of-type {
  border-top: 0;
}

.approval-meta {
  display: flex;
  align-items: center;
  gap: 12px;
  min-width: 0;
}

.status-dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  flex-shrink: 0;
}

.approval-title {
  margin: 0;
  color: #0f172a;
  font-size: var(--project-text-sm);
  font-weight: 600;
  overflow-wrap: anywhere;
}

.approval-sub {
  margin: 2px 0 0;
  color: var(--project-neutral-color);
  font-size: var(--project-text-xs);
}
</style>