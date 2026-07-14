/**
 * H5 / WebView 兼容性辅助工具函数
 */

/**
 * 解决 iOS WebView 软键盘收起后页面不回落、点击错位的问题
 */
export const handleInputBlur = () => {
  // 强制页面微滚动，让 iOS WebView 重新校准页面高度和物理点击区域
  window.scrollTo(
    0,
    Math.max(
      document.body.clientHeight,
      document.documentElement.clientHeight
    )
  );
};
