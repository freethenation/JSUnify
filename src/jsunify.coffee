#!/usr/bin/env node

# This is the source for the jsunify command line program
compiler = require './JSUnifyCompiler.js'
program = require 'commander'
fs = require 'fs'
path = require 'path'

program
    .version('0.8.0')
    .option('-o, --output <file>', 'set the output directory for compiled JavaScript')
    .option('-c, --compile <file>', 'Add pineapple')
    .parse(process.argv);

inputPath = program.compile
console.log 'reading input files.....'
outputFile = fs.readFileSync(inputPath, 'utf8')
console.log 'compiling input files.....'
outputFile = compiler.compile(outputFile)
console.log 'saving compiled files.....'
fs.writeFileSync((if program.output? then program.output  else inputPath.replace(path.extname(inputPath), '.js')) , outputFile)