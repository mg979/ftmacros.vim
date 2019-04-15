fun! ftmacros#save(default, register, ...)
  if a:0    " called by buffer
    let b = a:default ? '!' : ''
    call feedkeys("\<c-u>:display\<cr>:SaveMacro ", 'n')
    return
  endif

  if !s:valid(a:register) | return | endif

  let registered = s:is_registered(a:default, a:register, a:0 ? a:1 : &ft)

  if a:default
    let g:ftmacros.default[a:register] = getreg(a:register)
  elseif !empty(&ft)
    if !has_key(g:ftmacros, &ft)
      let g:ftmacros[&ft] = { a:register: getreg(a:register) }
    else
      let g:ftmacros[&ft][a:register] = getreg(a:register)
    endif
  else
    let g:ftmacros.noft[a:register] = getreg(a:register)
  endif

  try
    call writefile(['let g:ftmacros = '.string(g:ftmacros)], fnamemodify(g:ftmacros_file, ':p'))
  catch
    return s:warn('[ftmacros] failed to write file!')
  endtry

  call s:update_buffer()

  let n = registered ? 'new' : ''
  let s = registered ? 'updated' : 'saved'

  if a:default
    echo '[ftmacros]' n 'default macro for register' a:register 'has been' s
  elseif !empty(&ft)
    echo '[ftmacros]' n 'macro for register' a:register 'and filetype' &ft 'has been' s
  else
    echo '[ftmacros]' n 'macro for register' a:register 'and no filetype has been' s
  endif
endfun

"------------------------------------------------------------------------------

fun! ftmacros#delete(default, register, ...)
  try
    if a:default
      unlet g:ftmacros.default[a:register]
    elseif !empty(&ft)
      unlet g:ftmacros[&ft][a:register]
    else
      unlet g:ftmacros.noft[a:register]
    endif
  catch
    return s:warn('[ftmacros] not a valid macro')
  endtry

  try
    call writefile(['let g:ftmacros = '.string(g:ftmacros)], fnamemodify(g:ftmacros_file, ':p'))
  catch
    return s:warn('[ftmacros] failed to write file!')
  endtry

  call s:update_buffer()

  if a:default
    echo '[ftmacros] default macro for register' a:register 'has been deleted'
  elseif !empty(&ft)
    echo '[ftmacros] macro for register' a:register 'and filetype' &ft 'has been deleted'
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
  nnoremap <buffer><nowait><silent> a :call ftmacros#save(0, v:register, 1)<cr>
  nnoremap <buffer><nowait><silent> A :call ftmacros#save(1, v:register, 1)<cr>
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
        \' A '.d2.' add! '.d1.' d '.d2.' delete %#TablineFill#'
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
  if has_key(b:ftmacros, line('.'))
    let R = b:ftmacros[line('.')]
    exe printf('call ftmacros#%s(%s, "%s", "%s")', a:cmd, R[0]=='default', R[1], R[0])
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
  return  a:default && has_key(g:ftmacros.default, a:register) ||
        \ !empty(a:ft) && has_key(g:ftmacros, a:ft) && has_key(g:ftmacros[a:ft], a:register) ||
        \ empty(a:ft) && has_key(g:ftmacros.noft, a:register)
endfun

"------------------------------------------------------------------------------

fun! s:warn(msg)
  echohl WarningMsg
  echo a:msg
  echohl None
endfun

