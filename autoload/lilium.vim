" =============================================================================
" URL: https://github.com/llimllib/lilium
" Filename: autoload/lilium.vim
" Author: llimllib 
" Email: bill@billmill.org
" License: MIT License
" =============================================================================

function! lilium#get_configuration() "{{{
  return {
        \ 'style': get(g:, 'lilium_style', 'default'),
        \ 'colors_override': get(g:, 'lilium_colors_override', {}),
        \ 'transparent_background': get(g:, 'lilium_transparent_background', 0),
        \ 'dim_inactive_windows': get(g:, 'lilium_dim_inactive_windows', 0),
        \ 'disable_italic_comment': get(g:, 'lilium_disable_italic_comment', 0),
        \ 'enable_italic': get(g:, 'lilium_enable_italic', 0),
        \ 'cursor': get(g:, 'lilium_cursor', 'auto'),
        \ 'menu_selection_background': get(g:, 'lilium_menu_selection_background', 'blue'),
        \ 'spell_foreground': get(g:, 'lilium_spell_foreground', 'none'),
        \ 'show_eob': get(g:, 'lilium_show_eob', 1),
        \ 'current_word': get(g:, 'lilium_current_word', get(g:, 'lilium_transparent_background', 0) == 0 ? 'grey background' : 'bold'),
        \ 'lightline_disable_bold': get(g:, 'lilium_lightline_disable_bold', 0),
        \ 'diagnostic_text_highlight': get(g:, 'lilium_diagnostic_text_highlight', 0),
        \ 'diagnostic_line_highlight': get(g:, 'lilium_diagnostic_line_highlight', 0),
        \ 'diagnostic_virtual_text': get(g:, 'lilium_diagnostic_virtual_text', 'grey'),
        \ 'disable_terminal_colors': get(g:, 'lilium_disable_terminal_colors', 0),
        \ 'better_performance': get(g:, 'lilium_better_performance', 0),
        \ }
endfunction "}}}
function! lilium#get_palette(style, colors_override) "{{{
  " to get the bg colors:
  " In [1]: from colour import Color
  " In [26]: c = Color("#252A39")
  " In [27]: for i in range(5):
  "     ...:     print(c.hex)
  "     ...:     c.luminance += 0.025
  "     ...: 

  " yellow-green on the bench: #9dd274
  " purple on the bench: #ba9cf3
  let palette = {
        \ 'black':      ['#181a1c',   '232'],
        \ 'bg_dim':     ['#24272e',   '232'],
        \ 'bg0':        ['#252A39',   '235'],
        \ 'bg1':        ['#2a3041',   '236'],
        \ 'bg2':        ['#2f3548',   '236'],
        \ 'bg3':        ['#343b50',   '237'],
        \ 'bg4':        ['#394158',   '237'],
        \ 'bg_red':     ['#ff6d7e',   '203'],
        \ 'diff_red':   ['#55393d',   '52'],
        \ 'bg_green':   ['#a5e179',   '107'],
        \ 'diff_green': ['#394634',   '22'],
        \ 'bg_blue':    ['#7ad5f1',   '110'],
        \ 'diff_blue':  ['#354157',   '17'],
        \ 'diff_yellow':['#4e432f',   '54'],
        \ 'fg':         ['#e1e3e4',   '250'],
        \ 'red':        ['#F47648',   '203'],
        \ 'orange':     ['#8ED0B2',   '215'],
        \ 'yellow':     ['#8ED0B2',   '179'],
        \ 'green':      ['#40BA93',   '107'],
        \ 'blue':       ['#72cce8',   '110'],
        \ 'purple':     ['#fca07f',   '176'],
        \ 'grey':       ['#828a9a',   '246'],
        \ 'grey_dim':   ['#5a6477',   '240'],
        \ 'none':       ['NONE',      'NONE']
        \ }
  return extend(palette, a:colors_override)
endfunction "}}}
function! lilium#highlight(group, fg, bg, ...) "{{{
  execute 'highlight' a:group
        \ 'guifg=' . a:fg[0]
        \ 'guibg=' . a:bg[0]
        \ 'ctermfg=' . a:fg[1]
        \ 'ctermbg=' . a:bg[1]
        \ 'gui=' . (a:0 >= 1 ?
          \ a:1 :
          \ 'NONE')
        \ 'cterm=' . (a:0 >= 1 ?
          \ a:1 :
          \ 'NONE')
        \ 'guisp=' . (a:0 >= 2 ?
          \ a:2[0] :
          \ 'NONE')
endfunction "}}}
function! lilium#syn_gen(path, last_modified, msg) "{{{
  " Generate the `after/syntax` directory.
  let full_content = join(readfile(a:path), "\n") " Get the content of `colors/lilium.vim`
  let syn_conent = []
  let rootpath = lilium#syn_rootpath(a:path) " Get the path to place the `after/syntax` directory.
  call substitute(full_content, '" syn_begin.\{-}syn_end', '\=add(syn_conent, submatch(0))', 'g') " Search for 'syn_begin.\{-}syn_end' (non-greedy) and put all the search results into a list.
  for content in syn_conent
    let syn_list = []
    call substitute(matchstr(matchstr(content, 'syn_begin:.\{-}{{{'), ':.\{-}{{{'), '\(\w\|-\)\+', '\=add(syn_list, submatch(0))', 'g') " Get the file types. }}}}}}
    for syn in syn_list
      call lilium#syn_write(rootpath, syn, content) " Write the content.
    endfor
  endfor
  call lilium#syn_write(rootpath, 'text', "let g:lilium_last_modified = '" . a:last_modified . "'") " Write the last modified time to `after/syntax/text/lilium.vim`
  let syntax_relative_path = has('win32') ? '\after\syntax' : '/after/syntax'
  if a:msg ==# 'update'
    echohl WarningMsg | echom '[lilium] Updated ' . rootpath . syntax_relative_path | echohl None
    call lilium#ftplugin_detect(a:path)
  else
    echohl WarningMsg | echom '[lilium] Generated ' . rootpath . syntax_relative_path | echohl None
    execute 'set runtimepath+=' . fnamemodify(rootpath, ':p') . 'after'
  endif
endfunction "}}}
function! lilium#syn_write(rootpath, syn, content) "{{{
  " Write the content.
  let syn_path = a:rootpath . '/after/syntax/' . a:syn . '/lilium.vim' " The path of a syntax file.
  " create a new file if it doesn't exist
  if !filereadable(syn_path)
    call mkdir(a:rootpath . '/after/syntax/' . a:syn, 'p')
    call writefile([
          \ "if !exists('g:colors_name') || g:colors_name !=# 'lilium'",
          \ '    finish',
          \ 'endif'
          \ ], syn_path, 'a') " Abort if the current color scheme is not lilium.
    call writefile([
          \ "if index(g:lilium_loaded_file_types, '" . a:syn . "') ==# -1",
          \ "    call add(g:lilium_loaded_file_types, '" . a:syn . "')",
          \ 'else',
          \ '    finish',
          \ 'endif'
          \ ], syn_path, 'a') " Abort if this file type has already been loaded.
  endif
  " If there is something like `call lilium#highlight()`, then add
  " code to initialize the palette and configuration.
  if matchstr(a:content, 'lilium#highlight') !=# ''
    call writefile([
          \ 'let s:configuration = lilium#get_configuration()',
          \ 'let s:palette = lilium#get_palette(s:configuration.style, s:configuration.colors_override)'
          \ ], syn_path, 'a')
  endif
  " Append the content.
  call writefile(split(a:content, "\n"), syn_path, 'a')
  " Add modeline.
  call writefile(['" vim: set sw=2 ts=2 sts=2 et tw=80 ft=vim fdm=marker fmr={{{,}}}:'], syn_path, 'a')
endfunction "}}}
function! lilium#syn_rootpath(path) "{{{
  " Get the directory where `after/syntax` is generated.
  if (matchstr(a:path, '^/usr/share') ==# '') " Return the plugin directory. The `after/syntax` directory should never be generated in `/usr/share`, even if you are a root user.
    return fnamemodify(a:path, ':p:h:h')
  else " Use vim home directory.
    if has('nvim')
      return stdpath('config')
    else
      return expand('~') . '/.vim'
    endif
  endif
endfunction "}}}
function! lilium#syn_newest(path, last_modified) "{{{
  " Determine whether the current syntax files are up to date by comparing the last modified time in `colors/lilium.vim` and `after/syntax/text/lilium.vim`.
  let rootpath = lilium#syn_rootpath(a:path)
  execute 'source ' . rootpath . '/after/syntax/text/lilium.vim'
  return a:last_modified ==# g:lilium_last_modified ? 1 : 0
endfunction "}}}
function! lilium#syn_clean(path, msg) "{{{
  " Clean the `after/syntax` directory.
  let rootpath = lilium#syn_rootpath(a:path)
  " Remove `after/syntax/**/lilium.vim`.
  let file_list = split(globpath(rootpath, 'after/syntax/**/lilium.vim'), "\n")
  for file in file_list
    call delete(file)
  endfor
  " Remove empty directories.
  let dir_list = split(globpath(rootpath, 'after/syntax/*'), "\n")
  for dir in dir_list
    if globpath(dir, '*') ==# ''
      call delete(dir, 'd')
    endif
  endfor
  if globpath(rootpath . '/after/syntax', '*') ==# ''
    call delete(rootpath . '/after/syntax', 'd')
  endif
  if globpath(rootpath . '/after', '*') ==# ''
    call delete(rootpath . '/after', 'd')
  endif
  if a:msg
    let syntax_relative_path = has('win32') ? '\after\syntax' : '/after/syntax'
    echohl WarningMsg | echom '[lilium] Cleaned ' . rootpath . syntax_relative_path | echohl None
  endif
endfunction "}}}
function! lilium#syn_exists(path) "{{{
  return filereadable(lilium#syn_rootpath(a:path) . '/after/syntax/text/lilium.vim')
endfunction "}}}
function! lilium#ftplugin_detect(path) "{{{
  " Check if /after/ftplugin exists.
  " This directory is generated in earlier versions, users may need to manually clean it.
  let rootpath = lilium#syn_rootpath(a:path)
  if filereadable(lilium#syn_rootpath(a:path) . '/after/ftplugin/text/lilium.vim')
    let ftplugin_relative_path = has('win32') ? '\after\ftplugin' : '/after/ftplugin'
    echohl WarningMsg | echom '[lilium] Detected ' . rootpath . ftplugin_relative_path | echohl None
    echohl WarningMsg | echom '[lilium] This directory is no longer used, you may need to manually delete it.' | echohl None
  endif
endfunction "}}}

" vim: set sw=2 ts=2 sts=2 et tw=80 ft=vim fdm=marker fmr={{{,}}}:
