should     = require 'should'
fs         = require 'fs'
path       = require 'path'
HOMEDIR    = path.join(__dirname,'..')
LIB_COV    = path.join(HOMEDIR,'lib-cov')
LIB_DIR    = if fs.existsSync(LIB_COV) then LIB_COV else path.join(HOMEDIR,'lib')
SwaggerDSL = require(path.join(LIB_DIR,'swagger-dsl'))

# Note that the pattern of:
#
#     foo = SwaggerDSL({})
#
# used in the unit tests below is different than the
# typical way to use SwaggerDSL.  We're just doing that
# here to make it easy to create many DSL instances in
# a single file.  Typcially end-users will do something like:
#
#     require('swagger-dsl')(this)
#
# and then use the `MODEL`, `POST`, `GET`, etc methods directly.

describe 'SwaggerDSL',->

  it "can create model definitions using MODEL",(done)->
    dsl = SwaggerDSL({})
    dsl.MODEL "Foo":
      varOne:['int','required',"The first variable"]
      varTwo:['str']
      varThree:['required','float']
      varFour:["An array of strings",['string']]
    should.exist dsl.rest.models.Foo
    should.exist dsl.rest.models.Foo.properties
    should.exist dsl.rest.models.Foo.properties.varOne
    dsl.rest.models.Foo.properties.varOne.type.should.equal 'integer'
    dsl.rest.models.Foo.properties.varOne.required.should.equal true
    dsl.rest.models.Foo.properties.varOne.description.should.equal "The first variable"
    should.exist dsl.rest.models.Foo.properties.varTwo
    dsl.rest.models.Foo.properties.varTwo.type.should.equal 'string'
    dsl.rest.models.Foo.properties.varTwo.required.should.equal false
    should.exist dsl.rest.models.Foo.properties.varThree
    dsl.rest.models.Foo.properties.varThree.type.should.equal 'number'
    dsl.rest.models.Foo.properties.varThree.format.should.equal 'float'
    dsl.rest.models.Foo.properties.varThree.required.should.equal true
    should.exist dsl.rest.models.Foo.properties.varFour
    dsl.rest.models.Foo.properties.varFour.type.should.equal 'array'
    dsl.rest.models.Foo.properties.varFour.items.type.should.equal 'string'
    dsl.rest.models.Foo.properties.varFour.description.should.equal 'An array of strings'
    dsl.rest.models.Foo.properties.varFour.required.should.equal false
    done()

  it "can create operation definitions using GET",(done)->
    dsl = SwaggerDSL({})
    dsl.GET "/foo/bar":{}
    dsl.rest.apis[0].path.should.equal "/foo/bar"
    dsl.rest.apis[0].operations.length.should.equal 1
    dsl.rest.apis[0].operations[0].method.should.equal "GET"
    should.exist dsl.rest.apis[0].operations[0].nickname
    done()

  it "can add summary and notes to operations",(done)->
    dsl = SwaggerDSL({})
    dsl.GET "/foo/bar":
      summary:"This is the *summary*."
      notes:"**THESE** are the notes."
    # console.log dsl.to_json()
    # console.log JSON.stringify(dsl.rest)
    dsl.rest.apis[0].path.should.equal "/foo/bar"
    dsl.rest.apis[0].operations.length.should.equal 1
    dsl.rest.apis[0].operations[0].nickname.should.equal "get_foo_bar"
    dsl.rest.apis[0].operations[0].method.should.equal "GET"
    dsl.rest.apis[0].operations[0].summary.should.equal "This is the <em>summary</em>."
    dsl.rest.apis[0].operations[0].notes.should.equal "<p><strong>THESE</strong> are the notes.</p>"
    done()

  it "can add response codes to operations",(done)->
    dsl = SwaggerDSL({})
    dsl.POST "/foo/bar":
      responses:
        200:true
        201:'Resource inserted'
        403:[true,"string"]
    dsl.rest.apis[0].path.should.equal "/foo/bar"
    dsl.rest.apis[0].operations.length.should.equal 1
    dsl.rest.apis[0].operations[0].method.should.equal "POST"
    dsl.rest.apis[0].operations[0].responseMessages[0].code.should.equal '200'
    dsl.rest.apis[0].operations[0].responseMessages[0].message.should.equal 'OK'
    dsl.rest.apis[0].operations[0].responseMessages[1].code.should.equal '201'
    dsl.rest.apis[0].operations[0].responseMessages[1].message.should.equal 'Created; Resource inserted'
    dsl.rest.apis[0].operations[0].responseMessages[2].code.should.equal '403'
    dsl.rest.apis[0].operations[0].responseMessages[2].message.should.equal 'Forbidden'
    dsl.rest.apis[0].operations[0].responseMessages[2].responseModel.should.equal 'string'
    done()
