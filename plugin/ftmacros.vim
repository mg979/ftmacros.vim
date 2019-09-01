" ========================================================================///
" Author:      Gianmaria Bajo <mg1979.git@gmail.com>
" Description: automatically set macros per filetype
" Url:         https://github.com/mg979
" License:     The MIT License (MIT)
" Created:     lun 11 marzo 2019 13:42:09
" Modified:    dom 17 marzo 2019 21:47:06
" ========================================================================///

if exists('g:loaded_ftmacros') | finish | endif

" settings file must exist to continue

if !exists('g:ftmacros_file')
  let g:ftmacros_file = has('win32') || has('win32unix') ? '~\\vimfiles\\.ftmacros.vim' : '~/.vim/.ftmacros.vim'
endif

if !filereadable(fnamemodify(g:ftmacros_file, ':p'))
  if writefile([], fnamemodify(g:ftmacros_file, ':p')) < 0
    echomsg "[ftmacros] Could not create settings file, define it in g:ftmacros_file"
    finish
  endif
endif

"------------------------------------------------------------------------------

let s:save_cpo = &cpo
set cpo&vim

"------------------------------------------------------------------------------

exe "source" g:ftmacros_file
if !exists('g:ftmacros')
  let g:ftmacros = {'default': {}, 'noft': {},
        \ 'annotations': {'default': {}, 'noft': {}}}
else
  let g:ftmacros = extend({'default': {}, 'noft': {},
        \ 'annotations': {'default': {}, 'noft': {}}}, g:ftmacros)
endif

"------------------------------------------------------------------------------

command! -bang -nargs=1 SaveMacro       call ftmacros#save(<bang>0, <q-args>)
command! -bang -nargs=1 EditMacro       call ftmacros#edit(<bang>0, <q-args>)
command! -bang -nargs=1 MoveMacro       call ftmacros#move(<bang>0, <q-args>)
command! -bang -nargs=1 DeleteMacro     call ftmacros#delete(<bang>0, <q-args>)
command! -bang          ListMacros      call ftmacros#list(<bang>0)
command!                ShowMacros      call ftmacros#show()
command! -bang -nargs=1 AnnotateMacro   call ftmacros#annotate(<bang>0, <q-args>)

"------------------------------------------------------------------------------

augroup ftmacros
  au!
  au Filetype,BufEnter * call s:load_ftmacros()
augroup END

"------------------------------------------------------------------------------

fun! s:load_ftmacros()
  if has_key(g:ftmacros, &ft)
    let macros = g:ftmacros[&ft]
  elseif empty(&ft)
    let macros = g:ftmacros.noft
  else
    let macros = {}
  endif

  for reg in keys(g:ftmacros.default)
    call setreg(reg, g:ftmacros.default[reg], 'v')
  endfor

  for reg in keys(macros)
    call setreg(reg, macros[reg], 'v')
  endfor
endfun

"------------------------------------------------------------------------------

let g:loaded_ftmacros = 1
let &cpo = s:save_cpo
unlet s:save_cpo

