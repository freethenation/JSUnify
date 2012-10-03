(function() {
  var Box, DICT_FLAG, DictFlag, FunctionCondition, HIDDEN_VAR_PREFIX, Program, Rule, Tin, Var, Variable, backtrack, bind, bind_tins, boxit, dir, extern, fulltest, g_hidden_var_counter, get_tin, gettest, internal, isHiddenVar, isarray, isbool, isfunc, isnum, isobj, isstr, isundef, isvaluetype, len, log, parse, parsetest, rollback, runtests, str, toJson, tryFunctionCondition, tryUnifyCondition, unboxit, unify, unifyfailtest, unifytest, _unify,
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
        var child = new ctor, result = func.apply(child, args), t = typeof result;
        return t == "object" || t == "function" ? result || child : child;
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

  parsetest = function(obj) {
    return deepEqual(parse(obj).unparse(), obj, "parse");
  };

  unifytest = function(obj1, obj2) {
    return ok(unify(obj1, obj2), "unify");
  };

  unifyfailtest = function(obj1, obj2) {
    return ok(!unify(obj1, obj2), "unify fail");
  };

  gettest = function(tin, varValueDict) {
    var v, _results;
    _results = [];
    for (v in varValueDict) {
      if (varValueDict[v] instanceof Var) {
        _results.push(ok(tin.get(v) instanceof Var, "get(" + v + ") = Var()"));
      } else {
        _results.push(deepEqual(tin.get(v), varValueDict[v], "get(" + v + ") == " + (toJson(varValueDict[v]))));
      }
    }
    return _results;
  };

  fulltest = function(obj1, obj2, varValueDict1, varValueDict2) {
    parsetest(obj1);
    parsetest(obj2);
    obj1 = parse(obj1);
    obj2 = parse(obj2);
    unifytest(obj1, obj2);
    gettest(obj1, varValueDict1);
    return gettest(obj2, varValueDict2);
  };

  runtests = function() {
    var prop;
    for (prop in JSUnify) {
      window[prop] = JSUnify[prop];
    }
    for (prop in JSUnify.internal) {
      window[prop] = JSUnify.internal[prop];
    }
    module("full tests");
    test("empty obj {} -> {}", function() {
      return fulltest({}, {}, {}, {});
    });
    test("null test [null] -> [null]", function() {
      return fulltest([null], [null], {}, {});
    });
    test("variable equal [X] -> [1]", function() {
      return fulltest([Var("a")], [1], {
        a: 1
      }, {});
    });
    test("variable equal [X,X] -> [1,1]", function() {
      return fulltest([Var("a"), Var("a")], [1, 1], {
        a: 1
      }, {});
    });
    test("variable equal [[1,2,3]] -> [y]", function() {
      return fulltest([[1, 2, 3]], [Var("y")], {}, {
        y: [1, 2, 3]
      });
    });
    test("variable equal [[1,2,x],x] -> [y,3]", function() {
      return fulltest([[1, 2, Var("x")], Var("x")], [Var("y"), 3], {
        x: 3
      }, {
        y: [1, 2, 3]
      });
    });
    test("unbound variable [y]->[x]", function() {
      return fulltest([Var("y")], [Var("x")], {
        y: Var("x")
      }, {
        x: Var("x")
      });
    });
    test("variable equal [1,X,X] -> [Z,Z,1]", function() {
      return fulltest([1, Var("X"), Var("X")], [Var("Z"), Var("Z"), 1], {
        X: 1
      }, {
        Z: 1
      });
    });
    module("unify fail tests");
    test("variable equal [X,X] -> [1,2]", function() {
      return unifyfailtest([Var("a"), Var("a")], [1, 2]);
    });
    test("variable unequal [1,3,2] -> [Y,Y,2]", function() {
      return unifyfailtest([1, 3, 2], [Var("y"), Var("y"), 2]);
    });
    test("variable unequal [1,X,X] -> [Z,Z,3]", function() {
      return unifyfailtest([1, Var("X"), Var("X")], [Var("Z"), Var("Z"), 3]);
    });
    module("misc");
    test("simple black box unify test", function() {
      return ok(unify({
        a: [1, 2, 3]
      }, {
        a: [1, Var("b"), 3]
      }));
    });
    module("unify");
    test("variable equal [X,2,X] -> [1,2,1]", function() {
      var tins;
      tins = unify([Var("x"), 2, Var("x")], [1, 2, 1]);
      ok(tins);
      return deepEqual(tins[0].get_all(), {
        "x": 1
      });
    });
    module("extract");
    test("simple variable extraction test", function() {
      var tins;
      tins = unify({
        a: [1, 2, 3]
      }, {
        a: [1, Var("b"), 3]
      });
      return ok(tins[1].get("b") === 2);
    });
    test("extract all variables test", function() {
      var tins;
      tins = unify({
        a: [1, 2, 3]
      }, {
        a: [1, Var("b"), 3]
      });
      return deepEqual(tins[1].get_all(), {
        "b": 2
      });
    });
    module("hidden variables");
    test("create hidden variable", function() {
      return ok((Var("_")).isHiddenVar());
    });
    test("simple hidden variable [_,X] -> [1,2]", function() {
      return fulltest([Var("_"), Var("x")], [1, 2], {
        "x": 2
      }, {});
    });
    test("multiple hidden variables [_,_,X] -> [1,2,3]", function() {
      return fulltest([Var("_"), Var("_"), Var("x")], [1, 2, 3], {
        "x": 3
      }, {});
    });
    test("[[1,_,3],[1,2,3]] -> [X,X]", function() {
      return fulltest([[1, Var("_"), 3], [1, 2, 3]], [Var("x"), Var("x")], {}, {
        "x": [1, 2, 3]
      });
    });
    module("rollback");
    return test("rollback successful unification", function() {
      var changes, cobj1, cobj2, obj1, obj2;
      obj1 = [1, 2, 3];
      obj2 = [Var("A"), Var("B"), 3];
      parsetest(obj1);
      parsetest(obj2);
      obj1 = parse(obj1);
      obj2 = parse(obj2);
      cobj1 = eval(obj1.toString());
      cobj2 = eval(obj2.toString());
      changes = [];
      ok(unify(obj1, obj2, changes), "unify");
      rollback(changes);
      ok(obj1.toString() === cobj1.toString());
      return ok(obj2.toString() === cobj2.toString());
    });
  };

  extern("RunJSUnifyUnitTests", runtests);

  runtests = function() {
    var prop;
    for (prop in JSUnify) {
      window[prop] = JSUnify[prop];
    }
    for (prop in JSUnify.internal) {
      window[prop] = JSUnify.internal[prop];
    }
    for (prop in JSUnifyLang) {
      window[prop] = JSUnifyLang[prop];
    }
    for (prop in JSUnifyLang.internal) {
      window[prop] = JSUnifyLang.internal[prop];
    }
    test("placeholder", function() {
      return ok(true);
    });
    module("Backtrack");
    test("Snowy Chicago", function() {
      return ok(new Program().rule({
        snowy: Var("X")
      }, {
        cold: [Var("X"), Var("Y")]
      }, {
        rainy: [Var("X"), Var("Y")]
      }).rule({
        rainy: ["cinci", 1]
      }).rule({
        rainy: ["chicago", 1]
      }).rule({
        cold: ["chicago", 1]
      }).run({
        snowy: Var("P")
      }).get("P") === "chicago");
    });
    test("Is Int", function() {
      var prog;
      prog = new Program().rule({
        number: 4.4
      }).rule({
        number: 9
      }).rule({
        int: Var("X")
      }, {
        number: Var("X")
      }, function(tin) {
        var X;
        X = tin.get("X");
        return parseInt(X) === X;
      });
      return ok(prog.run({
        int: Var("Y")
      }).get("Y") === 9);
    });
    test("N1 Is N-1", function() {
      var prog;
      prog = new Program().rule({
        number: 12
      }).rule({
        minus: Var("N1")
      }, {
        number: Var("N")
      }, function(tin) {
        var N;
        N = tin.get("N");
        return tin.bind("N1", N - 1);
      });
      return ok(prog.run({
        minus: Var("Q")
      }).get("Q") === 11);
    });
    test("Illegal rebind", function() {
      var prog;
      prog = new Program().rule({
        number: 12
      }).rule({
        minus: Var("N1")
      }, {
        number: Var("N")
      }, function(tin) {
        var N;
        N = tin.get("N");
        return tin.bind("N", N + 1);
      });
      return ok(prog.run({
        minus: Var("Q")
      }) === null);
    });
    test("Legal rebind - values equal", function() {
      var prog;
      prog = new Program().rule({
        number: 12
      }).rule({
        minus: Var("N")
      }, {
        number: Var("N")
      }, function(tin) {
        var N;
        N = tin.get("N");
        return tin.bind("N", N);
      });
      return ok(prog.run({
        minus: Var("Q")
      }).get("Q") === 12);
    });
    test("Deriv 4 * x + 7 * x", function() {
      var C, DU, DV, N, N1, U, V, X, prog;
      C = Var("C");
      X = Var("X");
      U = Var("U");
      DU = Var("DU");
      V = Var("V");
      DV = Var("DV");
      N = Var("N");
      N1 = Var("N1");
      prog = new Program().rule({
        'deriv': [C, X, 0]
      }, function(tin) {
        return isnum(tin.get("C"));
      }).rule({
        'deriv': [X, X, 1]
      }).rule({
        'deriv': [
          {
            'mult': [C, U]
          }, X, {
            'mult': [C, DU]
          }
        ]
      }, function(tin) {
        return isnum(tin.get("C"));
      }, {
        'deriv': [U, X, DU]
      }).rule({
        'deriv': [
          {
            'mult': [U, V]
          }, X, {
            'add': [
              {
                'mult': [U, DV]
              }, {
                'mult': [V, DU]
              }
            ]
          }
        ]
      }, {
        'deriv': [U, X, DU]
      }, {
        'deriv': [V, X, DV]
      }).rule({
        'deriv': [
          {
            'add': [U, V]
          }, X, {
            'add': [DU, DV]
          }
        ]
      }, {
        'deriv': [U, X, DU]
      }, {
        'deriv': [V, X, DV]
      }).rule({
        'deriv': [
          {
            'sub': [U, V]
          }, X, {
            'sub': [DU, DV]
          }
        ]
      }, {
        'deriv': [U, X, DU]
      }, {
        'deriv': [V, X, DV]
      });
      console.log(prog.run({
        'deriv': [
          {
            'add': [
              {
                'mult': [7, "x"]
              }, {
                'mult': [4, 'x']
              }
            ]
          }, 'x', Var("DR")
        ]
      }));
      return ok(true);
    });
    return test("Family Tree", function() {
      var prog, res, rules;
      rules = [];
      rules.push(new Rule({
        "male": ["james1"]
      }));
      rules.push(new Rule({
        "male": ["charles2"]
      }));
      rules.push(new Rule({
        "male": ["charles1"]
      }));
      rules.push(new Rule({
        "male": ["james2"]
      }));
      rules.push(new Rule({
        "male": ["george1"]
      }));
      rules.push(new Rule({
        "female": ["catherine"]
      }));
      rules.push(new Rule({
        "female": ["elizabeth"]
      }));
      rules.push(new Rule({
        "female": ["sophia"]
      }));
      rules.push(new Rule({
        "parent": ["charles1", "james1"]
      }));
      rules.push(new Rule({
        "parent": ["elizabeth", "james1"]
      }));
      rules.push(new Rule({
        "parent": ["charles2", "charles1"]
      }));
      rules.push(new Rule({
        "parent": ["catherine", "charles1"]
      }));
      rules.push(new Rule({
        "parent": ["james2", "charles1"]
      }));
      rules.push(new Rule({
        "parent": ["sophia", "elizabeth"]
      }));
      rules.push(new Rule({
        "parent": ["george1", "sophia"]
      }));
      rules.push(new Rule({
        "parent": ["george1", "james1"]
      }));
      rules.push(new Rule({
        "father": [Var("Kid"), Var("Dad")]
      }, {
        "male": [Var("Dad")]
      }, {
        "parent": [Var("Kid"), Var("Dad")]
      }));
      rules.push(new Rule({
        "mother": [Var("Kid"), Var("Mom")]
      }, {
        "female": [Var("Mom")]
      }, {
        "parent": [Var("Kid"), Var("Mom")]
      }));
      prog = new Program().load(rules);
      res = prog.run({
        "parent": ["charles1", "george1"]
      });
      ok(res === null);
      res = prog.run({
        "parent": ["elizabeth", Var("X")]
      });
      ok(res !== null);
      ok(res.get("X") === "james1");
      res = prog.run({
        "mother": ["george1", Var("Mom")]
      });
      ok(res !== null);
      ok(res.get("Mom") === "sophia");
      res = prog.run({
        "father": ["george1", Var("Dad")]
      });
      ok(res !== null);
      return ok(res.get("Dad") === "james1");
    });
  };

  extern("RunJSUnifyLangUnitTests", runtests);

}).call(this);
