http = require "http"
Docker = (require "dockerode")
docker = new Docker

Proxy =

  start: (_port) ->
    http.createServer (request, response) ->
      {protocol, path, method, headers} = request
      [host, port] = Routes.find request.headers.host
      request.pipe http.request {protocol, host, port, path, method, headers},
        (_response) -> _response.pipe response
    .listen _port, ->
      console.log "Listening on port #{_port}"

Routes =

  _table: (_table = {})

  update: (containers) ->
    for container in containers
      for port in container.Ports
        {IP, PrivatePort, PublicPort} = port
        if PrivatePort == 80
          Routes.add "localhost:80", [ IP, PublicPort ]

  find: (host) ->
    alternatives = _table[host]
    if alternatives?
      Routes.choose alternatives

  choose: (alternatives) ->
    index = Math.round(Math.random() * alternatives.length - 1)
    alternatives[index]

  add: (from, to) ->
    (_table[from] ?= []).push to

docker.listContainers (error, containers) ->
  if !error?
    Routes.update containers
    Proxy.start 80
  else
    console.error error
