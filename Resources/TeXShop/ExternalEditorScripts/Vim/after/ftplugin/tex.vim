" Open PDF in TeXShop:
nnoremap <silent><buffer> <leader>tv :<c-u>call tex#preview()<cr>

" Forward search:
nnoremap <silent><buffer> <leader>ts :<c-u>call tex#goto_texshop(expand("%:p"), line('.'), col('.'), 0, 0)<cr>

