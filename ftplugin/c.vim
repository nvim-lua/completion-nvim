" Last Change: 2020 mar 20


let b:completion_context_query = '((function_definition) @context)'

let b:completion_ident_query = '(function_declarator declarator: (identifier) @func)
            \ (preproc_def name: (identifier) @preproc)
            \ (preproc_function_def name: (identifier) @preproc)
            \ (parameter_declaration declarator: (identifier) @param)
            \ (parameter_declaration declarator: (pointer_declarator declarator: (identifier) @param))
            \ (array_declarator declarator: (identifier) @var)
            \ (pointer_declarator declarator: (identifier) @var)
            \ (init_declarator declarator: (identifier) @var)
            \ (declaration declarator: (identifier) @var)'
