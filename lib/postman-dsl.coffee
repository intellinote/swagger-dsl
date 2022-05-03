# EXPERIMENTAL - Generates Postman Collection (v2.1) files

BaseDsl = require("./base-dsl").BaseDsl

class PostmanDsl extends BaseDsl

  _init:(options)=>
    super(options)
    @_root.info = { schema: "https://schema.getpostman.com/json/collection/v2.1.0/collection.json" }
    return @_root

  API_TITLE:(val)=>
    @_root.info.name = val
    return @_root

  API_POSTMAN_ID:(val)=>
    @_root.info._postman_id = val
    return @_root

  API_DESCRIPTION:(val)=>
    @_root.info.description = val
    return @_root

  # TODO
  _INNER_TAG:(name, description)=>
    @_root._tmp ?= {}
    @_root._tmp.tags ?= {}
    @_root._tmp.tags[name] ?= {}
    @_root._tmp.tags[name].description = description
    return @_root

  RESOURCE:(map)=>
    @_parse_generic_resource(map)
    return @_root

  __break_down_path:(str)=>
    result = []
    if str?
      for part in str.split(/\//)
        unless part is ''
          if /^\{.+\}$/.test part
            result.push ":" + part.substring(1, part.length - 1)
          else
            result.push part
    return result

  __example_val_from_schema:(schema)=>
    switch schema?.type
      when "string"
        return "a string"
      when "integer"
        return "0"
      when "number"
        return "0.0"
      when "boolean"
        return "true"
      else
        return null

  __generic_param_to_postman_param:(generic_param)=>
    if generic_param?
      pm_param = {}
      pm_param.key = generic_param.name
      pm_param.value = generic_param.pm_value ? generic_param.example ? @__example_val_from_schema(generic_param.schema) ? null
      pm_param.description = generic_param.description ?  null
      #
      if generic_param.required
        if generic_param.in is "path"
          if pm_param.description?
            pm_param.description = "(Required) #{pm_param.description}"
          else
            pm_param.description = "(Required)"
      else if generic_param.in is "query"
        pm_param.disabled = true
      #
      return pm_param

  _http_method:(http_method, map)=>
    HTTP_METHOD = http_method.toUpperCase()
    item = {}
    item.request = {}
    item.request.method = HTTP_METHOD
    path = Object.keys(map)[0]
    item.request.url = {}
    item.request.url.raw = "{{baseUrl}}#{path}"
    item.request.url.host = [ "{{baseUrl}}" ]
    item.request.url.path = @__break_down_path(path)
    item.request.url.raw = "{{baseUrl}}/#{item.request.url.path.join('/')}"
    #
    if map[path].SUMMARY?
      item.name = map[path].SUMMARY
    if map[path].DESCRIPTION?
      item.description = map[path].DESCRIPTION
    #
    if map[path].PARAMETERS?
      params = @_map_to_generic_parameters(map[path].PARAMETERS)
      for param in params
        pm_param = @__generic_param_to_postman_param(param)
        if pm_param?
          if param.in is "path"
            item.request.url.variable ?= []
            item.request.url.variable.push pm_param
          else if param.in is "query"
            item.request.url.query ?= []
            item.request.url.query.push pm_param
    if map[path].REQUEST_BODY?
      generic_request_body = @_list_to_generic_request_body(map[path].REQUEST_BODY)
      if generic_request_body?
        item._generic_request_body = generic_request_body
    if map[path].RESPONSES?
      generic_responses  = @_map_to_generic_responses(map[path].RESPONSES)
      if generic_responses?
        item._generic_responses = generic_responses
    #
    @_root._tmp ?= {}
    @_root._tmp.methods ?= {}
    @_root._tmp.methods[path] ?= {}
    @_root._tmp.methods[path][item.request.method] = item
    #
    return @_root

  __generic_request_body_to_postman_request_body:(generic_body)=>
    if generic_body?
      pm_body = {}
      pm_body.mode = "raw"
      if generic_body.content?["application/json"]?
        pm_body.options = {
          raw: {
            language: "json"
          }
        }
      if generic_body.content?["application/json"]?.schema?.$ref?
        generic_resource = @_root._tmp?.resources?[generic_body.content?["application/json"]?.schema?.$ref]
        if generic_resource?
          eg = @__generic_resource_to_pm_example(generic_resource)
          if eg?
            pm_body.raw = eg
      return pm_body
    else
      return null

  __generic_responses_to_postman_responses:(generic_response_map, parent_request)=>
    pm_responses = []
    for generic_sc, generic_info of generic_response_map
      # console.error "GENERIC RESPONSE", generic_sc, JSON.stringify(generic_info)
      # GENERIC RESPONSE 200 {"description":"OK","content":{"application/json":{"schema":{"$ref":"AddressBook"}}}}
      pm_response = { code:parseInt(generic_sc) }
      if generic_info.description?
        pm_response.name = generic_info.description
      if generic_info.content?["application/json"]?
        pm_response.header ?= []
        pm_response.header.push { "Content-Type": "application/json" }
        pm_response._postman_previewlanguage = "json"
      else
        pm_response.header ?= []
        pm_response.header.push { "Content-Type": "text/plain" }
        pm_response._postman_previewlanguage = "text"
      if generic_info.content?["application/json"]?.schema?.$ref?
        generic_resource = @_root._tmp?.resources?[generic_info.content?["application/json"]?.schema?.$ref]
        if generic_resource?
          eg = @__generic_resource_to_pm_example(generic_resource)
          if eg?
            pm_response.body = eg
      if parent_request?
        pm_response.originalRequest = parent_request
      pm_responses.push pm_response
    return pm_responses


  _after_eval:(options)=>
    @_after_eval_methods_to_items()
    super(options)
    return @_root

  _after_eval_methods_to_items:()=>
    if @_root._tmp.methods?
      for path, methods of @_root._tmp.methods
        for http_method, pm_item of methods
          if pm_item._generic_request_body?
            pm_item.request.body = @__generic_request_body_to_postman_request_body(pm_item._generic_request_body)
            delete pm_item._generic_request_body
          if pm_item._generic_responses?
            pm_item.responses = @__generic_responses_to_postman_responses(pm_item._generic_responses, pm_item.request)
            delete pm_item._generic_responses
          @_root.item ?= []
          @_root.item.push pm_item
    return @_root

  __generic_resource_to_pm_example:(generic_resource)=>
    if generic_resource?.type is "object"
      example = {}
      for prop_name, prop_info of generic_resource.properties
        eg_val = prop_info.pm_value ? prop_info.example ? @__example_val_from_schema(prop_info.schema) ? null
        if eg_val?
          example[prop_name] = eg_val
      return JSON.stringify(example,null,2)
    else
      return null

exports.PostmanDsl = PostmanDsl
