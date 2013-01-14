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
    run: (query) ->
        query = unify.box(query)
        callback = (eventName, parms, resumeCallback)->
            console.log eventName + ": " + parms.goal.toString()
            if eventName == "success" then console.log query.unbox()
            if resumeCallback != null then resumeCallback()
        backtrack(@rules, [new Frame([query])], callback)
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
    
class Frame
    constructor: (@subgoals)->
        @goal = @subgoals.shift()
        @currentRule = 0

backtrack = (rules, frameStack, callback)->
    frame = frameStack[frameStack.length-1]
    goal = frame.goal
    success = false
    satisfyingRule = null
    if frame.currentRule == 0 then callback("try", {"goal":goal}, null) 
    else 
        callback("retry", {"goal":goal}, null)
        goal.rollback()
    # attempt to satisfy goal
    if goal instanceof FunctionCondition
        if frame.currentRule == 0 and goal.func(goal)
            success = true
            frame.currentRule++ # if we ever come back to here we need to fail cause a function can not branch
    else
        while frame.currentRule < rules.length
            if goal.unify(rules[frame.currentRule].tin) 
                success = true
                satisfyingRule = rules[frame.currentRule]
                frame.currentRule++ # increment rule so that if search is continued we do not check same rule
                break
            frame.currentRule++
    # if fail to satisfy goal then pop current frame
    if !success
        frameStack.pop()
        if frameStack.length == 0
            callback("fail", {"goal":goal}, null)
            callback("done", {"goal":goal}, null)
        else callback("fail", {"goal":goal}, ()->backtrack(rules, frameStack, callback))
    # if goal satisfied and satisfying rule has conditions then make new frame with conditions as new subgoals before existing subgoals
    else if satisfyingRule != null and satisfyingRule.conditions.length != 0
        frameStack.push(new Frame(satisfyingRule.conditions.concat(frame.subgoals)))
        callback("subgoals", {"goal":goal, "subgoals": frame.subgoals}, null)
        callback("next", {"goal":goal}, ()->backtrack(rules, frameStack, callback))
    # if goal is satisfied and there are no additional subgoals then exit
    else if frame.subgoals.length == 0
        callback("success", {"goal":goal}, ()->backtrack(rules, frameStack, callback))        
    # if goal is satisfied and there are additional subgoals then create a new frame and continue
    else
        frameStack.push(new Frame(frame.subgoals))
        callback("next", {"goal":goal}, ()->backtrack(rules, frameStack, callback))    
    return

    
    

extern "Rule", Rule
extern "Program", Program