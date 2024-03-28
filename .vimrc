" create a file name .vimrc in your home folder and then copy-paste
" save local mark https://www.linux.com/news/vim-tips-moving-around-using-marks-and-jumps/
set viminfo='100,f1
" enable find in subdirectory
set path+=**
" enable highlight search
" set hlsearch
" enable line number
" set nu
" enable always display file name
set laststatus=2
" set backgroud of vim to dark
set background=dark
" The width of a TAB is set to 4. Still it is a \t. It is just that Vim will interpret it to be having a width of 4
set tabstop=4
" Indents will have a width of 4
set shiftwidth=4
" Sets the number of columns for a TAB
set softtabstop=4
" Enable syntax highlight
syntax on
" Expand TABs to spaces
set expandtab
" Set no cursorline
set nocursorline
" Highlight selected tab
hi TabLineSel ctermfg=Black ctermbg=White
" Rename tabs to show tab number.
" (Based on http://stackoverflow.com/questions/5927952/whats-implementation-of-vims-default-tabline-function)
if exists("+showtabline")
    function! MyTabLine()
        let s = ''
        let wn = ''
        let t = tabpagenr()
        let i = 1
        while i <= tabpagenr('$')
            let buflist = tabpagebuflist(i)
            let winnr = tabpagewinnr(i)
            let s .= '%' . i . 'T'
            let s .= (i == t ? '%1*' : '%2*')
            let s .= ' '
            let wn = tabpagewinnr(i,'$')

            let s .= '%#TabNum#'
            let s .= i
            " let s .= '%*'
            let s .= (i == t ? '%#TabLineSel#' : '%#TabLine#')
            let bufnr = buflist[winnr - 1]
            let file = bufname(bufnr)
            let buftype = getbufvar(bufnr, 'buftype')
            if buftype == 'nofile'
                if file =~ '\/.'
                    let file = substitute(file, '.*\/\ze.', '', '')
                endif
            else
                let file = fnamemodify(file, ':p:t')
            endif
            if file == ''
                let file = '[No Name]'
            endif
            let s .= ' ' . file . ' '
            let i = i + 1
        endwhile
        let s .= '%T%#TabLineFill#%='
        let s .= (tabpagenr('$') > 1 ? '%999XX' : 'X')
        return s
    endfunction
    set stal=2
    set tabline=%!MyTabLine()
    set showtabline=1
    highlight link TabNum Special
endif

" Return indent (all whitespace at start of a line), converted from
" tabs to spaces if what = 1, or from spaces to tabs otherwise.
" When converting to tabs, result has no redundant spaces.
function! Indenting(indent, what, cols)
  let spccol = repeat(' ', a:cols)
  let result = substitute(a:indent, spccol, '\t', 'g')
  let result = substitute(result, ' \+\ze\t', '', 'g')
  if a:what == 1
    let result = substitute(result, '\t', spccol, 'g')
  endif
  return result
endfunction

" Convert whitespace used for indenting (before first non-whitespace).
" what = 0 (convert spaces to tabs), or 1 (convert tabs to spaces).
" cols = string with number of columns per tab, or empty to use 'tabstop'.
" The cursor position is restored, but the cursor will be in a different
" column when the number of characters in the indent of the line is changed.
function! IndentConvert(line1, line2, what, cols)
  let savepos = getpos('.')
  let cols = empty(a:cols) ? &tabstop : a:cols
  execute a:line1 . ',' . a:line2 . 's/^\s\+/\=Indenting(submatch(0), a:what, cols)/e'
  call histdel('search', -1) 
  call setpos('.', savepos)
endfunction


function AlignAssignments ()
    "Patterns needed to locate assignment operators...
    let ASSIGN_OP   = '[-+*/%|&]\?=\@<!=[=~]\@!'
    let ASSIGN_LINE = '^\(.\{-}\)\s*\(' . ASSIGN_OP . '\)'

    "Locate block of code to be considered (same indentation, no blanks)
    let indent_pat = '^' . matchstr(getline('.'), '^\s*') . '\S'
    let firstline  = search('^\%('. indent_pat . '\)\@!','bnW') + 1
    let lastline   = search('^\%('. indent_pat . '\)\@!', 'nW') - 1
    if lastline < 0
        let lastline = line('$')
    endif

    "Find the column at which the operators should be aligned...
    let max_align_col = 0
    let max_op_width  = 0
    for linetext in getline(firstline, lastline)
        "Does this line have an assignment in it?
        let left_width = match(linetext, '\s*' . ASSIGN_OP)

        "If so, track the maximal assignment column and operator width...
        if left_width >= 0
            let max_align_col = max([max_align_col, left_width])

            let op_width      = strlen(matchstr(linetext, ASSIGN_OP))
            let max_op_width  = max([max_op_width, op_width+1])
         endif
    endfor

    "Code needed to reformat lines so as to align operators...
    let FORMATTER = '\=printf("%-*s%*s", max_align_col, submatch(1),
    \                                    max_op_width,  submatch(2))'

    " Reformat lines with operators aligned in the appropriate column...
    for linenum in range(firstline, lastline)
        let oldline = getline(linenum)
        let newline = substitute(oldline, ASSIGN_LINE, FORMATTER, "")
        call setline(linenum, newline)
    endfor
endfunction

nmap <silent>  ;=  :call AlignAssignments()<CR>
function! CreateGitBlame()
    let filename = expand('%')
    let start_line = line("'<")
    let end_line = line("'>") 
    let @+ = "git blame -L " . start_line . "," . end_line . " " . filename
endfunction

function! CreateGitLog()
    let filename = expand('%')
    let start_line = line("'<")
    let end_line = line("'>") 
    let @+ = "git log -L " . start_line . "," . end_line . ":" . filename
endfunction

function! StrEndsWith(str, end_pattern)
    let ptr_pos = stridx(a:str, a:end_pattern)
    if (ptr_pos != -1) && ptr_pos == (strlen(a:str) - strlen(a:end_pattern))
        return ptr_pos
    else    
        return -1
    endif
endfunction

function! HandleSpecialFilename(filename)
    let header_file = a:filename . ".h"
    let find_result = findfile(header_file)

    if strlen(find_result) == 0
        let new_filename = 'I' . a:filename
        let header_file = new_filename . ".h"
        echo 'new header file' . header_file
        let find_result = findfile(header_file)
        if strlen(find_result) == 0
            return ''
        else
            return new_filename
        endif
    endif
    return a:filename
endfunction

function! AddDefinition()
    let current_word = expand("<cword>")
    let ptr_pos = StrEndsWith(current_word, 'Ptr')
    if ptr_pos != -1 
        let keyword = strpart(current_word, 0, ptr_pos)
    else
        let keyword = current_word
    endif
    let filename = system("myvimindexer " . keyword)
    echo 'file name' filename ', keyword' keyword
endfunction

function! ToDefinition()
    let current_word = expand("<cword>")
    let ptr_pos = StrEndsWith(current_word, 'Ptr')
    if ptr_pos != -1 
        let keyword = strpart(current_word, 0, ptr_pos)
    else
        let keyword = current_word
    endif
    let filename = system('myvimindexer', keyword)
    echo 'file name' filename ', keyword' keyword
endfunction

function! ToCtor()
    let current_word = expand("<cword>")
    let ctor = current_word . "::" . current_word
    let search_match = search(ctor)
endfunction

function! ToDtor()
    let current_word = expand("<cword>")
    let dtor = current_word . "::\\~" . current_word
    echo 'search for' dtor
    let res = search(dtor)
endfunction

    
function! ToHeader()
    let current_word = expand("<cword>")
    let ptr_pos = StrEndsWith(current_word, 'Ptr')
    if ptr_pos != -1 
        let filename = strpart(current_word, 0, ptr_pos)
    else
        let filename = current_word
    endif
    echo 'got filename' filename
    let final_name = HandleSpecialFilename(filename)
    if strlen(final_name) == 0
        echo "can't find the file" 
    else
        let header_file = final_name . ".h"
        let @+ = header_file
        execute "find " . header_file
        let search_match = search(current_word)
    endif
endfunction

command! -nargs=? -range=% Space2Tab call IndentConvert(<line1>,<line2>,0,<q-args>)
command! -nargs=? -range=% Tab2Space call IndentConvert(<line1>,<line2>,1,<q-args>)
command! -nargs=? -range=% RetabIndent call IndentConvert(<line1>,<line2>,&et,<q-args>)
command DelTrailingSpace %s/\s\+$//e

" https://vim.fandom.com/wiki/Remove_unwanted_empty_lines
command DelBlankLine v/\S/d
" Execute the content of current line in shell
nmap <F6> :exec '!'.getline('.')
" Type gl to go to last active tab
au TabLeave * let g:lasttab = tabpagenr()



" tab shortcut
nnoremap tn :tabnew<CR>

nnoremap <silent> gl :exe "tabn ".g:lasttab<cr>
vnoremap <silent> gl :exe "tabn ".g:lasttab<cr>
nnoremap <silent>   <tab>  :if &modifiable && !&readonly && &modified <CR> :write<CR> :endif<CR>:bnext<CR>
nnoremap <silent> <s-tab>  :if &modifiable && !&readonly && &modified <CR> :write<CR> :endif<CR>:bprevious<CR>

command -nargs=1 Class cscope f e ^class <args>$
command -nargs=1 IClass cscope f e ^class <args> : p
command -nargs=1 Public cscope f e public <args>

command Cpp e %<.cpp 
command Hpp e %<.h



command HelpCmake tabe /Users/daominhthuc/pro_wp/git/personal_git_dir/polyglot_memory/cpp/build/cmake 
command HelpCpp vsplit /Users/daominhthuc/pro_wp/git/personal_git_dir/polyglot_memory/cpp/short_help.txt 
command HelpGit vsplit /Users/daominhthuc/pro_wp/git/personal_git_dir/polyglot_memory/git/README.txt 
command HelpBash e /Users/daominhthuc/pro_wp/git/personal_git_dir/polyglot_memory/program_languages/shell/short_help.sh 
command HelpGdb tabe /Users/daominhthuc/.local/share/vim_book/gdb.txt 
command HelpWeb tabe /Users/daominhthuc/.local/share/vim_book/web_help.txt 
command Helplldb tabe /Users/daominhthuc/pro_wp/git/polyglot_memory/cpp/debugging/lldb/lldb.txt
command Cache vsplit /Users/daominhthuc/.local/share/vim_book/Cache.txt
command CliHist vsplit /Users/daominhthuc/.local/share/vim_book/CliHist.txt 
command TmuxNote vsplit /Users/daominhthuc/.local/share/vim_book/TmuxNote.txt 
command CnchMath vsplit /Users/daominhthuc/.local/share/vim_book/CnchMath.txt
command CnchRule vsplit /Users/daominhthuc/.local/share/vim_book/CnchMagic.txt
command CodeCache vsplit /Users/daominhthuc/.local/share/vim_book/CodeCache.txt
command Sso ! echo "Crocodile!23" | pbcopy
command Zsh tabe ~/.zshrc   
command Vimrc tabe ~/.vimrc
command Ssh tabe ~/.ssh/config
command Kafka tabe /Users/daominhthuc/.local/share/vim_book/Kafka.txt
command TaskNote tabe /Users/daominhthuc/pro_wp/CNCH
command Proto tabe ./dbms/src/Protos/

nnoremap <Leader>a :call ToHeader()<CR>
nnoremap <silent> <Leader>ct :call ToCtor()<CR>
nnoremap <silent> <Leader>dt :call ToDtor()<CR>
nnoremap <Leader>d :call AddDefinition()<CR>
nnoremap <Leader>c :e %<.cpp<cr> 
nnoremap <Leader>h :e %<.h<cr> 
nnoremap <Leader>re :e %<.reference<cr> 
nnoremap <Leader>sq :e %<.sql<cr> 
nnoremap <Leader>sh :e %<.sh<cr> 
nnoremap <Leader>vr :source ~/.vimrc<cr> 
nnoremap <Leader>yy "*yy
vnoremap <C-c> "*y
nnoremap <Leader>b :redir @+ <bar> silent echon expand('%:t:')":"line(".") <bar> redir END<cr> 
nnoremap <Leader>f :redir @+ <bar> silent echon expand('%:t:') <bar> redir END<cr> 
vnoremap <silent> <Leader>bl :call CreateGitBlame()<CR>
vnoremap <Leader>cm xi/*<Esc>pa*/<Esc>
" vnoremap <Leader>um xi/*<Esc>pa*/<Esc>
vnoremap <silent> <Leader>lo :call CreateGitLog()<CR>

" nnoremap git blame

function! FindInCache(str)
    echo a:str
endfunction

command ProtoCode vsplit /Users/daominhthuc/pro_wp/git/build_generate_code/Protos/
command LoadProto cs add /Users/daominhthuc/pro_wp/git/build_generate_code/Protos/cscope.out
command LoadKafka cs add /Users/daominhthuc/pro_wp/git/other_branch/ClickHouse/contrib/cppkafka/src/cscope.out
command -nargs=1 CacheFind call FindInCache(<q-args>)
command! -nargs=? -range=% Space2Tab call IndentConvert(<line1>,<line2>,0,<q-args>)
" Show full file name: 1 <C-g>
" select open tab browse oldfiles

" the belows command has been ported to lua
" nnoremap <Leader>ga :call system(['git', 'add', expand('%:p')])<CR><Esc>
