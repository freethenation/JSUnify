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
        rules.push(new Rule({"snowy":Var("X")},{"rainy":Var("X")},{"snowy":Var("X")}))
        ok(backtrack( goal, rules ))
        console.log goal.tin
        ok(goal.tin.get("P") == "Chicago")
    
extern=(name, o)->window[name] = o
extern "RunJSUnifyLangUnitTests", runtests
