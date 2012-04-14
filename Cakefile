fs = require 'fs'
{print} = require 'util'
{spawn} = require 'child_process'

# option '-o', '--output [DIR]', 'directory for compiled code'

build = (callback, from, to, watch) ->
    if watch? && watch == true
        coffee = spawn 'coffee', ['-w','-c', '-o', to, from]
    else
        coffee = spawn 'coffee', ['-c', '-o', to, from]
    coffee.stderr.on 'data', (data) ->
        process.stderr.write data.toString()
    coffee.stdout.on 'data', (data) ->
        print data.toString()
    coffee.on 'exit', (code) ->
        callback?() if code is 0
        

task 'build', 'Rebuild JSUnit', (options) ->
    build(null, "src", "bin")
    build(null, "tests", "tests")

task 'watch', 'Watch for changes and rebuild JSUnit', ->
    build(null, "src", "bin", true)
    build(null, "tests", "tests", true)