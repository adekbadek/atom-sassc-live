# atom-sassc-live

![demo gif](/demo.gif "Demo")

## What

This package will parse `.sass`/`.scss` files on newline (or as you type) and on saving the file. By default the `.css` output will be saved in the same directory where the edited `.sass` file is (you can change that in settings).

## How

1. Install the package - `apm install atom-sassc-live`
2. Link HTML to the output `.css` file, then [Set Up Persistence with DevTools Workspaces](https://developers.google.com/web/tools/setup/setup-workflow).
3. Toggle package (`Packages > atom-sassc-live > Toggle` or just `CTRL+ALT+O`)

## Why

This project is inspired by [Takana](http://usetakana.com). Unfortunately Takana does not support `.sass` syntax and runs it's own server, which may conflict with a local server or asset pipeline.

## Requirements

You have to have [sassc](https://github.com/sass/sassc) installed and added to PATH (on OSX - it's simplest with [homebrew](http://brewformulas.org/Sassc)).
