# swagger-dsl syntax

<!-- toc -->

## Operations

To generate an operation descriptor (an element of the `apis` array in the JSON document), we use an HTTP verb (method) followed by the path and a collection of options or attributes that futher specify the operation.

For example, a minimal API method can be defined by:

```coffeescript
GET '/path':{}
```

Typically howwever, rather than an empty map (`{}`), the method declaration will be followed by a YAML-like list of properities, as in this more complete example:.

```coffeescript
POST '/team/{team_id}/member':
  summary:'Add a new member (user) to a team.'
  returns:'ObjectIdentifier'
  parameters:
    team_id:[path,int,required]
    user:[body,required,type:'UserModel']
    role:[query,enum:['admin','member','guest'],string,default:'member']
  produces:json
  consumes:json
  response:
    201:'Member created and added to team, identifier in response body'
    401:[true,'ErrorResponse']
    403:[true,'ErrorResponse']
    404:'Specified team not found (or not accessible)'
    415:true
  authorization:
    oauth2:
      read:'Read content within your account.'
      write:'Create new or modify existing content within your account.'
```

Each parameter is discussed in more detail below.

### notes, summary

The `notes` and `summary` parameters map to strings that will be used to generate the corresponding Swagger Specification attributes.

The contents of each string will be interpreted as a [Markdown](http://daringfireball.net/projects/markdown/) document.

Note that since Swagger DSL files are just a special case of CoffeeScript files, you can take advantage of CoffeeScript features such as multi-line strings when writing your descriptor.

For example:

```coffeescript
POST '/team/{team_id}/member':
  summary:'Add a new member (user) to a team.'
  notes:"""
    ## Lorem ipsum

    Dolor sit amet, consectetur *adipiscing* elit.

    Vivamus suscipitt [incidunt augue](http://example.com/),
    ac malesuada `tortor` dapibus ut.
  """
```

which generates:

```json
{
  "apis": [
    {
      "path": "/team/{team_id}/member",
      "operations": [
        {
          "summary": "Add a new member (user) to a team.",
          "notes": "<h2 id=\"lorem-ipsum\">Lorem ipsum</h2>\n<p>Dolor sit amet, consectetur <em>adipiscing</em> elit.</p>\n<p>Vivamus suscipitt <a href=\"http://example.com/\">incidunt augue</a>,\nac malesuada <code>tortor</code> dapibus ut.</p>",
          "method": "POST",
          "nickname": "post__team__team_id__member"
        }
      ]
    }
  ]
}
```

### parameters

*TODO: fill in details here*

```coffeescript
POST '/team/{team_id}/member':
  parameters:
    team_id:[path,int,required]
    user:[body,required,type:'UserModel']
    role:[query,enum:['admin','member','guest'],string,default:'member']
```

which generates:

```json
{
  "apis": [
    {
      "path": "/team/{team_id}/member",
      "operations": [
        {
          "parameters": [
            {
              "name": "team_id",
              "paramType": "path",
              "type": "integer",
              "required": true,
              "format": "string"
            },
            {
              "name": "user",
              "paramType": "body",
              "required": true,
              "type": "UserModel",
              "format": "string"
            },
            {
              "name": "role",
              "paramType": "query",
              "enum": [
                "admin",
                "member",
                "guest"
              ],
              "type": "string",
              "default": "member",
              "required": false,
              "format": "string"
            }
          ],
          "method": "POST",
          "nickname": "post__team__team_id__member"
        }
      ]
    }
  ]
}
```

### returns, produces, consumes

*TODO: fill in details here*

```coffeescript
GET '/team/{team_id}/member/{user_id}':
  returns:'UserModel'
  produces: json

DELETE '/team/{team_id}/member/{user_id}':
  returns: VOID

GET '/team/{team_id}/members':
  returns:[ref:'UserModel']
  produces: 'application/json'
```

which generates:

```json
{
  "apis": [
    {
      "path": "/team/{team_id}/member/{user_id}",
      "operations": [
        {
          "type": "UserModel",
          "produces": [
            "application/json"
          ],
          "method": "GET",
          "nickname": "get__team__team_id__member__user_id_"
        },
        {
          "type": "void",
          "method": "DELETE",
          "nickname": "delete__team__team_id__member__user_id_"
        }
      ]
    },
    {
      "path": "/team/{team_id}/members",
      "operations": [
        {
          "type": "array",
          "items": {
            "$ref": "UserModel"
          },
          "produces": [
            "application/json"
          ],
          "method": "GET",
          "nickname": "get__team__team_id__members"
        }
      ]
    }
  ]
}
```

### response

*TODO: fill in details here*

```coffeescript
standard_responses
  200:true
  401:['User or application must authenticate','ErrorMessage']
  403:[true,'ErrorMessage']
  404:true

GET '/team/{team_id}/member/{user_id}':
  responses:{}

POST '/team/{team_id}/member':
  response:
    200:false
    201:'Member created and added to team, identifier in response body'
    415:'Parsing error while reading user from request body'
```

which generates:

```json
{
  "apis": [
    {
      "path": "/team/{team_id}/member/{user_id}",
      "operations": [
        {
          "responseMessages": [
            {
              "code": "200",
              "message": "OK"
            },
            {
              "code": "401",
              "message": "Unauthorized; User or application must authenticate",
              "responseModel": "ErrorMessage"
            },
            {
              "code": "403",
              "message": "Forbidden",
              "responseModel": "ErrorMessage"
            },
            {
              "code": "404",
              "message": "Not Found"
            }
          ],
          "method": "GET",
          "nickname": "get__team__team_id__member__user_id_"
        }
      ]
    },
    {
      "path": "/team/{team_id}/member",
      "operations": [
        {
          "responseMessages": [
            {
              "code": "201",
              "message": "Created; Member created and added to team, identifier in response body"
            },
            {
              "code": "401",
              "message": "Unauthorized; User or application must authenticate",
              "responseModel": "ErrorMessage"
            },
            {
              "code": "403",
              "message": "Forbidden",
              "responseModel": "ErrorMessage"
            },
            {
              "code": "404",
              "message": "Not Found"
            },
            {
              "code": "415",
              "message": "Unsupported Media Type; Parsing error while reading user from request body"
            }
          ],
          "method": "POST",
          "nickname": "post__team__team_id__member"
        }
      ]
    }
  ]
}
```
