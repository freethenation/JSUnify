(function() {
  var runtests;

  runtests = function() {
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
