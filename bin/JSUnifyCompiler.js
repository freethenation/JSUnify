(function() {
  var FunctionCondition, Program, Rule, backtrack, compile, extern, falafel, name, tryFunctionCondition, tryUnifyCondition, unify,
    __slice = [].slice,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  unify = typeof module === 'undefined' ? window.unify : require('unify');

  if (typeof module === 'undefined') {
    window.JSUnify = {};
  }

  extern = function(name, o) {
    if (typeof module === 'undefined') {
      return window.JSUnify[name] = o;
    } else {
      return module.exports[name] = o;
    }
  };

  for (name in unify) {
    extern(name, unify[name]);
  }

  Program = (function() {

    function Program() {
      this.rules = [];
      this.settings = {};
    }

    Program.prototype.run = function(goal) {
      goal = new Rule(goal);
      return backtrack(goal, this.rules);
    };

    Program.prototype.rule = function() {
      var conditions, fact;
      fact = arguments[0], conditions = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
      this.rules.push((function(func, args, ctor) {
        ctor.prototype = func.prototype;
        var child = new ctor, result = func.apply(child, args);
        return Object(result) === result ? result : child;
      })(Rule, [fact].concat(__slice.call(conditions)), function(){}));
      return this;
    };

    Program.prototype.iff = function(conditional) {
      var rule;
      if (this.rules.length === 0) {
        throw "iff is invalid in this context. A rule must be created first!";
      }
      rule = this.rules[this.rules.length - 1];
      rule.iff(conditional);
      return this;
    };

    Program.prototype.load = function(rules) {
      var rule, _i, _len;
      for (_i = 0, _len = rules.length; _i < _len; _i++) {
        rule = rules[_i];
        this.rules.push(rule);
      }
      return this;
    };

    return Program;

  })();

  Rule = (function() {

    function Rule() {
      var c, conditions, fact, _i, _len;
      fact = arguments[0], conditions = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
      this.fact = fact;
      this.tin = unify.box(fact);
      this.conditions = [];
      for (_i = 0, _len = conditions.length; _i < _len; _i++) {
        c = conditions[_i];
        this.iff(c);
      }
    }

    Rule.prototype.iff = function(condition) {
      var mergedVarlist, varKey, varValue, _ref, _ref1;
      if (unify.types.isFunc(condition)) {
        condition = new FunctionCondition(condition);
      } else {
        condition = unify.box(condition);
      }
      if (this.conditions.length === 0) {
        mergedVarlist = {};
        _ref = this.tin.varlist;
        for (varKey in _ref) {
          varValue = _ref[varKey];
          mergedVarlist[varKey] = varValue;
        }
      } else {
        mergedVarlist = this.conditions[0].varlist;
      }
      _ref1 = condition.varlist;
      for (varKey in _ref1) {
        varValue = _ref1[varKey];
        if (mergedVarlist[varKey] === void 0) {
          mergedVarlist[varKey] = varValue;
        }
      }
      condition.varlist = mergedVarlist;
      this.conditions.push(condition);
      return this;
    };

    return Rule;

  })();

  FunctionCondition = (function(_super) {

    __extends(FunctionCondition, _super);

    function FunctionCondition(func) {
      this.func = func;
      FunctionCondition.__super__.constructor.call(this, null, null, {});
    }

    FunctionCondition.prototype.toString = function() {
      return "new FunctionCondition(" + (toJson(this.node)) + ", " + (toJson(this.varlist)) + ")";
    };

    return FunctionCondition;

  })(unify.TreeTin);

  backtrack = function(goals, rules) {
    var goal, ret, rule, _i, _len;
    if (goals instanceof Rule) {
      goals = [goals.tin];
    }
    goal = goals.pop();
    for (_i = 0, _len = rules.length; _i < _len; _i++) {
      rule = rules[_i];
      if (goal instanceof FunctionCondition) {
        ret = tryFunctionCondition(goal, rule, goals, rules);
      } else {
        ret = tryUnifyCondition(goal, rule, goals, rules);
      }
      if (ret !== null) {
        return ret;
      }
    }
    goals.push(goal);
    return null;
  };

  tryUnifyCondition = function(goal, rule, goals, rules) {
    var changes, cond, _i, _len, _ref;
    changes = [];
    if (goal.unify(rule.tin)) {
      rule.conditions.reverse();
      _ref = rule.conditions;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        cond = _ref[_i];
        goals.push(cond);
      }
      rule.conditions.reverse();
      if (goals.length === 0) {
        return goal;
      } else if (backtrack(goals, rules) !== null) {
        return goal;
      }
    }
    goal.rollback();
    return null;
  };

  tryFunctionCondition = function(goal, rule, goals, rules) {
    if (goal.func(goal)) {
      return goal;
    } else {
      return null;
    }
  };

  extern("Rule", Rule);

  extern("Program", Program);

  falafel = typeof module === 'undefined' ? window.falafel : require('free-falafel');

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
