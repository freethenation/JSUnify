# utils
log=(o)->console.log o
str=(o)->o.toString()
String.prototype.format = (args...)->
	@replace(new RegExp("{(\d+)}", "g"), (match, number) -> if typeof args[number] != 'undefined' then args[number] else match )
String.prototype.repeat = (num)->new Array(num + 1).join(this)

# type testing functions
isbool=(o) -> typeof o == "boolean"
isarray=(o) -> o? && Array.isArray o
isstr=(o) -> typeof o == "string"
isnum=(o) -> typeof o == "number"
isobj=(o) -> not isarray(o) and typeof o == "object"
isvaluetype=(o) -> isbool(o) or isstr(o) or isnum(o)
    
b2s = (elem) ->
    if isarray elem
        arrEle = (b2s e for e in elem).join(",")
        return "[#{ arrEle }]"
    else if elem instanceof Box
        return elem.value
    else
        return str(elem)
    
# metadata to indicate this was a dictionary
WAS_DICT = "WAS_DICT"

class Box
    constructor: (v) ->
        if isvaluetype(v)
            @value = v
        else
            throw "Can only box value types"
    toString: () -> "Box(#{ @value })"

class Var
    constructor: (@name) ->
    toString: () -> "Var(#{ @name })"

class Tin
    constructor: (name, node, varlist...) ->
        @node = if node? then node else null
        @varlist = if (isarray varlist) then varlist else null
        @chainlength = 1
        @name = name
    isfree:()->!@node?
    toString: () -> "Tin(#{ @name })"

boxit = (elem,tinlist) ->
    if elem instanceof Var
        tinlist?.push(new Tin( elem.name, null, null ))
        return elem
    else if elem instanceof Box
        return elem
    else if isarray elem
        return (boxit(item,tinlist) for item in elem)
    else if isobj elem
        a = []
        for key of elem
            a.push( [boxit(key,tinlist), boxit(elem[key],tinlist)] )
        a.push(WAS_DICT)
        return a.sort()
    else if isvaluetype elem
        return new Box elem
    else
        throw "Don't understand the type of elem"

# Unbox the result and get back plain JS
unboxit = (tree) ->
    # log "Unboxing tree #{tree}"
    if isarray tree
        if tree[tree.length-1] == WAS_DICT #TODO: Check bounds
            hash = new Object()
            for e in tree[0...tree.length-1]
                hash[unboxit(e[0])] = unboxit(e[1])
            return hash
        else
            return (unboxit(item) for item in tree)
    else if tree instanceof Box
        return tree.value
    else if tree instanceof Var
        return tree
    else
        throw "Unrecognized type '#{typeof(tree)}' in unboxit"

# create the relevant tins
init = (elems...) ->
    out = []
    for elem in elems
        tinlist = []
        tree = boxit(elem,tinlist)
        headtin = new Tin( null, tree, tinlist... )
        out.push(headtin)
    return out

get_tin = (varlist,node) ->
    throw "Node must be a Var to get_tin" if not node instanceof Var
    for v in varlist
        if v.name == node.name
            return v
    throw "Couldn't find node #{node.name} in varlist #{varlist}"

bind = (t1,t2) ->
    log "Binding #{t1} and #{t2}"
    if not t1.isfree and not t2.isfree
        return false
    else if t1.isfree and not t2.isfree
        t1.node = t2.node
        t1.varlist = t2.varlist
    else if not t1.isfree and t2.isfree
        t2.node = t1.node
        t2.varlist = t1.varlist
    else if t1.chainlength > t2.chainlength
        t1.node = t2.node
        t1.varlist = t2.varlist
    else
        t2.node = t1.node
        t2.varlist = t1.varlist
    return true

# unification!
unify = (n1,v1,n2,v2) ->
    log "#{n1} -> #{n2}"
    return 1 if n1 == undefined and n2 == undefined
    return 1 if n1 == null and n2 == null
    return 0 if n1 == null or n2 == null
    if n1 instanceof Var and n2 instanceof Var
        t1 = get_tin(v1, n1)
        t2 = get_tin(v2, n2)
        if not bind(t1,t2)
            return 0 if unify(t1.node, t1.varlist, t2.node, t2.varlist) == 0
    else if n1 instanceof Var
        t1 = get_tin(v1,n1)
        if t1.isfree
            t1.node = n2
            t1.varlist = v2
        else
            return 0 if unify(t1.node,t1.varlist,n2,v2)
    else if n2 instanceof Var
        t2 = get_tin(v2,n2)
        if t2.isfree
            t2.node = n1
            t2.varlist = v1
        else
            return 0 if unify(t2.node,t2.varlist,n1,v1)
    else
        if n1 instanceof Box and n2 instanceof Box and isvaluetype(n1.value) and isvaluetype(n2.value) 
            return if n1.value != n2.value then 0 else 1
        else if isarray(n1) and isarray(n2)
            return 0 if n1.length != n2.length
            for idx in (num for num in [0..n1.length])
                return 0 if unify(n1[idx],v1,n2[idx],v2) == 0
    return 1 

# TODO: Make this work for N expressions
unify_tins = (headtins) ->
    ht1 = headtins[0]
    ht2 = headtins[1]
    return unify(ht1.node,ht1.varlist,ht2.node,ht2.varlist)

# (a bit less) stupid slow implemention to get a variable's binding
# would be more elegant to rewrite the Var case to use get_tin from the start
get_value = (headtins, var_name) ->
    for headtin in headtins
        for vartin in headtin.varlist
            if vartin.name == var_name
                if not vartin.node? or vartin.node == null
                    return null
                else if vartin.node instanceof Box
                    return vartin.node
                else if vartin.node instanceof Var
                    node = vartin.node
                    vlist = vartin.varlist
                    while node instanceof Var
                        t = get_tin(vlist,node)
                        node = t.node
                        vlist = t.varlist
                else if isarray(vartin.node) or isobj(vartin.node)
                    return vartin.node
                else
                    throw "Unknown type in get_value"
 
ht = init( {a: [1,{},3]}, {a: [1,new Var("b"),3]} ) 
console.log unify_tins( ht ) and "unification succeeded!" or "unification failed"
log unboxit( get_value(ht, "b") )
