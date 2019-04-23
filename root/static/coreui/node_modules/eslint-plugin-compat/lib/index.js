"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.rules = exports.config = exports.configs = void 0;

var _recommended = _interopRequireDefault(require("./config/recommended"));

var _compat = _interopRequireDefault(require("./rules/compat"));

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

/**
 * @author Amila Welihinda
 * 
 */
//------------------------------------------------------------------------------
// Requirements
//------------------------------------------------------------------------------
//------------------------------------------------------------------------------
// Plugin Definition
//------------------------------------------------------------------------------
// import all rules in lib/rules
const configs = {
  recommended: _recommended.default
}; // Kept for backwards compatibility

exports.configs = configs;
const config = configs;
exports.config = config;
const rules = {
  compat: _compat.default
};
exports.rules = rules;