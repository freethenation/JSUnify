(function() {
  var Box, DICT_FLAG, DictFlag, FunctionCondition, HIDDEN_VAR_PREFIX, Program, Rule, Tin, Var, Variable, backtrack, bind, bind_tins, boxit, compile, dir, extern, falafel, g_hidden_var_counter, get_tin, internal, isHiddenVar, isarray, isbool, isfunc, isnum, isobj, isstr, isundef, isvaluetype, len, log, mergeJson, parse, rollback, str, toJson, tryFunctionCondition, tryUnifyCondition, unboxit, unify, _unify,
    __slice = [].slice,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  log = function(o) {
    return console.log(o);
  };

  dir = function(o) {
    return console.dir(o);
  };

  len = function(o) {
    return o.length;
  };

  if (typeof exports === 'undefined') {
    window.JSUnify = {};
  }

  extern = function(name, o) {
    if (typeof exports === 'undefined') {
      return window.JSUnify[name] = o;
    } else {
      return exports[name] = o;
    }
  };

  if (typeof exports === 'undefined') {
    window.JSUnify.internal = {};
  } else {
    exports.internal = {};
  }

  internal = function(name, o) {
    if (typeof exports === 'undefined') {
      return window.JSUnify.internal[name] = o;
    } else {
      return exports.internal[name] = o;
    }
  };

  str = function(o) {
    if (typeof o === "undefined") {
      return "undefined";
    } else if (o === null) {
      return "null";
    } else {
      return o.toString();
    }
  };

  mergeJson = function() {
    var arg, name, ret, value, _i, _len;
    ret = {};
    for (_i = 0, _len = arguments.length; _i < _len; _i++) {
      arg = arguments[_i];
      for (name in arg) {
        value = arg[name];
        ret[name] = value;
      }
    }
    return ret;
  };

  isundef = function(o) {
    return typeof o === "undefined";
  };

  isbool = function(o) {
    return typeof o === "boolean";
  };

  isarray = function(o) {
    return (o != null) && Array.isArray(o);
  };

  isstr = function(o) {
    return typeof o === "string";
  };

  isnum = function(o) {
    return typeof o === "number";
  };

  isobj = function(o) {
    return o !== null && !isarray(o) && typeof o === "object";
  };

  isvaluetype = function(o) {
    return isbool(o) || isstr(o) || isnum(o);
  };

  isfunc = function(o) {
    return !!(o && o.constructor && o.call && o.apply);
  };

  toJson = function(elem) {
    var e;
    if (isarray(elem)) {
      return "[" + (((function() {
        var _i, _len, _results;
        _results = [];
        for (_i = 0, _len = elem.length; _i < _len; _i++) {
          e = elem[_i];
          _results.push(toJson(e));
        }
        return _results;
      })()).join(',')) + "]";
    } else if (elem instanceof Box || elem instanceof Tin || elem instanceof Variable || elem instanceof DictFlag) {
      return str(elem);
    } else if (isobj(elem)) {
      return "{" + (((function() {
        var _results;
        _results = [];
        for (e in elem) {
          _results.push(e + ':' + toJson(elem[e]));
        }
        return _results;
      })()).join(',')) + "}";
    } else if (isstr(elem)) {
      return "\"" + elem + "\"";
    } else {
      return str(elem);
    }
  };

  DictFlag = (function() {

    function DictFlag() {}

    DictFlag.prototype.toString = function() {
      return "new DictFlag()";
    };

    return DictFlag;

  })();

  DICT_FLAG = new DictFlag();

  Box = (function() {

    function Box(v) {
      if (isvaluetype(v) || v === null) {
        this.value = v;
      } else {
        throw "Can only box value types, not " + (toJson(v));
      }
    }

    Box.prototype.toString = function() {
      return "new Box(" + (toJson(this.value)) + ")";
    };

    return Box;

  })();

  g_hidden_var_counter = 1;

  HIDDEN_VAR_PREFIX = "__B3qgfO__";

  isHiddenVar = function(name) {
    return name.slice(0, HIDDEN_VAR_PREFIX.length) === HIDDEN_VAR_PREFIX;
  };

  Variable = (function() {

    function Variable(name) {
      if (name === "_") {
        this.name = HIDDEN_VAR_PREFIX + g_hidden_var_counter;
        g_hidden_var_counter += 1;
      } else {
        this.name = name;
      }
    }

    Variable.prototype.isHiddenVar = function() {
      return isHiddenVar(this.name);
    };

    Variable.prototype.toString = function() {
      return "Var(" + (toJson(this.name)) + ")";
    };

    return Variable;

  })();

  Var = function(name) {
    return new Variable(name);
  };

  Tin = (function() {

    function Tin(name, node, varlist) {
      this.node = node != null ? node : null;
      this.varlist = isobj(varlist) ? varlist : null;
      this.chainlength = 1;
      this.name = name;
    }

    Tin.prototype.end_of_chain = function() {
      var t;
      t = this;
      while (t.varlist instanceof Tin) {
        t = t.varlist;
      }
      return t;
    };

    Tin.prototype.isfree = function() {
      var t;
      t = this.end_of_chain();
      return t.node === null && t.varlist === null;
    };

    Tin.prototype.isHiddenVar = function() {
      return isHiddenVar(this.name);
    };

    Tin.prototype.toString = function() {
      return "new Tin(" + (toJson(this.name)) + ", " + (toJson(this.node)) + ", " + (toJson(this.varlist)) + ")";
    };

    Tin.prototype.get = function(var_name) {
      var n, vartin;
      vartin = this.varlist[var_name];
      if (vartin !== null && vartin !== void 0) {
        vartin = vartin.end_of_chain();
      }
      if (!(vartin != null)) {
        throw "Variable " + var_name + " not in this tin";
      } else if (!(vartin.node != null) || vartin.node === null) {
        return new Var(vartin.name);
      } else if (vartin.node instanceof Box) {
        return unboxit(vartin.node, vartin.varlist);
      } else if (vartin.node instanceof Var) {
        return unboxit(vartin.node, vartin.varlist);
      } else if (isarray(vartin.node)) {
        return (function() {
          var _i, _len, _ref, _results;
          _ref = vartin.node;
          _results = [];
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            n = _ref[_i];
            _results.push(unboxit(n, vartin.varlist));
          }
          return _results;
        })();
      } else {
        throw "Unknown type in get";
      }
    };

    Tin.prototype.get_all = function() {
      var j, key;
      j = {};
      for (key in this.varlist) {
        if (!isHiddenVar(key)) {
          j[key] = this.get(key);
        }
      }
      return j;
    };

    Tin.prototype.unparse = function() {
      return unboxit(this.node);
    };

    return Tin;

  })();

  boxit = function(elem, tinlist) {
    var a, item, key;
    if (elem instanceof Variable) {
      if (tinlist != null) {
        tinlist[elem.name] = new Tin(elem.name, null, null);
      }
      return elem;
    } else if (elem instanceof Box) {
      return elem;
    } else if (isarray(elem)) {
      return (function() {
        var _i, _len, _results;
        _results = [];
        for (_i = 0, _len = elem.length; _i < _len; _i++) {
          item = elem[_i];
          _results.push(boxit(item, tinlist));
        }
        return _results;
      })();
    } else if (isobj(elem)) {
      a = [];
      for (key in elem) {
        a.push([boxit(key, tinlist), boxit(elem[key], tinlist)]);
      }
      a.push(DICT_FLAG);
      return a.sort();
    } else if (isvaluetype(elem || elem === null)) {
      return new Box(elem);
    } else {
      throw "Don't understand the type of elem";
    }
  };

  unboxit = function(tree, varlist) {
    var e, hash, item, tin, _i, _len, _ref;
    if (isarray(tree)) {
      if (tree[tree.length - 1] === DICT_FLAG) {
        hash = new Object();
        _ref = tree.slice(0, tree.length - 1);
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          e = _ref[_i];
          hash[unboxit(e[0])] = unboxit(e[1]);
        }
        return hash;
      } else {
        return (function() {
          var _j, _len1, _results;
          _results = [];
          for (_j = 0, _len1 = tree.length; _j < _len1; _j++) {
            item = tree[_j];
            _results.push(unboxit(item));
          }
          return _results;
        })();
      }
    } else if (tree instanceof Box) {
      return tree.value;
    } else if (tree instanceof Variable) {
      if (varlist !== void 0) {
        try {
          tin = get_tin(varlist, tree);
        } catch (error) {
          return tree;
        }
        return unboxit(tin.node, tin.varlist);
      } else {
        return tree;
      }
    } else {
      throw "Unrecognized type '" + (typeof tree) + "' in unboxit";
    }
  };

  parse = function(elem) {
    var tinlist, tree;
    tinlist = {};
    tree = boxit(elem, tinlist);
    return new Tin(null, tree, tinlist);
  };

  get_tin = function(varlist, node) {
    if (!node instanceof Variable) {
      throw "Node must be a Var to get_tin";
    }
    if ((varlist != null ? varlist[node.name] : void 0) != null) {
      return varlist[node.name];
    }
    throw "Couldn't find node " + node.name + " in varlist " + varlist;
  };

  bind = function(t, node, varlist, changes) {
    t = t.end_of_chain();
    if (!t.isfree()) {
      return false;
    }
    t.node = node;
    t.varlist = varlist;
    return changes.push(function() {
      t.node = null;
      t.varlist = null;
      return t.chainlength = 1;
    });
  };

  bind_tins = function(t1, t2, changes) {
    if (!t1.isfree() && !t2.isfree()) {
      return false;
    } else if (t1.isfree() && !t2.isfree()) {
      return bind(t1, t2.node, t2.varlist, changes);
    } else if (!t1.isfree() && t2.isfree()) {
      return bind(t2, t1.node, t1.varlist, changes);
    } else if (t2.chainlength < t1.chainlength) {
      t2.chainlength += 1;
      return bind(t2, null, t1, changes);
    } else {
      t1.chainlength += 1;
      return bind(t1, null, t2, changes);
    }
  };

  _unify = function(n1, v1, n2, v2, changes) {
    var idx, num, t1, t2, _i, _len, _ref;
    if (changes == null) {
      changes = [];
    }
    if (n1 === void 0 && n2 === void 0) {
      return true;
    }
    if (n1 === null && n2 === null) {
      return true;
    }
    if (n1 === null || n2 === null) {
      return false;
    }
    if (n1 instanceof Variable && n2 instanceof Variable) {
      t1 = get_tin(v1, n1);
      t2 = get_tin(v2, n2);
      if (!bind_tins(t1, t2, changes)) {
        if (!_unify(t1.node, t1.varlist, t2.node, t2.varlist, changes)) {
          return false;
        }
      }
    } else if (n1 instanceof Variable) {
      t1 = get_tin(v1, n1);
      if (!bind(t1, n2, v2, changes)) {
        if (!_unify(t1.node, t1.varlist, n2, v2, changes)) {
          return false;
        }
      }
    } else if (n2 instanceof Variable) {
      t2 = get_tin(v2, n2);
      if (!bind(t2, n1, v1, changes)) {
        if (!_unify(t2.node, t2.varlist, n1, v1, changes)) {
          return false;
        }
      }
    } else {
      if (n1 instanceof Box && n2 instanceof Box && isvaluetype(n1.value) && isvaluetype(n2.value)) {
        return n1.value === n2.value;
      } else if (isarray(n1) && isarray(n2)) {
        if (n1.length !== n2.length) {
          return false;
        }
        _ref = (function() {
          var _j, _ref, _results;
          _results = [];
          for (num = _j = 0, _ref = n1.length; 0 <= _ref ? _j <= _ref : _j >= _ref; num = 0 <= _ref ? ++_j : --_j) {
            _results.push(num);
          }
          return _results;
        })();
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          idx = _ref[_i];
          if (!_unify(n1[idx], v1, n2[idx], v2, changes)) {
            return false;
          }
        }
      }
    }
    return true;
  };

  unify = function(expr1, expr2, changes) {
    var success;
    if (changes == null) {
      changes = [];
    }
    success = true;
    expr1 = expr1 instanceof Tin ? expr1 : parse(expr1);
    expr2 = expr2 instanceof Tin ? expr2 : parse(expr2);
    success = _unify(expr1.node, expr1.varlist, expr2.node, expr2.varlist, changes);
    if (success === false) {
      return null;
    } else {
      return [expr1, expr2];
    }
  };

  rollback = function(changes) {
    var change, _i, _len, _results;
    _results = [];
    for (_i = 0, _len = changes.length; _i < _len; _i++) {
      change = changes[_i];
      _results.push(change());
    }
    return _results;
  };

  extern("parse", parse);

  extern("unify", unify);

  extern("Var", Var);

  internal("Tin", Tin);

  internal("Box", Box);

  internal("DictFlag", DictFlag);

  internal("toJson", toJson);

  internal("Variable", Variable);

  extern("rollback", rollback);

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

  falafel = (typeof window !== "undefined" && window !== null) && (window.falafel != null) ? window.falafel : require('falafel.js');

  compile = function(src, settings) {
    var breathFirstFn, depthFirstFn, inCallExpr, name, ret, value;
    if (settings == null) {
      settings = {};
    }
    inCallExpr = function(node) {
      if (!(node != null)) {
        return false;
      }
      if (!(node.inCallExpr != null)) {
        node.inCallExpr = node.type === "CallExpression" ? true : inCallExpr(node.parent);
      }
      return node.inCallExpr;
    };
    ret = [];
    depthFirstFn = function(node) {
      var n, ops, s;
      if (node.ignore) {
        return;
      }
      s = [];
      if (node.type === "ExpressionStatement") {
        s.push("p.rule(" + (node.expression.source()) + ");");
      }
      if (node.type === "CallExpression") {
        s.push("{" + node.callee.name + ":[");
        s.push(((function() {
          var _i, _len, _ref, _results;
          _ref = node["arguments"];
          _results = [];
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            n = _ref[_i];
            _results.push(n.source());
          }
          return _results;
        })()).join(','));
        s.push("]}");
      }
      if (node.type === "Identifier") {
        s.push("Var(\"" + node.name + "\")");
      }
      if (node.type === "LogicalExpression" || node.type === "BinaryExpression") {
        if (inCallExpr(node)) {
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
            s.push("{" + ops[node.operator] + ":[" + (node.left.source()) + ", " + (node.right.source()) + "]}");
          }
        } else {
          s.push(node.left.source() + "," + node.right.source());
        }
      }
      if (s.length > 0) {
        node.update(s.join(""));
      }
    };
    breathFirstFn = function(node) {
      if (node.type === "FunctionExpression") {
        return node.ignore = true;
      } else if (node.type === "ExpressionStatement" && node.parent.type === "Program" && node.expression.type === "CallExpression" && node.expression.callee.type !== "FunctionExpression") {
        return node.ignore = false;
      } else if (node.type === "ExpressionStatement" && node.parent.type === "Program" && (node.expression.type === "LogicalExpression" || node.expression.type === "BinaryExpression")) {
        return node.ignore = false;
      } else if ((node.parent != null) && (node.parent.ignore != null)) {
        return node.ignore = node.parent.ignore;
      } else {
        return node.ignore = true;
      }
    };
    if (!(settings.isExpression != null) || !settings.isExpression) {
      ret.push("//This program was complied using JSUnify compiler v0.8.0");
      ret.push("(function(){");
      ret.push("var JSUnify;");
      ret.push("if (typeof window != 'undefined' && typeof window.JSUnify != 'undefined' ) { JSUnify = window.JSUnify; }");
      ret.push("else { JSUnify = require('JSUnifyCompiler'); }");
      ret.push("var p = new JSUnify.Program();");
      ret.push("var prog = p;");
      ret.push("var settings = p.settings;");
      ret.push("var Var = JSUnify.Var;");
    }
    ret.push(falafel(src, {}, depthFirstFn, breathFirstFn).toString());
    if (!(settings.isExpression != null) || !settings.isExpression) {
      for (name in settings) {
        value = settings[name];
        ret.push("settings[\"" + name + "\"] = " + value + ";");
      }
      ret.push("if (typeof module !== \"undefined\" && typeof require !== \"undefined\") {  module.exports = p; }");
      ret.push("else { window[settings.name] = p; }");
      ret.push("})();");
    }
    return ret.join('\n');
  };

  extern("compile", compile);

}).call(this);
