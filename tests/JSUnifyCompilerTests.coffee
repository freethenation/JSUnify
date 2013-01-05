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
#simple
#######################
test "Snowy Chicago", () ->
    @expect(1)
    @ok($jsunify(()->
        snowy(X) == cold(X,Y) && rainy(X,Y)
        rainy("cinci",1)
        rainy("chicago",1)
        cold("chicago",1)
    ).run($jsunify(snowy(P))).get("P") == "chicago")

test "list decomposition", () ->
    @expect(1)
    @ok($jsunify(
        head(H, [H,$_])
        tail($T, [_,$T])
    ).run($jsunify(head(HEAD,[1,2,3]))).get("HEAD") == 1)

