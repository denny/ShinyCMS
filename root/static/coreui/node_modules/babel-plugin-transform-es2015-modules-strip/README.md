# babel-plugin-transform-es2015-modules-strip

[![npm](https://img.shields.io/npm/v/babel-plugin-transform-es2015-modules-strip.svg?style=flat-square&maxAge=2592000)](https://www.npmjs.com/package/babel-plugin-transform-es2015-modules-strip)
[![License](https://img.shields.io/badge/license-MIT-brightgreen.svg?style=flat-square)](https://github.com/bardiharborow/babel-plugin-transform-es2015-modules-strip/blob/master/LICENSE)
[![Gratipay](https://img.shields.io/gratipay/user/BardiHarborow.svg?maxAge=2592000&style=flat-square)](https://gratipay.com/~BardiHarborow/)

> A Babel plugin that strips import and export declarations.

## Installation

```sh
$ npm install babel-plugin-transform-es2015-modules-strip
```

## Usage

### Via `.babelrc` (Recommended)

**.babelrc**

```js
{
  "presets": [
    ["es2015", {
      "modules": false
    }]
  ],
  "plugins": ["transform-es2015-modules-strip"]
}

```

### Via Node API

```javascript
require("babel-core").transform("code", {
  presets: [
    ["es2015", {
      modules: false
    }]
  ],
  plugins: ["transform-es2015-modules-strip"]
});
```

Made with <3 by [Bardi Harborow](https://bardiharborow.com).
