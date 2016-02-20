Base64 = require "base64"

URITemplates = require "./uri-templates"

Github = require 'github'

p = new Promise (resolve, reject) ->
  resolve(localStorage.authToken)

gh = Github(p)

Repository = gh.Repository

log = (value) ->
  console.log value
  return value

doItLive = false

setTimeout ->
  gh.api('repos/distri/packager')
  .then (data) ->
    repo = Repository(data)
    url = URITemplates(repo.contents_url()).fill(path: "") + "?ref=gh-pages"
    console.log url
    convertRepo(repo, url)
  .catch (e) ->
    console.error e

, 100

getNextLink = () ->
  gh.lastRequest().getResponseHeader("Link").split(',').map (link) ->
    link.split(';').map (s) ->
      s.trim()
  .filter (link) ->
    link[1] is 'rel="next"'
  .map (link) ->
    str = link[0]
    str.substring 1, str.length - 1

convertResultPage = (data) ->
  nextLink = getNextLink()[0]

  sequentially data, (datum) ->
    template = URITemplates(datum.contents_url)
    uri = template.fill(path: "") + "?ref=gh-pages"

    repo = Repository(datum)

    convertRepo(repo, uri)
  .then ->
    if nextLink
      console.log nextLink

      gh.api(nextLink)
      .then convertResultPage
    else
      console.log 'DONE!'

convertRepo = (repo, uri) ->
  gh.api(uri)
  .then (files) ->
    Promise.all(
      files.filter (file) ->
        file.type is "file" and file.path.match /\.json\.js$/
      .map (file) ->
        gh.api(file.url)
    )
  .then (files) ->
    files.map convertFile
  .then (files) ->
    if doItLive
      if files.length > 0
        repo.commitTree
          baseTree: true
          branch: "gh-pages"
          message: "Converting .json.js to .json"
          tree: files
    else
      console.log "Dry run #{uri}"
  .then ->
    log "converted #{uri}"
  .catch (e) ->
    if e.status is 404
      log "Skipped:", uri
    else
      console.error e
      throw e

convertFile = (file) ->
  path: file.path.replace /\.js$/, ""
  mode: "100644"
  type: "blob"
  content: extractJSON(Base64.decode(file.content))

extractJSON = (content) ->
  start = content.indexOf('{')
  end = content.length - 2

  jsonData = content.substring start, end

  JSON.parse jsonData

  jsonData + "\n"

sequentially = (array, fn) ->
  new Promise (resolve, reject) ->
    index = 0
    results = []

    step = ->
      if index < array.length
        p = fn(array[index], index)
        index += 1

        results.push p

        p.then step
      else
        resolve(results)

    step()

# We want to get all the repos in distri, STRd6
# for each repo we want to look at the gh-pages branch
# for each .json.js file in the gh-pages branch we want to write a corresponding
# .json file
