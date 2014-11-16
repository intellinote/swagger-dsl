marked = require 'marked'

# "private" (not-exported) methods
_clone = (a)->
  b = {}
  for k,v of a
    b[k] = v
  return b

_merge = (a,b)->
  c = _clone(a)
  for k,v of b
    c[k] = v
  return c

_remove_falsey = (a)->
  for k,v of a
    unless v
      delete a[k]
  return a

_alphanumerify = (str,replacement='_')=>str.replace(/[^A-Za-z0-9]/g,replacement)

_markdown_to_html = (str,strip_p=false)=>
  if str?
    str = (marked(str,{}))
    str = str?.trim()
    if strip_p and /^<p>(.*)<\/p>$/.test str
      str = str.substring(3,str.length-4)
  return str

# **_map_to_responses** generates the `responses` attribute
# of the Swagger document based on `status_codes`, the given
# `map` and the given `defaults`.
_map_to_responses = (map,defaults={},status_codes={})=>
  responses = []
  input = _remove_falsey(_merge(defaults,map))
  for code,v of input
    response = { code:code }
    if typeof v is 'string'
      response.message = v
    else if Array.isArray(v)
      response.message = v[0]
      response.responseModel = v[1]
    else if typeof v is 'object'
      response = _merge(response,v)
    if typeof response.message is 'string' and response.message?.length > 0 and status_codes[code]?.length > 0
      response.message = "#{status_codes[code]}; #{response.message}"
    else if status_codes[code]?.length > 0
      response.message = status_codes[code]
    responses.push response
  responses = responses.sort (a,b)->(a.code ? 0) - (b.code ? 0)
  return responses

_map_to_model = (map)->
  model = {}
  model.properties = {}
  for prop_name,values of map
    prop = {}
    if Array.isArray(values)
      for value in values
        switch value
          when 'required'
            prop.required= true
          when 'float','double'
            prop.type = 'number'
            prop.format = value
          when 'boolean','string','integer','date'
            prop.type = value
          when 'int'
            prop.type = 'integer'
          when 'str'
            prop.type = 'string'
          when 'datetime','date-time','dateTime'
            prop.type = 'string'
            prop.format = 'date-time'
          when 'int64','int32','long'
            prop.format = value
            prop.type = 'integer'
          when 'array'
            prop.type = 'array'
          else
            if Array.isArray(value)
              prop.type = 'array'
              if typeof value[0] is 'object'
                prop.items = value[0]
              else
                prop.items = {type:value[0]}
            else if typeof value is 'object'
              for k,v of value
                prop[k] = v
            else
              prop.description = value
    else
      for attr,value of values
        prop[attr] = value
    prop.description =  _markdown_to_html(prop.description,true)
    prop.required ?= false
    if prop.items?.ref? and not prop.items?['$ref']?
      prop.items['$ref'] = prop.items.ref
      delete prop.items.ref
    if prop.ref? and not prop?['$ref']?
      prop['$ref'] = prop.ref
      delete prop.ref
    model.properties[prop_name] = prop
  return model

_map_to_operation = (map)->
  op = {}
  path = Object.keys(map)[0]
  for name,value of map[path]
    if value?
      switch name
        when 'summary','notes'
          op[name] = _markdown_to_html(value,(name is 'summary'))
        when 'returns','type'
          if Array.isArray(value)
            op.type = 'array'
            op.items = value[0]
            if op.items.ref? and not op.items['$ref']?
              op.items['$ref'] = op.items.ref
              delete op.items.ref
          else
            op.type = value
        when 'produces','consumes'
          unless Array.isArray(value)
            value = [value]
          op[name] = value
        when 'nickname','deprecated'
          op[name] = value
        when 'response','responses','responseMessages'
          op.responseMessages = _map_to_responses(value,_standard_responses ? {}, status_codes)
        when 'parameters'
          op.parameters = _map_to_parameters(value)
        when 'authorization','authorizations'
          if value.oauth2?
            op.authorizations = _map_to_authorizations(value)
        else
          op[name] = value
  return [path,op]

_map_to_parameters = (map)->
  params = []
  for name,values of map
    param = {}
    param.name = name
    if Array.isArray(values)
      for value in values
        switch value
          when 'path'
            param.paramType = 'path'
          when 'query','querystring','qs'
            param.paramType = 'query'
          when 'body'
            param.paramType = 'body'
          when 'required'
            param.required= true
          when 'float','double'
            param.type = 'number'
            param.format = value
          when 'int','integer'
            param.type = 'integer'
          when 'int32','int64','long'
            param.type = 'integer'
            param.format = value
          when 'boolean','string'
            param.type = value
          when 'str'
            param.type = 'string'
          when 'date_time','datetime','dateTime'
            param.type = 'string'
            param.format = 'date-time'
          when 'date'
            param.type = 'string'
            param.format = 'date'
          else
            if typeof value is 'object' and Object.keys(value).length is 1
              for k,v of value
                param[k] = v
            else
              param.defaultValue = value
    else
      for attr,value of values
        switch attr
          when /(param-?)?type/i
            param.paramType = value
          when /(allow-?)?multiple/i
            param.allowMultiple = value
          else
            param[attr] = value
    param.description =  _markdown_to_html(param.description,true)
    param.required ?= false
    param.format ?= 'string'
    params.push param
  return params

_map_to_authorizations = (map)->
  auths = {}
  for type,scopes of map
    x = []
    for scope,description of scopes
      description = _markdown_to_html(description,true)
      x.push {scope:scope,description:description}
    auths[type] = x
    # auth.type = type
    # auth.scopes = []
    # for scope,description of scopes
    #   description = _markdown_to_html(description,true)
    #   auth.scopes.push {scope:scope,description:description}
    #   auths[type] = auth
  return auths

init = (self,options)->

  # The root SwaggerUI document we are creating.
  this.rest = { }
  this.rest.apis = []
  this.rest.models = {}
  this.rest.swaggerVersion = '1.2'

  # **swagger_version(ver)** sets the document's `swaggerVersion` property.
  this.swagger_version = this.swaggerVersion = this.swaggerversion = (ver)=>
    rest.swaggerVersion = "#{ver}"

  # **api_version(ver)** sets the document's `apiVersion` property.
  this.version = this.api_version = this.apiVersion= this.apiversion = (ver="1.0")=>
    rest.apiVersion = "#{ver}"

  # **base(path)** sets the document's `basePath` property.
  this.base = this.basepath = this.base_path = this.basePath = (path)=>
    rest.basePath = path


  # For "convenience", we add variables containing the string version of
  # their name, so that (for exapmle) we can use the token `string` rather than
  # `"string"` with the DSL.
  unless options?.strings is false
    # `paramType` values
    this.path                = 'path'
    this.query               = 'query'
    this.body                = 'body'

    # MIME-types
    this.json                = 'application/json'
    this.multipart_form_data = 'multipart/form-data'
    this.html                = 'text/html'
    this.text                = 'text/plain'
    this.xml                 = 'application/xml'
    this.octet_stream        = 'application/octet-stream'
    this.binary_data         = 'application/octet-stream'

    # `type` and `format` values
    this.int                 = 'integer'
    this.integer             = 'integer'
    this.long                = 'long'
    this.float               = 'float'
    this.double              = 'double'
    this.boolean             = 'boolean'
    this.date                = 'date'
    this.datetime            = 'date-time'
    this.dateTime            = 'date-time'
    this.datetime            = 'date-time'
    this.date_time           = 'date-time'
    this.boolean             = 'boolean'
    this.string              = 'string'
    this.array               = 'array'
    this.VOID                = 'void'
    this.int32               = 'int32'
    this.int64               = 'int64'
    this.array               = 'array'
    this.byte                = 'byte'

    # other
    this.required            = 'required'
    this.ref                 = '$ref'

  #-------------------------------------------------------------------

  # ## Status/Response Code Management

  # **status_codes** is just a map of HTTP status codes
  # and messages.
  this.status_codes = options?.status_codes ?
    200:'OK'
    201:'Created'
    204:'No Content'
    400:'Bad Request'
    401:'Unauthorized' #; User or application must authenticate'
    402:'Payment Required'
    403:'Forbidden'# ; User or applicaton is not allowed to take this action'
    404:'Not Found'
    405:'Method Not Allowed'
    406:'Not Acceptable'
    409:'Conflict'
    412:'Precondition Failed'
    415:'Unsupported Media Type'
    420:'Enhance Your Calm' #; API rate limit exceeded'
    422:'Unprocessable Entity'
    429:'Too Many Requests' #; API count limit exceeded'
    500:'Internal Server Error'
    502:'Gateway Error'
    503:'Service Unavailable'

  # **standard_responses** contains a collecion of status codees
  # and messages that will be added (by default) to the
  # `responses` part of each operation.
  #
  # To override (remove) one of the standard respones on a
  # particular operation, map the status code to something falsey.
  this.standard_responses = this.standardresponses = (map)=>
    this._standard_responses = map

  #-------------------------------------------------------------------

  # ## Models

  this._add_model = (name,map)->
    map = _map_to_model(map)
    map.id ?= name
    rest.models[name] = map

  this.MODEL = (map)->
    for name,props of map
      _add_model(name,props)

  this._add_operation = (path,op)->
    for elt in rest.apis
      if elt?.path is path
        elt.operations ?= []
        elt.operations.push op
        return
    rest.apis.push {path:path,operations:[op]}

  #-------------------------------------------------------------------

  # ## Operations

  this.GET     = (map)->api_method('GET',map)
  this.POST    = (map)->api_method('POST',map)
  this.PUT     = (map)->api_method('PUT',map)
  this.DELETE  = (map)->api_method('DELETE',map)
  this.PATCH   = (map)->api_method('PATCH',map)
  this.HEAD    = (map)->api_method('HEAD',map)
  this.OPTIONS = (map)->api_method('OPTIONS',map)

  this.api_method = (method,map)->
    [path,op] = _map_to_operation(map)
    op.method = method
    op.nickname ?= _alphanumerify "#{method.toLowerCase()}-#{path}"
    _add_operation(path,op)

  #-------------------------------------------------------------------

  this.to_json = (spaces=2)->JSON.stringify(rest,null,spaces)

  #-------------------------------------------------------------------

  return this


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
  callback ?= process?.exit ? (()->)
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
      for file in argv._
        data = fs.readFileSync(file)
        code = "init(this)\n#{data}\nreturn to_json(#{argv.i})\n"
        json = eval(CoffeeScript.compile(code))
        if argv.r?
          matches = argv.r.match /^(\/.+\/),((".+\")|(\'.+\'))$/
          if not matches?[2]?
            errfn "Error parsing rename pair #{argv.r}"
            callback(1)
            return
          else
            regexp = eval(matches[1])
            string = eval(matches[2])
            argv.o = file.replace regexp,string
        else if argv.x?
          argv.o = file.replace /^(.+)($)/,"$1.#{argv.x}"
          # argv.o = "#{file}.#{argv.x}"
        if argv.o is '-'
          logfn json
        else
          fs.writeFileSync(argv.o,json)
      callback()
  finally
    process.argv = original_argv

module.exports = init

if require.main is module
  _main()
