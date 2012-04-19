isundef=(o) -> typeof o == "undefined"
isbool=(o) -> typeof o == "boolean"
isarray=(o) -> o? && Array.isArray o
isstr=(o) -> typeof o == "string"
isnum=(o) -> typeof o == "number"
isobj=(o) -> o!=null and not isarray(o) and typeof o == "object"
isvaluetype=(o) -> isbool(o) or isstr(o) or isnum(o)

class Program
    constructor: () ->
        @rules=[]
    load: (func) ->
        func.call(this)
    
class Rule
    constructor: (fact, conditions...) ->
        @fact = fact
        conditions = if isarray conditions then conditions else []
        @conditions = conditions
            
    iff: (conditional) ->
        conditions.push(conditional)
    
rule=(fact, conditions...)->
    @rules.push(new Rule(fact, conditions...))
    
iff=(conditional)->
    if @rules.length == 0 then throw "iff is invalid in this context. A rule must be created first!"
    rule = @rules[@rules.length - 1]
    rule.iff(conditional)
    
    
# rule {d:[C,X,0]}
# iff (vars)->typeof vars.C == "number"