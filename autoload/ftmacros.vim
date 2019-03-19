fun! ftmacros#save(default, register, ...)
  if a:0    " called by buffer
    let b = a:default ? '!' : ''
    call feedkeys("\<c-u>:display\<cr>:SaveMacro ", 'n')
    return
  endif

  if !s:valid(a:register) | return | endif

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

  if a:default
    echo '[ftmacros] default macro for register' a:register 'has been saved'
  elseif !empty(&ft)
    echo '[ftmacros] macro for register' a:register 'and filetype' &ft 'has been saved'
  else
    echo '[ftmacros] macro for register' a:register 'and no filetype has been saved'
  endif
endfun

"------------------------------------------------------------------------------

fun! ftmacros#delete(default, register)
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

fun! ftmacros#edit(default, register)
  let macro = substitute(getreg(a:register), "\<Esc>", '\\<Esc>', 'g')
  if !s:valid(a:register) | return | endif

  echohl String
  let new = input('Register '.a:register.': ', macro)
  echohl None
  if empty(new) | return s:warn('Canceled') | endif

  let new = substitute(new, '\c\\<Esc>', "\<Esc>", 'g')
  call setreg(a:register, new, 'v')

  if a:default
    let g:ftmacros.default[a:register] = new
  elseif !empty(&ft)
    if !has_key(g:ftmacros, &ft)
      let g:ftmacros[&ft] = { a:register: new }
    else
      let g:ftmacros[&ft][a:register] = new
    endif
  else
    let g:ftmacros.noft[a:register] = new
  endif

  call s:update_buffer()

  if a:default
    echo '[ftmacros] default macro for register' a:register 'has been updated'
  elseif !empty(&ft)
    echo '[ftmacros] macro for register' a:register 'and filetype' &ft 'has been updated'
  else
    echo '[ftmacros] macro for register' a:register 'and no filetype has been updated'
  endif
endfun

"------------------------------------------------------------------------------

fun! ftmacros#list()
  if g:ftmacros.default == {} &&
        \ ( !has_key(g:ftmacros, &ft) && &ft != ''
        \ || &ft == '' && g:ftmacros.noft == {} )
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
  let b:ftmacros = {'ft': ft}
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

  for type in ['default', b:ftmacros.ft]
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
    exe printf('call ftmacros#%s(%s, "%s")', a:cmd, R[0]=='default', R[1])
  else
    call s:warn('Wrong line')
  endif
endfun

"------------------------------------------------------------------------------

fun! s:update_buffer()
  if getbufvar(bufnr('%'), 'ftmacros', {}) != {}
    q
    call ftmacros#list()
  endif
endfun

"------------------------------------------------------------------------------

fun! s:valid(reg)
  let valid = map(range(97, 122) + range(48, 57), 'nr2char(v:val)')
  if getregtype(a:reg) !=# 'v' || index(valid, a:reg) < 0
    return s:warn('[ftmacros] wrong or empty register')
  endif
  return 1
endfun

"------------------------------------------------------------------------------

fun! s:warn(msg)
  echohl WarningMsg
  echo a:msg
  echohl None
endfun

