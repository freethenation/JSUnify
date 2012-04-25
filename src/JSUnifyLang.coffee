
# utils
log=(o)->console.log o
dir=(o)->console.dir o
len=(o)-> o.length
if typeof exports == 'undefined' then window.JSUnifyLang={}
extern=(name, o)->if typeof exports == 'undefined' then window.JSUnifyLang[name] = o else exports[name] = o
if typeof exports == 'undefined' then window.JSUnifyLang.internal={} else exports.internal = {}
internal=(name, o)->if typeof exports == 'undefined' then window.JSUnifyLang.internal[name] = o else exports.internal[name] = o
str=(o)->
    if typeof o == "undefined"
        return "undefined"
    else if o==null
        return "null"
    else
        return o.toString()

# type testing functions
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
        @tin = parse(fact)
        conditions = if isarray conditions then (parse(c) for c in conditions) else []
        @conditions = conditions
            
    iff: (conditional) ->
        conditions.push(conditional)
    
rule=(fact, conditions...)->
    @rules.push(new Rule(fact, conditions...))
    
iff=(conditional)->
    if @rules.length == 0 then throw "iff is invalid in this context. A rule must be created first!"
    rule = @rules[@rules.length - 1]
    rule.iff(conditional)
    
# EMS This algorithm cannot work -- the internal unify of rule.tin with cond cannot succeed;
# EMS consider the rule ["Snowy", Var("X")] and the condition ["Rainy", Var("X")].
# EMS Those will never unify, yet we need to ensure their X variables are the same.
# EMS Perhaps we need to hack on the unify algo a bit more to allow this sort of thing?
# EMS 
# EMS We cannot just share the tins - ex. Snowy(A,B) -> Rainy(A) && Cold(B)
backtrack = (goal, rules) ->
    for rule in rules
        changes1 = []
        console.log "Head unify: #{ toJson goal.tin } -> #{ toJson rule.tin }"
        if unify(goal.tin, rule.tin, changes1)
            for cond in rule.conditions
                changes2 = []
                console.log "Internal unify: #{ toJson rule.tin } -> #{ toJson cond }"
                if unify(rule.tin, cond, changes2)
                    backtrack(cond, rules)
                else
                    console.log "Rolling back last internal unify"
                    rollback(changes2)
        else
            console.log "Rolling back last head unify"
            rollback(changes1)


extern "backtrack", backtrack
extern "Rule", Rule

# rule {d:[C,X,0]}
# iff (vars)->typeof vars.C == "number"
