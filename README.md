# atom-sassc-live

NOTE: it's a work in progress...

## Requirements

You have to have [sassc](https://github.com/sass/sassc) installed and added to PATH (on OSX - easiest with [homebrew](http://brewformulas.org/Sassc)).

## What

This package will parse ```.sass```/```.scss``` files *while you type*. By default the ```.css``` output will be saved in the same directory where the edited ```.sass``` file is (you can change that in settings).

## How

1. Link HTML to the output ```.css``` file, then [Set Up Persistence with DevTools Workspaces](https://developers.google.com/web/tools/setup/setup-workflow).
2. Toggle package (```Packages > atom-sassc-live > Toggle``` or just ```CTRL+ALT+O```)

Now, when you type, Atom will save the file and sassc will compile it to CSS.

## Why

This project is inspired by [Takana](http://usetakana.com). Unfortunately Takana does not support ```.sass``` syntax and runs it's own server, which is probably the reason I couldn't make it work with [Middleman](https://middlemanapp.com/).
