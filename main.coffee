Github = require 'github'

p = new Promise (resolve, reject) ->
  resolve(localStorage.authToken)

gh = Github(p)

setTimeout ->
  gh.api('user').then console.log.bind console
, 100

# We want to get all the repos in distri, STRd6
# for each repo we want to look at the gh-pages branch
# for each .json.js file in the gh-pages branch we want to write a corresponding
# .json file
