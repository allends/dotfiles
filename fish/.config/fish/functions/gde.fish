function gde --description "Ghostty Dev Environment: Claude (2/3) + lazygit (1/3)"
    osascript -e '
        tell application "System Events"
            tell process "Ghostty"
                -- Split right (Cmd+D), focus moves to right pane
                keystroke "d" using {command down}
                delay 0.15

                -- Shrink right pane: Cmd+Ctrl+Right x4
                repeat 10 times
                    key code 124 using {command down, control down}
                    delay 0.05
                end repeat

                -- Type lazygit in right pane
                keystroke "lazygit"
                delay 0.05
                keystroke return
                delay 0.1

                -- Switch to left pane (Cmd+Alt+Left)
                key code 123 using {command down, option down}
                delay 0.1

                -- Type c (claude alias) in left pane
                keystroke "c"
                delay 0.05
                keystroke return
            end tell
        end tell
    '
end
