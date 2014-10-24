marked = require 'meta-marked'
assign = ()->

  this.rest = { }
  this.rest.swaggerVersion = '1.2'
  this.rest.apis = []
  this.rest.models = {}

  this.path      = 'path'
  this.query     = 'query'
  this.body      = 'body'

  this.json      = 'application/json'
  this.multipart_form_data      = 'multipart/form-data'
  this.html      = 'text/html'
  this.text      = 'text/plain'
  this.xml       = 'application/xml'
  this.octet_stream  = 'application/octet-stream'
  this.binary_data  = 'application/octet-stream'

  this.int       = 'integer'
  this.integer   = 'integer'
  this.long      = 'long'
  this.float     = 'float'
  this.double    = 'double'
  this.boolean   = 'boolean'
  this.date      = 'date'
  this.datetime  = 'date-time'
  this.dateTime  = 'date-time'
  this.datetime  = 'date-time'
  this.date_time = 'date-time'
  this.boolean   = 'boolean'
  this.string    = 'string'
  this.array     = 'array'
  this.ref       = '$ref'
  this.VOID      = 'void'
  this.int32     = 'int32'
  this.int64     = 'int64'
  this.array     = 'array'
  this.byte      = 'byte'
  this.required  = 'required'

  this.swagger_version = this.swaggerVersion = this.swaggerversion = (ver)=>
    rest.swaggerVersion = "#{ver}"

  this.version = this.api_version = this.apiVersion= this.apiversion = (ver)=>
    rest.apiVersion = "#{ver}"

  this.base = this.basepath = this.base_path = this.basePath = (path)=>
    rest.basePath = path

  this.default_responses = this.defaultresponses = (map)=>
    this._default_responses = map

  this.status_codes =
    200:'OK'
    201:'Created'
    204:'No Content'
    401:'Unauthorized; User or application must authenticate'
    403:'Forbidden; User or applicaton is not allowed to take this action'
    404:'Not Found'
    405:'Method Not Allowed'
    409:'Conflict'
    415:'Unsupported Media Type'
    420:'Enhance Your Calm; API rate limit exceeded'
    422:'Unprocessable Entity'
    429:'Too Many Requests; API count limit exceeded'
    500:'Server Error'

  this.map_to_model = (map)=>
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
      prop.required ?= false
      if prop.items?.ref? and not prop.items?['$ref']?
        prop.items['$ref'] = prop.items.ref
        delete prop.items.ref
      if prop.ref? and not prop?['$ref']?
        prop['$ref'] = prop.ref
        delete prop.ref
      model.properties[prop_name] = prop
    return model

  this.markdown_to_html = (str,strip_p=false)=>
    if str?
      str = (marked(str,{}))?.html
      str = str?.trim()
      if strip_p and /^<p>(.*)<\/p>$/.test str
        str = str.substring(3,str.length-4)
    return str

  this.map_to_parameters = (map)=>
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
      param.required ?= false
      param.format ?= 'string'
      params.push param
    return params

  this.map_to_authorizations = (map)=>
    auths = {}
    for type,scopes of map
      auth = {}
      auth.type = type
      auth.scopes = []
      for scope,description of scopes
        auth.scopes.push {scope:scope,description:description}
        auths[type] = auth
    return auths

  this.map_to_responses = (map,defaults={})=>
    responses = []
    map_keys = Object.keys(map)
    default_keys = Object.keys(defaults)
    for code,message of defaults
      if code in map_keys
        if Array.isArray(map[code])
          map_msg = map[code][0]
          map_model = map[code][1]
        else
          map_msg = map[code]
          map_model = null
        if not map_msg? or not map_msg
          # skip it when set to null or false
        else
          message = "#{message}; #{map_msg}"
          message = markdown_to_html(message,true)
          response = { code:code, message:message }
          if map_model?
            response.responseModel = map_model
          responses.push response
      else
        responses.push { code:code, message:message }
    for code,message of map
      unless code in default_keys
        unless not message? or not message
          if status_codes[code]?
            if Array.isArray(message)
              model = message[1]
              message = message[0]
            if typeof message is 'boolean'
              message = status_codes[code]
            else
              message = "#{status_codes[code]}; #{message}"
          message = markdown_to_html(message,true)
          response = { code:code, message:message }
          if model?
            response.responseModel = model
            model = null
          responses.push response
    responses = responses.sort (a,b)->(a.code ? 0) - (b.code ? 0)
    return responses

  this.map_to_operation = (map)=>
    op = {}
    path = Object.keys(map)[0]
    for name,value of map[path]
      if value?
        switch name
          when 'summary','notes'
            op[name] = markdown_to_html(value,(name is 'summary'))
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
            op.responseMessages = map_to_responses(value,_default_responses)
          when 'parameters'
            op.parameters = map_to_parameters(value)
          when 'authorization','authorizations'
            if value.oauth2?
              op.authorizations = map_to_authorizations(value)
          else
            op[name] = value

    return [path,op]

  this.alphanumerify = (str,replacement='_')=>str.replace(/[^A-Za-z0-9]/g,replacement)

  this.add_model = (name,map)->
    map = map_to_model(map)
    map.id ?= name
    rest.models[name] = map

  this.MODEL = (map)->
    for name,props of map
      add_model(name,props)

  this.add_op = (path,op)->
    for elt in rest.apis
      if elt?.path is path
        elt.operations ?= []
        elt.operations.push op
        return
    rest.apis.push {path:path,operations:[op]}

  this.api_method = (method,map)->
    [path,op] = map_to_operation(map)
    op.method = method
    op.nickname ?= alphanumerify "#{method.toLowerCase()}-#{path}"
    add_op(path,op)

  this.GET = (map)->api_method('GET',map)
  this.POST = (map)->api_method('POST',map)
  this.PUT = (map)->api_method('PUT',map)
  this.DELETE = (map)->api_method('DELETE',map)

module.exports = assign
