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

class Tin
    constructor: (name, node, varlist...) ->
        @node = if node? then node else null
        @varlist = if (isarray varlist) then varlist else null
        @chainlength = 1
        @name = name
    isfree:()->!@node?

boxit = (elem,tinlist) ->
    if elem instanceof Var
        tinlist?.push(new Tin( elem.name, null, null ))
        return elem
    else if elem instanceof Box
        return elem
    else if isarray elem
        return (boxit(item) for item in elem)
    else if isobj elem
        a = []
        for key of elem
            a.push( [boxit(key), boxit(elem[key])] )
        a.push(WAS_DICT)
        return a.sort()
    else if isvaluetype elem
        return new Box elem
    else
        throw "Don't understand the type of elem"

# create the relevant tins
init = (elems...) ->
    out = []
    for elem in elems
        tinlist = []
        tree = boxit(elem,tinlist)
        headtin = new Tin( null, tree, tinlist... )
        out.push(headtin)
    return out

log boxit( {a:[1,2,3]},[] )
log b2s(boxit( {a:[1,2,3]},[] ))

log (init( {a: [1,2,3]}, {a: [1,new Var("b"),3]} ))

