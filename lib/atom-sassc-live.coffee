{CompositeDisposable} = require 'atom'
pty = require('pty.js')

SUPPORTED_FILE_TYPES = [
  '.sass'
  '.scss'
]

ACTIVE = false
directory_regex = /[^\/]*$/
filename_regex = /^.*[\\\/]/

SUBDIR_NAME = null
IGNORE_WITH_UNDERSCORE = true
DEBOUNCE_DELAY = 250


# debouncer - sassc will run max. 1 time every <delay>
onetimer = false
debounce = (fn, delay) ->
  timer = null
  func = () ->
    # console.log "no you won't..."
    onetimer = true
    context = this
    args = arguments
    clearTimeout timer
    timer = setTimeout((->
      if onetimer
        # console.log "now you will, but just one time"
        fn.apply context, args
        onetimer = false
      return
    ), delay)
    return
  func()

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
  watcher: null

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

    # read settings:
    #
    # console.log 'ignoreUnderscored = '+ atom.config.get('atom-sassc-live.ignoreUnderscored')
    IGNORE_WITH_UNDERSCORE = atom.config.get('atom-sassc-live.ignoreUnderscored')
    # 
    if atom.config.get('atom-sassc-live.subdirName')
      # console.log 'subdirName = '+ atom.config.get('atom-sassc-live.subdirName')
      SUBDIR_NAME = atom.config.get('atom-sassc-live.subdirName')
    if atom.config.get('atom-sassc-live.debounceDelay')
      # console.log 'debounceDelay = '+ atom.config.get('atom-sassc-live.debounceDelay')
      DEBOUNCE_DELAY = atom.config.get('atom-sassc-live.debounceDelay')

    # observe file changes
    atom.workspace.observeTextEditors (editor) ->
      # if it's a sass file
      if isSassFile(editor.getPath())
        # on any change (typing)
        editor.onDidChange ->

          debounce (->
            if ACTIVE

              filename = editor.getPath().replace(filename_regex, '')
              # return if we ignore underscored'd files
              if IGNORE_WITH_UNDERSCORE and filename.indexOf('_') >= 0
                return

              # first we need to save the file
              atom.workspace.saveActivePaneItem()

              dir = editor.getPath().replace(directory_regex, '')
              if SUBDIR_NAME?
                # create dir (if it doesn't exist)
                term.write 'cd '+dir+'\n'
                term.write 'mkdir -p '+SUBDIR_NAME+'\n'

              oldfile = editor.getPath()
              if SUBDIR_NAME?
                newfile = dir+SUBDIR_NAME+toCss(filename)
              else
                newfile = dir+'/'+toCss(filename)

              # run sassc
              term.write 'sassc '+oldfile+' > '+newfile+' --style compressed\n'
              console.log "UPDATED FILE "+filename

          ), DEBOUNCE_DELAY

  deactivate: ->

      @subscriptions.dispose()

  toggle: ->
    if(ACTIVE)
      console.log 'AtomSasscLive was de-activated!'
      ACTIVE = false
    else
      console.log 'AtomSasscLive was activated!'
      ACTIVE = true

  config:
    ignoreUnderscored:
      title: 'Ignore files which names begin with an underscore'
      description: "By convention, these are partials, so you wouldn't want to compile them to CSS."
      type: 'boolean'
      default: true
    debounceDelay:
      title: 'Delay for debounce'
      description: "It wouldn't be a good idea to trigger compiling on _every_ keystroke. This is a minimum time until next compilation takes place (in miliseconds)"
      type: 'integer'
      default: 250
      minimum: 1
    subdirName:
      title: 'Subdirectory'
      description: "If you want CSS files to be save in a different folder, specify it here (e.g. ```css/```)"
      type: 'string'
      default: ''
