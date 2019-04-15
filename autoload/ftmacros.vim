fun! ftmacros#save(default, args, ...)
  if a:0    " called by buffer
    let b = a:default ? '!' : ' ft='.a:1
    call feedkeys("\<c-u>:display\<cr>:SaveMacro".b." ", 'n')
    return
  endif

  try
    let args = split(a:args)
    if match(args[0], 'ft=') >= 0
      let ft = substitute(args[0], 'ft=', '', '')
      let reg = args[1]
    else
      let ft = &ft
      let reg = args[0]
    endif

    if !s:valid(reg) | return | endif
    let registered = s:is_registered(a:default, reg, ft)

    if a:default
      let g:ftmacros.default[reg] = getreg(reg)
    elseif !empty(ft)
      if !has_key(g:ftmacros, ft)
        let g:ftmacros[ft] = { reg: getreg(reg) }
      else
        let g:ftmacros[ft][reg] = getreg(reg)
      endif
    else
      let g:ftmacros.noft[reg] = getreg(reg)
    endif
  catch
    return s:warn('[ftmacros] error while saving macro')
  endtry

  if !s:writefile() | return s:warn('[ftmacros] failed to write file!') | endif

  call s:update_buffer()

  let n = registered ? '' : 'new '
  let s = registered ? 'updated' : 'saved'

  if a:default
    echo '[ftmacros]' n.'default macro for register' reg 'has been' s
  elseif !empty(ft)
    echo '[ftmacros]' n.'macro for register' reg 'and filetype' ft 'has been' s
  else
    echo '[ftmacros]' n.'macro for register' reg 'and no filetype has been' s
  endif
endfun

"------------------------------------------------------------------------------

fun! ftmacros#delete(default, register, ...)
  if confirm('Confirm?', "&Yes\n&No", 1) != 1 | return | endif

  try
    let ft = a:0 ? a:1 : &ft
    if a:default
      unlet g:ftmacros.default[a:register]
    elseif !empty(ft)
      unlet g:ftmacros[ft][a:register]
    else
      unlet g:ftmacros.noft[a:register]
    endif
  catch
    return s:warn('[ftmacros] not a valid macro')
  endtry

  if !s:writefile() | return s:warn('[ftmacros] failed to write file!') | endif

  call s:update_buffer()

  if a:default
    echo '[ftmacros] default macro for register' a:register 'has been deleted'
  elseif !empty(ft)
    echo '[ftmacros] macro for register' a:register 'and filetype' ft 'has been deleted'
  else
    echo '[ftmacros] macro for register' a:register 'and no filetype has been deleted'
  endif
endfun

"------------------------------------------------------------------------------

fun! ftmacros#edit(default, register, ...)
  if !s:valid(a:register) | return | endif
  call s:macro_buffer(a:default, a:register, a:0 ? a:1 : &ft)
endfun

fun! s:macro_buffer(default, register, ft)
  botright new ftmacro_edit
  setlocal bt=acwrite bh=wipe noswf nobl
  put =getreg(a:register)
  1d _
  set nomodified
  if line('$') < winheight(winnr())
    execute 'resize' line('$')
  end
  let &l:statusline = "Editing Register ".a:register
  let b:ftmacros = {'default': a:default, 'register': a:register, 'ft': a:ft}
  redraw!

  autocmd WinLeave    <buffer> wincmd p
  autocmd BufWriteCmd <buffer> call s:macro_write_back()
endfun

fun! s:macro_write_back() abort
  let [ R, default, ft ] = [ b:ftmacros.register, b:ftmacros.default, b:ftmacros.ft ]
  let new = join(getline(1, '$'), '\n')
  let type = getregtype(R) ==# 'v' ? 'char' : getregtype(R) ==# 'V' ? 'line' : 'block'
  if type == 'char'
    call setreg(R, new, 'v')
  else
    let type = confirm("Current register type is ".type.", set type to?", "&char\n&line\n&block", 1)
    if !type | return s:warn('Canceled') | endif
    let type = type == 1 ? 'v' : type == 2 ? 'l' : 'b'
    call setreg(R, new, type)
  endif

  bw!
  if !s:is_registered(default, R, ft)
    redraw
    echo '[ftmacros] macro for register' R 'has been edited, but is currently not registered'
    return
  endif

  if default        | let g:ftmacros.default[R] = new
  elseif !empty(ft) | let g:ftmacros[ft][R] = new
  else              | let g:ftmacros.noft[R] = new
  endif

  call s:update_buffer()

  if default
    echo '[ftmacros] default macro for register' R 'has been updated'
  elseif !empty(ft)
    echo '[ftmacros] macro for register' R 'and filetype' ft 'has been updated'
  else
    echo '[ftmacros] macro for register' R 'and no filetype has been updated'
  endif
endfun

"------------------------------------------------------------------------------

fun! ftmacros#move(default, args, ...)
  if a:0    " called by buffer
    let b = a:default ? '!' : ' ft='.a:1
    call feedkeys("\<c-u>:display\<cr>:MoveMacro".b." ".a:args." ", 'n')
    return
  endif

  try
    if match(a:args, 'ft=') >= 0
      let [ft, old, new] = split(a:args)
      let ft = substitute(ft, 'ft=', '', '')
    else
      let ft = &ft
      let [old, new] = split(a:args)
    endif
    if a:default
      let g:ftmacros.default[new] = copy(g:ftmacros.default[old])
      unlet g:ftmacros.default[old]
    elseif !empty(ft)
      let g:ftmacros[ft][new] = copy(g:ftmacros[ft][old])
      unlet g:ftmacros[ft][old]
    else
      let g:ftmacros.noft[new] = copy(g:ftmacros.noft[old])
      unlet g:ftmacros.noft[old]
    endif
  catch
    return s:warn('[ftmacros] not a valid macro')
  endtry

  if !s:writefile() | return s:warn('[ftmacros] failed to write file!') | endif

  call s:update_buffer()

  if a:default
    echo '[ftmacros] default macro for register' old 'has been moved to register' new
  elseif !empty(ft)
    echo '[ftmacros] macro for register' old 'and filetype' ft 'has been moved to register' new
  else
    echo '[ftmacros] macro for register' old 'and no filetype has been moved to register' new
  endif
endfun

"------------------------------------------------------------------------------

fun! ftmacros#list(bang)
  if a:bang && g:ftmacros == {'default': {}} ||
        \ g:ftmacros.default == {} &&
        \ ( !has_key(g:ftmacros, &ft) && &ft != '' ) ||
        \ ( &ft == '' && g:ftmacros.noft == {} )
    return s:warn('[ftmacros] no saved macros')
  endif

  let ft = empty(&ft) ? 'noft' : &ft

  new
  setlocal bt=nofile bh=wipe noswf nobl ts=8 noet nowrap
  nnoremap <buffer><nowait><silent> q :q!<cr>
  nnoremap <buffer><nowait><silent> e :call <sid>buffer_cmd('edit')<cr>
  nnoremap <buffer><nowait><silent> d :call <sid>buffer_cmd('delete')<cr>
  nnoremap <buffer><nowait><silent> m :call <sid>buffer_cmd('move')<cr>
  nnoremap <buffer><nowait><silent> a :call <sid>buffer_cmd('save', 0)<cr>
  nnoremap <buffer><nowait><silent> A :call <sid>buffer_cmd('save', 1)<cr>
  setf ftmacros
  syn clear
  syn match ftmacrosFt '^\S\+$'
  hi def link ftmacrosFt Statement

  if a:bang
    let b:ftmacros = {'ft': keys(g:ftmacros), 'list_all': 1}
  else
    let b:ftmacros = {'ft': ['default', ft], 'list_all': 0}
  endif

  let [ d1, d2 ] = ['%#TablineSel#', '%#Tabline#']
  let &l:statusline = '%#DiffText# Registered macros '.d1.' q '.d2.
        \' quit '.d1.' e '.d2.' edit '.d1.' a '.d2.' add '.d1.
        \' A '.d2.' add! '.d1.' m '.d2.' move '.d1.' d '.d2.' delete %#TablineFill#'
  call s:fill_buffer()
endfun

"------------------------------------------------------------------------------

fun! s:fill_buffer() abort
  call append('$', "reg.\tnote\t\tmacro")
  call append('$', repeat('-', &columns-5).' ')

  for type in b:ftmacros.ft
    if !has_key(g:ftmacros, type) || empty(g:ftmacros[type])
      continue
    endif
    call append('$', '')
    call append('$', type.':')
    for reg in keys(g:ftmacros[type])
      call append('$', reg."\t\t\t".g:ftmacros[type][reg])
      let b:ftmacros[line('$')-1] = [type, reg]
    endfor
  endfor
  call append('$', '')
  redraw!
  " go to the first macro
  normal! gg"_dd}}k
endfun

"------------------------------------------------------------------------------

fun! s:buffer_cmd(cmd, ...)
  if a:cmd == 'save' && a:1
    return ftmacros#save(1, '', 1)
  endif
  if has_key(b:ftmacros, line('.'))
    let R = b:ftmacros[line('.')]
    if a:cmd == 'save'
      call ftmacros#save(0, '', R[0])
    else
      exe printf('call ftmacros#%s(%s, "%s", "%s")', a:cmd, R[0]=='default', R[1], R[0])
    endif
  else
    call s:warn('Wrong line')
  endif
endfun

"------------------------------------------------------------------------------

fun! s:update_buffer()
  if getbufvar(bufnr('%'), 'ftmacros', {}) != {}
    let all = b:ftmacros.list_all
    q
    call ftmacros#list(all)
  endif
endfun

"------------------------------------------------------------------------------

fun! s:valid(reg)
  let valid = map(range(97, 122) + range(48, 57), 'nr2char(v:val)')
  if index(valid, a:reg) < 0
    return s:warn('[ftmacros] wrong or empty register')
  endif
  return 1
endfun

"------------------------------------------------------------------------------

fun! s:is_registered(default, register, ft) abort
  """Return true if the macro is in the g:ftmacros register.
  return  ( a:default && has_key(g:ftmacros.default, a:register) ) ||
        \ ( !empty(a:ft) && has_key(g:ftmacros, a:ft) && has_key(g:ftmacros[a:ft], a:register) ) ||
        \ ( empty(a:ft) && has_key(g:ftmacros.noft, a:register) )
endfun

"------------------------------------------------------------------------------

fun! s:writefile() abort
  return writefile(['let g:ftmacros = '.string(g:ftmacros)], fnamemodify(g:ftmacros_file, ':p')) == 0
endfun

"------------------------------------------------------------------------------

fun! s:warn(msg)
  echohl WarningMsg
  echo a:msg
  echohl None
endfun

