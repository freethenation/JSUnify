unify = if typeof module == 'undefined' then window.unify else require('unify')
if typeof module == 'undefined' then window.JSUnify={}
extern=(name, o)->if typeof module == 'undefined' then window.JSUnify[name] = o else module.exports[name] = o

for name of unify
    extern(name, unify[name])

class Program
    constructor: () ->
        @rules=[]
        @settings={}
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
        @tin = unify.box(fact)
        @conditions = []
        for c in conditions
            @iff(c)
            
    iff: (condition) ->
        if unify.types.isFunc condition
            condition = new FunctionCondition(condition)
        else
            condition = unify.box(condition) 
        if @conditions.length == 0
            mergedVarlist = {}
            for varKey, varValue of @tin.varlist
                mergedVarlist[varKey] = varValue
        else
            mergedVarlist = @conditions[0].varlist
        for varKey, varValue of condition.varlist
            if mergedVarlist[varKey] == undefined
                mergedVarlist[varKey] = varValue
        condition.varlist = mergedVarlist
        @conditions.push(condition)
        return this

class FunctionCondition extends unify.TreeTin
    constructor: (@func)->
        super(null, null, {})
    toString: ()->"new FunctionCondition(#{ toJson @node }, #{ toJson @varlist})"

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
    if goal.unify(rule.tin)
        # log("UNIFY SUCCESS: " + toJson(goal) + " AND " + toJson(rule.tin))
        rule.conditions.reverse() # RPK: prob should make this a for loop from length-1 to 0
        for cond in rule.conditions
            goals.push(cond)
        rule.conditions.reverse()
        if goals.length == 0
            return goal
        else if backtrack(goals, rules) != null
            return goal
    goal.rollback()
    return null
    
tryFunctionCondition = (goal, rule, goals, rules)->
    if goal.func(goal) then return  goal else null

extern "Rule", Rule
extern "Program", Program