export default {
  plugins: {
    tailwindcss: {},
    autoprefixer: {},
    'postcss-px-to-viewport-8-plugin': {
      viewportWidth: 375,
      viewportUnit: 'vw',
      fontViewportUnit: 'vw',
      selectorBlackList: ['.ignore-vw', '.sandbox-container'],
      minPixelValue: 1,
      mediaQuery: false,
      exclude: [/node_modules/i]
    }
  }
}
