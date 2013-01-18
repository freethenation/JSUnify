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
createTestSteps=(outFile)->
    return [
        (step, err)->
            console.log('Running "' + outFile + '"!')
            test(outFile, step.options.exception, step.next)
        (step, err)->
            console.log('Ran "' + outFile + '"!')
            step.next()
    ]

buildRuntimeSteps = createBuildSteps('./src/JSUnifyRuntime.coffee', './bin/JSUnifyRuntime.js')
buildCompilerSteps = [
    (step, err)->readFile('./src/JSUnifyRuntime.coffee', step.next)
    (step, err, file)->
        step.file = file
        readFile('./src/JSUnifyCompiler.coffee', step.next)
    (step, err, file)->step.next(step.file + '\n' + file)
    (step, err, file)->compile(file, step.next)
    (step, err, file)->writeFile('./bin/JSUnifyCompiler.js',  file, step.next)
    (step, err)->
        console.log('Compiled "' + './bin/JSUnifyCompiler.js' + '"!')
        step.next()
]
buildCommandSteps = createBuildSteps('./src/JSUnifyCommand.coffee', './bin/JSUnifyCommand.js')
buildRuntimeMinSteps = createMinSteps('./bin/JSUnifyRuntime.js', './bin/JSUnifyRuntime.min.js')
buildCompilerMinSteps = createMinSteps('./bin/JSUnifyCompiler.js', './bin/JSUnifyCompiler.min.js')
testRuntimeSteps = flatten([
    createBuildSteps('./tests/JSUnifyRuntimeTests.coffee', './tests/JSUnifyRuntimeTests.js')
    createTestSteps('./tests/JSUnifyRuntimeTests.js')
])
testCompilerSteps = flatten([
    createBuildSteps('./tests/JSUnifyCompilerTests.coffee', './tests/JSUnifyCompilerTests.jsunify')
    (step, err)->readFile('./tests/JSUnifyCompilerTests.jsunify', step.next)
    (step, err, file)->
        JSUnify = require('./bin/JSUnifyCompiler')
        writeFile('./tests/JSUnifyCompilerTests.js', JSUnify.compile(file), step.next)
    createTestSteps('./tests/JSUnifyCompilerTests.js')
])

task 'build', 'builds the runtime and compiler', (options)->
    funcflow(flatten([buildRuntimeSteps, buildCompilerSteps, buildCommandSteps]), {catchExceptions:false, "options":options}, ()->)

task 'build:min', 'builds the runtime and compiler and then minifies it', (options)->
    funcflow(flatten([buildRuntimeSteps, buildCompilerSteps, buildCommandSteps, buildRuntimeMinSteps, buildCompilerMinSteps]), {catchExceptions:false, "options":options}, ()->)

option '-e', '--exception', "don't catch exceptions when running unit tests"
task 'build:full', 'compiles runtime and compiler, minifies, and runs unit tests', (options)->
    funcflow(flatten([buildRuntimeSteps, buildCompilerSteps, buildCommandSteps, buildRuntimeMinSteps, buildCompilerMinSteps, testRuntimeSteps, testCompilerSteps]),{catchExceptions:false, "options":options}, ()->)
    
task 'test', 'compiles and runs unit tests', (options)->
    funcflow(flatten([testRuntimeSteps, testCompilerSteps]), {catchExceptions:false, "options":options}, ()->)
    
compile = (inputFile, callback) ->
    coffee = require 'coffee-script'
    callback?(coffee.compile(inputFile))

compress = (inputFile, callback) ->
    UglifyJS = require "uglify-js"
    toplevel = UglifyJS.parse(inputFile)
    toplevel.figure_out_scope()
    compressor = UglifyJS.Compressor()
    compressed_ast = toplevel.transform(compressor)
    compressed_ast.figure_out_scope()
    compressed_ast.compute_char_frequency()
    compressed_ast.mangle_names()
    callback?(compressed_ast.print_to_string())
    
readFile = (filename, callback) ->
    data = fs.readFile(filename, 'utf8', (err, data)-> if err then throw err else callback(data))
 
writeFile = (filename, data, callback) ->
    fs.writeFile(filename, data, 'utf8', (err)-> if err then throw err else callback())

test = (inputFile, throwException, callback) ->
    tests = require(inputFile)
    # tests.RunAll(throwException)
    tests["Family Tree"]?()
    callback()