" A Neovim plugin that implements GUI helper commands
if !has('nvim') || exists('g:GuiLoaded')
  finish
endif
let g:GuiLoaded = 1

" Close the GUI
function! GuiClose() abort
  call rpcnotify(0, 'Gui', 'Close')
endfunction

" Notify the GUI when exiting Neovim
autocmd VimLeave * call GuiClose()

" A replacement for foreground()
function! GuiForeground() abort
  call rpcnotify(0, 'Gui', 'Foreground')
endfunction

" Set maximized state for GUI window (1 is enabled, 0 disabled)
function! GuiWindowMaximized(enabled) abort
  call rpcnotify(0, 'Gui', 'WindowMaximized', a:enabled)
endfunction

" Set fullscreen state for GUI window (1 is enabled, 0 disabled)
function! GuiWindowFullScreen(enabled) abort
  call rpcnotify(0, 'Gui', 'WindowFullScreen', a:enabled)
endfunction

" Set GUI font
function! GuiFont(fname, ...) abort
  let force = get(a:000, 0, 0)
  call rpcnotify(0, 'Gui', 'Font', a:fname, force)
endfunction

" Set additional linespace
function! GuiLinespace(height) abort
  call rpcnotify(0, 'Gui', 'Linespace', a:height)
endfunction

" Configure mouse hide behaviour (1 is enabled, 0 disabled)
function! GuiMousehide(enabled) abort
  call rpcnotify(0, 'Gui', 'Mousehide', a:enabled)
endfunction

" The GuiFont command. For compatibility there is also Guifont
function s:GuiFontCommand(fname, bang) abort
  if a:fname ==# ''
    if exists('g:GuiFont')
      echo g:GuiFont
    else
      echo 'No GuiFont is set'
    endif
  else
    call GuiFont(a:fname, a:bang ==# '!')
  endif
endfunction
command! -nargs=? -bang Guifont call s:GuiFontCommand("<args>", "<bang>")
command! -nargs=? -bang GuiFont call s:GuiFontCommand("<args>", "<bang>")

function s:GuiLinespaceCommand(height) abort
  if a:height ==# ''
    if exists('g:GuiLinespace')
      echo g:GuiLinespace
    else
      echo 'No GuiLinespace is set'
    endif
  else
    call GuiLinespace(a:height)
  endif
endfunction
command! -nargs=? GuiLinespace call s:GuiLinespaceCommand("<args>")

function! s:GuiTabline(enable) abort
	call rpcnotify(0, 'Gui', 'Option', 'Tabline', a:enable)
endfunction
command! -nargs=1 GuiTabline call s:GuiTabline(<args>)

" GuiDrop('file1', 'file2', ...) is similar to :drop file1 file2 ...
" but it calls fnameescape() over all arguments
function GuiDrop(...)
	let l:fnames = deepcopy(a:000)
	let l:args = map(l:fnames, 'fnameescape(v:val)')
	exec 'drop '.join(l:args, ' ')
	if !has('nvim-0.2')
		doautocmd BufEnter
	endif
endfunction

function! s:on_gui_event(jobid, data, event)
  if a:event ==# 'exit'
    let g:GuiJobId = 0
    if a:data != 0
      echoerr 'GUI closed with exit code ' . a:data
    endif
  elseif a:event ==# 'stderr'
	for line in a:data
		call chansend(v:stderr, string(a:data))
	endfor
  endif
endfunction

" Start GUI from nvim, a wrapper around jobstart()
function! GuiStart(argv)
  " TODO: add option for rpc variant
  let jobopts = {
    \ 'on_exit': function('s:on_gui_event'),
    \ 'on_stderr': function('s:on_gui_event'),
    \ }
  let jobid = jobstart(a:argv, jobopts)

  if jobid == 0
    echoerr 'Could not spawn GUI, jobstart returned 0'
    return 0
  elseif jobid == -1
    echoerr 'Could not spawn GUI, failed to execute' . string(a:argv)
    return 0
  else
    let g:GuiJobId = jobid
    return 1
  endif
endfunction
