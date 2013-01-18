unify = if typeof module == 'undefined' then window.unify else require('unify')
if typeof module == 'undefined' then window.JSUnify={}
extern=(name, o)->if typeof module == 'undefined' then window.JSUnify[name] = o else module.exports[name] = o

for name of unify
    extern(name, unify[name])

class Program
    constructor: () ->
        @rules=[]
        @settings={debug:false}
    query: (goals...)->
        goals = (unify.box(goal) for goal in goals)
        success = false
        backtrack(@rules, [new Frame(goals.slice(0))],
            if @settings.debug then (parms, resume)->
                {
                    "try":(name)->@fail(name)
                    "retry":(name)->@fail(name)
                    "match":(name)->console.log "#{name}: #{if parms.rule != null then unify.toJson(parms.rule.tin.unbox())}"
                    "fail":(name)->console.log "#{name}: #{unify.toJson(parms.goal.unbox())}"
                    "done":(name)->@fail(name)
                    "success":(name)->@match(name)
                }[parms.name]?(parms.name)
                if parms.name == "success" then success = true 
                else if resume != null then resume()
            else (parms, resume)->
                if parms.name == "success" then success = true 
                else if resume != null then resume()
        )
        if !success then return null
        else if goals.length == 1 then return goals[0]
        else return goals
    queryAsync: (goals, callback)->
        newCallback = callback
        if callback == null
            newCallback=((parms, resume)->if resume != null and parms.name != "success" then resume())
        else if !@settings.debug
            newCallback=(parms, resume)->
                if parms.name == "done" then callback(parms, resume)
                else if resume != null then resume()
        goals = (unify.box(goal) for goal in goals)
        backtrack(@rules, [new Frame(goals.slice(0))], newCallback)
        return goals
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
        @clone = ()->new Rule(fact, conditions...)
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
    unbox: ()->@toString()
    
class Frame
    constructor: (@subgoals)->
        @subgoals = @subgoals.slice(0)
        @goal = @subgoals.shift()
        @ruleIndex = 0
        @satisfyingRule = null

backtrack = (rules, frameStack, callback)->
    frame = frameStack[frameStack.length-1]
    goal = frame.goal
    success = false
    frame.satisfyingRule = null
    if frame.ruleIndex == 0 then callback({"name":"try", "goal":goal}, null) 
    else 
        goal.rollback()
        callback({"name":"retry", "goal":goal}, null)
    # attempt to satisfy goal
    if goal instanceof FunctionCondition
        if frame.ruleIndex == 0 and goal.func(goal)
            success = true
            frame.ruleIndex++ # if we ever come back to here we need to fail cause a function can not branch
    else
        while frame.ruleIndex < rules.length
            if goal.unify(rules[frame.ruleIndex].tin) 
                success = true
                frame.satisfyingRule = rules[frame.ruleIndex]
                rules[frame.ruleIndex] = frame.satisfyingRule.clone()
                frame.ruleIndex++ # increment rule so that if search is continued we do not check same rule
                break
            frame.ruleIndex++
    # if fail to satisfy goal then pop current frame
    if !success
        frameStack.pop()
        if frameStack.length == 0
            callback({"name":"done", "goal":goal}, null)
        else callback({"name":"fail", "goal":goal}, ()->backtrack(rules, frameStack, callback))
    # if goal satisfied and satisfying rule has conditions then make new frame with conditions as new subgoals before existing subgoals
    else if frame.satisfyingRule != null and frame.satisfyingRule.conditions.length != 0
        frameStack.push(new Frame(frame.satisfyingRule.conditions.concat(frame.subgoals)))
        callback({"name":"match", "goal":goal, "subgoals": frame.subgoals, "rule":frame.satisfyingRule}, ()->backtrack(rules, frameStack, callback))
    # if goal is satisfied and there are no additional subgoals then exit
    else if frame.subgoals.length == 0
        callback({"name":"success", "goal":goal, "rule":frame.satisfyingRule}, ()->backtrack(rules, frameStack, callback))        
    # if goal is satisfied and there are additional subgoals then create a new frame and continue
    else
        frameStack.push(new Frame(frame.subgoals))
        callback({"name":"match", "goal":goal, "subgoals": null, "rule":frame.satisfyingRule}, ()->backtrack(rules, frameStack, callback))    
    return

extern "Rule", Rule
extern "Program", Program