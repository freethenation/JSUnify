runtests=()->
    for prop of JSUnify
        window[prop] = JSUnify[prop]
        
    module "parse"
    test "parse array", ()->
        res = parse([{a: [1,{},3]}])[0].node
        # deepEqual(res, 

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
 