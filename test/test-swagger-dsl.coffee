should     = require 'should'
fs         = require 'fs'
path       = require 'path'
HOMEDIR    = path.join(__dirname,'..')
LIB_COV    = path.join(HOMEDIR,'lib-cov')
LIB_DIR    = if fs.existsSync(LIB_COV) then LIB_COV else path.join(HOMEDIR,'lib')
SwaggerDSL = require(path.join(LIB_DIR,'swagger-dsl'))

# Note that the pattern of:
#
#    dsl = {}
#    SwaggerDSL.apply(dsl)
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
    dsl = {}
    SwaggerDSL.apply(dsl)
    dsl.MODEL "Foo":
      varOne:['int','required',"The first variable"]
      varTwo:['str']
      varThree:['required','float']
      varFour:["An array of strings",['string']]

    should.exist dsl.rest.definitions.Foo
    should.exist dsl.rest.definitions.Foo.properties
    should.exist dsl.rest.definitions.Foo.properties.varOne
    dsl.rest.definitions.Foo.properties.varOne.type.should.equal 'integer'
    dsl.rest.definitions.Foo.properties.varOne.required.should.equal true
    dsl.rest.definitions.Foo.properties.varOne.description.should.equal "The first variable"
    should.exist dsl.rest.definitions.Foo.properties.varTwo
    dsl.rest.definitions.Foo.properties.varTwo.type.should.equal 'string'
    should.not.exist dsl.rest.definitions.Foo.properties.varTwo.required
    should.exist dsl.rest.definitions.Foo.properties.varThree
    dsl.rest.definitions.Foo.properties.varThree.type.should.equal 'number'
    dsl.rest.definitions.Foo.properties.varThree.format.should.equal 'float'
    dsl.rest.definitions.Foo.properties.varThree.required.should.equal true
    should.exist dsl.rest.definitions.Foo.properties.varFour
    dsl.rest.definitions.Foo.properties.varFour.type.should.equal 'array'
    dsl.rest.definitions.Foo.properties.varFour.items.type.should.equal 'string'
    dsl.rest.definitions.Foo.properties.varFour.description.should.equal 'An array of strings'
    should.not.exist dsl.rest.definitions.Foo.properties.varFour.required
    done()

  it "can create operation definitions using GET",(done)->
    dsl = {}
    SwaggerDSL.apply(dsl)
    dsl.GET "/foo/bar":{}
    dsl.rest.paths["/foo/bar"].should.be.ok
    dsl.rest.paths["/foo/bar"].get.should.be.ok
    dsl.rest.paths["/foo/bar"].get.method.should.equal "GET"
    dsl.rest.paths["/foo/bar"].get.operationId.should.be.ok
    done()

  it "can add summary and notes to operations",(done)->
    dsl = {}
    SwaggerDSL.apply(dsl)
    dsl.GET "/foo/bar":
      summary:"This is the *summary*."
      description:"**THESE** are the notes."
    dsl.rest.paths["/foo/bar"].should.be.ok
    dsl.rest.paths["/foo/bar"].get.should.be.ok
    dsl.rest.paths["/foo/bar"].get.method.should.equal "GET"
    dsl.rest.paths["/foo/bar"].get.operationId.should.equal "get_foo_bar"
    dsl.rest.paths["/foo/bar"].get.summary.should.equal "This is the <em>summary</em>."
    dsl.rest.paths["/foo/bar"].get.description.should.equal "<p><strong>THESE</strong> are the notes.</p>"
    done()

  it "can add response codes to operations",(done)->
    dsl = {}
    SwaggerDSL.apply(dsl)
    dsl.POST "/foo/bar":
      responses:
        200:true
        201:'Resource inserted'
        403:"Forbidden"
    dsl.rest.paths["/foo/bar"].should.be.ok
    dsl.rest.paths["/foo/bar"].post.should.be.ok
    dsl.rest.paths["/foo/bar"].post.method.should.equal "POST"
    dsl.rest.paths["/foo/bar"].post.responses["200"].should.be.ok
    dsl.rest.paths["/foo/bar"].post.responses["201"].description.should.equal "Resource inserted"
    dsl.rest.paths["/foo/bar"].post.responses["403"].description.should.equal "Forbidden"
    done()
