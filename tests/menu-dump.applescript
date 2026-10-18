-- Dump the status-item menu's structure — every row, recursing into submenus up to depth 3 — so the
-- manual menu walk can be diffed instead of eyeballed. Read-only: it opens the menu, reads titles,
-- enabled state and mark chars, and closes it again.
--
--   pgrep -U "$(id -u)" -f '/CoAwake( |$)'      # get the pid
--   osascript tests/menu-dump.applescript <pid>
--
-- Output: one row per line, indented two spaces per depth level:
--   <path> <title>  [enabled=<true|false>] [mark=<AXMenuItemMarkChar>]
--
-- Requires Accessibility permission for the calling terminal (System Settings → Privacy & Security →
-- Accessibility), which is why this is a hand-run aid (docs/ARCHITECTURE.md § 13) and not
-- part of `tests/qa.sh` — the core tier must stay runnable headless and unprivileged.
--
-- THREE THINGS THAT WILL BITE YOU, all found the hard way:
--
-- 1. Resolve the target by UNIX ID, never by name. Every instance is named "CoAwake", and a
--    long-running one is holding the PREVIOUS build's menu — matching by name silently dumps the wrong
--    app, which reads as "no regression" when there is one, or vice versa. Hence the required argument.
-- 2. The status item is `menu bar 1`, not `menu bar 2`. An accessory app (`.accessory`) has no main
--    menu bar, so there is no index 1 for it to sit behind.
-- 3. What you get back is NOT rendered — you cannot screenshot it, and selection marks read as empty
--    because they are a custom `onStateImage`, so `AXMenuItemMarkChar` is blank. The `mark=` column is
--    recorded verbatim and NOT interpreted: an empty mark does not mean "unselected". This dump proves
--    STRUCTURE (rows, order, nesting, titles, enabled). The dot glyphs, VoiceOver and keyboard reach stay
--    hands-on checks; a synthesized CGEvent click does render the menu if you ever need a real
--    screenshot, but that path needs the item's screen coordinates and AX reports those unreliably on a
--    multi-display setup.

property maxDepth : 3

on run argv
	if (count of argv) is not 1 then
		return "usage: osascript tests/menu-dump.applescript <pid>" & linefeed & ¬
			"       pid from: pgrep -U \"$(id -u)\" -f '/CoAwake( |$)'"
	end if
	set targetPid to (item 1 of argv) as integer
	tell application "System Events"
		if not (exists (first application process whose unix id is targetPid)) then
			return "no application process with pid " & targetPid & ¬
				" (is it running? does this terminal have Accessibility permission?)"
		end if
		tell (first application process whose unix id is targetPid)
			click menu bar item 1 of menu bar 1
			delay 1
			set out to my dumpMenu(menu 1 of menu bar item 1 of menu bar 1, 1, "")
			key code 53 -- Escape, so the menu never stays open after a dump
			return out
		end tell
	end tell
end run

-- Re-address by INDEX on every access; never hold a row in a variable. System Events re-resolves a
-- stored specifier BY TITLE, and the first row's title carries a 1s countdown while a window is armed —
-- so it changed between the lookup and the submenu fetch and the dump died with -1728, making the armed
-- menu the one state this tool could not read. (Found 2026-07-31.) The menu itself is passed down as a
-- specifier rooted at an index chain, which stays stable.
on dumpMenu(theMenu, depth, prefix)
	set out to ""
	set indent to ""
	repeat (depth - 1) times
		set indent to indent & "  "
	end repeat
	tell application "System Events"
		set rowCount to count of menu items of theMenu
		repeat with i from 1 to rowCount
			set rowTitle to title of menu item i of theMenu
			-- A separator, or a view-based row, has no title.
			if rowTitle is missing value or rowTitle is "" then set rowTitle to "· (separator or view row)"
			set rowEnabled to "?"
			try
				set rowEnabled to (enabled of menu item i of theMenu) as text
			end try
			set rowMark to ""
			try
				set rowMark to value of attribute "AXMenuItemMarkChar" of menu item i of theMenu
				if rowMark is missing value then set rowMark to ""
			end try
			set rowPath to prefix & i
			set out to out & indent & rowPath & " " & rowTitle & "  [enabled=" & rowEnabled & "] [mark=" & rowMark & "]" & linefeed
			if depth < maxDepth then
				if (count of menus of menu item i of theMenu) > 0 then
					set out to out & my dumpMenu(menu 1 of menu item i of theMenu, depth + 1, rowPath & ".")
				end if
			end if
		end repeat
	end tell
	return out
end dumpMenu
