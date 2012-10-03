coffee = require 'coffee-script'
fs = require 'fs'
log=console.log

paths=['./src/JSUnify.coffee', './src/JSUnifyLang.coffee', './src/JSUnifySugar.coffee']
testPaths=['./tests/JSUnifyUnitTests.coffee', './tests/JSUnifyLangUnitTests.coffee']
buildTasks={}
buildTask=(name, callback)->
    buildTasks[name]=()->
        log "building '#{name}.js'"
        callback()
        log "done!"
    task 'build:'+name, "builds '#{name}.js'", buildTasks[name]
buildTask 'unify', ()->build(paths.slice(0,1),'./bin/unify.js')
buildTask 'JSUnifyRuntime', ()->build(paths.slice(0,2),'./bin/JSUnifyRuntime.js')
buildTask 'JSUnifyCompiler', ()->build(paths.slice(0,3),'./bin/JSUnifyCompiler.js')
buildTask 'unifyTests', ()->build(paths.slice(0,1).concat(testPaths.slice(0,1)), './tests/unifyTests.js')
buildTask 'JSUnifyRuntimeTests', ()->build(paths.slice(0,2).concat(testPaths.slice(0,2)), './tests/JSUnifyRuntimeTests.js')
task 'build', 'does a full build of the project including unit tests', ()->(buildTasks[task]() for task of buildTasks)
build=(inputPaths, outputPath)->
    outputFile = []
    for path in inputPaths
        outputFile.push fs.readFileSync(path, 'utf8')
        outputFile.push "#File '#{path}'"
    outputFile = outputFile.join('\n')
    outputFile = coffee.compile(outputFile)
    fs.writeFileSync(outputPath, outputFile)
    
        