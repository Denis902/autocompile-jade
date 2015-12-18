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
  debug: ->
  activate: ->
    @disposable = atom.commands.add 'atom-workspace', 'core:save', @handleSave
  consumeDebug: (debugSetup) =>
    @debug = debugSetup(pkg: pkgName, nsp: "")
    @debug "debug service consumed", 2
  consumeAutoreload: (reloader) =>
    reloader(pkg:pkgName)
    @debug "autoreload service consumed", 2
  deactivate: =>
    @debug "deactivating"
    @disposable.dispose()
    log = null
    reloader?.dispose()
    reloader = null
    spawn = null
    path = null
    jadeCompiler.kill("SIGHUP") if jadeCompiler?
    jadeCompiler = null

  handleSave: =>
    @debug "got save - is jade?"
    @activeEditor = atom.workspace.getActiveTextEditor()
    return unless @activeEditor?
    scopeName = @activeEditor.getGrammar().scopeName
    return unless scopeName.match /\bjade\b/
    @debug "is jade!"
    path = @activeEditor.getURI()
    text = @activeEditor.getText()
    firstComment = text.match /^\s*(\/\/\-.*)\n*/
    return unless firstComment? and firstComment[1]?
    @debug "found comment"
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
    @debug "rendering"
    @render(params)


  render: (params) ->
    {spawn} = require "child_process"
    path = require "path"
    fs = require "fs"
    jadeCompiler.kill("SIGHUP") if jadeCompiler?
    sh = "sh"
    relativePath = atom.project.relativizePath params.path
    if relativePath[0]? # within a project folder
      tmpString = path.resolve(relativePath[0],"./node_modules/.bin/jade")
      try
        jadeString = tmpString if fs.statSync(tmpString).isFile()
    jadeString ?= path.resolve(path.dirname(module.filename),
                              "../node_modules/.bin/jade")
    unless params.compress
      jadeString += " --pretty"
    if params.obj?
      objPath = path.resolve(path.dirname(params.path),params.obj).replace(/\\$/,"")
      jadeString += " --obj \"#{objPath}\""
    outPath = path.resolve(path.dirname(params.path),params.out).replace(/\\$/,"")
    jadeString += " --out \"#{outPath}\""
    jadeString += " \"#{params.path}\""
    args = ["-c",jadeString]
    if process.platform == "win32"
      sh = "cmd"
      args[0]= "/c"
    jadeCompiler = spawn sh, args, {
      cwd: process.cwd
      env: PATH:process.env.PATH
      windowsVerbatimArguments: process.platform == "win32"
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
