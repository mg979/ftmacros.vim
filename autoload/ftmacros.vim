
fun! ftmacros#save(default, register)
  if getregtype(a:register) !=# 'v'
    return s:warn('[ftmacros] wrong or empty register')
  endif

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

  if a:default
    echo '[ftmacros] default macro for register' a:register 'has been deleted'
  elseif !empty(&ft)
    echo '[ftmacros] macro for register' a:register 'and filetype' &ft 'has been deleted'
  else
    echo '[ftmacros] macro for register' a:register 'and no filetype has been deleted'
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
  nnoremap <buffer> q :q!<cr>
  setf ftmacros
  syn clear
  syn match ftmacrosFt '^\S\+$'
  hi def link ftmacrosFt Statement

  call append('$', "reg.\tnote\t\tmacro")
  call append('$', repeat('-', &columns).' ')

  for type in ['default', ft]
    if !has_key(g:ftmacros, type) || empty(g:ftmacros[type])
      echom type
      continue
    endif
    call append('$', '')
    call append('$', type.':')
    for reg in keys(g:ftmacros[type])
      call append('$', reg."\t\t\t".g:ftmacros[type][reg])
    endfor
  endfor
  normal! gg"_dd}
endfun

"------------------------------------------------------------------------------

fun! s:warn(msg)
  echohl WarningMsg
  echo a:msg
  echohl None
endfun

