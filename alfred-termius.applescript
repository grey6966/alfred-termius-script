-- 配置项
property termius_menu_name : "New Local Terminal" -- 若界面为中文，请改为 "新建本地终端"
property timeout_seconds : 7

-- 检查 Termius 是否正在运行
on isRunning()
    tell application "System Events"
        set appList to name of (processes)
    end tell
    return appList contains "Termius"
end isRunning

-- 激活 Termius
on summon()
    tell application "Termius" to activate
end summon

-- 检查是否有窗口
on hasWindows()
    if not my isRunning() then return false
    tell application "System Events"
        try
            return (count of windows of process "Termius") > 0
        on error
            return false
        end try
    end tell
end hasWindows

-- 等待窗口出现
on waitForWindow(timeout_s)
    set end_time to (current date) + timeout_s
    repeat until ((my hasWindows()) or ((current date) > end_time))
        delay 0.1
    end repeat
    return my hasWindows()
end waitForWindow

-- 等待菜单项出现（首次启动时需要）
on waitForMenu(timeout_s)
    set end_time to (current date) + timeout_s
    repeat
        tell application "System Events"
            try
                set menu_exists to exists menu item termius_menu_name of menu "File" of menu bar 1 of process "Termius"
                if menu_exists then
                    exit repeat
                end if
            end try
        end tell
        if (current date) > end_time then
            exit repeat
        end if
        delay 0.1
    end repeat
end waitForMenu

-- 打开本地终端
on openLocalTerminal()
    tell application "System Events"
        tell process "Termius"
            click menu item termius_menu_name of menu "File" of menu bar 1
        end tell
    end tell
end openLocalTerminal

-- 【关键优化】一次性粘贴命令并执行（极快）
on send_command(a_command)
    try
        -- 放入剪贴板
        set the clipboard to a_command
        
        -- 粘贴并回车
        tell application "System Events"
            tell process "Termius"
                keystroke "v" using command down -- Cmd+V 粘贴
                delay 0.05
                keystroke return -- 执行
            end tell
        end tell
    on error errMsg
        display notification "发送命令失败: " & errMsg with title "Termius Script"
    end try
end send_command

-- Alfred 主入口
on alfred_script(query)
    set just_activated to not my isRunning()
    my summon()

    if just_activated then
        if not my waitForWindow(timeout_seconds) then
            display dialog "Termius 窗口创建失败"
            return
        end if
        my waitForMenu(timeout_seconds)
    end if

    my openLocalTerminal()
    if not my waitForWindow(timeout_seconds) then
        display dialog "新建本地终端窗口失败"
        return
    end if

    -- 等待终端完全就绪（关键）
    delay 0.7

    -- 一次性发送完整命令
    my send_command(query)
end alfred_script
