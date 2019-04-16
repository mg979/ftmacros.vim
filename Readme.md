This plugin lets you:

- have different sets of macros that are automatically applied with filetypes
- edit any macro (or vim register) in a buffer
- list saved macros in a special buffer
- move/delete/annotate macros

For more details:

`:help ftmacros-vim`

-------------------------------------------------------------------------------

### Commands

    :SaveMacro
    :EditMacro
    :MoveMacro
    :DeleteMacro
    :ListMacros
    :ShowMacros
    :AnnotateMacro

#### SaveMacro

    :SaveMacro[!] {register} [as {register}]

Save macro stored in {register}, for current filetype. The next time that
a file of the same type will be loaded, that macro will be loaded too.

-------------------------------------------------------------------------------

#### EditMacro

    :EditMacro[!] {register}

Edit a macro in a buffer. Save the buffer to update the macro.
You can edit any macro (or register), even if it's not saved in your ftmacros
file.

-------------------------------------------------------------------------------

#### MoveMacro

    :MoveMacro[!] [ft={filetype}] {old} {new}

Move a macro, if it's been saved before.

-------------------------------------------------------------------------------

#### DeleteMacro

    :DeleteMacro[!] {register}

Delete a macro, if it's been saved before.

-------------------------------------------------------------------------------

#### ListMacros

    :ListMacros[!]

List your saved macros in a special buffer.

-------------------------------------------------------------------------------

#### ShowMacros

    :ShowMacros

Same as `:registers`, but on a side scratch buffer.

-------------------------------------------------------------------------------

#### AnnotateMacro

    :AnnotateMacro[!] {register} {note}

Annotate a saved macro. The annotation will be visible on the command line, in the
ListMacros buffer. The command will fail if the macro hasn't been saved.

