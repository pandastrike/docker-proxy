http = require "http"
{promise, all} = require "when"
DockerAPI = (require "dockerode")
dockerAPI = new DockerAPI

Docker =

  listContainers: ->
    promise (resolve, reject) ->
      dockerAPI.listContainers (error, containers) ->
        if !error?
          resolve all (for container in containers
                        Container.inspect Container.normalize container)
        else
          reject error

Container =

  normalize: (container) ->
    id: container.Id
    locations: for port in container.Ports
      address: port.IP
      ports:
        public: port.PublicPort
        private: port.PrivatePort

  inspect: (container) ->
    promise (resolve, reject) ->
      dockerAPI.getContainer container.id
      .inspect (error, details) ->
        if !error?
          container.domain =  "web.foobar.com"
          # container.domain = if details.Config.Domainname == ''
          #   undefined
          # else
          #   details.Config.Domainname
          resolve container
        else
          reject error

Proxy =

  start: (_port) ->
    http.createServer (request, response) ->
      {protocol, path, method, headers} = request
      # if (route = Routes.find request.headers.host)?
      if (route = Routes.find "web.foobar.com")?
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
    for {domain, locations} in containers
      if domain?
        for {address, ports} in locations when ports.private == 80
          Routes.add domain, [ address, ports.public ]

  find: (host) ->
    alternatives = _table[host]
    if alternatives?
      Routes.choose alternatives

  choose: (alternatives) ->
    index = Math.round(Math.random() * (alternatives.length - 1))
    alternatives[index]

  add: (from, to) ->
    (_table[from] ?= []).push to

Docker.listContainers()
.then (containers) ->
    Routes.update containers
    Proxy.start if process.argv[2]? then process.argv[2] else 80
.catch (error) ->
  console.error error
