Files copied next to the exported `index.html` by `.github/workflows/godot-ci.yml`:
the web app manifest and icons that make "Add to Home Screen" open the game fullscreen
with its own icon (Android and iPhone). `.gdignore` keeps Godot from importing them.

`shell.html` is the loading page (export preset `html/custom_html_shell`): the splash picture from
`tools/make_splash.py` with a pixel loading bar and tips. CI also copies the Jersey 10 font next to it.
