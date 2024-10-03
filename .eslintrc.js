module.exports = {
  env: {
    node: true,
    es2021: true
  },
  parserOptions: {
    ecmaVersion: 12
  },
  extends: ['eslint:recommended', 'plugin:import/recommended'],
  rules: {
    'no-debugger': 0,
    'no-inner-declarations': 0,
    'import/no-extraneous-dependencies': 'error'
  }
};
