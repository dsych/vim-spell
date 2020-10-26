let s:plugin_dir = expand("<sfile>:p:h:h")
let s:words_dir = s:plugin_dir . "/words"
let s:spell_dir = s:plugin_dir . "/spell"
let s:tags_dir = s:plugin_dir . "/tags"

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Functions to build spell files
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Build .spl files from word lists
function! spell#BuildAllSyntaxFiles()
  let wordlists = split(globpath(s:words_dir, "*.txt"))
  for inname in wordlists
    let outname = s:spell_dir . (inname[len(s:spell_dir):-5])
    exe join(["mkspell! -ascii", outname, inname])
  endfor
endfunction

" Generate spell file for the specified filetype
function! spell#BuildSyntaxFile(filetype)
  let wordfile = s:words_dir . "/" . a:filetype . ".txt"
  let spellfile = s:spell_dir . "/" . a:filetype . ".ascii.spl"
  exe join(["silent mkspell! -ascii", spellfile, wordfile])
endfunction

function! spell#BuildTagsFile()
  " Keep only the tags without special chars
  let tags = taglist("^[a-zA-Z0-9_]*$")
  if empty(tags)
    echohl WarningMsg
    echo empty(tagfiles())
          \ ? "No spell files loaded"
          \ : "No tags match \"[a-zA-Z0-9_]*\""
    echohl None
    return
  endif

  " Append '/=' to word to respect case when spell checking
  " See |:help wordlist| for more info on word list formats
  let words = uniq(map(tags, {i, val -> val.name . "/="}))
  let wordfile = tempname()
  call writefile(words, wordfile, "S")

  let tags_spell_dir = s:tags_dir . getcwd() . "/spell"
  call mkdir(tags_spell_dir, "p")
  let tags_spell_file = tags_spell_dir . "/tags"
  exe join(["mkspell! -ascii", tags_spell_file, wordfile])
endfunction

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Functions to load spell files
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Load the spell file corresponding to current filetype
function! spell#LoadSyntaxFile()
  let syntax_spell_file = s:spell_dir . "/" . &filetype . ".ascii.spl"
  if filereadable(syntax_spell_file)
    exe "setlocal spelllang+=" . &filetype
  endif
endfunction

" Load the spell file corresponding to current tags
function! spell#LoadTagsFile()
  let tags_spell_runtime_dir = s:tags_dir . getcwd()
  let tags_spell_file = tags_spell_runtime_dir . "/spell/tags.ascii.spl"
  if filereadable(tags_spell_file)
    exe "setlocal runtimepath+=" . tags_spell_runtime_dir
    setlocal spelllang+=tags
  endif
endfunction

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Functions to modify spell files
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Add a new word to the word list and spell file for the current
" filetype. This is currently terribly inefficient because we
" re-generate the spell file for each word added and should be
" improved. This is not a major problem for now because the word
" lists aren't too big
function! spell#SpellSyntaxAdd(...)
  let word = a:0 == 0 ? expand("<cword>") : a:1
  echo "Adding word \"" . word . "\""
  let wordfile = s:words_dir . "/" . &filetype . ".txt"
  call writefile([word], wordfile, "a")
  call spell#BuildSyntaxFile(&filetype)
  call spell#LoadSyntaxFile()
endfunction