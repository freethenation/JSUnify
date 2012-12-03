coffee = require 'coffee-script'
fs = require 'fs'
log=console.log
uglify = require "uglify-js"

paths=['./src/unify.coffee', './src/JSUnifyRuntime.coffee', './src/JSUnifyCompiler.coffee']
testPaths=['./tests/unifyTests.coffee', './tests/JSUnifyRuntimeTests.coffee','./tests/JSUnifyCompilerTests.coffee']
depends=['./submodule/node-falafel/index.js', './submodule/esprima/esprima.js']
buildTasks={}
buildTask=(name, desc, callback)->
    if !callback?
        callback = desc
        desc = null
    buildTasks[name]=()->
        log "building '#{name}'"
        callback()
        log "done!"
    task 'build:'+name.replace('.js',''),  (if desc? then desc else "builds '#{name}'"), buildTasks[name]
task 'build', 'does a full build of the project including unit tests', ()->(buildTasks[task]() for task of buildTasks)

buildTask 'unify.js', ()->build(paths.slice(0,1),'./bin/unify.js')
buildTask 'JSUnifyRuntime.js', ()->build(paths.slice(0,2),'./bin/JSUnifyRuntime.js')
buildTask 'JSUnifyCompiler.js', ()->
    build(paths.slice(0,3),'./bin/JSUnifyCompiler.js')
    fs.writeFileSync('./bin/falafel.js', fs.readFileSync('./submodule/node-falafel/index.js', 'utf8'))
buildTask 'JSUnifyCompilerWithDependencies.js', ()->build(paths.slice(0,3),'./bin/JSUnifyCompilerWithDependencies.js',depends)
buildTask 'jsunify',  'builds jsunify, a command line compiler for the JSUnify language', ()->build(['./src/jsunify.coffee'],'./bin/jsunify')

buildTask 'unifyTests', ()->build(paths.slice(0,1).concat(testPaths.slice(0,1)), './tests/unifyTests.js')
buildTask 'JSUnifyRuntimeTests', ()->build(paths.slice(0,2).concat(testPaths.slice(0,2)), './tests/JSUnifyRuntimeTests.js')
buildTask 'JSUnifyCompilerTests', ()->build(paths.slice(0,3).concat(testPaths.slice(0,3)),'./tests/JSUnifyCompiler.js',depends)

minify=(inputFile)->
    ast = uglify.parser.parse(inputFile); # parse code and get the initial AST
    ast = uglify.uglify.ast_mangle(ast); # get a new AST with mangled names
    ast = uglify.uglify.ast_squeeze(ast); # get an AST with compression optimizations
    return uglify.uglify.gen_code(ast); # compressed code here
        
build=(inputPaths, outputPath, inputJSPaths=[])->
    outputFile = []
    for path in inputPaths
        outputFile.push fs.readFileSync(path, 'utf8')
        outputFile.push "#File '#{path}'"
    outputFile = outputFile.join('\n')
    outputFile = coffee.compile(outputFile)
    for path in inputJSPaths
        outputFile = fs.readFileSync(path, 'utf8') + '\n' + outputFile
    fs.writeFileSync(outputPath, outputFile)
    outputFile = minify(outputFile)
    if outputFile? and outputPath.indexOf('.js') > -1 then fs.writeFileSync(outputPath.replace('.js', '.min.js'), outputFile)
    
    
        