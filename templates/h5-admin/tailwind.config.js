/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{vue,js,ts,jsx,tsx}'],
  theme: {
    screens: {
      sm: '640px',   // --project-bp-sm
      md: '768px',   // --project-bp-md
      lg: '1024px',  // --project-bp-lg
      xl: '1280px',  // --project-bp-xl
    },
    extend: {
      colors: {
        primary: 'var(--project-primary-color)',
        success: 'var(--project-success-color)',
        warning: 'var(--project-warning-color)',
        danger: 'var(--project-danger-color)',
        neutral: 'var(--project-neutral-color)',
      },
      spacing: {
        'safe-top': 'env(safe-area-inset-top)',
        'safe-bottom': 'env(safe-area-inset-bottom)',
      },
      maxWidth: {
        container: 'var(--project-container-max)',
      },
    },
  },
  plugins: [],
}