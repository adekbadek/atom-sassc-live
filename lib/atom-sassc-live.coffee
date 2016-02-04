{CompositeDisposable} = require 'atom'
pty = require('pty.js')

SUPPORTED_FILE_TYPES = [
  '.sass'
  '.scss'
]

directory_regex = /[^\/]*$/
filename_regex = /^.*[\\\/]/



# TODO: make it editable in package settings
SUBDIR_NAME = 'css/'

# TODO: make it editable in package settings
IGNORE_WITH_LODASH = true



ACTIVE = false

isSassFile = (filePath) ->
  path.extname(filePath) in SUPPORTED_FILE_TYPES

toCss = (fileName) ->
  if fileName.indexOf('.css') >= 0
    # it's name.css.sass
    return fileName.replace(/.sass/, '')
  else
    # it's - name.scss or name.sass
    return fileName.replace(/\.sass|\.scss/, '.css')

module.exports = AtomSasscLive =
  modalPanel: null
  subscriptions: null

  activate: (state) ->

    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register command that toggles this package
    @subscriptions.add atom.commands.add 'atom-workspace', 'atom-sassc-live:toggle': => @toggle()

    # pty - terminal in console
    term = pty.spawn('bash', [],
      name: 'xterm-color'
      cols: 80
      rows: 30
      cwd: process.env.HOME
      env: process.env)

    # debug
    # term.on 'data', (data) ->
    #   console.log data

    # observe file changes
    atom.workspace.observeTextEditors (editor) ->
      # if it's a sass file
      if isSassFile(editor.getPath())
        # on any change (typing)
        editor.onDidChange(->
          filename = editor.getPath().replace(filename_regex, '')
          # return if we ignore lodash'd files
          if IGNORE_WITH_LODASH and filename.indexOf('_') >= 0
            return
          dir = editor.getPath().replace(directory_regex, '')
          # create dir (if it doesn't exist)
          term.write 'cd '+dir+'\n'
          term.write 'mkdir -p '+SUBDIR_NAME+'\n'

          oldfile = editor.getPath()
          newfile = dir+SUBDIR_NAME+toCss(filename)
          # run sassc
          term.write 'sassc '+oldfile+' > '+newfile+' --style compressed -m\n'
          console.log "UPDATED FILE "+oldfile
        )


  deactivate: ->

    # TODO: deactivate observing!

    @subscriptions.dispose()

  toggle: ->
    if(ACTIVE)
      console.log 'AtomSasscLive was de-activated!'
      ACTIVE = false
    else
      console.log 'AtomSasscLive was activated!'
      ACTIVE = true
