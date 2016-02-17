URITemplates = require "./uri-templates"

Github = require 'github'

p = new Promise (resolve, reject) ->
  resolve(localStorage.authToken)

gh = Github(p)

log = (value) ->
  console.log value
  return value

setTimeout ->
  gh.api('orgs/distri/repos').then log
  .then (data) ->
    data.forEach (datum, i) ->
      template = URITemplates(datum.contents_url)
      uri = template.fill(path: "") + "?ref=gh-pages"
      console.log uri

      if i is 1
        gh.api(uri).then log
        .then (files) ->
          log( 
            files.filter (file) ->
              file.type is "file" and file.path.match /\.json\.js$/
            .map (file) ->
              # TODO: Read the file, convert path to .json, write json data to gh-pages branch
              file.path
          )

    log gh.lastRequest().getResponseHeader("Link").split(',').map (link) ->
      link.split(';').map (s) ->
        s.trim()
, 100

# We want to get all the repos in distri, STRd6
# for each repo we want to look at the gh-pages branch
# for each .json.js file in the gh-pages branch we want to write a corresponding
# .json file
