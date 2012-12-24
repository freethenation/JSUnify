(function() {
  var compile, falafel;

  falafel = (typeof window !== "undefined" && window !== null) && (window.falafel != null) ? window.falafel : require('./falafel.js');

  compile = function(src) {
    var breathFirstFn, depthFirstFn, descendantNodeTypes, isJsProgramOrExprRoot, isJsUnifyCall;
    depthFirstFn = function(node) {
      var indent, n, ops;
      if (node.unifyType === null) {
        return;
      }
      indent = (new Array(node.unifyIndent + 5)).join(" ");
      if (node.unifyType === "JsUnifyCall") {
        node.update(["(function(){", "var JSUnify = typeof(module) == 'undefined' || typeof(require) == 'undefined' ? window.JSUnify : require('jsunify');", "var Var = JSUnify.Var;", node.isUnifyProg ? "return new JSUnify.Program()\n" + (node["arguments"][0].source()) : "return " + (node["arguments"][0].source()) + ";", "})()"].join("\n" + indent));
      } else if (node.unifyType === "ProgramRoot") {
        node.update(node.body.source());
      } else if (node.unifyType === "OutCall") {
        if (node.type === "LogicalExpression" || node.type === "BinaryExpression") {
          node.update("" + (node.left.source()) + ", " + (node.right.source()));
        } else if (node.type === "ExpressionStatement") {
          node.update("" + indent + ".rule(" + (node.expression.source()) + ")");
        } else if (node.type === "BlockStatement") {
          node.update(((function() {
            var _i, _len, _ref, _results;
            _ref = node.body;
            _results = [];
            for (_i = 0, _len = _ref.length; _i < _len; _i++) {
              n = _ref[_i];
              _results.push(n.source());
            }
            return _results;
          })()).join('\n'));
        }
      } else if (node.unifyType === "ExprRoot" || node.unifyType === "InCall") {
        if (node.type === "CallExpression") {
          node.update([
            "{" + node.callee.name + ":[", ((function() {
              var _i, _len, _ref, _results;
              _ref = node["arguments"];
              _results = [];
              for (_i = 0, _len = _ref.length; _i < _len; _i++) {
                n = _ref[_i];
                _results.push(n.source());
              }
              return _results;
            })()).join(','), "]}"
          ].join(""));
        } else if (node.type === "Identifier") {
          node.update("Var(\"" + node.name + "\")");
        } else if (node.type === "LogicalExpression" || node.type === "BinaryExpression") {
          ops = {
            "+": "add",
            "-": "sub",
            "*": "mult",
            "/": "div",
            "==": "eq",
            "===": "eq",
            "%": "mod",
            "!=": "neq",
            "!==": "neq",
            ">": "greater",
            "<": "less",
            ">=": "greaterOrEqual",
            "<=": "lessOrEqual",
            "&&": "and",
            "||": "or"
          };
          if (ops[node.operator] != null) {
            node.update("{" + ops[node.operator] + ":[" + (node.left.source()) + ", " + (node.right.source()) + "]}");
          }
        }
      }
    };
    isJsUnifyCall = function(node) {
      return node.type === "CallExpression" && node.callee.name === "$jsunify";
    };
    isJsProgramOrExprRoot = function(node) {
      return (node.parent != null) && isJsUnifyCall(node.parent);
    };
    descendantNodeTypes = {
      ProgramRoot: "OutCall",
      ExprRoot: "InCall",
      ProgramRoot: "OutCall",
      InCall: "InCall",
      OutCall: "OutCall"
    };
    breathFirstFn = function(node) {
      var _ref, _ref1, _ref2;
      if (isJsUnifyCall(node)) {
        node.unifyType = "JsUnifyCall";
        node.unifyIndent = node.loc.start.column;
      } else if (isJsProgramOrExprRoot(node)) {
        node.unifyType = node.type === "FunctionExpression" ? "ProgramRoot" : "ExprRoot";
        node.isUnifyProg = node.type === "FunctionExpression";
        node.parent.isUnifyProg = node.isUnifyProg;
      } else if (node.type === "FunctionExpression") {
        node.unifyType = null;
      } else if (node.type === "CallExpression" && (((_ref = node.parent) != null ? _ref.unifyType : void 0) != null)) {
        node.unifyType = "InCall";
      } else if (node.parent != null) {
        node.unifyType = node.parent.unifyType === null ? null : descendantNodeTypes[node.parent.unifyType];
      } else {
        node.unifyType = null;
      }
      if (node.unifyType !== null && (((_ref1 = node.parent) != null ? _ref1.isUnifyProg : void 0) != null) && !(node.isUnifyProg != null)) {
        node.isUnifyProg = node.parent.isUnifyProg;
      }
      if (node.unifyType !== null && !(node.unifyIndent != null) && (((_ref2 = node.parent) != null ? _ref2.unifyIndent : void 0) != null)) {
        node.unifyIndent = node.parent.unifyIndent;
      }
    };
    return falafel(src, {
      loc: true
    }, depthFirstFn, breathFirstFn).toString();
  };

  extern("compile", compile);

}).call(this);
