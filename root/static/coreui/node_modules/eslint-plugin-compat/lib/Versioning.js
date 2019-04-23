"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.default = DetermineTargetsFromConfig;
exports.Versioning = Versioning;

var _browserslist = _interopRequireDefault(require("browserslist"));

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

/**
 * Determine the targets based on the browserslist config object
 */
function DetermineTargetsFromConfig(config) {
  if (Array.isArray(config)) {
    return (0, _browserslist.default)(config);
  }

  if (config && typeof config === 'object') {
    return (0, _browserslist.default)([...(config.production || []), ...(config.development || [])]);
  }

  return (0, _browserslist.default)();
}
/**
 * Take a list of targets returned from browserslist api, return the lowest version
 * version of each target
 */


function Versioning(targetslist) {
  return targetslist // Sort the targets by target name and then version number in ascending order
  .map(e => {
    const [target, version] = e.split(' ');
    return {
      target,
      version,
      parsedVersion: version === 'all' ? 0 : version.includes('-') ? parseFloat(version.split('-')[0]) : parseFloat(version)
    };
  }) // Sort the targets by target name and then version number in descending order
  // ex. [a@3, b@3, a@1] => [a@3, a@1, b@3]
  .sort((a, b) => {
    if (b.target === a.target) {
      // If any version === 'all', return 0. The only version of op_mini is 'all'
      // Otherwise, compare the versions
      return typeof b.parsedVersion === 'string' || typeof a.parsedVersion === 'string' ? 0 : b.parsedVersion - a.parsedVersion;
    }

    return b.target > a.target ? 1 : -1;
  }) // First last target always has the latest version
  .filter((e, i, items // Check if the current target is the last of its kind. If it is, then it
  // is most recent version
  ) => i + 1 === items.length || e.target !== items[i + 1].target);
}