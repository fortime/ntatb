
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"                                                                              "
" File Name:   ntatb                                                           "
" Abstract:    A (G)Vim plugin forked from trinity 2.1. It replaces 'Taglist'  "
"              with 'Tagbar'. And support for 'Source Explorer' is canceled.   "
" Authors:     Wenlong Che <wenlong.che@gmail.com>                             "
"              Fortime Fan <palfortime@gmail.com>                              "
" GitHub:      https://github.com/fortime/ntatb                                "
" Version:     0.2                                                             "
" Last Change: August 11th, 2013                                               "
" Licence:     This program is free software; you can redistribute it and / or "
"              modify it under the terms of the GNU General Public License as  "
"              published by the Free Software Foundation; either version 2, or "
"              any later version.                                              "
"                                                                              "
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Avoid reloading {{{

if exists('loaded_ntatb')
    finish
endif

let loaded_ntatb = 1
let s:save_cpo = &cpoptions

set cpoptions&vim

autocmd bufenter * call <SID>Ntatb_CloseIfOnly()

" }}}

" VIM version control {{{

" The VIM version control for running the Ntatb

if v:version < 700
    " Tell the user what has happened
    echohl ErrorMsg
        echo "Require VIM 7.0 or above for running the Ntatb."
    echohl None
    finish
endif

" }}}

" User interfaces {{{

" User interface for switching all the three plugins

command! -nargs=0 -bar NtatbToggleAll
    \ call <SID>Ntatb_Toggle()

" User interface for switching the Tagbar

command! -nargs=0 -bar NtatbToggleTagbar
    \ call <SID>Ntatb_ToggleTagbar()

" User interface for switching the NERD tree

command! -nargs=0 -bar NtatbToggleNERDTree
    \ call <SID>Ntatb_ToggleNERDTree()

" User interface for updating window positions
" e.g. open/close Quickfix

command! -nargs=0 -bar NtatbUpdateWindow
    \ call <SID>Ntatb_UpdateWindow()

" }}}

" Global variables {{{

let s:Ntatb_switch         = 0
let s:Ntatb_tabPage        = 0
let s:Ntatb_isDebug        = 0
let s:Ntatb_logPath        = '~/ntatb.log'

let s:tagbar_switch        = 0
let s:tagbar_title         = "__Tagbar__"

let s:nerd_tree_switch       = 0
let s:nerd_tree_title        = "NERD_tree_1"

let s:pluginList = [
        \ s:tagbar_title,
        \ s:nerd_tree_title
    \]

" }}}

" Ntatb_CloseIfOnly() {{{

" auto quit vim, if there are only ntatb's window.

function! <SID>Ntatb_CloseIfOnly()
    " no ntatb's window, exit
    if s:Ntatb_switch == 0
        return
    endif
    " window's amount is more than ntatb's, exit
    let l:amount = winnr("$")
    if l:amount > len(s:pluginList)
        return
    endif
    " find non ntatb's window
    let l:rtn = <SID>Ntatb_GetEditWin()
    if l:rtn == -1
        qa
    endif
endfunction " }}}

" Ntatb_InitTagbar() {{{

" Initialize the parameters of the 'Tagbar' plugin

function! <SID>Ntatb_InitTagbar()
    " Split to the left side of the screen
    if exists('g:tagbar_left') == 0
        let g:tagbar_left = 1
    endif
    " Set the window width
    if exists('g:tagbar_width') == 0
        let g:tagbar_width = 30
    endif
    " Sort by file order
    if exists('g:tagbar_sort') == 0
        let g:tagbar_sort = 1
    endif
    " Use compact view to save screen real estate
    if exists('g:tagbar_compact') == 0
        let g:tagbar_compact = 1
    endif
    " Auto open a closed fold if the current tag is in it
    if exists('g:tagbar_autoshowtag') == 0
        let g:tagbar_autoshowtag = 1
    endif

    " If you are the last, kill yourself
    "let g:Tlist_Exit_OnlyWindow = 1
    " Do not close tags for other files
    "let g:Tlist_File_Fold_Auto_Close = 1
    " Do not show folding tree
    "let g:Tlist_Enable_Fold_Column = 0
    " Always display one file tags
    "let g:Tlist_Show_One_File = 1

endfunction " }}}

" Ntatb_InitNERDTree() {{{

" Initialize the parameters of the 'NERD tree' plugin

function! <SID>Ntatb_InitNERDTree()

    " Set the window width
    if exists('g:NERDTreeWinSize') == 0
        let g:NERDTreeWinSize = 23
    endif
    " Set the window position
    if exists('g:NERDTreeWinPos') == 0
        let g:NERDTreeWinPos = "right"
    endif
    " Auto centre
    if exists('g:NERDTreeAutoCenter') == 0
        let g:NERDTreeAutoCenter = 0
    endif
    " Not Highlight the cursor line
    if exists('g:NERDTreeHighlightCursorline') == 0
        let g:NERDTreeHighlightCursorline = 0
    endif

endfunction " }}}

" Ntatb_Debug() {{{

" Log the supplied debug information along with the time

function! <SID>Ntatb_Debug(log)

    " Debug switch is on
    if s:Ntatb_isDebug == 1
        " Log file path is valid
        if s:Ntatb_logPath != ''
            " Output to the log file
            exe "redir >> " . s:Ntatb_logPath
            " Add the current time
            silent echon strftime("%H:%M:%S") . ": " . a:log . "\r\n"
            redir END
        endif
    endif

endfunction " }}}

" Ntatb_GetEditWin() {{{

" Get the edit window number

function! <SID>Ntatb_GetEditWin()

    let l:i = 1

    while 1
        " use for flaging whether window not in plugin list is found or not.
        let l:found = 1

        " compatible for Named Buffer Version and Preview Window Version
        for item in s:pluginList
            if (bufname(winbufnr(l:i)) ==# item)
                let l:found = 0
                break
            endif
        endfor

        if l:found == 1
            return l:i
        else
            let l:i += 1
        endif

        if l:i > winnr("$")
            return -1
        endif
    endwhile

endfunction " }}}

" Ntatb_UpdateWindow() {{{

" Update the postions of the whole IDE windows

function! <SID>Ntatb_UpdateWindow()

    let l:rtn = <SID>Ntatb_GetEditWin()
    if l:rtn < 0
        return
    endif

    silent! exe l:rtn . "wincmd w"

endfunction " }}}

" Ntatb_UpdateStatus() {{{

" Update status according to the status of the three plugins

function! <SID>Ntatb_UpdateStatus()

    if s:tagbar_switch == 1 ||
    \ s:nerd_tree_switch == 1
        let s:Ntatb_switch = 1
    endif

    if s:tagbar_switch == 0 &&
    \ s:nerd_tree_switch == 0
        let s:Ntatb_switch = 0
    endif

endfunction " }}}

" Ntatb_ToggleNERDTree() {{{

" Initialize the parameters of the 'NERD tree' plugin

function! <SID>Ntatb_ToggleNERDTree()

    if s:Ntatb_tabPage == 0
        let s:Ntatb_tabPage = tabpagenr()
    endif

    if s:Ntatb_tabPage != tabpagenr()
        echohl ErrorMsg
            echo "Ntatb: Not support multiple tab pages for now."
        echohl None
        return
    endif

    call <SID>Ntatb_UpdateStatus()
    if s:Ntatb_switch == 0
        if s:nerd_tree_switch == 0
            call <SID>Ntatb_InitNERDTree()
            NERDTree
            let s:nerd_tree_switch = 1
        endif
    else
        if s:nerd_tree_switch == 1
            NERDTreeClose
            let s:nerd_tree_switch = 0
        else
            call <SID>Ntatb_InitNERDTree()
            NERDTree
            let s:nerd_tree_switch = 1
        endif
    endif

    call <SID>Ntatb_UpdateStatus()
    call <SID>Ntatb_UpdateWindow()

    if s:Ntatb_switch == 0
        let s:Ntatb_tabPage = 0
    endif

endfunction " }}}

" Ntatb_ToggleTagbar() {{{

" The User Interface function to open / close the Tagbar

function! <SID>Ntatb_ToggleTagbar()

    if s:Ntatb_tabPage == 0
        let s:Ntatb_tabPage = tabpagenr()
    endif
    if s:Ntatb_tabPage != tabpagenr()
        echohl ErrorMsg
            echo "Ntatb: Not support multiple tab pages for now."
        echohl None
        return
    endif
    call <SID>Ntatb_UpdateStatus()
    if s:Ntatb_switch == 0
        if s:tagbar_switch == 0
            call <SID>Ntatb_InitTagbar()
            TagbarOpen 
            let s:tagbar_switch = 1
        endif
    else
        if s:tagbar_switch == 1
            TagbarClose 
            let s:tagbar_switch = 0
        else
            call <SID>Ntatb_InitTagbar()
            TagbarOpen
            let s:tag_list_switch = 1
        endif
    endif

    call <SID>Ntatb_UpdateStatus()
    call <SID>Ntatb_UpdateWindow()

    if s:Ntatb_switch == 0
        let s:Ntatb_tabPage = 0
    endif

endfunction " }}}

" Ntatb_Toggle() {{{

" The User Interface function to open / close the Ntatb of
" Tagbar and NERD tree

function! <SID>Ntatb_Toggle()

    if s:Ntatb_tabPage == 0
        let s:Ntatb_tabPage = tabpagenr()
    endif

    if s:Ntatb_tabPage != tabpagenr()
        echohl ErrorMsg
            echo "Ntatb: Not support multiple tab pages for now."
        echohl None
        return
    endif

    if s:Ntatb_switch == 1
        if s:tagbar_switch == 1
            TagbarClose
            let s:tagbar_switch = 0
        endif
        if s:nerd_tree_switch == 1
            NERDTreeClose
            let s:nerd_tree_switch = 0
        endif
        let s:Ntatb_switch = 0
        let s:Ntatb_tabPage = 0
    else
        call <SID>Ntatb_InitTagbar()
        TagbarOpen
        let s:tagbar_switch = 1
        call <SID>Ntatb_InitNERDTree()
        NERDTree
        let s:nerd_tree_switch = 1
        let s:Ntatb_switch = 1
    endif

    call <SID>Ntatb_UpdateWindow()

endfunction " }}}

" Avoid side effects {{{

set cpoptions&
let &cpoptions = s:save_cpo
unlet s:save_cpo

" }}}

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" vim:foldmethod=marker:tabstop=4

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

