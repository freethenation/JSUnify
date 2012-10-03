isDef=(obj)-> exports == 'undefined'
extern=(name, o)->if typeof exports == 'undefined' then window.JSUnify[name] = o else exports[name] = o
internal=(name, o)->if typeof exports == 'undefined' then window.JSUnify.internal[name] = o else exports.internal[name] = o
esprima = if isDef require then require('esprima') else window.esprima

parse=(JSUnifySource)->
    

compile=(JSUnifySource)->
    
extern 'parse', parse
extern 'compile', compile