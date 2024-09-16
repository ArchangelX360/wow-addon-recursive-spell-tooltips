# wow-addon-recursive-spell-tooltips
World of Warcraft add-on to display tooltips of spell mentioned in the description of the currently hovered spell.

## Known bugs

* Sometimes it does not work, probably a race condition in querying descriptions
* When there is too many transitive tooltips to display and the original tooltip is not too big, it can crunch the transitives
