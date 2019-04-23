"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.generateErrorName = generateErrorName;
exports.default = Lint;

var _index = require("./providers/index");

function generateErrorName(_node) {
  if (_node.name) return _node.name;
  if (_node.property) return `${_node.object}.${_node.property}()`;
  return _node.object;
}
/**
 * Return false if a if a rule fails
 *
 * TODO: Eventually, targets will default to 'modern', ('chrome@50', safari@8)
 *       See https://github.com/amilajack/eslint-plugin-compat/wiki#release-200
 */


function Lint(eslintNode, targets = ['chrome', 'firefox', 'safari', 'edge'], polyfills = new Set()) {
  // Find the corresponding rules for a eslintNode by it's ASTNodeType
  const failingRule = _index.rules.filter(rule => rule.ASTNodeType === eslintNode.type && // Check if polyfill is provided
  !polyfills.has(rule.id)) // Find the first failing rule
  .find(rule => !rule.isValid(rule, eslintNode, targets));

  return failingRule ? {
    rule: failingRule,
    isValid: false,
    unsupportedTargets: failingRule.getUnsupportedTargets(failingRule, targets)
  } : {
    rule: {},
    unsupportedTargets: [],
    isValid: true
  };
}