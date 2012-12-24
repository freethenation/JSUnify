(function() {
  var FunctionCondition, Program, Rule, backtrack, tryFunctionCondition, tryUnifyCondition,
    __slice = [].slice,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

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
      this.tin = parse(fact);
      this.conditions = [];
      for (_i = 0, _len = conditions.length; _i < _len; _i++) {
        c = conditions[_i];
        this.iff(c);
      }
    }

    Rule.prototype.iff = function(condition) {
      var mergedVarlist, varKey, varValue, _ref, _ref1;
      if (isfunc(condition)) {
        condition = new FunctionCondition(condition);
      } else {
        condition = parse(condition);
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

    FunctionCondition.prototype.bind = function(var_name, value) {
      var ver;
      ver = this.varlist[var_name].end_of_chain();
      if (ver.isfree()) {
        ver.node = boxit(value, {});
        return true;
      } else if (unboxit(ver.node) === value) {
        return true;
      } else {
        return false;
      }
    };

    return FunctionCondition;

  })(Tin);

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
    if (unify(goal, rule.tin, changes)) {
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
    rollback(changes);
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

}).call(this);
