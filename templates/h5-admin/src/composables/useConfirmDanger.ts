import { showConfirmDialog, showDialog, showToast } from 'vant'

export interface ConfirmDangerOptions {
  /** 弹窗标题 */
  title: string
  /** 弹窗正文（说明操作影响） */
  message: string
  /** 操作原因 prompt 的占位文字 */
  reasonPlaceholder?: string
  /** 原因最少字数（默认 10） */
  reasonMinLength?: number
  /** 是否要求强制填写原因（默认 true，false 则不弹原因 dialog） */
  requireReason?: boolean
  /** 取消按钮文字 */
  cancelText?: string
  /** 确认按钮文字 */
  confirmText?: string
}

export interface ConfirmDangerResult {
  confirmed: boolean
  reason?: string
}

/**
 * 高危操作两步确认：
 * 1. showConfirmDialog（说明风险）
 * 2. showDialog prompt 强制填写原因（reasonMinLength 字以上）
 *
 * 用法：
 * ```ts
 * const { confirmed, reason } = await useConfirmDanger({
 *   title: '确认废弃预算',
 *   message: '此操作无法撤销',
 *   reasonPlaceholder: '请填写废弃原因（至少 10 字）',
 * })
 * if (!confirmed) return
 * await api.submit({ reason })
 * ```
 *
 * 详见 playbook/h5-admin.md §3.2
 */
export async function useConfirmDanger(opts: ConfirmDangerOptions): Promise<ConfirmDangerResult> {
  const {
    title,
    message,
    reasonPlaceholder = '请填写操作原因（将记录到审计日志）',
    reasonMinLength = 10,
    requireReason = true,
    cancelText = '取消',
    confirmText = '继续',
  } = opts

  // 第一步：风险确认
  try {
    await showConfirmDialog({
      title,
      message,
      showCancelButton: true,
      cancelButtonText: cancelText,
      confirmButtonText: confirmText,
      confirmButtonColor: 'var(--project-danger-color)',
    })
  } catch {
    return { confirmed: false }
  }

  // 第二步：强制填写原因（可选）
  if (!requireReason) {
    return { confirmed: true }
  }

  try {
    const result = await showDialog({
      title: '填写操作原因',
      message: `${reasonPlaceholder}（至少 ${reasonMinLength} 字）`,
      showCancelButton: true,
      cancelButtonText: '取消',
      confirmButtonText: '提交',
      // Vant 4 showDialog prompt 字段在 v4.9.x 引入，TS 类型未覆盖
      ...({
        prompt: {
          placeholder: reasonPlaceholder,
          maxlength: 200,
        },
      } as any),
    })
    const value = (result as { value?: string }).value?.trim() || ''
    if (value.length < reasonMinLength) {
      showToast(`原因长度不足 ${reasonMinLength} 字，操作已取消`)
      return { confirmed: false }
    }
    return { confirmed: true, reason: value }
  } catch {
    return { confirmed: false }
  }
}