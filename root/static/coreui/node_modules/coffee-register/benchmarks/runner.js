var Benchmark, COFFEE_CACHE_DIR, Promise, benchmarks, chalk, deRegister, exec, extend, fs, path, runClean, sample, suite, temp, theImporter,
  slice = [].slice;

Promise = require('bluebird');

Benchmark = require('benchmark');

benchmarks = require('beautify-benchmark');

exec = require('child_process').execSync;

fs = require('fs-jetpack');

path = require('path');

chalk = require('chalk');

extend = require('extend');

sample = function() {
  return path.join.apply(path, [__dirname, 'samples'].concat(slice.call(arguments)));
};

temp = function() {
  return path.join.apply(path, [__dirname, 'temp'].concat(slice.call(arguments)));
};

process.env.COFFEE_CACHE_DIR = COFFEE_CACHE_DIR = temp('.cache');

fs.dir(temp(), {
  empty: true
});

theImporter = null;

runClean = function(type) {
  deRegister();
  switch (type) {
    case 'coffee-script/register':
      require('coffee-script/register');
      break;
    case 'coffee-register':
      require('../');
  }
  return theImporter();
};

deRegister = function() {
  var cached, cachedFile, i, item, j, k, largeModules, len, len1, len2, sampleFile, samples;
  delete require.extensions['.coffee'];
  delete require.extensions['.litcoffee'];
  delete require.extensions['.coffee.md'];
  delete require.cache[require.resolve('coffee-script/register')];
  delete require.cache[require.resolve('coffee-script/lib/coffee-script/register')];
  delete require.cache[require.resolve('../')];
  samples = fs.list(sample());
  for (i = 0, len = samples.length; i < len; i++) {
    sampleFile = samples[i];
    delete require.cache[sample(sampleFile)];
  }
  cached = fs.list(temp('.cache')) || [];
  for (j = 0, len1 = cached.length; j < len1; j++) {
    cachedFile = cached[j];
    delete require.cache[temp('.cache', cachedFile)];
  }
  largeModules = Object.keys(require.cache).filter(function(path) {
    return path.includes('simplyimport') || path.includes('simplywatch');
  });
  for (k = 0, len2 = largeModules.length; k < len2; k++) {
    item = largeModules[k];
    delete require.cache[item];
  }
};

suite = function(name, options) {
  return Benchmark.Suite(name, options).on('start', function() {
    return console.log(chalk.dim(name));
  }).on('cycle', function() {
    return benchmarks.add(arguments[0].target);
  }).on('complete', function() {
    return benchmarks.log();
  });
};

suite('3 small modules', {
  onComplete: function() {
    return fs.dir(temp(), {
      empty: true
    });
  },
  onStart: function() {
    return theImporter = function() {
      require('./samples/small1');
      require('./samples/small2');
      require('./samples/small3');
    };
  }
}).add('coffee-script/register', function() {
  return runClean('coffee-script/register');
}).add('coffee-register (uncached)', function() {
  process.env.COFFEE_NO_CACHE = true;
  return runClean('coffee-register');
}).add('coffee-register (cached)', function() {
  delete process.env.COFFEE_NO_CACHE;
  return runClean('coffee-register');
}).run();

suite('6 small modules', {
  onComplete: function() {
    return fs.dir(temp(), {
      empty: true
    });
  },
  onStart: function() {
    return theImporter = function() {
      require('./samples/small1');
      require('./samples/small2');
      require('./samples/small3');
      require('./samples/small4');
      require('./samples/small5');
      return require('./samples/small6');
    };
  }
}).add('coffee-script/register', function() {
  return runClean('coffee-script/register');
}).add('coffee-register (uncached)', function() {
  process.env.COFFEE_NO_CACHE = true;
  return runClean('coffee-register');
}).add('coffee-register (cached)', function() {
  delete process.env.COFFEE_NO_CACHE;
  return runClean('coffee-register');
}).run();

suite('4 medium modules', {
  onComplete: function() {
    return fs.dir(temp(), {
      empty: true
    });
  },
  onStart: function() {
    return theImporter = function() {
      require('./samples/medium1');
      require('./samples/medium2');
      require('./samples/medium3');
      return require('./samples/medium4');
    };
  }
}).add('coffee-script/register', function() {
  return runClean('coffee-script/register');
}).add('coffee-register (uncached)', function() {
  process.env.COFFEE_NO_CACHE = true;
  return runClean('coffee-register');
}).add('coffee-register (cached)', function() {
  delete process.env.COFFEE_NO_CACHE;
  return runClean('coffee-register');
}).run();

suite('2 large modules', {
  onComplete: function() {
    return fs.dir(temp(), {
      empty: true
    });
  },
  onStart: function() {
    return theImporter = function() {
      require('simplyimport/lib/simplyimport');
      return require('simplywatch/lib/simplywatch');
    };
  }
}).add('coffee-script/register', function() {
  return runClean('coffee-script/register');
}).add('coffee-register (uncached)', function() {
  process.env.COFFEE_NO_CACHE = true;
  return runClean('coffee-register');
}).add('coffee-register (cached)', function() {
  delete process.env.COFFEE_NO_CACHE;
  return runClean('coffee-register');
}).run();
