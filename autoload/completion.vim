" Perform a Hack to confirm completion
function! completion#completion_confirm() abort
    lua require'completion'.confirmCompletion()
    call nvim_feedkeys("\<C-Y>", "n", v:true)
endfunction

function! completion#wrap_completion() abort
    if pumvisible() != 0 && complete_info()["selected"] != "-1"
        call completion#completion_confirm()
    else
        call nvim_feedkeys("\<c-g>\<c-g>", "n", v:true)
        let key = g:completion_confirm_key
        call nvim_feedkeys(key, "n", v:true)
    endif
endfunction

" Depracated
" Wrapper to get manually trigger working
" Please send me a pull request if you know how to do this properly...
function! completion#completion_wrapper()
    lua require'completion'.triggerCompletion()
    return ''
endfunction

" Depracated
function! completion#trigger_completion()
    return "\<c-r>=completion#completion_wrapper()\<CR>"
endfunction

" Depracated
" Wrapper of getting buffer variable
" Avoid accessing to unavailable variable
function! completion#get_buffer_variable(str)
    return get(b:, a:str, v:null)
endfunction

function! completion#enable_in_comment()
    let l:list = g:completion_chain_complete_list
    if type(l:list) == v:t_dict && has_key(l:list, 'default')
                \ && type(l:list.default) == v:t_dict
                \ && has_key(l:list.default, 'comment')
        call remove(g:completion_chain_complete_list, 'comment')
    endif
endfunction
