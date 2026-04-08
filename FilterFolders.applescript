-- FilterFolders: 根據清單篩選 Finder 中的子資料夾
-- 使用方式：放在 Finder 工具列，點擊即可對當前視窗篩選

on run
	-- 自動抓取當前 Finder 視窗路徑
	set targetPath to getFinderPath()

	set actionChoice to button returned of (display dialog "目前路徑：" & return & targetPath & return & return & "篩選：輸入名稱清單，隱藏不符合的資料夾" & return & "還原：取消所有隱藏，恢復顯示" buttons {"還原", "篩選"} default button "篩選" with title "資料夾篩選工具")

	if actionChoice is "篩選" then
		filterFolders(targetPath)
	else
		restoreFolders(targetPath)
	end if
end run

on getFinderPath()
	tell application "Finder"
		try
			set frontWindow to window 1
			set targetFolder to (target of frontWindow) as alias
			return POSIX path of targetFolder
		on error
			-- 如果沒有開啟 Finder 視窗，讓使用者手動選擇
			set targetFolder to choose folder with prompt "找不到 Finder 視窗，請手動選擇資料夾："
			return POSIX path of targetFolder
		end try
	end tell
end getFinderPath

on filterFolders(targetPath)
	-- 輸入要顯示的資料夾名稱（每行一個）
	set inputText to text returned of (display dialog "請輸入要顯示的資料夾名稱" & return & "（每行一個，支援模糊比對）：" default answer "" & return & "" & return & "" & return & "" & return & "" & return & "" & return & "" & return & "" & return & "" & return & "" with title "輸入篩選清單")

	if inputText is "" then
		display dialog "未輸入任何名稱，操作取消。" buttons {"確定"} default button "確定"
		return
	end if

	-- 將輸入文字轉成清單
	set AppleScript's text item delimiters to {return, linefeed}
	set nameList to text items of inputText
	set AppleScript's text item delimiters to ""

	-- 過濾掉空行並去除前後空白
	set cleanList to {}
	repeat with aName in nameList
		set trimmed to my trimText(aName as text)
		if trimmed is not "" then
			set end of cleanList to trimmed
		end if
	end repeat

	if (count of cleanList) is 0 then
		display dialog "未輸入有效名稱，操作取消。" buttons {"確定"} default button "確定"
		return
	end if

	-- 取得所有子資料夾（包含已隱藏的）
	set shellResult to do shell script "find " & quoted form of targetPath & " -maxdepth 1 -type d ! -path " & quoted form of targetPath & " -exec basename {} \\;"

	if shellResult is "" then
		display dialog "該資料夾內沒有子資料夾。" buttons {"確定"} default button "確定"
		return
	end if

	set AppleScript's text item delimiters to {return, linefeed}
	set allFolders to text items of shellResult
	set AppleScript's text item delimiters to ""

	set hiddenCount to 0
	set shownCount to 0
	set matchedNames to {}

	-- 隱藏不在清單中的資料夾
	repeat with folderName in allFolders
		set folderName to folderName as text
		if folderName is not "" then
			if my isInList(folderName, cleanList) then
				-- 確保符合清單的資料夾是可見的
				do shell script "chflags nohidden " & quoted form of (targetPath & folderName)
				set shownCount to shownCount + 1
				set end of matchedNames to folderName
			else
				-- 隱藏不符合的資料夾
				do shell script "chflags hidden " & quoted form of (targetPath & folderName)
				set hiddenCount to hiddenCount + 1
			end if
		end if
	end repeat

	-- 檢查清單中哪些關鍵字沒有匹配到任何資料夾
	set notFoundNames to {}
	repeat with searchName in cleanList
		set found to false
		repeat with folderName in allFolders
			if (folderName as text) contains (searchName as text) then
				set found to true
				exit repeat
			end if
		end repeat
		if not found then
			set end of notFoundNames to (searchName as text)
		end if
	end repeat

	-- 組合結果訊息
	set resultMsg to "篩選完成！" & return & return
	set resultMsg to resultMsg & "顯示：" & shownCount & " 個資料夾" & return
	set resultMsg to resultMsg & "隱藏：" & hiddenCount & " 個資料夾" & return

	if (count of notFoundNames) > 0 then
		set AppleScript's text item delimiters to ", "
		set notFoundStr to notFoundNames as text
		set AppleScript's text item delimiters to ""
		set resultMsg to resultMsg & return & "找不到匹配的關鍵字：" & return & notFoundStr
	end if

	display dialog resultMsg buttons {"確定"} default button "確定" with title "篩選結果"
end filterFolders

on restoreFolders(targetPath)
	-- 取消所有子資料夾的隱藏屬性
	do shell script "find " & quoted form of targetPath & " -maxdepth 1 -type d ! -path " & quoted form of targetPath & " -exec chflags nohidden {} \\;"

	display dialog "已還原所有子資料夾的顯示狀態！" buttons {"確定"} default button "確定" with title "還原完成"
end restoreFolders

-- 輔助函數：去除前後空白
on trimText(theText)
	set theText to theText as text
	repeat while theText begins with " " or theText begins with tab
		if length of theText is 1 then return ""
		set theText to text 2 thru -1 of theText
	end repeat
	repeat while theText ends with " " or theText ends with tab
		if length of theText is 1 then return ""
		set theText to text 1 thru -2 of theText
	end repeat
	return theText
end trimText

-- 輔助函數：檢查名稱是否在清單中（模糊比對）
on isInList(itemName, theList)
	repeat with listItem in theList
		-- 完全比對
		if (itemName as text) is (listItem as text) then return true
		-- 模糊比對：資料夾名稱包含清單中的關鍵字
		if (itemName as text) contains (listItem as text) then return true
	end repeat
	return false
end isInList
