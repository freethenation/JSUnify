
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

backtrack = (goals, rules) ->
    if goals instanceof Rule
        goals = [goals.tin]
    goal = goals.pop()
    for rule in rules
        changes = []
        log("TRY UNIFY: " + toJson(goal) + " AND " + toJson(rule.tin))
        if unify(goal, rule.tin, changes)
            log("UNIFY SUCCESS")
            rule.conditions.reverse()
            for cond in rule.conditions
                goals.push(cond)
            rule.conditions.reverse()
            if goals.length == 0
                return true
            else if backtrack(goals, rules)
                return true
        rollback(changes)
    log("UNIFY FAILURE... BACKTRACKING")
    goals.push(goal)
    return false

extern "backtrack", backtrack
extern "Rule", Rule

# rule {d:[C,X,0]}
# iff (vars)->typeof vars.C == "number"