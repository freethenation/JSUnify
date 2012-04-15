runtests=()->
    for prop of JSUnify
        window[prop] = JSUnify[prop]
        
    module "parse"
    test "simple parse Tin.node test", ()->
        res = parse([{a: [1,{},"r"]}])[0].node
        deepEqual(res, [[new Box("a"),[new Box(1),[new DictFlag()],new Box("r")]],new DictFlag()])
        
    module "unify"
    test "simple black box unify test", () ->
        ok(unify([{a: [1,2,3]}, {a: [1,new Var("b"),3]}]))

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
