# Common base for PostmanDsl and SwaggerDsl

CoffeeScript = require('coffeescript')

class BaseDsl

  _bind_strings_to_global:(options)=>
    unless options?.strings is false
      @_prebound_globals ?= {}
      for k,v of {
        path      : 'path'
        query     : 'query'
        body      : 'body'

        optional  : 'optional'
        required  : 'required'

        nullable  : 'nullable'

        string    : 'string'
        string255 : 'string255'
        int       : 'int'
        integer   : 'integer'
        int16     : 'int16'
        int32     : 'int32'
        int64     : 'int64'
        array     : "array"
      }
        @_prebound_globals[k] = global[k] ? undefined
        global[k] = v
    return null


  _bind_to_global:(options)=>
    # console.log "_bind_to_global"
    @_prebound_globals ?= {}
    for name, value of @
      if /^[A-Z][A-Z0-9_]*$/.test(name)
        @_prebound_globals[name] = global[name] ? undefined
        global[name] = value
    @_bind_strings_to_global(options)
    return null

  _unbind_to_global:()=>
    if @_prebound_globals?
      for name, value of @_prebound_globals
        if value is undefined
          delete global[name]
        else
          global[name] = value
      @_prebound_globals = null
    return null

  _is_object:(val)->
    return val? and typeof val is 'object' and val.constructor is Object

  _init:(options)=>
    @_root = {}
    return @_root

  _eval_in_context:(code, options)=>
    # console.log "EVALUATING", code
    if code?
      compiled = CoffeeScript.compile(code)
      wrapped = (js)=>
        @_bind_to_global()
        eval(js)
        @_unbind_to_global()
        return @_root
      wrapped(compiled)
    return @_root

  _before_eval:(options)=>@_root
  _after_eval:(options)=>
    # console.error "options.debug is", options?.debug, options
    unless options?.debug
      delete @_root._tmp
    return @_root

  _process:(input_data_list, options)=>
    @_init(options)
    @_before_eval(options)
    @_eval_in_context(input_data_list.join("\n"),options)
    @_after_eval(options)
    # return JSON.stringify(@_root,null,2)
    return @_stringify_json(@_root, options)

  _stringify_json:(obj, options)=>
    if (options?.pretty) or (options is true)
      return JSON.stringify(obj,null,2)
    else
      return JSON.stringify(obj)

  _parse_generic_resource:(map)=>
    resource_name = Object.keys(map)[0]
    if map[resource_name].extends?
      resource = @_extends_generic_resource resource_name, map[resource_name].extends, map[resource_name]
    else
      resource = { }
      resource_type = Object.keys(map[resource_name])[0]
      switch resource_type
        when "array"
          resource.type = "array"
          resource.items = map[resource_name].array
        when "object"
          resource.type = "object"
          resource.properties = {}
          for prop_name, prop_info of map[resource_name].object
            resource = @_parse_generic_resource_attribute_array(resource, prop_name, prop_info)
    if resource_name? and resource?
      resource.resource_name = resource_name
      @_root._tmp ?= {}
      @_root._tmp.resources ?= {}
      @_root._tmp.resources[resource_name] = resource
    return resource

  _extends_generic_resource:(resource_name, parent_resource_name, resource_attr)=>
    parent_resource = @_root._tmp?.resources?[parent_resource_name]
    if parent_resource
      resource = JSON.parse(JSON.stringify(parent_resource))
      resource.properties = {}
      if resource_attr.requires?
        resource.required = resource_attr.requires
        for prop_name in resource_attr.requires
          resource.properties[prop_name] = parent_resource.properties[prop_name]
      if resource_attr.contains?
        for prop_name in resource_attr.contains
          resource.properties[prop_name] = parent_resource.properties[prop_name]
      if resource_attr.adds?
        for prop_name, prop_info of resource_attr.adds
          resource = @_parse_generic_resource_attribute_array(resource, prop_name, prop_info)
    return resource

  _parse_generic_resource_attribute_array:(resource, prop_name, prop_info)=>
    resource ?= {}
    resource.properties ?= {}
    resource.properties[prop_name] ?= {}
    for elt in prop_info
      if elt is "required"
        resource.required ?= []
        resource.required.push prop_name
      else
        prop_as_schema = @_keyword_string_or_ref_to_schema(elt)
        if prop_as_schema?
          for k, v of prop_as_schema
            resource.properties[prop_name][k] = v
        else
          if typeof elt is "string"
            resource.properties[prop_name].description = elt
          else if @_is_object(elt)
            for k, v of elt
              resource.properties[prop_name][k] = v
              if k is "enum"
                resource.properties[prop_name].type ?= "string"
    return resource

  _map_to_generic_parameters:(map)=>
    params = []
    for name, values of map
      param = {}
      param.name = name
      if Array.isArray(values)
        for value in values
          switch value
            #
            when 'path'
              param.in = 'path'
            when 'query','querystring','qs'
              param.in = 'query'
            when 'body'
              param.in = 'body'
            #
            when 'required'
              param.required = true
            when 'optional'
              param.required = false
            #
            when 'nullable'
              param.nullable = true
            #
            else
              if @_is_object(value)
                if value.pm_value?
                  param.pm_value = value.pm_value
              #
              schema = @_keyword_string_or_ref_to_schema(value)
              if schema?
                param.schema = schema
              #
              else
                if typeof value is "string"
                  param.description = value
                else if typeof value is 'object' and Object.keys(value).length is 1
                  for k,v of value
                    param[k] = v
      params.push param
    return params

  _keyword_string_or_ref_to_schema:(keyword)=>
    schema = null
    if @_is_object(keyword) and Object.keys(keyword)[0] is "$ref"
      schema = keyword
    else if @_is_object(keyword) and Object.keys(keyword)[0] is "array"
      schema = {
        type: "array"
        items: keyword.array
      }
    else if typeof keyword is "string"
      switch keyword
        when 'float','double'
          schema = {
            type: "number"
            format: keyword
          }
        when 'int','integer'
          schema = {
            type: "integer"
            format: keyword
          }
        when 'int16','int32','int64','long'
          schema = {
            type: "integer"
            format: keyword
          }
        when 'boolean'
          schema = {
            type: keyword
          }
        when 'str','string'
          schema = {
            type: 'string'
          }
        when 'str255','string255'
          schema = {
            type: 'string'
            maxLength: 255
          }
    return schema

  _list_to_generic_request_body:(list)=>
    body = {}
    unless Array.isArray(list)
      list = [list]
    for elt in list
      if typeof elt is "string"
        switch elt
          when "required"
            body.required = true
          when "optional"
            body.required = false
          when 'nullable'
            body.nullable = true
          else
            body.description = elt
      else if @_is_object(elt)
        content_type = Object.keys(elt)[0]
        switch content_type
          when "json","application/json"
            body.content ?= {}
            body.content["application/json"] = {
              schema: elt[content_type]
            }
          else
            body.content ?= {}
            body.content[content_type] = {
              schema: elt[content_type]
            }
    return body


  _map_to_generic_responses:(map)=>
    responses = {}
    for status_code, values of map
      response = {}
      unless Array.isArray(values)
        values = [values]
      for value in values
        if typeof value is "string"
          response.description = value
        else if @_is_object(value)
          for key, subval of value
            switch key
              when "json","application/json"
                response.content ?= {}
                response.content["application/json"] = {
                  schema: subval
                }
              when "headers"
                response.headers ?= {}
                for header_name, header_info of subval
                  response.headers[header_name] ?= {}
                  for info_val in header_info
                    schema = @_keyword_string_or_ref_to_schema(info_val)
                    if schema?
                      response.headers[header_name].schema = schema
                    else if typeof info_val is "string"
                      response.headers[header_name].description = info_val
      responses[status_code] = response
    return responses

  API_TITLE:(x)=>@_root
  API_DESCRIPTION:(val)=>@_root
  API_POSTMAN_ID:(val)=>@_root
  API_LICENSE:(val)=>@_root

  SERVERS:(urls...)=>@_root
  SERVER:(urls...)=>@SERVERS(urls...)


  TAG:(name, description)=>
    if @_is_object(name) and not description?
      for n, v of name
        @_INNER_TAG(n,v)
    else
      @_INNER_TAG(name, description)
    return @_root

  TAGS:(args...)=>@TAG(args...)

  _INNER_TAG:(name, description)=>
    return @_root

  # happens to be the same for both swagger and postman
  API_VERSION:(val)=>
    @_root.info ?= {}
    @_root.info.version = val
    return @_root

  RESOURCE:(map)=>@_root

  GET:(map)=>@_http_method('get',map)
  PUT:(map)=>@_http_method('put',map)
  POST:(map)=>@_http_method('post',map)
  PATCH:(map)=>@_http_method('patch',map)
  DELETE:(map)=>@_http_method('delete',map)
  OPTIONS:(map)=>@_http_method('options',map)
  _http_method:(http_method, map)=>@_root

exports.BaseDsl = BaseDsl
