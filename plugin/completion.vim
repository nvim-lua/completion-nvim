" Last Change: 2020 avr 01

if exists('g:loaded_completion') | finish | endif

let s:save_cpo = &cpo
set cpo&vim

if ! exists('g:completion_enable_snippet')
    let g:completion_enable_snippet = v:null
endif

if ! exists('g:completion_confirm_key')
    let g:completion_confirm_key = "\<CR>"
endif

if ! exists('g:completion_confirm_key_rhs')
    let g:completion_confirm_key_rhs = ''
endif

if ! exists('g:completion_enable_auto_hover')
    let g:completion_enable_auto_hover = 1
endif

if ! exists('g:completion_enable_focusable_hover')
    let g:completion_enable_focusable_hover = 0
endif

if ! exists('g:completion_enable_auto_signature')
    let g:completion_enable_auto_signature = 1
endif

if ! exists('g:completion_trigger_character')
    let g:completion_trigger_character = ['.']
endif

if ! exists('g:completion_auto_popup')
    let g:completion_enable_auto_popup = 1
endif

if ! exists('g:completion_trigger_keyword_length')
    let g:completion_trigger_keyword_length = 1
endif

if ! exists('g:completion_auto_change_source')
    let g:completion_auto_change_source = 0
endif

if ! exists('g:completion_max_items')
    let g:completion_max_items = v:null
endif

if ! exists('g:completion_chain_complete_list')
    let g:completion_chain_complete_list = {
                \ "default" : [
                \       {'ins_complete': v:false, 'complete_items': ['lsp', 'snippet']},
                \       {'ins_complete': v:true,  'mode': '<c-p>'},
                \       {'ins_complete': v:true,  'mode': '<c-n>'}],
                \ 'rust' : {
                \       '.*comment.*': []
                \   }
                \}
endif

command! -nargs=0 CompletionToggle  lua require'completion'.completionToggle()

let &cpo = s:save_cpo
unlet s:save_cpo

let g:loaded_completion = 1
