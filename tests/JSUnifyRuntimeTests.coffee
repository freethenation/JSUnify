#General Util Functions
str=(obj)->
    if obj == null then "null"
    else if typeof obj == "undefined" then "undefined"
    else obj.toString()

#General Testing Code
class Test
    constructor:(@name, @func)->
        @num = 0
    expect:(num)->
        @num = num
    equal:(arg1, arg2, message="''")->
        @num--
        if arg1 != arg2 then throw "NotEqual: '#{str(arg1)}' does not equal '#{str(arg2)}'\n   #{message}"
    deepEqual:(arg1, arg2, message="")->
        @num--
        if not require('deep-equal')(arg1, arg2) then throw "NotEqual: '#{str(arg1)}' does not equal '#{str(arg2)}'\n   #{message}"
    ok:(bool,message="")->
        @num--
        if not bool then throw "NotOk: false was passed to ok\n   #{message}"
    done:(message="")->
        if @num != 0 then throw "NotDone: #{str(@num)} more checks were expected before done was called\n   #{message}"
    run:()->
        @func.call(this)
        @done()
        
test=(name, func)->
    t = new Test(name, func)
    exports[name]=()->t.run()

exports.RunAll = (throwException)->
    for name of exports
        if name != "RunAll"
            if throwException then exports[name]()
            else
                try
                    exports[name]()
                catch ex
                    console.log "Error in Test '#{name}'"
                    console.log "Message: #{ex}"
                    console.log "Stack:\n#{ex.stack}"
                    console.log ''
    return

#File specific test functions
bin=require("../bin/JSUnifyRuntime")
for prop of bin
    global[prop] = bin[prop]


#######################
#backtrack
#######################
test "Snowy Chicago", () ->
    @expect(1)
    @ok(new Program()
        .rule({snowy:variable("X")},
            {cold:[variable("X"),variable("Y")]},
            {rainy:[variable("X"),variable("Y")]})
        .rule({rainy:["cinci",1]})
        .rule({rainy:["chicago",1]})
        .rule({cold:["chicago",1]})
        .query({snowy:variable("P")}).get("P") == "chicago")
        
test "Is Int",()->
    @expect(1)
    prog = new Program()
        .rule({number:4.4})
        .rule({number:9})
        .rule({int:variable("X")},
            {number:variable("X")},
            (tin)->
                X = tin.get("X")
                return parseInt(X) == X)
    @ok(prog.query({int:variable("Y")}).get("Y") == 9)

test "N1 Is N-1",()->
    @expect(1)
    prog = new Program()
        .rule({number:12})
        .rule({minus:variable("N1")},
            {number:variable("N")},
            (tin)->
                N = tin.get("N")
                return tin.bind("N1",N-1)
        )
    @ok(prog.query({minus:variable("Q")}).get("Q") == 11)

test "Illegal rebind", ()->
    @expect(1)
    prog = new Program()
        .rule({number:12})
        .rule({minus:variable("N")},
            {number:variable("N")},
            (tin)->
                N = tin.get("N")
                return tin.bind("N",N+1)
        )
    @ok(prog.query({minus:variable("Q")}) == null)

test "Family Tree", () ->
    @expect(7)
    rules = []
    rules.push(new Rule({"male":["james1"]}))
    rules.push(new Rule({"male":["charles2"]}))
    rules.push(new Rule({"male":["charles1"]}))
    rules.push(new Rule({"male":["james2"]}))
    rules.push(new Rule({"male":["george1"]}))

    rules.push(new Rule({"female":["catherine"]}))
    rules.push(new Rule({"female":["elizabeth"]}))
    rules.push(new Rule({"female":["sophia"]}))

    rules.push(new Rule({"parent":["charles1", "james1"]}))
    rules.push(new Rule({"parent":["elizabeth", "james1"]}))
    rules.push(new Rule({"parent":["charles2", "charles1"]}))
    rules.push(new Rule({"parent":["catherine", "charles1"]}))
    rules.push(new Rule({"parent":["james2", "charles1"]}))
    rules.push(new Rule({"parent":["sophia", "elizabeth"]}))
    rules.push(new Rule({"parent":["george1", "sophia"]}))
    rules.push(new Rule({"parent":["george1", "james1"]})) # Lies!

    rules.push(new Rule({"father":[variable("Kid"),variable("Dad")]}, {"male":[variable("Dad")]}, {"parent":[variable("Kid"),variable("Dad")]}))
    rules.push(new Rule({"mother":[variable("Kid"),variable("Mom")]}, {"female":[variable("Mom")]}, {"parent":[variable("Kid"),variable("Mom")]}))
    
    prog = new Program().load(rules)
    # prog.settings.debug=true
    
    res = prog.query({"mother":["george1",variable("Mom")]})
    @ok(res != null)
    @ok(res.get("Mom") == "sophia")
    
    res = prog.query({"parent":["charles1","george1"]})
    @ok(res == null)
    
    res = prog.query({"parent":["elizabeth",variable("X")]})
    @ok(res != null)
    @ok(res.get("X") == "james1")
    
    res = prog.query({"father":["george1",variable("Dad")]})
    @ok(res != null)
    @ok(res.get("Dad") == "james1")
