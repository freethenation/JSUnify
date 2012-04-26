
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
        
        mergedVarlist = {}
        for cond in conditions
            for varKey, varValue of cond.varlist
                mergedVarlist[varKey] = varValue
        for c in conditions
            c.varlist = mergedVarlist
        
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
    if goal instanceof Rule
        goal = goal.tin
    else if not goal instanceof Tin
        goal = parse(goal)
    for rule in rules
        flag = true
        changes1 = []
        console.log "Head unify: #{ toJson goal.unparse() } -> #{ toJson rule.tin.unparse() }"
        if unify(goal, rule.tin, changes1)
            console.log "rule conditions - #{ toJson rule.conditions }"
            for cond in rule.conditions
                # start log
                #console.log "starting backtrack(#{ toJson cond.unparse() }, #{ toJson (r.tin.unparse() for r in rules) })"
                console.log "\nstarting new backtrack"
                # end log
                if not backtrack(cond, rules)
                    #console.log "Rolling back last unify for backtrack"
                    #rollback(changes1)
                    #console.log "Tins after rollback: #{ toJson goal } -> #{ toJson rule.tin }"
                    #console.log ""
                    console.log "Backtrack failed"
                    flag = false
                    break

                    #return false
            if not flag
                continue
            console.log "Backtrack succeeded"
            return true
        else
            console.log "Rolling back last head unify"
            rollback(changes1)
            console.log "Tins after rollback: #{ toJson goal } -> #{ toJson rule.tin }"
            console.log ""

    console.log "ending backtrack with rule failure"
    return false

extern "backtrack", backtrack
extern "Rule", Rule

# rule {d:[C,X,0]}
# iff (vars)->typeof vars.C == "number"
