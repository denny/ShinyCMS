/* eslint no-console: 0 */

'use strict';

var utils = require('./utils');

var testDir = utils.prepareJetpackTestDir();
var toCopyDir = testDir.dir('to-copy');
var timer;
var jetpackTime;
var nativeTime;

var test = function (testConfig) {
  console.log('');

  return utils.prepareFiles(toCopyDir, testConfig)
  .then(utils.waitAWhile)
  .then(function () {
    timer = utils.startTimer('jetpack.copyAsync()');
    return toCopyDir.copyAsync('.', testDir.path('copied-jetpack'));
  })
  .then(function () {
    jetpackTime = timer();
    return utils.waitAWhile();
  })
  .then(function () {
    timer = utils.startTimer('Native cp -R');
    return utils.exec('cp -R ' + toCopyDir.path() + ' ' + testDir.path('copied-native'));
  })
  .then(function () {
    nativeTime = timer();
    utils.showDifferenceInfo(jetpackTime, nativeTime);
    return utils.cleanAfterTest();
  })
  .catch(function (err) {
    console.log(err);
  });
};

var testConfigs = [
  {
    files: 10000,
    size: 1000
  },
  {
    files: 50,
    size: 1000 * 1000 * 10
  }
];

var runNext = function () {
  if (testConfigs.length > 0) {
    test(testConfigs.pop()).then(runNext);
  }
};

runNext();
