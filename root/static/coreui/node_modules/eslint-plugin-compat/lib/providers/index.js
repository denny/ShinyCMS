"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.default = exports.rules = void 0;

var _KangaxProvider = _interopRequireDefault(require("./KangaxProvider"));

var _CanIUseProvider = _interopRequireDefault(require("./CanIUseProvider"));

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

const rules = [..._KangaxProvider.default, ..._CanIUseProvider.default];
exports.rules = rules;
var _default = {};
exports.default = _default;