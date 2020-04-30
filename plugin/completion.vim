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

if ! exists('g:completion_enable_auto_paren')
    let g:completion_enable_auto_paren = 0
endif

if ! exists('g:completion_enable_auto_hover')
    let g:completion_enable_auto_hover = 1
endif

if ! exists('g:completion_docked_hover')
    let g:completion_docked_hover = 0
endif

if ! exists('g:completion_docked_minimum_size')
    let g:completion_docked_minimum_size = 5
endif

if ! exists('g:completion_docked_maximum_size')
    let g:completion_docked_maximum_size = 20
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

if ! exists('g:completion_enable_auto_popup')
    let g:completion_enable_auto_popup = 1
endif

if ! exists('g:completion_trigger_keyword_length')
    let g:completion_trigger_keyword_length = 1
endif

if ! exists('g:completion_auto_change_source')
    let g:completion_auto_change_source = 0
endif

if !exists('g:completion_timer_cycle')
    let g:completion_timer_cycle = 80
endif

if ! exists('g:completion_max_items')
    let g:completion_max_items = v:null
endif

if ! exists('g:completion_chain_complete_list')
    let g:completion_chain_complete_list = {
                \ 'default' : {
                \   'default': [
                \       {'ins_complete': v:false, 'complete_items': ['lsp', 'snippet']},
                \       {'ins_complete': v:true,  'mode': '<c-p>'},
                \       {'ins_complete': v:true,  'mode': '<c-n>'}],
                \   'comment': []
                \   }
                \}
endif

if ! exists('g:completion_customize_lsp_label')
    let g:completion_customize_lsp_label = {}
endif

if ! exists('g:completion_items_priority')
    let g:completion_items_priority = {}
endif


command! -nargs=0 CompletionToggle  lua require'completion'.completionToggle()

let &cpo = s:save_cpo
unlet s:save_cpo

let g:loaded_completion = 1
