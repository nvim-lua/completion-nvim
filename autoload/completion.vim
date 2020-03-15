" Perform a Hack to confirm completion
function! completion#completion_confirm() abort
    call nvim_feedkeys("\<c-y>", 'n', v:true)
endfunction

function! completion#wrap_completion() abort
    if pumvisible() != 0
        lua require'completion'.confirmCompletion()
    else
        let key = g:completion_confirm_key
        let remap = 'n'
        if !empty(g:completion_confirm_key_rhs)
            let key = g:completion_confirm_key_rhs
            let remap = 'm'
        endif

        call nvim_feedkeys(key, remap, v:true)
    endif
endfunction

" Wrapper to get manually trigger working
" Please send me a pull request if you know how to do this properly...
function! completion#completion_wrapper()
    lua require'completion'.triggerCompletion(true)
    return ''
endfunction

function! completion#trigger_completion()
    return "\<c-r>=completion#completion_wrapper()\<CR>"
endfunction

