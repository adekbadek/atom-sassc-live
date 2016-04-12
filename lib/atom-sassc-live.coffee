{CompositeDisposable} = require 'atom'
{MessagePanelView, LineMessageView} = require 'atom-message-panel'
pty = require('pty.js')

SUPPORTED_FILE_TYPES = [
  '.sass'
  '.scss'
]

ACTIVE = false
directory_regex = /[^\/]*$/
filename_regex = /^.*[\\\/]/
error_title = '<span class="text-error">atom-sassc-live: ERROR 💩</span>'

PARSE_ON_NEWLINE = true
SUBDIR_NAME = null
IGNORE_WITH_UNDERSCORE = true
DEBOUNCE_DELAY = 250
SASSC_OPTIONS = '-t compressed'

messages = new MessagePanelView
  title: 'atom-sassc-live messages'

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

parseSass = (editor, term, msg) ->
  console.log msg
  if ACTIVE
    filename = editor.getPath().replace(filename_regex, '')
    # return if we ignore underscored'd files
    if IGNORE_WITH_UNDERSCORE and filename.indexOf('_') >= 0
      return

    # first we need to save the file
    atom.workspace.saveActivePaneItem()

    dir = editor.getPath().replace(directory_regex, '')
    if SUBDIR_NAME? && SUBDIR_NAME != '../'
      # create dir (if it doesn't exist)
      term.write 'cd '+dir+'\n'
      term.write 'mkdir -p '+SUBDIR_NAME+'\n'

    oldfile = editor.getPath()
    if SUBDIR_NAME?
      newfile = dir+SUBDIR_NAME+toCss(filename)
    else
      newfile = dir+'/'+toCss(filename)

    # run sassc
    messages.clear()
    messages.setTitle('<span class="text-success">atom-sassc-live: OK 😎</span>', true)
    term.write 'sassc '+oldfile+' > '+newfile+' '+SASSC_OPTIONS+'\n'
    console.log "UPDATED FILE "+filename


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
    term.on 'data', (data) ->
      if data.indexOf('Segmentation fault') >= 0
        # message panel
        messages.attach()
        messages.setTitle(error_title, true)
        messages.add new LineMessageView
          className: 'text-error'
          message: data
      if data.indexOf('Error: ') >= 0
        # message panel
        messages.attach()
        messages.setTitle(error_title, true)
        messages.add new LineMessageView
          line: parseInt(data.substring(data.indexOf('line')+5, data.length))
          className: 'text-error'
          message: data.split('\n')[0]

    # make sure that sassc is in the $PATH
    term.write 'export PATH=/usr/local/bin:$PATH\n'

    # read settings:
    #
    # console.log 'ignoreUnderscored = '+ atom.config.get('atom-sassc-live.ignoreUnderscored')
    IGNORE_WITH_UNDERSCORE = atom.config.get('atom-sassc-live.ignoreUnderscored')
    # console.log 'parseOnNewLine = '+ atom.config.get('atom-sassc-live.parseOnNewLine')
    PARSE_ON_NEWLINE = atom.config.get('atom-sassc-live.parseOnNewLine')
    if atom.config.get('atom-sassc-live.subdirName')
      # console.log 'subdirName = '+ atom.config.get('atom-sassc-live.subdirName')
      SUBDIR_NAME = atom.config.get('atom-sassc-live.subdirName')
    if atom.config.get('atom-sassc-live.debounceDelay')
      # console.log 'debounceDelay = '+ atom.config.get('atom-sassc-live.debounceDelay')
      DEBOUNCE_DELAY = atom.config.get('atom-sassc-live.debounceDelay')
    if atom.config.get('atom-sassc-live.SasscOptions')
      # console.log 'SasscOptions = '+ atom.config.get('atom-sassc-live.SasscOptions')
      SASSC_OPTIONS = atom.config.get('atom-sassc-live.SasscOptions')

    # observe file changes
    atom.workspace.observeTextEditors (editor) ->
      # if it's a sass file
      if isSassFile(editor.getPath())
        # on any change (typing)
        editor.onDidChange ->
          if PARSE_ON_NEWLINE && editor.buffer != undefined
            new_char = editor.buffer.history.undoStack[editor.buffer.history.undoStack.length-1].newText
            if new_char == "↵" || new_char == "\n"
              parseSass(editor, term, 'on newline')
          else if !PARSE_ON_NEWLINE
            debounce (->
              parseSass(editor, term, 'debouns')
            ), DEBOUNCE_DELAY

  deactivate: ->

      @subscriptions.dispose()

  toggle: ->
    if(ACTIVE)
      console.log 'AtomSasscLive was de-activated!'
      # message panel
      messages.close()
      ACTIVE = false
    else
      console.log 'AtomSasscLive was activated!'
      # message panel
      messages.attach()
      ACTIVE = true

  config:
    ignoreUnderscored:
      order: 1
      title: 'Ignore files which names begin with an underscore'
      description: "By convention, these are partials, so you wouldn't want to compile them to CSS."
      type: 'boolean'
      default: true
    parseOnNewLine:
      order: 2
      title: "Parse on newline"
      description: "Parse the Sass to CSS *on hitting return*, that is when the last character is newline."
      type: 'boolean'
      default: true
    subdirName:
      order: 3
      title: 'Subdirectory'
      description: "If you want CSS files to be save in a different folder, specify it here (e.g. `css/`)"
      type: 'string'
      default: ''
    debounceDelay:
      title: 'Delay for debounce'
      description: "If __Parse on newline__ is turned off, package will parse Sass on typing anything. However it wouldn't be a good idea to trigger compiling on _every_ keystroke - this is a minimum time until next compilation takes place (in miliseconds)"
      type: 'integer'
      default: 250
      minimum: 1
    SasscOptions:
      title: 'Sassc options'
      description: "Pass options when running `sassc` command"
      type: 'string'
      default: '-t compressed'
