# coffee-register
[![Build Status](https://travis-ci.org/danielkalen/coffee-register.svg?branch=master)](https://travis-ci.org/danielkalen/coffee-register)
[![Coverage](.config/badges/coverage.png?raw=true)](https://github.com/danielkalen/coffee-register)
[![Code Climate](https://codeclimate.com/github/danielkalen/coffee-register/badges/gpa.svg)](https://codeclimate.com/github/danielkalen/coffee-register)
[![NPM](https://img.shields.io/npm/v/coffee-register.svg)](https://npmjs.com/package/coffee-register)
[![NPM](https://img.shields.io/npm/dm/coffee-register.svg)](https://npmjs.com/package/coffee-register)

`require` coffeescript files "on-the-fly" without precompilation up to 2000% faster than the official [coffee-script/register](https://github.com/jashkenas/coffeescript) package.

## Usage
**index.js**:
```javascript
require('coffee-register');

// That's it! After this call require coffee files as you would JS files.
require('./somefile.coffee')
require('./another') // ext is optional
require('./dir') // loads './dir/index.coffee'
```


## Benchmarks
[![Benchmarks](benchmarks/results.png?raw=true)](https://github.com/danielkalen/coffee-register)


## How is it so much faster?
There are two primary reasons:

a) This module attaches a hook in node's module system to be invoked only for files ending with `.coffee` as opposed to the official coffee-script/register which hooks onto `.coffee`, `.litcoffee`, `.coffee.md`. Each additional hook imposes overhead on module loading times and since the latter 2 extensions are rarely used they have been ommited by default (although they can be manually registered by using `require('coffee-register').register(['.coffee', '.litcoffee', ...])` and any other extension you wish)

b) By leverging dynamic caching. When `coffee-register` encounters a coffee file it compiles it and then saves it to disk, mapping its content's hash to the saved compiled file so that the next time it encounters this coffee file it inspects its content's hash and attempts to load it from cache. The cache never has to be purged as the process is done automatically for you.

## What about `child_process` forks?
Forks created by `child_process` will also work after this module is loaded.

## Source maps
Due to how the official coffee-script package works source maps will only work by default for non-cached files (i.e. only on the first time they are loaded). `coffee-register` provides an optional workaround which can be enabled by setting the `SOURCE_MAPS` env variable to true.

Example:
```bash
SOURCE_MAPS=1 node index.js
```


## License
MIT © [Daniel Kalen](https://github.com/danielkalen)