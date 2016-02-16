http = require "http"
Docker = (require "dockerode")
docker = new Docker

Proxy =

  start: (_port) ->
    http.createServer (request, response) ->
      {protocol, path, method, headers} = request
      # if (route = Routes.find request.headers.host)?
      if (route = Routes.find "localhost:80")?
        [host, port] = route
        request.pipe http.request {protocol, host, port, path, method, headers},
          (_response) -> _response.pipe response
      else
        response.statusCode = 503
        response.end()
    .listen _port, ->
      console.log "Listening on port #{_port}"

Routes =

  _table: (_table = {})

  update: (containers) ->
    for container in containers
      [name] = container.Image.split(":")
      if name != "docker-proxy"
        for port in container.Ports
          {IP, PrivatePort, PublicPort} = port
          if PrivatePort == 80
            Routes.add "localhost:80", [ IP, PublicPort ]

  find: (host) ->
    alternatives = _table[host]
    if alternatives?
      Routes.choose alternatives

  choose: (alternatives) ->
    index = Math.round(Math.random() * (alternatives.length - 1))
    alternatives[index]

  add: (from, to) ->
    (_table[from] ?= []).push to

docker.listContainers (error, containers) ->
  if !error?
    Routes.update containers
    console.log "Routes"
    console.log Routes._table
    Proxy.start if process.argv[2]? then process.argv[2] else 80
  else
    console.error error
