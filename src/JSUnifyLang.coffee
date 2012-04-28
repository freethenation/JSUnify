
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
    run: (goal) ->
        goal = new Rule(goal)
        return backtrack(goal, @rules)
    rule: (fact, conditions...)->
        @rules.push(new Rule(fact, conditions...))
        return this
    iff: (conditional)->
        if @rules.length == 0 then throw "iff is invalid in this context. A rule must be created first!"
        rule = @rules[@rules.length - 1]
        rule.iff(conditional)
        return this
    
class Rule
    constructor: (fact, conditions...) ->
        @fact = fact
        @tin = parse(fact)
        @conditions = []
        for c in conditions
            @iff(c)
        
        ###
        conditions = if isarray conditions then (parse(c) for c in conditions) else []
        
        mergedVarlist = {}
        for cond in conditions
            for varKey, varValue of cond.varlist
                mergedVarlist[varKey] = varValue
        for varKey, varValue of @tin.varlist
            mergedVarlist[varKey] = varValue
        for c in conditions
            c.varlist = mergedVarlist
        
        @conditions = conditions
        ###
            
    iff: (conditional) ->
        conditional = parse(conditional) 
        if @conditions.length == 0
            mergedVarlist = {}
            for varKey, varValue of @tin.varlist
                mergedVarlist[varKey] = varValue
        else
            mergedVarlist = @conditions[0].varlist
        for varKey, varValue of conditional.varlist
            if not varKey of mergedVarlist
                mergedVarlist[varKey] = varValue
        conditional.varlist = mergedVarlist
        @conditions.push(conditional)
        return this

backtrack = (goals, rules) ->
    if goals instanceof Rule
        goals = [goals.tin]
    goal = goals.pop()
    for rule in rules
        changes = []
        log("TRY UNIFY: " + toJson(goal) + " AND " + toJson(rule.tin))
        if unify(goal, rule.tin, changes)
            log("UNIFY SUCCESS: " + toJson(goal) + " AND " + toJson(rule.tin))
            rule.conditions.reverse() # RPK: prob should make this a for loop from length-1 to 0
            for cond in rule.conditions
                goals.push(cond)
            rule.conditions.reverse()
            if goals.length == 0
                return goal
            else if backtrack(goals, rules) != null
                return goal
        rollback(changes)
    log("UNIFY FAILURE... BACKTRACKING")
    goals.push(goal)
    return null

extern "backtrack", backtrack
extern "Rule", Rule
extern "Program", Program

# rule {d:[C,X,0]}
# iff (vars)->typeof vars.C == "number"
