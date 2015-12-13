log = null
reloader = null
spawn = null
path = null
jadeCompiler = null
pkgName = "autocompile-jade"

module.exports = new class AutocompileJade
  config:
    debug:
      type: "integer"
      default: 0
      minimum: 0
  activate: ->
    setTimeout (->
      reloaderSettings = pkg:pkgName,folders:["lib"]
      try
        reloader ?= require("atom-package-reloader")(reloaderSettings)
      ),500

    unless log?
      log = require("atom-simple-logger")(pkg:pkgName,nsp:"main")
      log "activating"
    @disposable = atom.commands.add 'atom-workspace', 'core:save', @handleSave

  deactivate: ->
    log "deactivating"
    @disposable.dispose()
    log = null
    reloader?.dispose()
    reloader = null
    spawn = null
    path = null
    jadeCompiler.kill("SIGHUP") if jadeCompiler?
    jadeCompiler = null

  handleSave: =>
    log "got save - is jade?"
    @activeEditor = atom.workspace.getActiveTextEditor()
    return unless @activeEditor?
    scopeName = @activeEditor.getGrammar().scopeName
    return unless scopeName.match /\bjade\b/
    log "is jade!"
    path = @activeEditor.getURI()
    text = @activeEditor.getText()
    firstComment = text.match /^\s*(\/\/\-.*)\n*/
    return unless firstComment? and firstComment[1]?
    log "found comment"
    paramsString = firstComment[1].replace(/^\/\/\-\s*/, "")
    params = path: path
    for param in paramsString.split ","
      [key, value] = param.split ":"
      continue unless key? and value?
      params[key.replace(/^\s+|\s+$/gm,"")] = value.replace(/^\s+|\s+$/gm,"")
    unless params.out?
      atom.notifications.addError "no output path provided"
    params.compress = true unless params.compress?
    params.compress = @parseBoolean params.compress
    log "rendering"
    @render(params)


  render: (params) ->
    {spawn} = require "child_process"
    path = require "path"
    jadeCompiler.kill("SIGHUP") if jadeCompiler?
    sh = "sh"
    jadeString = path.resolve(path.dirname(module.filename),
                              "../node_modules/.bin/jade")
    unless params.compress
      jadeString += " --pretty"
    if params.obj?
      objPath = path.resolve(path.dirname(params.path),params.obj)
      jadeString += " --obj \"#{objPath}\""
    outPath = path.resolve(path.dirname(params.path),params.out)
    jadeString += " --out \"#{outPath}\""
    jadeString += " #{params.path}"
    args = ["-c",jadeString]
    if process.platform == "win32"
      sh = "cmd"
      args[0] = "/c"
    jadeCompiler = spawn sh, args, {
      cwd: process.cwd
      env: PATH:process.env.PATH
    }
    stderrData = []
    jadeCompiler.stderr.setEncoding("utf8")
    jadeCompiler.stderr.on "data", (data) ->
      stderrData.push data
    jadeCompiler.on "close", (code) ->
      if code
        atom.notifications.addError "compiling failed", detail:stderrData
      else
        atom.notifications.addSuccess(outPath + path.sep +
          path.basename(params.path,".jade") +
          ".html created")

  parseBoolean: (value) ->
    (value is 'true' or value is 'yes' or value is 1 or value is true) and
      value isnt 'false' and value isnt 'no' and value isnt 0 and value isnt false
