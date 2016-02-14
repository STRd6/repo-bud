Github = require 'github'

p = new Promise (resolve, reject) ->
  resolve(localStorage.authToken)

gh = Github(p)

gh.api('user').then console.log.bind console
