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
    let g:completion_trigger_character = []
endif

if ! exists('g:completion_enable_server_trigger')
    let g:completion_enable_server_trigger = 1
endif

if ! exists('g:completion_enable_auto_popup')
    let g:completion_enable_auto_popup = 1
endif

if ! exists('g:completion_trigger_on_delete')
    let g:completion_trigger_on_delete = 0
end

if ! exists('g:completion_trigger_keyword_length')
    let g:completion_trigger_keyword_length = 1
endif

if ! exists('g:completion_auto_change_source')
    let g:completion_auto_change_source = 0
endif

if !exists('g:completion_timer_cycle')
    let g:completion_timer_cycle = 80
endif

if ! exists('g:completion_sorting')
    let g:completion_sorting = 'alphabet'
endif

if ! exists('g:completion_fuzzy_match')
    let g:completion_enable_fuzzy_match = 0
endif

if ! exists('g:completion_expand_characters')
    let g:completion_expand_characters = [' ', '\t', '>', ';']
endif

if ! exists('g:completion_matching_ignore_case')
    let g:completion_matching_ignore_case = &ignorecase
endif

if ! exists('g:completion_matching_smart_case')
    let g:completion_matching_smart_case = &smartcase
endif

if ! exists('g:completion_matching_strategy_list')
    let g:completion_matching_strategy_list = ['exact']
endif

if ! exists('g:completion_chain_complete_list')
    let g:completion_chain_complete_list = {
                \ 'default' : {
                \   'default': [
                \       {'complete_items': ['lsp', 'snippet']},
                \       {'mode': '<c-p>'},
                \       {'mode': '<c-n>'}],
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

if ! exists('g:completion_abbr_length')
    let g:completion_abbr_length = 0
endif

if ! exists('g:completion_menu_length')
    let g:completion_menu_length = 0
endif

if ! exists('g:completion_items_duplicate')
    let g:completion_items_duplicate = {}
endif

inoremap <silent> <Plug>(completion_confirm_completion)
      \ <cmd>call completion#wrap_completion()<CR>

inoremap <silent> <Plug>(completion_next_source)
      \ <cmd>lua require'completion'.nextSource()<CR>

inoremap <silent> <Plug>(completion_prev_source)
      \ <cmd>lua require'completion'.prevSource()<CR>

inoremap <silent> <Plug>(completion_smart_tab)
      \ <cmd>lua require'completion'.smart_tab()<CR>

inoremap <silent> <Plug>(completion_smart_s_tab)
      \ <cmd>lua require'completion'.smart_s_tab()<CR>

inoremap <silent> <Plug>(completion_trigger)
      \ <cmd>lua require'completion'.triggerCompletion()<CR>

command! -nargs=0 CompletionToggle  lua require'completion'.completionToggle()

let &cpo = s:save_cpo
unlet s:save_cpo

let g:loaded_completion = 1


