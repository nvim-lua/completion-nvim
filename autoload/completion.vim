" Perform a Hack to confirm completion
function! completion#completion_confirm() abort
    call nvim_feedkeys("\<c-y>", 'n', v:true)
endfunction

function! completion#wrap_completion() abort
    if pumvisible() != 0
        lua require'completion'.confirmCompletion()
    else
        call nvim_feedkeys(g:completion_confirm_key, 'n', v:true)
    endif
endfunction

function! completion#wrap_neosnippet_expand(expand) abort
    call nvim_feedkeys("\<C-r>=neosnippet#expand('".a:expand."')\<CR>", 'i', v:true)
endfunction
