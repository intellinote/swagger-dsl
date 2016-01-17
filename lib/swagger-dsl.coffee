marked = require 'marked'

_alphanumerify = (str,replacement='_')=>
  str = str.replace(/[^A-Za-z0-9]/g,replacement)
  re = new RegExp("#{replacement}+","g")
  str = str.replace(re,replacement)
  return str
_to_array = (arg,split_strings = false)=>
  if split_strings and typeof arg is 'string' and /,/.test arg
    arg = arg.split /,/
  if arg? and not Array.isArray(arg)
    arg = [arg]
  return arg
_warn = (args...)=>console.error "WARNING:",args...
_truthy:(v)=>/^((T(rue)?)|(Y(es)?)|(ON)|1)$/i.test("#{v}")
_falsey:(v)=>/^((F(alse)?)|(No?)|(OFF)|0|(-1))$/i.test("#{v}")
_is_email = (str)->/^[^@]+@[^@]+$/.test(str)
_is_url = (str)->/^https?:\/\//i.test(str)
_markdown_to_html = (str,strip_p=false)=>
  if str?
    str = (marked(str,{}))
    str = str?.trim()
    if strip_p and /^<p>(.*)<\/p>$/.test str
      str = str.substring(3,str.length-4)
  return str


init = (self,options)->

  this.to_json = (spaces=2)->JSON.stringify(rest,null,spaces)

  unless options?.strings is false
    # `paramType` values
    this.path                = 'path'
    this.query               = 'query'
    this.body                = 'body'
    # other
    this.required            = 'required'
    this.optional            = ''
    this.ref                 = '$ref'
    this.$ref                = '$ref'
    # MIME TYPES
    this.MIME = {
      JSON:'application/json'
      XML:'application/xml'
    }
    # `type` and `format` values
    this.array               = 'array'
    this.binary              = 'binary'
    this.boolean             = 'boolean'
    this.byte                = 'byte'
    this.date                = 'date'
    this.date_time           = 'date-time'
    this.datetime            = 'date-time'
    this.dateTime            = 'date-time'
    this.double              = 'double'
    this.float               = 'float'
    this.int                 = 'integer'
    this.int32               = 'int32'
    this.int64               = 'int64'
    this.integer             = 'integer'
    this.long                = 'long'
    this.number              = 'number'
    this.password            = 'password'
    this.string              = 'string'
    #
    this.VOID                = 'void'
    this.file                = 'file'
    # licenses
    this.Apache2 = this.APACHE2 = {
      name: "Apache 2.0"
      url: "http://www.apache.org/licenses/LICENSE-2.0.html"
    }
    this.MIT = {
      name: "The MIT License"
      url: "https://opensource.org/licenses/MIT"
    }
    
    
  # The root SwaggerUI document we are creating.
  this.rest = { }
  
  #############################################################################
  # ROOT LEVEL ELEMENTS
  #############################################################################
  
  
  # SWAGGER -------------------------------------------------------------------
  this.rest.swagger = "2.0"
  
  this.swagger = this.swagger_version = this.swaggerVersion = this.swaggerversion = (ver)=>
    rest.swaggerVersion = "#{ver}"

  # HOST ----------------------------------------------------------------------
  this.host = (host)=>
    this.rest.host = host # TODO check format to ensure that this is the host only

  # BASEPATH ------------------------------------------------------------------
  this.base = this.basepath = this.base_path = this.basePath = (path)=>
    this.rest.basePath = path

  #############################################################################
  # THE INFO OBJECT
  #############################################################################
  
  this.rest.info = null
  
  this.title = (str)=>
    this.rest.info ?= {}
    this.rest.info.title = str
    
  this.description = (str)=>
    this.rest.info ?= {}
    this.rest.info.description = str
    
  this.terms_of_service = this.termsOfService = this.TOS = this.ToS = (str)=>
    this.rest.info ?= {}
    this.rest.info.termsOfService = str
    
  this.version = this.apiVersion = this.ApiVersion = this.APIVersion = this.APIversion = this.api_version = this.API_version = this.API_Version = this.API_VERSION = (str)=>
    this.rest.info ?= {}
    this.rest.info.version = "#{str}"
    
  this.contact = (name, url, email)=>
    if Array.isArray(name)
      email = name[2]
      url = name[1]
      name = name[0]
    if name? and typeof name is 'object'
      this.rest.info ?= {}
      this.rest.info.contact = name # TODO look at fields?
    else if (typeof name is 'string') or (typeof url is 'string') or (typeof email is 'string')
      this.rest.info ?= {}
      this.rest.info.contact = {}
      for value in [name, url, email]
        if _is_email(value)
          this.rest.info.contact.email = value
        else if _is_url(value)
          this.rest.info.contact.url = value
        else
          this.rest.info.contact.name = value
    else
      _warn("Didn't expect to get here. contact(",name,",",url,",",value,") was called.")

  this.license = (name, url)=>
    if name? and typeof name is 'object'
      this.rest.info ?= {}
      this.rest.info.license = name # TODO look at fields?
      if url? and typeof url is 'string'
        this.rest.info.license.url = url
    else if typeof name is 'string' or typeof url is 'string'
      this.rest.info ?= {}
      this.rest.info.license = {}
      for value in [name, url]
        if _is_url(value)
          this.rest.info.license.url = value
        else
          this.rest.info.license.name = value

  this.INFO = (map)=>
    # optionally support "root" fields under INFO so they can use the name:value syntax
    root_fields = [
      "host"
      "base"
      "basepath"
      "base_path"
      "basePath"
      "swagger"
      "swagger_version"
      "swaggerVersion"
      "swaggerversion"
    ]
    info_fields = [
      "title"
      "description"
      "terms_of_service"
      "termsOfService"
      "TOS"
      "ToS"
      "version"
      "apiVersion"
      "ApiVersion"
      "APIVersion"
      "APIversion"
      "api_version"
      "API_version"
      "API_Version"
      "API_VERSION"
      "license"
      "contact"
    ]
    for name, value of map
      if (name in info_fields) or (name in root_fields)
        if Array.isArray(value)  # expand arrays into arguments
          this[name](value...)
        else
          this[name](value)
      else
        unless /^x-/.test name
          _warn "Found an attribute named \"#{name}\" in the INFO section. According to the SwaggerUI tean, extensions should begin with \"x-\"."
        this.rest.info ?= {}
        this.rest.info[name] = value

  #############################################################################
  # THE PATHS OBJECT
  #############################################################################
    
  this._add_operation = (method,path,op)->
    this.rest.paths ?= {}
    this.rest.paths[path] ?= {}
    this.rest.paths[path][method.toLowerCase()] = op

  this.api_method = (method,map)->
    for path, attr of map
      op = _map_to_operation(attr)
      op.method = method
      unless op.operationId?
        op.operationId ?= _alphanumerify "#{method.toLowerCase()}-#{path}"
      _add_operation(method,path,op)

  # ## Operations
  this.GET     = (map)->api_method('GET',map)
  this.PUT     = (map)->api_method('PUT',map)
  this.POST    = (map)->api_method('POST',map)
  this.DELETE  = (map)->api_method('DELETE',map)
  this.OPTIONS = (map)->api_method('OPTIONS',map)
  this.HEAD    = (map)->api_method('HEAD',map)
  this.PATCH   = (map)->api_method('PATCH',map)

  # TODO: add check of valid attributes and valid values (for collectionFormat, etc.)
  _parse_op_parameters = (value)=>
    param = {}
    for elt in value
      if Array.isArray(elt)
        param.items = _parse_op_parameters(elt)
      else if typeof elt is 'object'
        for k,v of elt
          param[k] = v
      else if typeof elt is 'string'
        switch elt
          when 'path', 'query', 'body'
            param.in = elt
          when 'required'
            param.required = true
          when 'string','boolean','file'
            param.type = elt
            param.format = undefined
          when 'integer','int32'
            param.type = 'integer'
            param.format = 'int32'
          when 'long', 'int64'
            param.type = 'integer'
            param.format = 'int64'
          when 'number', 'float'
            param.type = 'number'
            param.format = 'float'
          when 'double'
            param.type = 'number'
            param.format = 'double'
          when 'byte','binary','date','date-time','password'
            param.type = 'string'
            param.format = elt
          else
            param.description = elt
      else
        console.error typeof elt, elt
    if param.default? and param.items?
      param.items.default ?= param.default
      delete param.default
    if param.type? and param.items?
      param.items.type ?= param.type
      delete param.type
    if param.items?
      param.type = 'array'
    if (not param.type?)
      proto = param.default ? param.enum?[0] ? param.maximum ? param.minimum
      if proto?
        switch (typeof proto)
          when 'string'
            param.type = 'string'
          when 'number'
            if /^-?[0-9]+/.test proto
              param.type = 'integer'
            else
              param.type = 'number'
          when 'boolean'
            param.type = 'boolean'
      else if param.pattern?
        param.type = 'string'
    return param

  _map_to_operation = (map)->
    op = {}
    for name, value of map
      if value?
        switch name.toLowerCase()
          when 'tags'
            op.tags = _to_array(value,true).map (x)->(x?.trim())
          when 'summary'
            if value?.length > 120
              _warn("The SwaggerUI team recommends that the method summary should be less than 120 characters. Found #{value.length} in \"#{value}\".")
            op.summary = _markdown_to_html value, true
          when 'description'
            op.description = value # swagger now supports GFM here so no need to process as markdown
          when 'externaldocs' # TODO
            op.externalDocs = value # swagger now supports GFM here so no need to process as markdown
          when 'id','operationid'
            op.operationId = value
          when 'produces','consumes'
            op[name] = _to_array(value,true)
          when 'parameters'
            op.parameters ?= []
            for n,v of value
              p = _parse_op_parameters(v)
              p.name = n
              op.parameters.push p
          when 'responses'
            op.responses ?= {}
            for n,v of value
              if typeof v is 'string'
                op.responses[n] = {description:v}
              else
                op.responses[n] = v
          when 'security'
            # TODO make this more convenient?
            value = _to_array(value)
            op.security = value
          when 'schemes'
            value = _to_array(value,true)
            op.schemes = value
            for scheme in value
              unless value in ["http", "https", "ws", "wss"]
                _warn("According to the SwaggerUI team, elements of \"scheme\" must be one of \"http\", \"https\", \"ws\", \"wss\". Found #{scheme} in #{value}.")
          when 'deprecated'
            op.deprecated = _truthy(value)
          else
            unless /^x-/.test name
              _warn "Found an attribute named \"#{name}\" in the following method (operation) definition. According to the SwaggerUI tean, extensions should begin with \"x-\".", JSON.stringify(map)
            op[name] = value
    return op

  #############################################################################
  # THE DEFINITIONS OBJECT
  #############################################################################
    
  this._add_definition = (key,value)->
    this.rest.definitions ?= {}
    this.rest.definitions[key] = value

  this.MODEL = this.MODELS = this.DEFINITION = this.DEFINITIONS = (map)->
    for key,value of map
      _add_definition(key,_map_to_model(value))
      
  _map_to_model = (map)->
    model = {}
    model.properties = {}
    for prop_name,values of map
      if typeof values is 'string'
        values = [values]
      model.properties[prop_name] = _parse_op_parameters(values)
    if model.properties? and not model.type?
      model.type = 'object'
    return model

  #############################################################################


_main = (argv,logfn,errfn,callback)=>
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
  callback ?= process?.exit ? (()->undefined)
  # swap out process.argv so that optimist reads the parameter passed to this main function
  original_argv = process.argv
  process.argv = argv

  # perform the rest of the operation in a try block so we can be
  # sure to restore process.argv when we're finished.
  try

    CoffeeScript = require('coffee-script')
    optimist = require('optimist')
    fs = require('fs')

    # read command line parameters using node-optimist
    options = {
      h: { alias: 'help', boolean:true, describe: "Show help" }
      t: { alias: 'indent', describe:"Number of spaces per indent level. Use 0 to print on one line", default:2 }
      o: { alias: 'out', describe:"Name of file to write to, use '-'for STDOUT.", default:'-' }
      x: { alias: 'suffix', describe:"Extension to add to ouput files. Overrides --out.", default:null }
      r: { alias: 'rename', describe:"Regexp/String pair describing mapping between input and output filenames. Overrides --out and --suffix.", default:null }
    }
    argv = optimist.usage('Usage: $0 ... [FILE(S)]',options).argv
    # handle help
    if argv.help
      optimist.showHelp(errfn)
      callback()
    else
      # read input files or stdin using node-argf
      for f in argv._
        data = fs.readFileSync(f)
        code = "init(this)\n#{data}\nreturn to_json(#{argv.i})\n"
        json = eval(CoffeeScript.compile(code))
        if argv.r?
          matches = argv.r.match /^(\/.+\/),((".+\")|(\'.+\'))$/
          if not matches?[2]?
            errfn "Error parsing rename pair #{argv.r}"
            callback(1)
            return
          else
            rxp = eval(matches[1])
            str = eval(matches[2])
            argv.o = f.replace rxp,str
        else if argv.x?
          argv.o = f.replace /^(.+)($)/,"$1.#{argv.x}"
          # argv.o = "#{f}.#{argv.x}"
        if argv.o is '-'
          logfn json
        else
          fs.writeFileSync(argv.o,json)
      callback()
  finally
    process.argv = original_argv

if require.main is module
  _main()
