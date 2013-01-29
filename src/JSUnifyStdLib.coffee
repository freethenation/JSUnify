prog = $jsunify(()->
    # Type Testing
    variable(X) == (t)->t.get("X",1) instanceof JSUnify.Variable
    integer(X) == (t)->JSUnify.types.isInt(t.get("X",1))
    number(X) == (t)->JSUnify.types.isNum(t.get("X",1))
    list(X) == (t)->JSUnify.types.isArray(t.get("X",1))
    nonvar(X) == (t)->!(t.get("X",1) instanceof JSUnify.Variable)
    raise(msg) == (t)->throw t.get("msg",1)
)

if typeof module == 'undefined' then 
    JSUnify = window.JSUnify
else 
    JSUnify = require('unify')
    module.exports = prog
JSUnify.libs.std = prog