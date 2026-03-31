/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{js,ts,jsx,tsx}'],
  theme: {
    extend: {
      colors: {
        brand: {
          50:  '#EBF2FF',
          100: '#BFDBFE',
          500: '#1A56B0',
          600: '#1447A0',
          700: '#0F3976',
          800: '#0A2550',
        },
        teal: {
          50:  '#E1F5EE',
          100: '#A7F3D0',
          500: '#0F6E56',
          600: '#0A5240',
          700: '#063B2A',
        },
      },
      fontFamily: {
        sans: ['Plus Jakarta Sans', 'system-ui', 'sans-serif'],
        mono: ['JetBrains Mono', 'monospace'],
      },
    },
  },
  plugins: [],
}
