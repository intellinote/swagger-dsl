# swagger-dsl [![Build Status](https://travis-ci.org/intellinote/swagger-dsl.svg?branch=master)](https://travis-ci.org/intellinote/swagger-dsl) [![Dependencies](https://david-dm.org/intellinote/swagger-dsl.svg)](https://npmjs.org/package/swagger-dsl) [![NPM version](https://badge.fury.io/js/swagger-dsl.svg)](http://badge.fury.io/js/swagger-dsl)

A CoffeeScript-based domain-specific language for generating JSON documents for Swagger.

Work in Progress.

---

<div class="row"><div class="col-md-10 col-md-offset-1"><div class="lead">DSL Format (input)</div></div></div>
<div class="row"><div class="col-md-10 col-md-offset-1"><textarea  id="dsl-in" style="width:100%" rows="12" cols="80">api_version 1.2
base "https://api.example.com/rest/v1.1/"

GET "/foo/bar/{id}":
  summary: "Create a new FooBar object"
  parameters:
    id:[path,int64,required]
  produces: json
  returns:"FooBar"
  responses:
    200:true
    404:true

POST "/foo/bar":
  summary: "Create a new FooBar object"
  parameters:
    foobar:[body,required,type:"FooBar"]
  consumes: json
  responses:
    201:"FooBar created"
    401:"User or application must authenticate"
    403:"User or application not allowed to take this action"

MODEL "FooBar":
  id:[integer,required,"an example attribute"]
  name:[string,"another attribute"]
  bars:[[ref:"ModelBar"],"an array of 'ModelBar' objects"]</textarea></div></div><div class="row" style="margin-top:1em;"><div class="col-md-10 col-md-offset-1 center"><button id="runbtn" class="btn btn-primary">Generate JSON</button></div></div><div class="row"><div class="col-md-10 col-md-offset-1"><div class="lead">JSON Format (output)</div></div></div><div class="row"><div class="col-md-10 col-md-offset-1"><textarea  id="json-out" style="width:100%" rows="12" cols="80"></textarea></div></div>


<script src="https://ajax.googleapis.com/ajax/libs/jquery/1.11.1/jquery.min.js"></script>
<script src="https://maxcdn.bootstrapcdn.com/bootstrap/3.2.0/js/bootstrap.min.js"></script>
<script type="text/javascript">
$( document ).ready(function() {
swagger_it = function(dsl_code) {
var code = "swagger_dsl(this);\n";
code += dsl_code;
code += "\nreturn to_json()\n";
return eval(CoffeeScript.compile(code));
};
$("#runbtn").click( function() {
try {
$("#json-out")[0].value = (swagger_it(document.getElementById("dsl-in").value));
$("#json-out").addClass("success");
setTimeout(function(){$("#json-out").removeClass("success");},200);
} catch(err) {
$("#dsl-in").addClass("error");
setTimeout(function(){$("#dsl-in").removeClass("error");},200);
console.log(err);
<!-- alert("Sorry, an occur occured. Please review console log for details.",err); -->
}
});
});
</script>
<script type="text/javascript" src="http://github.com/intellinote/swagger-dsl/raw/master/demo/script.js"> </script>
<script type="text/javascript" src="http://github.com/jashkenas/coffee-script/raw/master/extras/coffee-script.js"> </script>


<style>
.error { background-color: #993333; border-color:red;}
.success { background-color: #339933; border-color:green;}
textarea {  -webkit-transition:background-color 1s; transition:background-color 0.2s; }
.strong { font-weight: bold;}
.center { text-align: center; }
textarea { font-family: consolas, inconsolatas, droid sans mono slashed, droid sans mono, monospace; font-size:10pt; }
</style>

---

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
