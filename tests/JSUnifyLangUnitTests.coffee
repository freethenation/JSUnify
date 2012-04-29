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
        ok(new Program()
            .rule({snowy:Var("X")},
                {cold:Var("X")},
                {rainy:Var("X")})
            .rule({rainy:"cinci"})
            .rule({rainy:"chicago"})
            .rule({cold:"chicago"})
            .run({snowy:Var("P")}).get("P") == "chicago")
            
    test "Is Int",()->
        prog = new Program()
            .rule({number:4.4})
            .rule({number:9})
            .rule({int:Var("X")}, 
                {number:Var("X")},
                (tin)->
                    X = tin.get("X")
                    return parseInt(X) == X)
        ok(prog.run({int:Var("Y")}).get("Y") == 9)
   
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
        
        prog = new Program().load(rules)
        
        res = prog.run({"parent":["charles1","george1"]})
        ok(res == null)
        
        res = prog.run({"parent":["elizabeth",Var("X")]})
        ok(res != null)
        ok(res.get("X") == "james1")
        
        res = prog.run({"mother":["george1",Var("Mom")]})
        ok(res != null)
        ok(res.get("Mom") == "sophia")
        
        res = prog.run({"father":["george1",Var("Dad")]})
        ok(res != null)
        ok(res.get("Dad") == "james1")

extern=(name, o)->window[name] = o
extern "RunJSUnifyLangUnitTests", runtests
