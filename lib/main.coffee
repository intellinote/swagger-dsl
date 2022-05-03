# Root/index script for CLI

yargs      = require('yargs')
fs         = require('fs')
SwaggerDsl = require("./swagger-dsl").SwaggerDsl
PostmanDsl = require("./postman-dsl").PostmanDsl

main = (argv,logfn,errfn,callback)->
  # set default arguments
  if errfn? and not callback?
    callback = errfn
    errfn = null
  if logfn? and not callback?
    callback = lognf
    logfn = null
  argv ?= process?.argv
  logfn ?= console.log
  errfn ?= console.error
  callback ?= (err,status)->
    if err?
      errfn("ERROR:",err)
      process.exit(status ? 1)
    else
      process.exit(status ? 0)
  # swap out process.argv so that yargs reads the parameter passed to this main function
  original_argv = process.argv
  process.argv = argv

  try
    options = {
     f: { alias: 'format', describe:"output format", default:"openapi", choices:["openapi","swagger","postman"] }
     o: { alias: 'out'   , describe:"output file to write to (defaults to STDOUT)"  }
     p: { alias: 'pretty', describe:"pretty-print JSON output", boolean:true, default:true }
     d: { alias: 'debug' , describe:"include debugging info", boolean:true, default:false }

     index: { describe:"index file containing ordered list of DSL files to import" }
    }
    argv = yargs
      .version(false)
      .options(options)
      .usage("swagger-dsl [OPTIONS] [INPUT_FILES...]")
      .argv
    if argv.f is "swagger"
      argv.f = argv.format = "openapi"
    #
    if argv.help
      yargs.showHelp(errfn)
      callback(null,0)
    else if argv.index? and argv._?.length > 0
      errfn "Do not include a list of input files on the comman line when --index is specified"
      callback(null,1)
    else
      if argv.index?
        unless fs.existsSync(argv.index)
          errfn("ERROR: index file \"#{argv.index}\" was not found")
          callback(null,2)
        else
          index = fs.readFileSync(argv.index).toString().split(/[\n\l\f]/)
          file_list = []
          for elt in index
            trimmed = elt?.trim()
            if elt.length > 0
              file_list.push trimmed
          specified_in_index = " specified in index file \"#{argv.index}\""
      else
        file_list = argv._
        specified_in_index = ""
      unless file_list?.length > 0
        errfn("ERROR: either --index <FILENAME> or a list of input files is required")
        yargs.showHelp(errfn)
        callback(null,3)
      else
        for f in file_list
          unless fs.existsSync(f)
            errfn("ERROR: input file \"#{f}\"#{specified_in_index} was not found")
            callback(null,4)
            return
        if argv.format is "openapi"
          DslCtor = SwaggerDsl
        else if argv.format is "postman"
          DslCtor = PostmanDsl
        dsl = new DslCtor()
        #
        data_list = []
        for infile in file_list
          data_list.push fs.readFileSync(infile).toString()
        output = dsl._process(data_list, argv)
        if argv.o?
          fs.writeFileSync(argv.o,output)
        else
          logfn output
        callback(null,0)
  finally
    process.argv = original_argv

if require.main is module
  main()
