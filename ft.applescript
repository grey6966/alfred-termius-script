property termius_menu_name : "New Local Terminal" -- 或 "新建本地终端"
property timeout_seconds : 7

on isRunning()
  tell application "System Events"
    set appList to name of (processes)
  end tell
  return appList contains "Termius"
end isRunning

on summon()
  tell application "Termius" to activate
end summon

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

on waitForWindow(timeout_s)
  set end_time to (current date) + timeout_s
  repeat until ((my hasWindows()) or ((current date) > end_time))
    delay 0.1
  end repeat
  return my hasWindows()
end waitForWindow

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

on openLocalTerminal()
  tell application "System Events"
    tell process "Termius"
      click menu item termius_menu_name of menu "File" of menu bar 1
    end tell
  end tell
end openLocalTerminal

on send_command(a_command)
  -- 先复制命令到剪贴板
  set the clipboard to a_command
  delay 0.1
  tell application "System Events"
    tell process "Termius"
      -- 粘贴 (command + v)
      keystroke "v" using command down
      delay 0.1
      -- 回车
      keystroke return
    end tell
  end tell
end send_command

on alfred_script(q)
  -- 获取Finder前窗口路径
  tell application "Finder"
    set pathList to POSIX path of (folder of the front window as alias)
  end tell
  set cd_command to "cd " & quoted form of pathList

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

  delay 0.6 -- window/tab fully ready
  my send_command(cd_command)
end alfred_script
