
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
isfunc=(o)->!!(o && o.constructor && o.call && o.apply);

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
    load: (rules)->
        for rule in rules
            @rules.push(rule)
        return this
    
class Rule
    constructor: (fact, conditions...) ->
        @fact = fact
        @tin = parse(fact)
        @conditions = []
        for c in conditions
            @iff(c)
            
    iff: (condition) ->
        if isfunc condition
            condition = new Functioncondition(condition)
        else
            condition = parse(condition) 
        if @conditions.length == 0
            mergedVarlist = {}
            for varKey, varValue of @tin.varlist
                mergedVarlist[varKey] = varValue
        else
            mergedVarlist = @conditions[0].varlist
        for varKey, varValue of condition.varlist
            if not varKey of mergedVarlist
                mergedVarlist[varKey] = varValue
        condition.varlist = mergedVarlist
        @conditions.push(condition)
        return this

class Functioncondition
    constructor: (func)->
        @func = func
        @varlist = {}

backtrack = (goals, rules) ->
    if goals instanceof Rule
        goals = [goals.tin]
    goal = goals.pop()
    for rule in rules
        changes = []
        # log("TRY UNIFY: " + toJson(goal) + " AND " + toJson(rule.tin))
        if unify(goal, rule.tin, changes)
            # log("UNIFY SUCCESS: " + toJson(goal) + " AND " + toJson(rule.tin))
            rule.conditions.reverse() # RPK: prob should make this a for loop from length-1 to 0
            for cond in rule.conditions
                goals.push(cond)
            rule.conditions.reverse()
            if goals.length == 0
                return goal
            else if backtrack(goals, rules) != null
                return goal
        rollback(changes)
    # log("UNIFY FAILURE... BACKTRACKING")
    goals.push(goal)
    return null

extern "Rule", Rule
extern "Program", Program
extern "isfunc", isfunc
