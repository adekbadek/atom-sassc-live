# atom-sassc-live

NOTE: it's a work in progress...

## Requirements

You have to have [sassc](https://github.com/sass/sassc) installed (on OSX - easiest with [brew](https://github.com/sass/sassc))

## What

This package, once toggled (```Packages > atom-sassc-live > Toggle```) will parse ```.sass```/```.scss``` files *while you type*. By default the ```.css``` output will be saved in the same directory.

## How

1. Link HTML to the output ```.css``` file, then [set Up Persistence with DevTools Workspaces](https://developers.google.com/web/tools/setup/setup-workflow) it.
2. Toggle package

Now, when you type, Atom will save the file and sassc will compile it to CSS.



## TODO:

  - enable output to different folder (package options?)
  - about Takana
