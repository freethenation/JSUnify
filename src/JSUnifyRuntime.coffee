unify = if typeof module == 'undefined' then window.unify else require('unify')
if typeof module == 'undefined' then window.JSUnify={}
extern=(name, o)->if typeof module == 'undefined' then window.JSUnify[name] = o else module.exports[name] = o

for name of unify
    extern(name, unify[name])
    
class Debugger
    constructor:(logger)->
        @level=0
        @logger=logger
    event:(name, goal)->
        if name == "fail" || name == "exit" then @level--
        @logger.log("#{@level} #{name}: #{goal}")
        if name == "call" then @level++

class Program
    constructor: () ->
        @rules=[]
        @settings={debug:false}
    run: (goal) ->
        goal = new Rule(goal)
        return backtrack(goal, @rules, if @settings.debug then (new Debugger(console)) else {event:()->})
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
    toString: ()->@func.toString().replace(/(\r\n|\n|\r)/gm,"")  
    
backtrack = (goals, rules, debug) ->
    if goals instanceof Rule
        goals = [goals.tin]
    goal = goals.pop()
    debug.event("call", goal)
    for rule in rules
        if goal instanceof FunctionCondition
            ret = tryFunctionCondition(goal, rule, goals, rules, debug)
        else
            ret = tryUnifyCondition(goal, rule, goals, rules, debug)
        if ret != null
            debug.event("exit", goal)
            return ret
    debug.event("fail", goal)
    goals.push(goal)
    return null
    
tryUnifyCondition = (goal, rule, goals, rules, debug)->
    changes = []
    if goal.unify(rule.tin)
        debug.event("call", rule.tin)
        rule.conditions.reverse() # RPK: prob should make this a for loop from length-1 to 0
        for cond in rule.conditions
            goals.push(cond)
        rule.conditions.reverse()
        if goals.length == 0
            return goal
        else if backtrack(goals, rules, debug) != null
            return goal
    debug.event("fail", rule.tin)
    goal.rollback()
    return null

tryFunctionCondition = (goal, rule, goals, rules, debug)->
    if goal.func(goal) then return  goal else null

extern "Rule", Rule
extern "Program", Program