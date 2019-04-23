module.exports = function() {
  return {
    visitor: {
      ModuleDeclaration: function(path) {
        path.remove();
      }
    }
  };
}
