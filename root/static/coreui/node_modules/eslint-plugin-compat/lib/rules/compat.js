"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.default = void 0;

var _Lint = _interopRequireWildcard(require("../Lint"));

var _Versioning = _interopRequireWildcard(require("../Versioning"));

function _interopRequireWildcard(obj) { if (obj && obj.__esModule) { return obj; } else { var newObj = {}; if (obj != null) { for (var key in obj) { if (Object.prototype.hasOwnProperty.call(obj, key)) { var desc = Object.defineProperty && Object.getOwnPropertyDescriptor ? Object.getOwnPropertyDescriptor(obj, key) : {}; if (desc.get || desc.set) { Object.defineProperty(newObj, key, desc); } else { newObj[key] = obj[key]; } } } } newObj.default = obj; return newObj; } }

var _default = {
  meta: {
    docs: {
      description: 'Ensure cross-browser API compatibility',
      category: 'Compatibility',
      recommended: true
    },
    fixable: 'code',
    schema: []
  },

  create(context) {
    // Determine lowest targets from browserslist config, which reads user's
    const browserslistConfig = context.settings.browsers || context.settings.targets;
    const browserslistTargets = (0, _Versioning.Versioning)((0, _Versioning.default)(browserslistConfig));

    function lint(node) {
      const {
        isValid,
        rule,
        unsupportedTargets
      } = (0, _Lint.default)(node, browserslistTargets, context.settings.polyfills ? new Set(context.settings.polyfills) : undefined);

      if (!isValid) {
        context.report({
          node,
          message: [(0, _Lint.generateErrorName)(rule), 'is not supported in', unsupportedTargets.join(', ')].join(' ')
        });
      }
    }

    return {
      // HACK: Ideally, rules will be generated at runtime. Each rule will have
      //       have the ability to register itself to run on specific AST
      //       nodes. For now, we're using the `CallExpression` node since
      //       its what most rules will run on
      CallExpression: lint,
      MemberExpression: lint,
      NewExpression: lint
    };
  }

};
exports.default = _default;