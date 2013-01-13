(function() {
  var Debugger, FunctionCondition, Program, Rule, backtrack, extern, name, tryFunctionCondition, tryUnifyCondition, unify,
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

  Debugger = (function() {

    function Debugger(logger) {
      this.level = 0;
      this.logger = logger;
    }

    Debugger.prototype.event = function(name, goal) {
      if (name === "fail" || name === "exit") {
        this.level--;
      }
      this.logger.log("" + this.level + " " + name + ": " + goal);
      if (name === "call") {
        return this.level++;
      }
    };

    return Debugger;

  })();

  Program = (function() {

    function Program() {
      this.rules = [];
      this.settings = {
        debug: false
      };
    }

    Program.prototype.run = function(goal) {
      goal = new Rule(goal);
      return backtrack(goal, this.rules, this.settings.debug ? new Debugger(console) : {
        event: function() {}
      });
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
      return this.func.toString().replace(/(\r\n|\n|\r)/gm, "");
    };

    return FunctionCondition;

  })(unify.TreeTin);

  backtrack = function(goals, rules, debug) {
    var goal, ret, rule, _i, _len;
    if (goals instanceof Rule) {
      goals = [goals.tin];
    }
    goal = goals.pop();
    debug.event("call", goal);
    for (_i = 0, _len = rules.length; _i < _len; _i++) {
      rule = rules[_i];
      if (goal instanceof FunctionCondition) {
        ret = tryFunctionCondition(goal, rule, goals, rules, debug);
      } else {
        ret = tryUnifyCondition(goal, rule, goals, rules, debug);
      }
      if (ret !== null) {
        debug.event("exit", goal);
        return ret;
      }
    }
    debug.event("fail", goal);
    goals.push(goal);
    return null;
  };

  tryUnifyCondition = function(goal, rule, goals, rules, debug) {
    var changes, cond, _i, _len, _ref;
    changes = [];
    if (goal.unify(rule.tin)) {
      debug.event("call", rule.tin);
      rule.conditions.reverse();
      _ref = rule.conditions;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        cond = _ref[_i];
        goals.push(cond);
      }
      rule.conditions.reverse();
      if (goals.length === 0) {
        return goal;
      } else if (backtrack(goals, rules, debug) !== null) {
        return goal;
      }
    }
    debug.event("fail", rule.tin);
    goal.rollback();
    return null;
  };

  tryFunctionCondition = function(goal, rule, goals, rules, debug) {
    if (goal.func(goal)) {
      return goal;
    } else {
      return null;
    }
  };

  extern("Rule", Rule);

  extern("Program", Program);

}).call(this);
