fs = require 'fs'
funcflow = require 'funcflow'
_ = require 'underscore'
flatten = _.flatten

createBuildSteps=(inFile, outFile)->
    return [
        (step, err)->readFile(inFile, step.next)
        (step, err, file)->compile(file, step.next)
        (step, err, file)->writeFile(outFile, file, step.next)
        (step, err)->
            console.log('Compiled "' + outFile + '"!')
            step.next()
    ]
createMinSteps=(inFile, outFile)->
    return [
        (step, err)->readFile(inFile, step.next)
        (step, err, file)->compress(file, step.next)
        (step, err, file)->writeFile(outFile,  file, step.next)
        (step, err)->
            console.log('Compiled "' + outFile + '"!')
            step.next()
    ]
createTestSteps=(inFile, outFile)->
    return flatten([
        createBuildSteps(inFile, outFile)
        (step, err)->
            console.log('Running "' + outFile + '"!')
            test(outFile, step.options.exception, step.next)
        (step, err)->
            console.log('Ran "' + outFile + '"!')
            step.next()
    ])
    
buildRuntimeSteps = createBuildSteps('./src/JSUnifyRuntime.coffee', './bin/JSUnifyRuntime.js')
buildCompilerSteps = createBuildSteps('./src/JSUnifyCompiler.coffee', './bin/JSUnifyCompiler.js')
buildRuntimeMinSteps = createMinSteps('./bin/JSUnifyRuntime.js', './bin/JSUnifyRuntime.min.js')
buildCompilerMinSteps = createMinSteps('./bin/JSUnifyCompiler.js', './bin/JSUnifyCompiler.min.js')
testRuntimeSteps = createTestSteps('./tests/JSUnifyRuntimeTests.coffee', './tests/JSUnifyRuntimeTests.js')
testCompilerSteps = createTestSteps('./tests/JSUnifyCompilerTests.coffee', './tests/JSUnifyCompilerTests.js')

task 'build', 'builds the runtime and compiler', (options)->
    funcflow(flatten([buildRuntimeSteps, buildCompilerSteps]), {catchExceptions:false, "options":options}, ()->)

task 'build:min', 'builds the runtime and compiler and then minifies it', (options)->
    funcflow(flatten([buildRuntimeSteps, buildCompilerSteps, buildRuntimeMinSteps, buildCompilerMinSteps]), {catchExceptions:false, "options":options}, ()->)

option '-e', '--exception', "don't catch exceptions when running unit tests"
task 'build:full', 'compiles runtime and compiler, minifies, and runs unit tests', (options)->
    funcflow(flatten([buildRuntimeSteps, buildCompilerSteps, buildRuntimeMinSteps, buildCompilerMinSteps, testCompilerSteps]),{catchExceptions:false, "options":options}, ()->)
    #funcflow(flatten([buildRuntimeSteps, buildCompilerSteps, buildRuntimeMinSteps, buildCompilerMinSteps, testRuntimeSteps, testCompilerSteps]),{catchExceptions:false, "options":options}, ()->)
    
task 'test', 'compiles and runs unit tests', (options)->
    funcflow(flatten([testRuntimeSteps, testCompilerSteps]), {catchExceptions:false, "options":options}, ()->)
    funcflow(flatten([testRuntimeSteps, testCompilerSteps]), {catchExceptions:false, "options":options}, ()->)
    
compile = (inputFile, callback) ->
    coffee = require 'coffee-script'
    callback?(coffee.compile(inputFile))

compress = (inputFile, callback) ->
    uglify = require "uglify-js"
    ast = uglify.parser.parse(inputFile); # parse code and get the initial AST
    ast = uglify.uglify.ast_mangle(ast); # get a new AST with mangled names
    ast = uglify.uglify.ast_squeeze(ast); # get an AST with compression optimizations
    callback?(uglify.uglify.gen_code(ast))
    
readFile = (filename, callback) ->
    data = fs.readFile(filename, 'utf8', (err, data)-> if err then throw err else callback(data))
 
writeFile = (filename, data, callback) ->
    fs.writeFile(filename, data, 'utf8', (err)-> if err then throw err else callback())

test = (inputFile, throwException, callback) ->
    tests = require(inputFile)
    tests.RunAll(throwException)
    callback()