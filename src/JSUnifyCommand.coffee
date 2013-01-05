# A simple **OptionParser** class to parse option flags from the command-line.
# Use it like so:
#
#     parser  = new OptionParser switches, helpBanner
#     options = parser.parse process.argv
#
# The first non-option is considered to be the start of the file (and file
# option) list, and all subsequent arguments are left unparsed.
class OptionParser

  # Initialize with a list of valid options, in the form:
  #
  #     [short-flag, long-flag, description]
  #
  # Along with an an optional banner for the usage help.
  constructor: (rules, @banner) ->
    @rules = buildRules rules

  # Parse the list of arguments, populating an `options` object with all of the
  # specified options, and return it. Options after the first non-option
  # argument are treated as arguments. `options.arguments` will be an array
  # containing the remaining arguments. This is a simpler API than many option
  # parsers that allow you to attach callback actions for every flag. Instead,
  # you're responsible for interpreting the options object.
  parse: (args) ->
    options = arguments: []
    skippingArgument = no
    originalArgs = args
    args = normalizeArguments args
    for arg, i in args
      if skippingArgument
        skippingArgument = no
        continue
      if arg is '--'
        pos = originalArgs.indexOf '--'
        options.arguments = options.arguments.concat originalArgs[(pos + 1)..]
        break
      isOption = !!(arg.match(LONG_FLAG) or arg.match(SHORT_FLAG))
      # the CS option parser is a little odd; options after the first
      # non-option argument are treated as non-option arguments themselves
      seenNonOptionArg = options.arguments.length > 0
      unless seenNonOptionArg
        matchedRule = no
        for rule in @rules
          if rule.shortFlag is arg or rule.longFlag is arg
            value = true
            if rule.hasArgument
              skippingArgument = yes
              value = args[i + 1]
            options[rule.name] = if rule.isList then (options[rule.name] or []).concat value else value
            matchedRule = yes
            break
        throw new Error "unrecognized option: #{arg}" if isOption and not matchedRule
      if seenNonOptionArg or not isOption
        options.arguments.push arg
    options

  # Return the help text for this **OptionParser**, listing and describing all
  # of the valid options, for `--help` and such.
  help: ->
    lines = []
    lines.unshift "#{@banner}\n" if @banner
    for rule in @rules
      spaces  = 15 - rule.longFlag.length
      spaces  = if spaces > 0 then Array(spaces + 1).join(' ') else ''
      letPart = if rule.shortFlag then rule.shortFlag + ', ' else '    '
      lines.push '  ' + letPart + rule.longFlag + spaces + rule.description
    "\n#{ lines.join('\n') }\n"

# Helpers
# -------

# Regex matchers for option flags.
LONG_FLAG  = /^(--\w[\w\-]*)/
SHORT_FLAG = /^(-\w)$/
MULTI_FLAG = /^-(\w{2,})/
OPTIONAL   = /\[(\w+(\*?))\]/

# Build and return the list of option rules. If the optional *short-flag* is
# unspecified, leave it out by padding with `null`.
buildRules = (rules) ->
  for tuple in rules
    tuple.unshift null if tuple.length < 3
    buildRule tuple...

# Build a rule from a `-o` short flag, a `--output [DIR]` long flag, and the
# description of what the option does.
buildRule = (shortFlag, longFlag, description, options = {}) ->
  match     = longFlag.match(OPTIONAL)
  longFlag  = longFlag.match(LONG_FLAG)[1]
  {
    name:         longFlag.substr 2
    shortFlag:    shortFlag
    longFlag:     longFlag
    description:  description
    hasArgument:  !!(match and match[1])
    isList:       !!(match and match[2])
  }

# Normalize arguments by expanding merged flags into multiple flags. This allows
# you to have `-wl` be the same as `--watch --lint`.
normalizeArguments = (args) ->
  args = args[..]
  result = []
  for arg in args
    if match = arg.match MULTI_FLAG
      result.push '-' + l for l in match[1].split ''
    else
      result.push arg
  result

helpers = {
    extend: (object, properties) ->
      for key, val of properties
        object[key] = val
      object
}

# The `jsunify` utility. Handles command-line compilation of JSUnify
# into various forms: saved into `.js` files or printed to stdout, piped to
# [JavaScript Lint](http://javascriptlint.com/) or recompiled every time the source is
# saved, printed as a token stream or as the syntax tree, or launch an
# interactive REPL.
  
# External dependencies.
fs             = require 'fs'
path           = require 'path'
JSUnify   = require './JSUnifyCompiler'
{spawn, exec}  = require 'child_process'
{EventEmitter} = require 'events'

exists         = fs.exists or path.exists
# Allow JSUnify to emit Node.js events.
helpers.extend JSUnify, new EventEmitter

printLine = (line) -> process.stdout.write line + '\n'
printWarn = (line) -> process.stderr.write line + '\n'

hidden = (file) -> /^\.|~$/.test file

# The help banner that is printed when `coffee` is called without arguments.
BANNER = '''
  Usage: jsunify [options] path/to/script.jsunify -- [args]

  If called without options, `jsunify` will run your script.
'''

# The list of all the valid option flags that `coffee` knows how to handle.
SWITCHES = [
  ['-b', '--bare',            'compile without a top-level function wrapper']
  ['-c', '--compile',         'compile to JavaScript and save as .js files']
  ['-e', '--eval',            'pass a string from the command line as input']
  ['-h', '--help',            'display this help message']
  ['-i', '--interactive',     'run an interactive JSUnify REPL']
  ['-j', '--join [FILE]',     'concatenate the source JSUnify before compiling']
  ['-l', '--lint',            'pipe the compiled JavaScript through JavaScript Lint']
  ['-n', '--nodes',           'print out the parse tree that the parser produces']
  [      '--nodejs [ARGS]',   'pass options directly to the "node" binary']
  ['-o', '--output [DIR]',    'set the output directory for compiled JavaScript']
  ['-p', '--print',           'print out the compiled JavaScript']
  ['-r', '--require [FILE*]', 'require a library before executing your script']
  ['-s', '--stdio',           'listen for and compile scripts over stdio']
  ['-t', '--tokens',          'print out the tokens that the lexer/rewriter produce']
  ['-v', '--version',         'display the version number']
  ['-w', '--watch',           'watch scripts for changes and rerun commands']
]

# Top-level objects shared by all the functions.
opts         = {}
sources      = []
sourceCode   = []
notSources   = {}
watchers     = {}
optionParser = null

# Run `coffee` by parsing passed options and determining what action to take.
# Many flags cause us to divert before compiling anything. Flags passed after
# `--` will be passed verbatim to your script as arguments in `process.argv`
exports.run = ->
  parseOptions()
  return forkNode()                      if opts.nodejs
  return usage()                         if opts.help
  return version()                       if opts.version
  loadRequires()                         if opts.require
  return require './repl'                if opts.interactive
  if opts.watch and !fs.watch
    return printWarn "The --watch feature depends on Node v0.6.0+. You are running #{process.version}."
  return compileStdio()                  if opts.stdio
  return compileScript null, sources[0]  if opts.eval
  return require './repl'                unless sources.length
  literals = if opts.run then sources.splice 1 else []
  process.argv = process.argv[0..1].concat literals
  process.argv[0] = 'coffee'
  process.execPath = require.main.filename
  for source in sources
    compilePath source, yes, path.normalize source

# Compile a path, which could be a script or a directory. If a directory
# is passed, recursively compile all '.jsunify' extension source files in it
# and all subdirectories.
compilePath = (source, topLevel, base) ->
  fs.stat source, (err, stats) ->
    throw err if err and err.code isnt 'ENOENT'
    if err?.code is 'ENOENT'
      if topLevel and source[-7..] isnt '.jsunify'
        source = sources[sources.indexOf(source)] = "#{source}.jsunify"
        return compilePath source, topLevel, base
      if topLevel
        console.error "File not found: #{source}"
        process.exit 1
      return
    if stats.isDirectory()
      watchDir source, base if opts.watch
      fs.readdir source, (err, files) ->
        throw err if err and err.code isnt 'ENOENT'
        return if err?.code is 'ENOENT'
        index = sources.indexOf source
        files = files.filter (file) -> not hidden file
        sources[index..index] = (path.join source, file for file in files)
        sourceCode[index..index] = files.map -> null
        files.forEach (file) ->
          compilePath (path.join source, file), no, base
    else if topLevel or path.extname(source) is '.jsunify'
      watch source, base if opts.watch
      fs.readFile source, (err, code) ->
        throw err if err and err.code isnt 'ENOENT'
        return if err?.code is 'ENOENT'
        compileScript(source, code.toString(), base)
    else
      notSources[source] = yes
      removeSource source, base


# Compile a single source script, containing the given code, according to the
# requested options. If evaluating the script directly sets `__filename`,
# `__dirname` and `module.filename` to be correct relative to the script's path.
compileScript = (file, input, base) ->
  o = opts
  options = compileOptions file
  try
    t = task = {file, input, options}
    JSUnify.emit 'compile', task
    if      o.tokens      then printTokens JSUnify.tokens t.input
    else if o.nodes       then printLine JSUnify.nodes(t.input).toString().trim()
    else if o.run         then JSUnify.run t.input, t.options
    else if o.join and t.file isnt o.join
      sourceCode[sources.indexOf(t.file)] = t.input
      compileJoin()
    else
      t.output = JSUnify.compile(t.input, t.options)
      # t.output = JSUnify.compile t.input, t.options
      JSUnify.emit 'success', task
      if o.print          then printLine t.output.trim()
      else if o.compile   then writeJs t.file, t.output, base
      else if o.lint      then lint t.file, t.output
  catch err
    JSUnify.emit 'failure', err, task
    return if JSUnify.listeners('failure').length
    return printLine err.message + '\x07' if o.watch
    printWarn err instanceof Error and err.stack or "ERROR: #{err}"
    process.exit 1

# Attach the appropriate listeners to compile scripts incoming over **stdin**,
# and write them back to **stdout**.
compileStdio = ->
  code = ''
  stdin = process.openStdin()
  stdin.on 'data', (buffer) ->
    code += buffer.toString() if buffer
  stdin.on 'end', ->
    compileScript null, code

# If all of the source files are done being read, concatenate and compile
# them together.
joinTimeout = null
compileJoin = ->
  return unless opts.join
  unless sourceCode.some((code) -> code is null)
    clearTimeout joinTimeout
    joinTimeout = wait 100, ->
      compileScript opts.join, sourceCode.join('\n'), opts.join

# Load files that are to-be-required before compilation occurs.
loadRequires = ->
  realFilename = module.filename
  module.filename = '.'
  require req for req in opts.require
  module.filename = realFilename

# Watch a source JSUnify file using `fs.watch`, recompiling it every
# time the file is updated. May be used in combination with other options,
# such as `--lint` or `--print`.
watch = (source, base) ->

  prevStats = null
  compileTimeout = null

  watchErr = (e) ->
    if e.code is 'ENOENT'
      return if sources.indexOf(source) is -1
      try
        rewatch()
        compile()
      catch e
        removeSource source, base, yes
        compileJoin()
    else throw e

  compile = ->
    clearTimeout compileTimeout
    compileTimeout = wait 25, ->
      fs.stat source, (err, stats) ->
        return watchErr err if err
        return rewatch() if prevStats and stats.size is prevStats.size and
          stats.mtime.getTime() is prevStats.mtime.getTime()
        prevStats = stats
        fs.readFile source, (err, code) ->
          return watchErr err if err
          compileScript(source, code.toString(), base)
          rewatch()

  try
    watcher = fs.watch source, compile
  catch e
    watchErr e

  rewatch = ->
    watcher?.close()
    watcher = fs.watch source, compile


# Watch a directory of files for new additions.
watchDir = (source, base) ->
  readdirTimeout = null
  try
    watcher = fs.watch source, ->
      clearTimeout readdirTimeout
      readdirTimeout = wait 25, ->
        fs.readdir source, (err, files) ->
          if err
            throw err unless err.code is 'ENOENT'
            watcher.close()
            return unwatchDir source, base
          for file in files when not hidden(file) and not notSources[file]
            file = path.join source, file
            continue if sources.some (s) -> s.indexOf(file) >= 0
            sources.push file
            sourceCode.push null
            compilePath file, no, base
  catch e
    throw e unless e.code is 'ENOENT'

unwatchDir = (source, base) ->
  prevSources = sources[..]
  toRemove = (file for file in sources when file.indexOf(source) >= 0)
  removeSource file, base, yes for file in toRemove
  return unless sources.some (s, i) -> prevSources[i] isnt s
  compileJoin()

# Remove a file from our source list, and source code cache. Optionally remove
# the compiled JS version as well.
removeSource = (source, base, removeJs) ->
  index = sources.indexOf source
  sources.splice index, 1
  sourceCode.splice index, 1
  if removeJs and not opts.join
    jsPath = outputPath source, base
    exists jsPath, (itExists) ->
      if itExists
        fs.unlink jsPath, (err) ->
          throw err if err and err.code isnt 'ENOENT'
          timeLog "removed #{source}"

# Get the corresponding output JavaScript path for a source file.
outputPath = (source, base) ->
  filename  = path.basename(source, path.extname(source)) + '.js'
  srcDir    = path.dirname source
  baseDir   = if base is '.' then srcDir else srcDir.substring base.length
  dir       = if opts.output then path.join opts.output, baseDir else srcDir
  path.join dir, filename

# Write out a JavaScript source file with the compiled code. By default, files
# are written out in `cwd` as `.js` files with the same name, but the output
# directory can be customized with `--output`.
writeJs = (source, js, base) ->
  jsPath = outputPath source, base
  jsDir  = path.dirname jsPath
  compile = ->
    js = ' ' if js.length <= 0
    fs.writeFile jsPath, js, (err) ->
      if err
        printLine err.message
      else if opts.compile and opts.watch
        timeLog "compiled #{source}"
  exists jsDir, (itExists) ->
    if itExists then compile() else exec "mkdir -p #{jsDir}", compile

# Convenience for cleaner setTimeouts.
wait = (milliseconds, func) -> setTimeout func, milliseconds

# When watching scripts, it's useful to log changes with the timestamp.
timeLog = (message) ->
  console.log "#{(new Date).toLocaleTimeString()} - #{message}"

# Pipe compiled JS through JSLint (requires a working `jsl` command), printing
# any errors or warnings that arise.
lint = (file, js) ->
  printIt = (buffer) -> printLine file + ':\t' + buffer.toString().trim()
  conf = __dirname + '/../../extras/jsl.conf'
  jsl = spawn 'jsl', ['-nologo', '-stdin', '-conf', conf]
  jsl.stdout.on 'data', printIt
  jsl.stderr.on 'data', printIt
  jsl.stdin.write js
  jsl.stdin.end()

# Pretty-print a stream of tokens.
printTokens = (tokens) ->
  strings = for token in tokens
    [tag, value] = [token[0], token[1].toString().replace(/\n/, '\\n')]
    "[#{tag} #{value}]"
  printLine strings.join(' ')

# Use the [OptionParser module](optparse.html) to extract all options from
# `process.argv` that are specified in `SWITCHES`.
parseOptions = ->
  optionParser  = new OptionParser SWITCHES, BANNER
  o = opts      = optionParser.parse process.argv[2..]
  o.compile     or=  !!o.output
  o.run         = not (o.compile or o.print or o.lint)
  o.print       = !!  (o.print or (o.eval or o.stdio and o.compile))
  sources       = o.arguments
  sourceCode[i] = null for source, i in sources
  return

# The compile-time options to pass to the JSUnify compiler.
compileOptions = (filename) ->
  {filename, bare: opts.bare, header: opts.compile}

# Start up a new Node.js instance with the arguments in `--nodejs` passed to
# the `node` binary, preserving the other options.
forkNode = ->
  nodeArgs = opts.nodejs.split /\s+/
  args     = process.argv[1..]
  args.splice args.indexOf('--nodejs'), 2
  spawn process.execPath, nodeArgs.concat(args),
    cwd:        process.cwd()
    env:        process.env
    customFds:  [0, 1, 2]

# Print the `--help` usage message and exit. Deprecated switches are not
# shown.
usage = ->
  printLine (new OptionParser SWITCHES, BANNER).help()

# Print the `--version` message and exit.
version = ->
  printLine "JSUnify version #{JSUnify.VERSION}"