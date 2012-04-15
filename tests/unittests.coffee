parsetest=(obj) -> deepEqual(parse([obj])[0].unparse(),obj, "parse")
unifytest=(objs) -> ok(unify(objs), "unify")
unifyfailtest=(obj1, obj2) -> ok(!unify(obj1,obj2), "unify fail")
gettest=(tin, varValueDict) ->
    for v of varValueDict
        equal(tin.get(v), varValueDict[v], "get(#{ v }) == #{ varValueDict[v] }")
fulltest=(obj1, obj2, varValueDict1, varValueDict2) ->
    parsetest(obj1)
    parsetest(obj2)
    obj1 = parse([obj1])[0]
    obj2 = parse([obj2])[0]
    unifytest([obj1, obj2])
    gettest(obj1, varValueDict1)
    gettest(obj2, varValueDict2)


runtests=()->
    for prop of JSUnify
        window[prop] = JSUnify[prop]
        
    module "full tests"
    test "empty obj {} -> {}", ()->
        fulltest({}, {}, {}, {})
    test "variable equal [X] -> [1]", ()->
        fulltest([new Var("a")], [1], {a:1}, {})
    test "variable equal [X,X] -> [1,1]", ()->
        fulltest([new Var("a"), new Var("a")], [1,1], {a:1}, {})
    
    module "unify fail tests"
    test "variable equal [X,X] -> [1,2]", ()->
        unifyfailtest([[new Var("a"), new Var("a")], [1,2]])
    test "variable unequal [1,3,2] -> [Y,Y,2]", () ->
        unifyfailtest([ [1, 3, 2], [new Var("y"), new Var("y"), 2] ])
        
    module "misc"
    test "simple parse Tin.node test", ()->
        res = parse([{a: [1,{},"r"]}])[0].node
        deepEqual(res, [[new Box("a"),[new Box(1),[new DictFlag()],new Box("r")]],new DictFlag()])
    test "simple black box unify test", () ->
        ok(unify([{a: [1,2,3]}, {a: [1,new Var("b"),3]}]))
    
    module "unify"
    test "variable equal [X,2,X] -> [1,2,1]", () ->
        tins = unify([[new Var("x"), 2, new Var("x")], [1,2,1]])
        ok(tins)
        deepEqual(tins[0].get_all(), {"x":1})
    test "simple three part unify [X,2,3] -> [1,Y,3] -> [1,2,Z]", () ->
        tins = unify([
            [new Var("X"),2,3],
            [1,new Var("Y"),3],
            [1,2,new Var("Z")]
        ])
        gettest(tins[0], {X:1})
        gettest(tins[1], {Y:2})
        gettest(tins[2], {Z:3})
    test "three part unify [X,1,2] -> [Y,1,2] -> [1,1,X]", () ->
        tins = unify([
            [new Var("x"),1,2],
            [new Var("y"),1,2],
            [1,1,new Var("x")]
        ])
        gettest(tins[0], {x:1})
        gettest(tins[1], {y:1})
        gettest(tins[2], {x:2})
        
    module "extract"
    test "simple variable extraction test", () ->
        tins = unify([{a: [1,2,3]}, {a: [1,new Var("b"),3]}])
        ok(tins[1].get("b") == 2)
    test "extract all variables test", () ->
        tins = unify([{a: [1,2,3]}, {a: [1,new Var("b"),3]}])
        deepEqual(tins[1].get_all(), {"b":2})


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
