# utils
if typeof exports == 'undefined' then window.JSUnifyLang={}
extern=(name, o)->if typeof exports == 'undefined' then window.JSUnifyLang[name] = o else exports[name] = o
if typeof exports == 'undefined' then window.JSUnifyLang.internal={} else exports.internal = {}
internal=(name, o)->if typeof exports == 'undefined' then window.JSUnifyLang.internal[name] = o else exports.internal[name] = o

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
            condition = new FunctionCondition(condition)
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

class FunctionCondition extends Tin
    constructor: (@func)->
        super(null, null, {})

backtrack = (goals, rules) ->
    if goals instanceof Rule
        goals = [goals.tin]
    goal = goals.pop()
    for rule in rules
        if goal instanceof FunctionCondition
            ret = tryFunctionCondition(goal, rule, goals, rules)
        else
            ret = tryUnifyCondition(goal, rule, goals, rules)
        if ret != null
            return ret
    # log("UNIFY FAILURE... BACKTRACKING")
    goals.push(goal)
    return null
    
tryUnifyCondition = (goal, rule, goals, rules)->
    # log("TRY UNIFY: " + toJson(goal) + " AND " + toJson(rule.tin))
    changes = []
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
    return null
    
tryFunctionCondition = (goal, rule, goals, rules)->
    if goal.func(goal) then return  goal else null

extern "Rule", Rule
extern "Program", Program