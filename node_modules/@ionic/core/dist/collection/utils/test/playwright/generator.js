/*!
 * (C) Ionic http://ionicframework.com - MIT License
 */
/**
 * Generates a unique test title based on a base title
 * and a test config. Playwright uses test titles to generate
 * test IDs for the test reports, so it's important that
 * each test title is unique.
 */
const generateTitle = (title, config) => {
  const { mode, direction } = config;
  return `${title} - ${mode}/${direction}`;
};
/**
 * Generates a unique filename based on a base filename
 * and a test config.
 */
const generateScreenshotName = (fileName, config) => {
  const { mode, direction } = config;
  return `${fileName}-${mode}-${direction}.png`;
};
/**
 * Given a config generate an array of test variants.
 */
export const configs = (testConfig = DEFAULT_TEST_CONFIG_OPTION) => {
  const { modes, directions } = testConfig;
  const configs = [];
  /**
   * If certain options are not provided,
   * fall back to the defaults.
   */
  const processedMode = modes !== null && modes !== void 0 ? modes : DEFAULT_MODES;
  const processedDirection = directions !== null && directions !== void 0 ? directions : DEFAULT_DIRECTIONS;
  processedMode.forEach((mode) => {
    processedDirection.forEach((direction) => {
      configs.push({ mode, direction });
    });
  });
  return configs.map((config) => {
    return {
      config,
      title: (title) => generateTitle(title, config),
      screenshot: (fileName) => generateScreenshotName(fileName, config),
    };
  });
};
const DEFAULT_MODES = ['ios', 'md'];
const DEFAULT_DIRECTIONS = ['ltr', 'rtl'];
const DEFAULT_TEST_CONFIG_OPTION = {
  modes: DEFAULT_MODES,
  directions: DEFAULT_DIRECTIONS,
};
