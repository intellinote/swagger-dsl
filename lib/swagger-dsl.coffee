# Generates OpenAPI (Swagger) v3.x files

BaseDsl = require("./base-dsl").BaseDsl

class SwaggerDsl extends BaseDsl

  _pm_specific_attr_re: /^pm_/

  _is_pm_specific_attribute_name:(name)=>
    return @_pm_specific_attr_re.test(name)

  _strip_pm_specific_attributes:(map)=>
    for k,v of map
      if @_is_pm_specific_attribute_name(k)
        delete map[k]
    return map

  _recursive_strip_pm_specific_attributes:(map)=>
    for k,v of map
      if @_is_pm_specific_attribute_name(k)
        delete map[k]
      else if Array.isArray(v)
        map[k] = v.map (x)=>@_recursive_strip_pm_specific_attributes(x)
      else if @_is_object(v)
        map[k] = @_recursive_strip_pm_specific_attributes(v)
    return map

  _insert_$ref_prefix:(map)=>
    if map.$ref? and not /^#\/components\/schemas\//.test(map.$ref)
      map.$ref = "#/components/schemas/#{map.$ref}"
    return map

  _recursive_insert_$ref_prefix:(map)=>
    map = @_insert_$ref_prefix(map)
    for k,v of map
      if Array.isArray(v)
        map[k] = v.map (x)=>@_recursive_insert_$ref_prefix(x)
      else if @_is_object(v)
        map[k] = @_recursive_insert_$ref_prefix(v)
    return map

  _init:(options)=>
    super(options)
    @_root.openapi = "3.0.1"
    return @_root

  API_TITLE:(val)=>
    @_root.title = val
    return @_root

  API_LICENSE:(name, url)=>
    if name? or url?
      @_root.info ?= {}
      @_root.info.license = {}
      if name?
        @_root.info.license.name = name
      if url?
        @_root.info.license.url = url
    return @_root

  SERVERS:(urls...)=>
    if urls.length is 1 and Array.isArray(urls[0])
      urls = urls[0]
    if urls?.length > 0
      @_root.servers = urls.map (x)->{url:x}
    return @_root

  _INNER_TAG:(name, description)=>
    @_root.tags ?= []
    @_root.tags.push {
      name: name
      description: description
    }
    return @_root

  _http_method:(http_method, map)=>
    http_method = http_method.toLowerCase()
    path = Object.keys(map)[0]
    @_root.paths ?= {}
    @_root.paths[path] ?= {}
    @_root.paths[path][http_method] = {}
    if map[path].SUMMARY?
      @_root.paths[path][http_method].summary = map[path].SUMMARY
    if map[path].DESCRIPTION?
      @_root.paths[path][http_method].description = map[path].DESCRIPTION
    if map[path].ID?
      @_root.paths[path][http_method].operationId = map[path].ID
    #
    tags = map[path].TAGS ? map[path].TAG
    if tags?
      unless Array.isArray(tags)
        tags = [tags]
      @_root.paths[path][http_method].tags = tags
    #
    if map[path].PARAMETERS?
      @_root.paths[path][http_method].parameters  = @_map_to_generic_parameters(map[path].PARAMETERS)
      for elt in @_root.paths[path][http_method].parameters
        for k, v of elt
          if @_is_pm_specific_attribute_name(k)
            delete elt[k]
    if map[path].REQUEST_BODY?
      @_root.paths[path][http_method].requestBody  = @_list_to_generic_request_body(map[path].REQUEST_BODY)
    if map[path].RESPONSES?
      # @_root.paths[path][http_method].responses  = @_map_to_responses(map[path].RESPONSES)
      @_root.paths[path][http_method].responses  = @_map_to_responses(map[path].RESPONSES)
    #
    return @_root

  _map_to_responses:(map)=>
    responses = @_map_to_generic_responses(map)
    responses = @_recursive_insert_$ref_prefix(responses)
    return responses

  RESOURCE:(map)=>
    resource = @_parse_generic_resource(map)
    resource_name = resource.resource_name
    resource = @_recursive_strip_pm_specific_attributes(resource)
    resource = @_recursive_insert_$ref_prefix(resource)
    delete resource.resource_name
    @_root.components ?= {}
    @_root.components.schemas ?= {}
    @_root.components.schemas[resource_name] = resource
    return @_root

exports.SwaggerDsl = SwaggerDsl
