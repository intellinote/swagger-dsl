# This file contains a work-in-progress demonstration of the
# Swagger-2-supporting version of Swagger DSL.
# It is an attempt to recreate
#   http://petstore.swagger.io/v2/swagger.json
# in the Swagger-DSL format.

host "petstore.swagger.io"
title "Swagger Petstore"
version "1.0.0"

INFO
  title: "Swagger Petstore"
  version: "1.0.0"
  description: """
    This is a sample server Petstore server.  You can find out more about Swagger at
    [http://swagger.io](http://swagger.io) or on [irc.freenode.net, #swagger](http://swagger.io/irc/).
    For this sample, you can use the api key `special-key` to test the authorization filters.
  """
  license: Apache2
  contact: "apiteam@swagger.io"
  ToS: "http://swagger.io/terms/"

GET '/pet/findByStatus':
  summary: "Finds Pets by status"
  description: "Multiple status values can be provided with comma separated strings"
  parameters:
    status:["Status values that need to be considered for filter",query,required,[enum:['available','pending','sold']],default:'available',collectionFormat:'multi']
  responses:
    200:
      schema:
         type: array
         items:
           $ref: "#/definitions/Pet"
      description: "successful operation"
    400: "Invalid status value"
  security:
    petstore_auth: [ "write:pets", "read:pets" ]
  produces:[
    MIME.JSON
    MIME.XML
  ]
  consumes:[
    MIME.XML
    MIME.JSON
  ]
  tags: "pet"

PUT '/pet':
  summary: "Update an existing pet"
  parameters:
    body:[body,required,schema:{$ref:"#/definitions/Pet"},"Pet object that needs to be added to the store"]
  responses:
    400: "Invalid ID supplied"
    404: "Pet not found"
    405: "Validation exception"
  security:
    petstore_auth: [ "write:pets", "read:pets" ]
  consumes:[
    MIME.JSON
    MIME.XML
  ]
  tags: "pet"
  
POST '/pet':
  summary: "Add a new pet to the store"
  parameters:
    body:[body,required,schema:{$ref:"#/definitions/Pet"},"Pet object that needs to be added to the store"]
  responses:
    405: "Invalid input"
  produces: [
    MIME.JSON
    MIME.XML
  ]
  consumes: [
    MIME.JSON
    MIME.XML
  ]
  security:
    petstore_auth: [ "write:pets", "read:pets" ]
  tags: "pet"
  

GET '/pet/{petId}':
  summary: "Find pet by ID"
  parameters:
    body:[body,required,schema:{$ref:"#/definitions/Pet"},"Pet object that needs to be added to the store"]
  responses:
    400: "Invalid ID supplied"
    404: "Pet not found"
    200:
      description: "successful operation"
      schema:
        $ref: "#/definitions/Pet"
  security:
    api_key:[]
  produces: [
    MIME.JSON
    MIME.XML
  ]
  tags: "pet"
  
MODEL Category:
  id: int64
  name: string
