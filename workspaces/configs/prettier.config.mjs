import { createRequire } from 'node:module';

const require = createRequire(import.meta.url);

/** @type {import('prettier').Config} */
const config = {
  arrowParens: 'always',
  overrides: [
    {
      files: ['package.json'],
      options: {
        plugins: [require.resolve('prettier-plugin-packagejson')],
        trailingComma: 'none',
      },
    },
    {
      excludeFiles: ['package.json'],
      files: ['*.json'],
      options: {
        jsonRecursiveSort: true,
        plugins: [require.resolve('prettier-plugin-sort-json')],
        trailingComma: 'none',
      },
    },
  ],
  plugins: ['prettier-plugin-tailwindcss'],
  printWidth: 120,
  singleQuote: true,
  trailingComma: 'all',
};

export default config;
