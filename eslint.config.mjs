// @ts-check
import withNuxt from "./.nuxt/eslint.config.mjs";

export default withNuxt(
  // Your custom configs

  {
    rules: {
      "vue/require-default-prop": "off", // allow no default prop
      "vue/no-unused-vars": "off", // allow unused variables
      "@typescript-eslint/no-explicit-any": "off", // allow using any type
      "@typescript-eslint/no-extraneous-class": "off", // allow using class only include static methods
      "@typescript-eslint/no-unused-vars": "off", // allow unused import
      "@typescript-eslint/ban-ts-comment": "off", // allow using ts-ignore
    },
  }
);
