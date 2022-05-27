if exists('g:loaded_kanban') || !has('nvim-0.5.0')
    finish
endif
let g:loaded_kanban = 1

function s:try(cmd)
    try
        execute a:cmd
    catch /E12/
        return
    endtry
endfunction

command! -bang Kanban call s:try('lua require("kanban").load("<bang>" == "!")')
