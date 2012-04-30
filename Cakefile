fs = require 'fs'
{print} = require 'util'
{spawn} = require 'child_process'
path = require 'path'

build = (callback, parms) ->
    coffee = spawn 'coffee', parms
    coffee.stderr.on 'data', (data) ->
        process.stderr.write data.toString()
    coffee.stdout.on 'data', (data) ->
        print data.toString()
    coffee.on 'exit', (code) ->
        callback?() if code is 0

task 'build', 'Rebuild JSUnit', (options) ->
    build(null, ["-j", path.join("bin","JSUnifyLang.js"), "-c", path.join("src","JSUnify.coffee"), path.join("src","JSUnifyLang.coffee")])
    build(null, ["-o", "bin", "-c", path.join("src","JSUnify.coffee")])
    build(null, ["-c", "tests"])

task 'watch', 'Watch for changes and rebuild JSUnit', ->
    build(null, ["-w", "-j", path.join("bin","JSUnifyLang.js"), "-c", path.join("src","JSUnify.coffee"), path.join("src","JSUnifyLang.coffee")])
    build(null, ["-w", "-o", "bin", "-c", path.join("src","JSUnify.coffee")])
    build(null, ["-w", "-c", "tests"])
    
 # coffee -j .\bin\JSUnifyLang.js -c .\src\JSUnify.coffee .\src\JSUnifyLang.coffee
 
 # coffee -o .\bin -c .\src\JSUnify.coffee
 
 # coffee -c .\tests