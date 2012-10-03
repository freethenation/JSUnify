coffee = require 'coffee-script'
fs = require 'fs'
log=console.log
uglify = require "uglify-js"

paths=['./src/unify.coffee', './src/JSUnifyRuntime.coffee', './src/JSUnifyCompiler.coffee']
testPaths=['./tests/unifyTests.coffee', './tests/JSUnifyRuntimeTests.coffee']
buildTasks={}
buildTask=(name, callback)->
    buildTasks[name]=()->
        log "building '#{name}.js'"
        callback()
        log "done!"
    task 'build:'+name, "builds '#{name}.js'", buildTasks[name]
task 'build', 'does a full build of the project including unit tests', ()->(buildTasks[task]() for task of buildTasks)
buildTask 'unify', ()->build(paths.slice(0,1),'./bin/unify')
buildTask 'JSUnifyRuntime', ()->build(paths.slice(0,2),'./bin/JSUnifyRuntime')
buildTask 'JSUnifyCompiler', ()->build(paths.slice(0,3),'./bin/JSUnifyCompiler')
buildTask 'unifyTests', ()->build(paths.slice(0,1).concat(testPaths.slice(0,1)), './tests/unifyTests')
buildTask 'JSUnifyRuntimeTests', ()->build(paths.slice(0,2).concat(testPaths.slice(0,2)), './tests/JSUnifyRuntimeTests')

minify=(inputFile)->
    ast = uglify.parser.parse(inputFile); # parse code and get the initial AST
    ast = uglify.uglify.ast_mangle(ast); # get a new AST with mangled names
    ast = uglify.uglify.ast_squeeze(ast); # get an AST with compression optimizations
    return uglify.uglify.gen_code(ast); # compressed code here
        
build=(inputPaths, outputPath)->
    outputFile = []
    for path in inputPaths
        outputFile.push fs.readFileSync(path, 'utf8')
        outputFile.push "#File '#{path}'"
    outputFile = outputFile.join('\n')
    outputFile = coffee.compile(outputFile)
    fs.writeFileSync(outputPath + '.js', outputFile)
    outputFile = minify(outputFile)
    if outputFile? then fs.writeFileSync(outputPath + '.min.js', outputFile)
    
    
        