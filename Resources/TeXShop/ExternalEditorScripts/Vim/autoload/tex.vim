fun! tex#preview()
  call job_start(['open', '-a', 'TeXShop.app', expand("%:p")])
endf

fun! tex#goto_texshop(path, linenr, colnr, context = 0, altpath = 0)
  call job_start(['osascript',
        \ '-e', 'tell front document of application "TeXShop"',
        \ '-e', 'activate',
        \ '-e', 'SyncWithOtherEditor',
        \ '-e', a:altpath ? 'AlternateBinPath' : 'StandardBinPath',
        \ '-e', a:context ? 'SyncConTeXt'      : 'SyncRegular',
        \ '-e', printf('sync_preview_line theLine %d',   a:linenr),
        \ '-e', printf('sync_preview_index theIndex %d', a:colnr),
        \ '-e', printf('sync_preview_name theName "%s"', a:path),
        \ '-e', 'end tell',
        \ ])
endf

