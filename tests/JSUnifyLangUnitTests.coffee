runtests=()->
    for prop of JSUnify
        window[prop] = JSUnify[prop]
    for prop of JSUnify.internal
        window[prop] = JSUnify.internal[prop]
    for prop of JSUnifyLang
        window[prop] = JSUnifyLang[prop]
    for prop of JSUnifyLang.internal
        window[prop] = JSUnifyLang.internal[prop]

    test "placeholder", ()->
        ok(true)

    module "Backtrack"
    test "Snowy Chicago", () ->
        goal = new Rule({"snowy":Var("P")})
        rules = []
        rules.push(new Rule({"rainy":"Cincinnati"}))
        rules.push(new Rule({"rainy":"Chicago"}))
        rules.push(new Rule({"cold":"Chicago"}))
        rules.push(new Rule({"snowy":Var("X")},{"rainy":Var("X")},{"cold":Var("X")}))
        ok(backtrack( goal, rules ) != null)
        # console.log goal.tin.toString()
        ok(goal.tin.get("P") == "Chicago")
        # console.log(goal.tin.get("P").toString())
   
    test "Family Tree", () ->
        rules = []
        rules.push(new Rule({"male":["james1"]}))
        rules.push(new Rule({"male":["charles2"]}))
        rules.push(new Rule({"male":["charles1"]}))
        rules.push(new Rule({"male":["james2"]}))
        rules.push(new Rule({"male":["george1"]}))

        rules.push(new Rule({"female":["catherine"]}))
        rules.push(new Rule({"female":["elizabeth"]}))
        rules.push(new Rule({"female":["sophia"]}))

        rules.push(new Rule({"parent":["charles1", "james1"]}))
        rules.push(new Rule({"parent":["elizabeth", "james1"]}))
        rules.push(new Rule({"parent":["charles2", "charles1"]}))
        rules.push(new Rule({"parent":["catherine", "charles1"]}))
        rules.push(new Rule({"parent":["james2", "charles1"]}))
        rules.push(new Rule({"parent":["sophia", "elizabeth"]}))
        rules.push(new Rule({"parent":["george1", "sophia"]}))
        rules.push(new Rule({"parent":["george1", "james1"]})) # Lies!

        rules.push(new Rule({"father":[Var("Kid"),Var("Dad")]}, {"male":[Var("Dad")]}, {"parent":[Var("Kid"),Var("Dad")]}))
        rules.push(new Rule({"mother":[Var("Kid"),Var("Mom")]}, {"female":[Var("Mom")]}, {"parent":[Var("Kid"),Var("Mom")]}))

        goal = new Rule({"parent":["charles1","george1"]})
        ok(backtrack( goal, rules) == null)
        
        goal = new Rule({"parent":["elizabeth",Var("X")]})
        ok(backtrack( goal, rules) != null)
        ok(goal.tin.get("X") == "james1")
        
        goal = new Rule({"mother":["george1",Var("Mom")]})
        ok(backtrack( goal, rules) != null)
        ok(goal.tin.get("Mom") == "sophia")

        goal = new Rule({"father":["george1",Var("Dad")]})
        ok(backtrack( goal, rules) != null)
        ok(goal.tin.get("Dad") == "james1")

extern=(name, o)->window[name] = o
extern "RunJSUnifyLangUnitTests", runtests
