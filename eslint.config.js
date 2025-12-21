// SPDX-License-Identifier: MPL-2.0
const js = require("@eslint/js");
const globals = require("globals");

module.exports = [
  js.configs.recommended,
  {
    files: ["client/*.js", "html/*.js"],
    languageOptions: {
      ecmaVersion: 2021,
      sourceType: "module",
      globals: { ...globals.browser },
    },
    rules: {
      "no-unused-vars": ["warn", { argsIgnorePattern: "^_" }],
      "no-undef": "off",
      "no-constant-condition": "off",
      "no-empty": ["warn", { allowEmptyCatch: true }],
      "no-console": "off",
    },
  },
];
