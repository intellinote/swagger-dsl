# swagger-dsl [![Build Status](https://travis-ci.org/intellinote/swagger-dsl.svg?branch=master)](https://travis-ci.org/intellinote/swagger-dsl) [![Dependencies](https://david-dm.org/intellinote/swagger-dsl.svg)](https://npmjs.org/package/swagger-dsl) [![NPM version](https://badge.fury.io/js/swagger-dsl.svg)](http://badge.fury.io/js/swagger-dsl)

A CoffeeScript-based domain-specific language for generating JSON documents for Swagger.

## Try it Now

See <http://intellinote.github.io/swagger-dsl/demo/live.html> for an in-browser, interactive demonstration.

## Example

Here is a Swagger-DSL-format document describing a simple REST API:

```coffeescript
swagger_version 1.2
api_version 3.2
base_path 'http://api.example.com/rest/v3.2/'

GET '/user/{uid}':
  summary: 'Fetch the user with the specified `uid`.'
  returns: 'UserModel'
  produces: json
  parameters:
    uid:[path,int64,required,'The user identifier']
    include:[query,string,default:'family_name,given_name,email']
  responses:
    200:true
    401:'User or application must authenticate'
    403:'User not authorized to take this action'
    404:'No user with the given `uid`'

MODEL 'UserModel':
  uid:         ['User identifier',int64,required]
  given_name:  ['First name',string]
  family_name: ['Last name',string]
  email:       ['Email address',required,string]
  tel:         ['Phone numbers',[ref:'PhoneNumber']]

MODEL 'PhoneNumber':
  type: [string,enum:['home','work','mobile','other'],required]
  number: [string,required]
```

When processed with `swagger-dsl` (for example, by executing `swagger-dsl listings/user`), the following [Swagger Specification](https://github.com/swagger-api/swagger-spec) JSON document is generated:

```json
{
  "apis": [
    {
      "path": "/user/{uid}",
      "operations": [
        {
          "summary": "Fetch the user with the specified <code>uid</code>.",
          "type": "UserModel",
          "produces": [
            "application/json"
          ],
          "parameters": [
            {
              "name": "uid",
              "paramType": "path",
              "type": "integer",
              "format": "int64",
              "required": true,
              "defaultValue": "The user identifier"
            },
            {
              "name": "include",
              "paramType": "query",
              "type": "string",
              "default": "family_name,given_name,email",
              "required": false,
              "format": "string"
            }
          ],
          "responseMessages": [
            {
              "code": "200",
              "message": "OK"
            },
            {
              "code": "401",
              "message": "Unauthorized; User or application must authenticate"
            },
            {
              "code": "403",
              "message": "Forbidden; User not authorized to take this action"
            },
            {
              "code": "404",
              "message": "Not Found; No user with the given `uid`"
            }
          ],
          "method": "GET",
          "nickname": "get__user__uid_"
        }
      ]
    }
  ],
  "models": {
    "UserModel": {
      "properties": {
        "uid": {
          "description": "User identifier",
          "format": "int64",
          "type": "integer",
          "required": true
        },
        "given_name": {
          "description": "Last name",
          "type": "string",
          "required": false
        },
        "family_name": {
          "description": "Last name",
          "type": "string",
          "required": false
        },
        "email": {
          "description": "Email address",
          "required": true,
          "type": "string"
        },
        "tel": {
          "description": "Phone numbers",
          "type": "array",
          "items": {
            "$ref": "PhoneNumber"
          },
          "required": false
        }
      },
      "id": "UserModel"
    },
    "PhoneNumber": {
      "properties": {
        "type": {
          "type": "string",
          "enum": [
            "home",
            "work",
            "mobile",
            "other"
          ],
          "required": true
        },
        "number": {
          "type": "string",
          "required": true
        }
      },
      "id": "PhoneNumber"
    }
  },
  "swaggerVersion": "1.2",
  "apiVersion": "3.2",
  "basePath": "http://api.example.com/rest/v3.2/"
}
```

## Installing

### Via npm

Swagger DSL is published as [`swagger-dsl` on npm](https://www.npmjs.org/package/swagger-dsl).

Hence you can install a pre-packaged version with the command:

```bash
npm install -g swagger-dsl
```

(Omit the `-g` to install swagger-dsl "locally" in the current working directory.)

### From Source

The source code and documentation for Swagger DSL is available on GitHub at [intellinote/swagger-dsl](https://github.com/intellinote/swagger-dsl).  You can clone the repository via:

```bash
git clone git@github.com:intellinote/swagger-dsl
```

Once you've cloned the respository, move (`cd`) into it and run:

```bash
make clean install test bin
```

in order to download and compile any external depedencies (`install`), run the unit test suite to confirm that everything was installed properly (`test`) and create the `swagger-dsl` script in the `./bin` directory (`bin`).

## Using

### Basics

Assuming `swagger-dsl` is in your `$PATH` (it will be in `node_modules/.bin` if you installed via npm, or `./bin` if you installed from the source files) you can run:

```bash
swagger-dsl myfile.dsl
```

to generate a [Swagger Specification](https://github.com/swagger-api/swagger-spec) JSON document from the Swagger DSL file `myfile.dsl`.

By default Swagger DSL will parse and execute each file you enumerate on the command line and print the resulting JSON document(s) to STDOUT.

You can use:

```bash
swagger-dsl myfile.dsl -o myfile.json
```

to write the output to the specified file.

### Renaming output files with `-x`

You can also use:

```bash
swagger-dsl myfile.dsl -x "json"
```

to write the output to a file named `myfile.dsl.json`.  (More generally, `-x` or `--suffix` specifies an extension to add to the input file name(s) to generate output file name(s).  Hence:

```bash
swagger-dsl listings/*.dsl -x "json"
```

will process all files with the extension `.dsl` in the `listings` directory. The output from processing each file will be written to files with names that end with `.dsl.json`, also in the `listings` directory.)

### Renaming output files with `-r`

For greater control over the generated filenames you can use the `-r` or `--rename` command line option to specify a rule for generating output file names based on input file names.  For example:

```bash
swagger-dsl listings/*.dsl -r listings/*.dsl --rename '/^(.+)\.dsl$/,\"$1\"'
```

will change the extension from `.dsl` to `.json`.

More generally, `-r` or `--rename` accepts a comma-delimited regular expression, string pair.  The regular expression will be matched against the input filename, and the string will be used to generate the output filename (by replacing `$n` with the text matching *n*th group in the regular expression).

```bash
swagger-dsl listings/*.dsl -x "json"
```

will process all files with the extension `.dsl` in the `listings` directory. The output from processing each file will be written to files with names that end with `.dsl.json`, also in the `listings` directory.)


## Licensing

The swagger-dsl library and related documentation are made available
under an [MIT License](http://opensource.org/licenses/MIT).  For details, please see the file [LICENSE.txt](LICENSE.txt) in the root directory of the repository.

## How to contribute

Your contributions, [bug reports](https://github.com/intellinote/swagger-dsl/issues) and [pull-requests](https://github.com/intellinote/swagger-dsl/pulls) are greatly appreciated.

We're happy to accept any help you can offer, but the following
guidelines can help streamline the process for everyone.

 * You can report any bugs at
   [github.com/intellinote/swagger-dsl/issues](https://github.com/intellinote/swagger-dsl/issues).

    - We'll be able to address the issue more easily if you can
      provide an demonstration of the problem you are
      encountering. The best format for this demonstration is a
      failing unit test (like those found in
      [./test/](https://github.com/intellinote/swagger-dsl/tree/master/test)), but
      your report is welcome with or without that.

 * Our preferred channel for contributions or changes to the
   source code and documentation is as a Git "patch" or "pull-request".

    - If you've never submitted a pull-request, here's one way to go
      about it:

        1. Fork or clone the repository.
        2. Create a local branch to contain your changes (`git
           checkout -b my-new-branch`).
        3. Make your changes and commit them to your local repository.
        4. Create a pull request [as described here](
           https://help.github.com/articles/creating-a-pull-request).

    - If you'd rather use a private (or just non-GitHub) repository,
      you might find
      [these generic instructions on creating a "patch" with Git](https://ariejan.net/2009/10/26/how-to-create-and-apply-a-patch-with-git/)
      helpful.

 * If you are making changes to the code please ensure that the
   [unit test suite](./test) still passes.

 * If you are making changes to the code to address a bug or introduce
   new features, we'd *greatly* appreciate it if you can provide one
   or more [unit tests](./test) that demonstrate the bug or
   exercise the new feature.

**Please Note:** We'd rather have a contribution that doesn't follow
these guidelines than no contribution at all.  If you are confused
or put-off by any of the above, your contribution is still welcome.
Feel free to contribute or comment in whatever channel works for you.

---

[![Intellinote](https://www.intellinote.net/wp-content/themes/intellinote/images/logo@2x.png)](https://www.intellinote.net/)

## About Intellinote

Intellinote is a multi-platform (web, mobile, and tablet) software
application that helps businesses of all sizes capture, collaborate
and complete work, quickly and easily.

Users can start with capturing any type of data into a note, turn it
into a task, assign it to others, start a discussion around it, add a
file and share – with colleagues, managers, team members, customers,
suppliers, vendors and even classmates. Since all of this is done in
the context of private and public workspaces, users retain end-to-end
control, visibility and security.

For more information about Intellinote, visit
<https://www.intellinote.net/>.

### Work with Us

Interested in working for Intellinote?  Visit
[the careers section of our website](https://www.intellinote.net/careers/)
to see our latest technical (and non-technical) openings.

---
