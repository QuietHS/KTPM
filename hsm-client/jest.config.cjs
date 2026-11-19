module.exports = {
  testEnvironment: "jsdom",

  setupFilesAfterEnv: [
    "<rootDir>/src/setupTests.js",
  ],

  transform: {
    "^.+\\.[jt]sx?$": "babel-jest",
  },

  moduleNameMapper: {
    "\\.(css|less|scss|sass)$": "identity-obj-proxy",

    "\\.(jpg|jpeg|png|gif|svg)$":
      "<rootDir>/src/__mocks__/fileMock.cjs",
  },

  testMatch: [
    "<rootDir>/src/**/*.test.js",
    "<rootDir>/src/**/*.test.jsx",
  ],
};