parsetest=(obj) -> deepEqual(parse(obj).unparse(),obj, "parse")
unifytest=(obj1, obj2) -> ok(unify(obj1, obj2), "unify")
unifyfailtest=(obj1, obj2) -> ok(!unify(obj1,obj2), "unify fail")
gettest=(tin, varValueDict) ->
    for v of varValueDict
        if varValueDict[v] instanceof Var
            ok(tin.get(v) instanceof Var, "get(#{ v }) = Var()")
        else
            deepEqual(tin.get(v), varValueDict[v], "get(#{ v }) == #{ toJson varValueDict[v] }")
fulltest=(obj1, obj2, varValueDict1, varValueDict2) ->
    parsetest(obj1)
    parsetest(obj2)
    obj1 = parse(obj1)
    obj2 = parse(obj2)
    unifytest(obj1, obj2)
    gettest(obj1, varValueDict1)
    gettest(obj2, varValueDict2)


runtests=()->
    for prop of JSUnify
        window[prop] = JSUnify[prop]
    for prop of JSUnify.internal
        window[prop] = JSUnify.internal[prop]
        
    module "full tests"
    test "empty obj {} -> {}", ()->
        fulltest({}, {}, {}, {})
    test "null test [null] -> [null]", ()->
        fulltest([null], [null], {}, {})
    test "variable equal [X] -> [1]", ()->
        fulltest([Var("a")], [1], {a:1}, {})
    test "variable equal [X,X] -> [1,1]", ()->
        fulltest([Var("a"), Var("a")], [1,1], {a:1}, {})
    test "variable equal [[1,2,3]] -> [y]", ()->
        fulltest([[1,2,3]], [Var("y")], {}, {y:[1,2,3]})
    test "variable equal [[1,2,x],x] -> [y,3]", ()->
        fulltest(
            [[1,2,Var("x")],Var("x")], 
            [Var("y"),3], 
            {x:3}, {y:[1,2,3]})
    test "unbound variable [y]->[x]", ()->
        fulltest([Var("y")], [Var("x")], {y:Var("y")}, {x:Var("x")})
    test "variable equal [1,X,X] -> [Z,Z,1]", () ->
        fulltest([1, Var("X"), Var("X")], [Var("Z"), Var("Z"), 1], {X:1}, {Z:1})
            
    module "unify fail tests"
    test "variable equal [X,X] -> [1,2]", ()->
        unifyfailtest([Var("a"), Var("a")], [1,2])
    test "variable unequal [1,3,2] -> [Y,Y,2]", () ->
        unifyfailtest([1, 3, 2], [Var("y"), Var("y"), 2])
    test "variable unequal [1,X,X] -> [Z,Z,3]", () ->
        unifyfailtest([1, Var("X"), Var("X")], [Var("Z"), Var("Z"), 3])
        
        
    module "misc"
    test "simple black box unify test", () ->
        ok(unify({a: [1,2,3]}, {a: [1,Var("b"),3]}))
    
    module "unify"
    test "variable equal [X,2,X] -> [1,2,1]", () ->
        tins = unify([Var("x"), 2, Var("x")], [1,2,1])
        ok(tins)
        deepEqual(tins[0].get_all(), {"x":1})
        
    module "extract"
    test "simple variable extraction test", () ->
        tins = unify({a: [1,2,3]}, {a: [1,Var("b"),3]})
        ok(tins[1].get("b") == 2)
    test "extract all variables test", () ->
        tins = unify({a: [1,2,3]}, {a: [1,Var("b"),3]})
        deepEqual(tins[1].get_all(), {"b":2})

    module "hidden variables"
    test "create hidden variable", () ->
        ok((Var("_")).isHiddenVar())
    test "simple hidden variable [_,X] -> [1,2]", () ->
        fulltest([Var("_"),Var("x")],[1,2],{"x":2},{})
    test "multiple hidden variables [_,_,X] -> [1,2,3]", () ->
        fulltest([Var("_"),Var("_"),Var("x")],[1,2,3],{"x":3},{})
    test "[[1,_,3],[1,2,3]] -> [X,X]", () ->
        fulltest([[1,Var("_"),3],[1,2,3]],[Var("x"),Var("x")],{},{"x":[1,2,3]})

# utils
log=(o)->console.log o
dir=(o)->console.dir o
len=(o)-> o.length
str=(o)->
    if typeof o == "undefined"
        "undefined"
    else if o==null
        "null"
    else
        o.toString()
extern=(name, o)->window[name] = o
extern "runtests", runtests
extern "str", str
extern "len", len
extern "log", log
extern "dir", dir
