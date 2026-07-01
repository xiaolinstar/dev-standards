# PostCSS px-to-viewport 配置参考

> 对应 Skill 核心约定 §1「Viewport vw 适配」。

## postcss.config.js 完整配置

```js
// postcss.config.js
module.exports = {
  plugins: {
    // 自动补全浏览器前缀
    autoprefixer: {},

    // px → vw 自动转换
    'postcss-px-to-viewport-8-plugin': {
      // ========== 基准宽度 ==========
      // 设计稿基准 375px（iPhone SE/8/X 视口宽度）
      // 开发时直接按 375px 设计稿的标注值写 px，编译时自动转为 vw
      viewportWidth: 375,

      // ========== 转换精度 ==========
      // vw 小数位数，5 位足够精度
      unitPrecision: 5,

      // ========== 目标单位 ==========
      // 转换后的 CSS 单位
      viewportUnit: 'vw',

      // ========== 字体也转换 ==========
      // font-size 同样参与 vw 转换，保持文字随屏幕等比缩放
      fontViewportUnit: 'vw',

      // ========== 最小转换阈值 ==========
      // 小于 1px 的值不转换（如 border: 0.5px）
      minPixelValue: 1,

      // ========== 媒体查询 ==========
      // 媒体查询内的 px 不转换
      mediaQuery: false,

      // ========== 选择器黑名单 ==========
      // 以下选择器中的 px 值不参与转换
      // sandbox-container 用于 PC 大屏沙盒居中，不能转 vw
      selectorBlackList: [
        '.sandbox-container',
        '.ignore-viewport',
      ],

      // ========== 排除文件 ==========
      // node_modules 中的第三方样式不转换
      exclude: [/node_modules/],

      // ========== 横屏处理 ==========
      // 如需支持横屏可设为 true
      landscape: false,
    },
  },
};
```

## Vite 项目集成方式

如果项目使用 Vite，可以在 `vite.config.ts` 中通过 `css.postcss` 配置，效果等同于独立的 `postcss.config.js`：

```ts
// vite.config.ts
import { defineConfig } from 'vite';
import vue from '@vitejs/plugin-vue';
import pxToViewport from 'postcss-px-to-viewport-8-plugin';

export default defineConfig({
  plugins: [vue()],
  css: {
    postcss: {
      plugins: [
        pxToViewport({
          viewportWidth: 375,
          unitPrecision: 5,
          viewportUnit: 'vw',
          fontViewportUnit: 'vw',
          minPixelValue: 1,
          mediaQuery: false,
          selectorBlackList: ['.sandbox-container', '.ignore-viewport'],
          exclude: [/node_modules/],
        }),
      ],
    },
  },
});
```

> **注意**：二者选其一。如果项目根目录存在 `postcss.config.js`，Vite 会自动加载它，`vite.config.ts` 中的 `css.postcss` 配置会被忽略。

## 安装依赖

```bash
npm install -D postcss-px-to-viewport-8-plugin autoprefixer
```

## 常见问题

### Q: 第三方组件库的 px 被转换了怎么办？

通过 `exclude` 排除 `node_modules`，或在 `selectorBlackList` 中添加特定前缀。

### Q: 某个元素不想被转换？

在该元素的样式选择器中添加 `.ignore-viewport` 类名，或使用行内注释：

```css
/* postcss-px-to-viewport-disable-next-line */
.fixed-size {
  width: 100px; /* 这行不会被转换 */
}
```

### Q: PC 沙盒容器为什么要排除？

`.sandbox-container` 用 `max-width: 480px` 固定像素限宽并居中。如果被转换为 vw，在大屏上宽度会跟着屏幕拉伸，失去沙盒效果。
