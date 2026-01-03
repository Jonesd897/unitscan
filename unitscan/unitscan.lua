--------------------------------------------------------------------------------------
--	Backport and modifications by Sattva
--	Credit to simon_hirsig & tablegrapes
--	Credit to Macumba for checking all rares in list and then adding frFR database!
--	Code from unitscan & unitscan-rares
--------------------------------------------------------------------------------------
	
	-- Create global table
	_G.unitscanDB = _G.unitscanDB or {}

	-- Create locals
	local unitscan = CreateFrame'Frame'
	local forbidden
	local is_resting
	local deadscan = false
	local unitscanLC, unitscanCB, usDropList, usConfigList, usLockList = {}, {}, {}, {}, {}
	local void

	--===== Check the current locale of the WoW client =====--
	local currentLocale = GetLocale()

	--===== Check for game version =====--
	local isTBC = select(4, GetBuildInfo()) == 20400 -- true if TBC 2.4.3
	local isWOTLK = select(4, GetBuildInfo()) == 30300 -- true if WOTLK 3.3.5

----------------------------------------------------------------------
--	L00: unitscan
----------------------------------------------------------------------

	-- Create event frame
	local usEvt = CreateFrame("FRAME")
	usEvt:RegisterEvent("ADDON_LOADED")
	usEvt:RegisterEvent("PLAYER_LOGIN")
	usEvt:RegisterEvent("PLAYER_ENTERING_WORLD")


----------------------------------------------------------------------
--	L01: Functions
----------------------------------------------------------------------

	-- Print text
	function unitscanLC:Print(text)
		DEFAULT_CHAT_FRAME:AddMessage(text, 1.0, 0.85, 0.0)
	end

	-- Lock and unlock an item
	function unitscanLC:LockItem(item, lock)
		if lock then
			item:Disable()
			item:SetAlpha(0.3)
		else
			item:Enable()
			item:SetAlpha(1.0)
		end
	end

	-- Hide configuration panels
	function unitscanLC:HideConfigPanels()
		for k, v in pairs(usConfigList) do
			v:Hide()
		end
	end

	-- Show a single line prefilled editbox with copy functionality
	function unitscanLC:ShowSystemEditBox(word, focuschat)
		if not unitscanLC.FactoryEditBox then
			-- Create frame for first time
			local eFrame = CreateFrame("FRAME", nil, UIParent)
			unitscanLC.FactoryEditBox = eFrame
			eFrame:SetSize(700, 110)
			eFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 150)
			eFrame:SetFrameStrata("FULLSCREEN_DIALOG")
			-- eFrame:SetFrameLevel(5000)
			eFrame:EnableMouse(true)
			eFrame:EnableKeyboard()
			eFrame:SetScript("OnMouseDown", function(self, btn)
				if btn == "RightButton" then
					eFrame:Hide()
				end
			end)
			-- Add background color
			eFrame.t = eFrame:CreateTexture(nil, "BACKGROUND")
			eFrame.t:SetAllPoints()
			eFrame.t:SetTexture(0.05, 0.05, 0.05, 0.9)
			-- Add copy title
			eFrame.f = eFrame:CreateFontString(nil, 'ARTWORK', 'GameFontNormalLarge')
			eFrame.f:SetPoint("TOPLEFT", x, y)
			eFrame.f:SetPoint("TOPLEFT", eFrame, "TOPLEFT", 12, -52)
			eFrame.f:SetWidth(676)
			eFrame.f:SetJustifyH("LEFT")
			eFrame.f:SetWordWrap(false)
			-- Add copy label
			eFrame.c = eFrame:CreateFontString(nil, 'ARTWORK', 'GameFontNormalLarge')
			eFrame.c:SetPoint("TOPLEFT", x, y)
			eFrame.c:SetText("Press CTRL/C to copy")
			eFrame.c:SetPoint("TOPLEFT", eFrame, "TOPLEFT", 12, -82)
			-- Add feedback label
			eFrame.x = eFrame:CreateFontString(nil, 'ARTWORK', 'GameFontNormalLarge')
			eFrame.x:SetPoint("TOPRIGHT", x, y)
			eFrame.x:SetText("|cff00ff00Feedback Discord:|r |cffadd8e6Sattva#7238|r")

			eFrame.x:SetPoint("TOPRIGHT", eFrame, "TOPRIGHT", -12, -52)
			hooksecurefunc(eFrame.f, "SetText", function()
				eFrame.f:SetWidth(676 - eFrame.x:GetStringWidth() - 26)
			end)
			-- Add cancel label
			eFrame.x = eFrame:CreateFontString(nil, 'ARTWORK', 'GameFontNormalLarge')
			eFrame.x:SetPoint("TOPRIGHT", x, y)
			eFrame.x:SetText("Right-click to close")
			eFrame.x:SetPoint("TOPRIGHT", eFrame, "TOPRIGHT", -12, -82)
			-- Create editbox
			eFrame.b = CreateFrame("EditBox", nil, eFrame, "InputBoxTemplate")
			eFrame.b:ClearAllPoints()
			eFrame.b:SetPoint("TOPLEFT", eFrame, "TOPLEFT", 16, -12)
			eFrame.b:SetSize(672, 24)
			eFrame.b:SetFontObject("GameFontNormalLarge")
			eFrame.b:SetTextColor(1.0, 1.0, 1.0, 1)
			eFrame.b:DisableDrawLayer("BACKGROUND")
			-- eFrame.b:SetBlinkSpeed(0)
			eFrame.b:SetHitRectInsets(99, 99, 99, 99)
			eFrame.b:SetAutoFocus(true)
			eFrame.b:SetAltArrowKeyMode(true)
			eFrame.b:EnableMouse(true)
			eFrame.b:EnableKeyboard(true)
			-- Editbox texture
			eFrame.t = CreateFrame("FRAME", nil, eFrame.b)
			eFrame.t:SetBackdrop({bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = false, tileSize = 16, edgeSize = 16, insets = { left = 5, right = 5, top = 5, bottom = 5 }})
			eFrame.t:SetPoint("LEFT", -6, 0)
			eFrame.t:SetWidth(eFrame.b:GetWidth() + 6)
			eFrame.t:SetHeight(eFrame.b:GetHeight())
			eFrame.t:SetBackdropColor(1.0, 1.0, 1.0, 0.3)
			-- Handler
			-- it doesnt work in 3.3.5
			eFrame.b:SetScript("OnKeyDown", function(void, key)
				if key == "c" and IsControlKeyDown() then
					LibCompat.After(0.1, function()
						eFrame:Hide()
						ActionStatus_DisplayMessage("Copied to clipboard.", true)
						if unitscanLC.FactoryEditBoxFocusChat then
							local eBox = ChatEdit_ChooseBoxForSend()
							ChatEdit_ActivateChat(eBox)
						end
					end)
				end
			end)
			-- Prevent changes
			-- eFrame.b:SetScript("OnEscapePressed", function() eFrame:Hide() end)
			-- eFrame.b:SetScript("OnEnterPressed", eFrame.b.HighlightText)
			-- eFrame.b:SetScript("OnMouseDown", eFrame.b.ClearFocus)
			-- eFrame.b:SetScript("OnMouseUp", eFrame.b.HighlightText)
			eFrame.b:SetScript("OnChar", function() eFrame.b:SetText(word); eFrame.b:HighlightText(); end);
			eFrame.b:SetScript("OnMouseUp", function() eFrame.b:HighlightText(); end);
			eFrame.b:SetScript("OnEscapePressed", function() eFrame:Hide() end)
			eFrame.b:SetFocus(true)
			eFrame.b:HighlightText()
			eFrame:Show()
		end
		if focuschat then unitscanLC.FactoryEditBoxFocusChat = true else unitscanLC.FactoryEditBoxFocusChat = nil end
		unitscanLC.FactoryEditBox:Show()
		unitscanLC.FactoryEditBox.b:SetText(word)
		unitscanLC.FactoryEditBox.b:HighlightText()
		unitscanLC.FactoryEditBox.b:SetScript("OnChar", function() unitscanLC.FactoryEditBox.b:SetFocus(true) unitscanLC.FactoryEditBox.b:SetText(word) unitscanLC.FactoryEditBox.b:HighlightText() end)
		unitscanLC.FactoryEditBox.b:SetScript("OnKeyUp", function() unitscanLC.FactoryEditBox.b:SetFocus(true) unitscanLC.FactoryEditBox.b:SetText(word) unitscanLC.FactoryEditBox.b:HighlightText() end)
	end

	-- Load a string variable or set it to default if it's not set to "On" or "Off"
	function unitscanLC:LoadVarChk(var, def)
		if unitscanDB[var] and type(unitscanDB[var]) == "string" and unitscanDB[var] == "On" or unitscanDB[var] == "Off" then
			unitscanLC[var] = unitscanDB[var]
		else
			unitscanLC[var] = def
			unitscanDB[var] = def
		end
	end

	-- Load a numeric variable and set it to default if it's not within a given range
	function unitscanLC:LoadVarNum(var, def, valmin, valmax)
		if unitscanDB[var] and type(unitscanDB[var]) == "number" and unitscanDB[var] >= valmin and unitscanDB[var] <= valmax then
			unitscanLC[var] = unitscanDB[var]
		else
			unitscanLC[var] = def
			unitscanDB[var] = def
		end
	end

	-- Load an anchor point variable and set it to default if the anchor point is invalid
	function unitscanLC:LoadVarAnc(var, def)
		if unitscanDB[var] and type(unitscanDB[var]) == "string" and unitscanDB[var] == "CENTER" or unitscanDB[var] == "TOP" or unitscanDB[var] == "BOTTOM" or unitscanDB[var] == "LEFT" or unitscanDB[var] == "RIGHT" or unitscanDB[var] == "TOPLEFT" or unitscanDB[var] == "TOPRIGHT" or unitscanDB[var] == "BOTTOMLEFT" or unitscanDB[var] == "BOTTOMRIGHT" then
			unitscanLC[var] = unitscanDB[var]
		else
			unitscanLC[var] = def
			unitscanDB[var] = def
		end
	end

	-- Load a string variable and set it to default if it is not a string (used with minimap exclude list)
	function unitscanLC:LoadVarStr(var, def)
		if unitscanDB[var] and type(unitscanDB[var]) == "string" then
			unitscanLC[var] = unitscanDB[var]
		else
			unitscanLC[var] = def
			unitscanDB[var] = def
		end
	end

	-- Show tooltips for checkboxes
	function unitscanLC:TipSee()
		GameTooltip:SetOwner(self, "ANCHOR_NONE")
		local parent = self:GetParent()
		local pscale = parent:GetEffectiveScale()
		local gscale = UIParent:GetEffectiveScale()
		local tscale = GameTooltip:GetEffectiveScale()
		local gap = ((UIParent:GetRight() * gscale) - (parent:GetRight() * pscale))
		if gap < (250 * tscale) then
			GameTooltip:SetPoint("TOPRIGHT", parent, "TOPLEFT", 0, 0)
		else
			GameTooltip:SetPoint("TOPLEFT", parent, "TOPRIGHT", 0, 0)
		end
		GameTooltip:SetText(self.tiptext, nil, nil, nil, nil, true)
	end

	-- Show tooltips for dropdown menu tooltips
	function unitscanLC:ShowDropTip()
		GameTooltip:SetOwner(self, "ANCHOR_NONE")
		local parent = self:GetParent():GetParent():GetParent()
		local pscale = parent:GetEffectiveScale()
		local gscale = UIParent:GetEffectiveScale()
		local tscale = GameTooltip:GetEffectiveScale()
		local gap = ((UIParent:GetRight() * gscale) - (parent:GetRight() * pscale))
		if gap < (250 * tscale) then
			GameTooltip:SetPoint("TOPRIGHT", parent, "TOPLEFT", 0, 0)
		else
			GameTooltip:SetPoint("TOPLEFT", parent, "TOPRIGHT", 0, 0)
		end
		GameTooltip:SetText(self.tiptext, nil, nil, nil, nil, true)
	end

	-- Show tooltips for configuration buttons and dropdown menus
	function unitscanLC:ShowTooltip()
		GameTooltip:SetOwner(self, "ANCHOR_NONE")
		local parent = unitscanLC["PageF"]
		local pscale = parent:GetEffectiveScale()
		local gscale = UIParent:GetEffectiveScale()
		local tscale = GameTooltip:GetEffectiveScale()
		local gap = ((UIParent:GetRight() * gscale) - (unitscanLC["PageF"]:GetRight() * pscale))
		if gap < (250 * tscale) then
			GameTooltip:SetPoint("TOPRIGHT", parent, "TOPLEFT", 0, 0)
		else
			GameTooltip:SetPoint("TOPLEFT", parent, "TOPRIGHT", 0, 0)
		end
		GameTooltip:SetText(self.tiptext, nil, nil, nil, nil, true)
	end

	-- Create configuration button
	function unitscanLC:CfgBtn(name, parent)
		local CfgBtn = CreateFrame("BUTTON", nil, parent)
		unitscanCB[name] = CfgBtn
		CfgBtn:SetWidth(20)
		CfgBtn:SetHeight(20)
		CfgBtn:SetPoint("LEFT", parent.f, "RIGHT", 0, 0)

		CfgBtn.t = CfgBtn:CreateTexture(nil, "BORDER")
		CfgBtn.t:SetAllPoints()
		CfgBtn.t:SetTexture("Interface\\WorldMap\\Gear_64.png")
		CfgBtn.t:SetTexCoord(0, 0.50, 0, 0.50);
		CfgBtn.t:SetVertexColor(1.0, 0.82, 0, 1.0)

		CfgBtn:SetHighlightTexture("Interface\\WorldMap\\Gear_64.png")
		CfgBtn:GetHighlightTexture():SetTexCoord(0, 0.50, 0, 0.50);

		CfgBtn.tiptext = "Click to configure the settings for this option."
		CfgBtn:SetScript("OnEnter", unitscanLC.ShowTooltip)
		CfgBtn:SetScript("OnLeave", GameTooltip_Hide)
	end

	-- Create a help button to the right of a fontstring
	function unitscanLC:CreateHelpButton(frame, panel, parent, tip)
		unitscanLC:CfgBtn(frame, panel)
		unitscanCB[frame]:ClearAllPoints()
		unitscanCB[frame]:SetPoint("LEFT", parent, "RIGHT", -parent:GetWidth() + parent:GetStringWidth(), 0)
		unitscanCB[frame]:SetSize(25, 25)
		unitscanCB[frame].t:SetTexture("Interface\\COMMON\\help-i.blp")
		unitscanCB[frame].t:SetTexCoord(0, 1, 0, 1)
		unitscanCB[frame].t:SetVertexColor(0.9, 0.8, 0.0)
		unitscanCB[frame]:SetHighlightTexture("Interface\\COMMON\\help-i.blp")
		unitscanCB[frame]:GetHighlightTexture():SetTexCoord(0, 1, 0, 1)
		unitscanCB[frame].tiptext = tip
		unitscanCB[frame]:SetScript("OnEnter", unitscanLC.TipSee)
	end

	-- Show a footer
	function unitscanLC:MakeFT(frame, text, left, width)
		local footer = unitscanLC:MakeTx(frame, text, left, 96)
		footer:SetWidth(width); footer:SetJustifyH("LEFT"); footer:SetWordWrap(true); footer:ClearAllPoints()
		footer:SetPoint("BOTTOMLEFT", left, 96)
	end

	-- Capitalise first character in a string
	function unitscanLC:CapFirst(str)
		return gsub(string.lower(str), "^%l", strupper)
	end

	-- Show memory usage stat
	function unitscanLC:ShowMemoryUsage(frame, anchor, x, y)

		-- Create frame
		local memframe = CreateFrame("FRAME", nil, frame)
		memframe:ClearAllPoints()
		memframe:SetPoint(anchor, x, y)
		memframe:SetWidth(100)
		memframe:SetHeight(20)

		-- Create labels
		local pretext = memframe:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
		pretext:SetPoint("TOPLEFT", 0, 0)
		pretext:SetText("Memory Usage")

		local memtext = memframe:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
		memtext:SetPoint("TOPLEFT", 0, 0 - 30)

		-- Create stat
		local memstat = memframe:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
		memstat:SetPoint("BOTTOMLEFT", memtext, "BOTTOMRIGHT")
		memstat:SetText("(calculating...)")

		-- Create update script
		local memtime = -1
		memframe:SetScript("OnUpdate", function(self, elapsed)
			if memtime > 2 or memtime == -1 then
				UpdateAddOnMemoryUsage();
				memtext = GetAddOnMemoryUsage("unitscan")
				memtext = math.floor(memtext + .5) .. " KB"
				memstat:SetText(memtext);
				memtime = 0;
			end
			memtime = memtime + elapsed;
		end)

		-- Release memory
		unitscanLC.ShowMemoryUsage = nil

	end

	-- Check if player is in LFG queue
	function unitscanLC:IsInLFGQueue()
		if unitscanLC["GameVer"] == "5" then
			if GetLFGQueueStats(LE_LFG_CATEGORY_LFD) or GetLFGQueueStats(LE_LFG_CATEGORY_LFR) or GetLFGQueueStats(LE_LFG_CATEGORY_RF) then
				return true
			end
		else
			if MiniMapLFGFrame:IsShown() then return true end
		end
	end

	-- Check if player is in combat
	function unitscanLC:PlayerInCombat()
		if (UnitAffectingCombat("player")) then
			unitscanLC:Print("You cannot do that in combat.")
			return true
		end
	end

	--  Hide panel and pages
	function unitscanLC:HideFrames()

		-- Hide option pages
		for i = 0, unitscanLC["NumberOfPages"] do
			if unitscanLC["Page"..i] then
				unitscanLC["Page"..i]:Hide();
			end;
		end

		-- Hide options panel
		unitscanLC["PageF"]:Hide();

	end

	-- Find out if Leatrix Plus is showing (main panel or config panel)
	function unitscanLC:IsPlusShowing()
		if unitscanLC["PageF"]:IsShown() then return true end
		for k, v in pairs(usConfigList) do
			if v:IsShown() then
				return true
			end
		end
	end

-- Check if a name is in your friends list or guild (does not check realm as realm is unknown for some checks)
function unitscanLC:FriendCheck(name)

		-- Do nothing if name is empty (such as whispering from the Battle.net app)
		if not name then return end

		-- Update friends list
		ShowFriends()

		-- Remove realm if it exists
		if name ~= nil then
			name = strsplit("-", name, 2)
		end

		-- Check character friends
		for i = 1, GetNumFriends() do
			local friendName, _, _, _, friendConnected = GetFriendInfo(i)
			if friendName ~= nil then -- Check if name is not nil
				friendName = strsplit("-", friendName, 2)
			end

			if (name == friendName) and friendConnected then -- Check if name matches and friend is connected
				return true
			end
		end

		-- -- Check Battle.net friends -- obviously disable as there is no bnet friends in 3.3.5 and 2.4.3
		-- local numfriends = BNGetNumFriends()
		-- for i = 1, numfriends do
		-- 	local numtoons = C_BattleNet.GetFriendNumGameAccounts(i)
		-- 	for j = 1, numtoons do
		-- 		local gameAccountInfo = C_BattleNet.GetFriendGameAccountInfo(i, j)
		-- 		local characterName = gameAccountInfo.characterName
		-- 		local client = gameAccountInfo.clientProgram
		-- 		if client == "WoW" and characterName == name then
		-- 			return true
		-- 		end
		-- 	end
		-- end

		-- Check guild members if guild is enabled (new members may need to press J to refresh roster)
		if unitscanLC["FriendlyGuild"] == "On" then
			local gCount = GetNumGuildMembers()
			for i = 1, gCount do
				local gName, void, void, void, void, void, void, void, gOnline = GetGuildRosterInfo(i)
				if gOnline then
					gName = strsplit("-", gName, 2)
					-- Return true if character name matches
					if (name == gName) then
						return true
					end
				end
			end
		end

	end	


---------------------------------------------------------------------------------------------------
-- Functions mainly for restrictions and conditions for unit scanning, RAID mark setup conditions.
---------------------------------------------------------------------------------------------------


	unitscan:SetScript('OnUpdate', function() unitscan.UPDATE() end)
	unitscan:SetScript('OnEvent', function(_, event, arg1)
		if event == 'ADDON_LOADED' and arg1 == 'unitscan' then
			unitscan.LOAD()
		elseif event == 'ADDON_ACTION_FORBIDDEN' and arg1 == 'unitscan' then
			forbidden = true
		elseif event == 'PLAYER_TARGET_CHANGED' then
			if UnitName'target' and strupper(UnitName'target') == unitscan.button:GetText() and not GetRaidTargetIndex'target' and (not UnitInRaid'player' or IsRaidOfficer() or IsRaidLeader()) then
				SetRaidTarget('target', 2)
			end
		elseif event == 'ZONE_CHANGED_NEW_AREA' or 'PLAYER_LOGIN' or 'PLAYER_UPDATE_RESTING' then
			local loc = GetRealZoneText()
			local _, instance_type = IsInInstance()
			is_resting = IsResting()
			nearby_targets = {}

			if instance_type == "raid" or instance_type == "pvp" then return end
			if loc == nil then return end

			for name, zone in pairs(rare_spawns) do
				if not unitscan_ignored[name] then
					local reaction = UnitReaction("player", name)
					if not reaction or reaction < 4 then reaction = true else reaction = false end
					if reaction and (loc == zone or string.match(loc, zone) or zone == "A H") then 
						table.insert(nearby_targets, name)
					end
				end
			end
			-- print("nearby_targets:", table.concat(nearby_targets, ", ")) -- Don't delete, it's a useful debug code to print what was added to the rare list scanning.
		end
	end)


-------------------------------------------------------------------------------------
-- Function to refresh current rare mob list, after doing /unitscan ignore #unitname
-------------------------------------------------------------------------------------


	function unitscan.refresh_nearby_targets()
		-- print("Refreshed nearby rare list.")
	    local loc = GetRealZoneText()
	    local _, instance_type = IsInInstance()
	    is_resting = IsResting()
	    nearby_targets = {}
	    
	    if instance_type == "raid" or instance_type == "pvp" then return end
	    if loc == nil then return end
	    
	    for name, zone in pairs(rare_spawns) do
	        if not unitscan_ignored[name] then
	            local reaction = UnitReaction("player", name)
	            if not reaction or reaction < 4 then reaction = true else reaction = false end
	            if reaction and (loc == zone or string.match(loc, zone) or zone == "A H") then 
	                table.insert(nearby_targets, name)
	            end
	        end
	    end

	    -- print("nearby_targets:", table.concat(nearby_targets, ", "))
	end


--------------------------------------------------------------------------------
-- Events
--------------------------------------------------------------------------------

	unitscan:RegisterEvent'ADDON_LOADED'
	unitscan:RegisterEvent'ADDON_ACTION_FORBIDDEN'
	unitscan:RegisterEvent'PLAYER_TARGET_CHANGED'
	unitscan:RegisterEvent'ZONE_CHANGED_NEW_AREA'
	unitscan:RegisterEvent'PLAYER_LOGIN'
	unitscan:RegisterEvent'PLAYER_UPDATE_RESTING'


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

	--===== Some Colors for borders of button =====--
	local BROWN = {.7, .15, .05}
	local YELLOW = {1, 1, .15}


--------------------------------------------------------------------------------
-- Creating SavedVariables DB tables here. 
--------------------------------------------------------------------------------

	--===== DB Table for user-added targets via /unitscan "name" or /unitscan target =====--
	unitscan_targets = {}

	--===== DB Table for user-added rare spawns to ignore from scanning =====--
	unitscan_ignored = {}

	--===== DB Table for Default Settings =====--
	unitscan_defaults = {
		CHECK_INTERVAL = .3,
	}


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

	--===== Not a SavedVariables table to prevent spamming the alert. =====--
	local found = {}



--------------------------------------------------------------------------------------
-- Rare Databases corrected, translated by Sattva & Macumba & "that guy" from discord.
-- Database is automatically set by current locale.
--------------------------------------------------------------------------------------

rare_spawns = {}
if currentLocale == "enUS" or currentLocale == "enGB" then
    rare_spawns = {
	["7:XT"] = "Badlands",
	["ACCURSED SLITHERBLADE"] = "Desolace",
	["ACHELLIOS THE BANISHED"] = "Thousand Needles",
	["AEAN SWIFTRIVER"] = "The Barrens",
	["AKKRILUS"] = "Ashenvale",
	["AKUBAR THE SEER"] = "Blasted Lands",
	["ALSHIRR BANEBREATH"] = "Felwood",
	["ALSHIRR BANEBREATH"] = "Felwood",
	["AMBASSADOR BLOODRAGE"] = "The Barrens",
	["ANATHEMUS"] = "Badlands",
	["ANTILOS"] = "Azshara",
	["ANTILUS THE SOARER"] = "Feralas",
	["APOTHECARY FALTHIS"] = "Ashenvale",
	["ARAGA"] = "Alterac Mountains",
	["ARASH-ETHIS"] = "Feralas",
	["AZSHIR THE SLEEPLESS"] = "Scarlet Monastery",
	["AZUROUS"] = "Winterspring",
	["AZZERE THE SKYBLADE"] = "The Barrens",
	["BANNOK GRIMAXE"] = "Blackrock Spire",
	["BARNABUS"] = "Badlands",
	["BARON BLOODBANE"] = "Eastern Plaguelands",
	["BAYNE"] = "Tirisfal Glades",
	["BIG SAMRAS"] = "Hillsbrad Foothills",
	["BJARN"] = "Dun Morogh",
	["BLACKMOSS THE FETID"] = "Teldrassil",
	["BLIND HUNTER"] = "Razorfen Kraul",
	["BLOODROAR THE STALKER"] = "Feralas",
	["BOAHN"] = "Wailing Caverns",
	["BOSS GALGOSH"] = "Loch Modan",
	["BOULDERHEART"] = "Redridge Mountains",
	["BRACK"] = "Westfall",
	["BRAINWASHED NOBLE"] = "The Deadmines",
	["BRANCH SNAPPER"] = "Ashenvale",
	["BRIMGORE"] = "Dustwallow Marsh",
	["BROKEN TOOTH"] = "Badlands",
	["BROKESPEAR"] = "The Barrens",
	["BRONTUS"] = "The Barrens",
	["BROTHER RAVENOAK"] = "Stonetalon Mountains",
	["BRUEGAL IRONKNUCKLE"] = "The Stockade",
	["BURGLE EYE"] = "Dustwallow Marsh",
	["BURNING FELGUARD"] = "Blackrock Spire",
	["CAPTAIN FLAT TUSK"] = "Durotar",
	["CAPTAIN GEROGG HAMMERTOE"] = "The Barrens",
	["CARNIVOUS THE BREAKER"] = "Darkshore",
	["CHATTER"] = "Redridge Mountains",
	["CLACK THE REAVER"] = "Blasted Lands",
	["CLUTCHMOTHER ZAVAS"] = "Un'Goro Crater",
	["COMMANDER FELSTROM"] = "Duskwood",
	["CRANKY BENJ"] = "Alterac Mountains",
	["CREEPTHESS"] = "Hillsbrad Foothills",
	["CRIMSON ELITE"] = "Western Plaguelands",
	["CRUSTY"] = "Desolace",
	["CRYSTAL FANG"] = "Blackrock Spire",
	["CURSED CENTAUR"] = "Desolace",
	["CYCLOK THE MAD"] = "Tanaris",
	["DALARAN SPELLSCRIBE"] = "Silverpine Forest",
	["DARBEL MONTROSE"] = "Arathi Highlands",
	["DARK IRON AMBASSADOR"] = "Gnomeregan",
	["DARKMIST WIDOW"] = "Dustwallow Marsh",
	["DART"] = "Dustwallow Marsh",
	["DEATH FLAYER"] = "Durotar",
	["DEATH HOWL"] = "Felwood",
	["DEATH KNIGHT SOULBEARER"] = "Eastern Plaguelands",
	["DEATHEYE"] = "Blasted Lands",
	["DEATHMAW"] = "Burning Steppes",
	["DEATHSPEAKER SELENDRE"] = "Eastern Plaguelands",
	["DEATHSWORN CAPTAIN"] = "Shadowfang Keep",
	["DEEB"] = "Tirisfal Glades",
	["DESSECUS"] = "Felwood",
	["DEVIATE FAERIE DRAGON"] = "Wailing Caverns",
	["DIAMOND HEAD"] = "Feralas",
	["DIGGER FLAMEFORGE"] = "The Barrens",
	["DIGMASTER SHOVELPHLANGE"] = "Badlands",
	["DISHU"] = "The Barrens",
	["DRAGONMAW BATTLEMASTER"] = "Wetlands",
	["DREADSCORN"] = "Blasted Lands",
	["DREADWHISPER"] = "Western Plaguelands",
	["DREAMWATCHER FORKTONGUE"] = "Swamp of Sorrows",
	["DROGOTH THE ROAMER"] = "Dustwallow Marsh",
	["DUGGAN WILDHAMMER"] = "Eastern Plaguelands",
	["DUSKSTALKER"] = "Teldrassil",
	["DUSTWRAITH"] = "Zul'Farrak",
	["EARTHCALLER HALMGAR"] = "Razorfen Kraul",
	["ECK'ALOM"] = "Ashenvale",
	["EDAN THE HOWLER"] = "Dun Morogh",
	["ELDER MYSTIC RAZORSNOUT"] = "The Barrens",
	["EMOGG THE CRUSHER"] = "Loch Modan",
	["ENFORCER EMILGUND"] = "Mulgore",
	["ENGINEER WHIRLEYGIG"] = "The Barrens",
	["FALLEN CHAMPION"] = "Scarlet Monastery",
	["FARMER SOLLIDEN"] = "Tirisfal Glades",
	["FAULTY WAR GOLEM"] = "Searing Gorge",
	["FEDFENNEL"] = "Elwynn Forest",
	["FELENDOR THE ACCUSER"] = "Felwood",
	["FELLICENT'S SHADE"] = "Tirisfal Glades",
	["FELWEAVER SCORNN"] = "Durotar",
	["FENROS"] = "Duskwood",
	["FINGAT"] = "Swamp of Sorrows",
	["FIRECALLER RADISON"] = "Darkshore",
	["FLAGGLEMURK THE CRUEL"] = "Darkshore",
	["FOE REAPER 4000"] = "Westfall",
	["FOREMAN GRILLS"] = "The Barrens",
	["FOREMAN JERRIS"] = "Western Plaguelands",
	["FOREMAN MARCRID"] = "Western Plaguelands",
	["FOREMAN RIGGER"] = "Stonetalon Mountains",
	["FOULBELLY"] = "Arathi Highlands",
	["FOULMANE"] = "Western Plaguelands",
	["FURY SHELDA"] = "Teldrassil",
	["GARNEG CHARSKULL"] = "Wetlands",
	["GATEKEEPER RAGEROAR"] = "Azshara",
	["GENERAL COLBATANN"] = "Winterspring",
	["GENERAL FANGFERROR"] = "Azshara",
	["GEOLORD MOTTLE"] = "Durotar",
	["GEOMANCER FLINTDAGGER"] = "Arathi Highlands",
	["GEOPRIEST GUKK'ROK"] = "The Barrens",
	["GESHARAHAN"] = "The Barrens",
	["GHOK BASHGUUD"] = "Blackrock Spire",
	["GHOST HOWL"] = "Mulgore",
	["GIBBLESNIK"] = "Thousand Needles",
	["GIBBLEWILT"] = "Dun Morogh",
	["GIGGLER"] = "Desolace",
	["GILMORIAN"] = "Swamp of Sorrows",
	["GISH THE UNMOVING"] = "Eastern Plaguelands",
	["GLUGGLE"] = "Stranglethorn Vale",
	["GNARL LEAFBROTHER"] = "Feralas",
	["GNAWBONE"] = "Wetlands",
	["GOREFANG"] = "Silverpine Forest",
	["GORGON'OCH"] = "Burning Steppes",
	["GRAVIS SLIPKNOT"] = "Alterac Mountains",
	["GREAT FATHER ARCTIKUS"] = "Dun Morogh",
	["GREATER FIREBIRD"] = "Tanaris",
	["GRETHEER"] = "Silithus",
	["GRIMMAW"] = "Teldrassil",
	["GRIMTOOTH"] = "Alterac Valley",
	["GRIMUNGOUS"] = "The Hinterlands",
	["GRIZLAK"] = "Loch Modan",
	["GRIZZLE SNOWPAW"] = "Winterspring",
	["GRUBTHOR"] = "Silithus",
	["GRUFF"] = "Un'Goro Crater",
	["GRUFF SWIFTBITE"] = "Elwynn Forest",
	["GRUKLASH"] = "Burning Steppes",
	["GRUNTER"] = "Blasted Lands",
	["HAARKA THE RAVENOUS"] = "Tanaris",
	["HAGG TAURENBANE"] = "The Barrens",
	["HAHK'ZOR"] = "Burning Steppes",
	["HAMMERSPINE"] = "Dun Morogh",
	["HANNAH BLADELEAF"] = "The Barrens",
	["HARB FOULMOUNTAIN"] = "Thousand Needles",
	["HAYOC"] = "Dustwallow Marsh",
	["HEARTHSINGER FORRESTEN"] = "Stratholme",
	["HEARTRAZOR"] = "Thousand Needles",
	["HED'MUSH THE ROTTING"] = "Eastern Plaguelands",
	["HEGGIN STONEWHISKER"] = "The Barrens",
	["HEMATOS"] = "Burning Steppes",
	["HIGH GENERAL ABBENDIS"] = "Eastern Plaguelands",
	["HIGH PRIESTESS HAI'WATNA"] = "Stranglethorn Vale",
	["HIGHLORD MASTROGONDE"] = "Searing Gorge",
	["HISSPERAK"] = "Desolace",
	["HUMAR THE PRIDELORD"] = "The Barrens",
	["HURICANIAN"] = "Silithus",
	["IMMOLATUS"] = "Felwood",
	["IRONBACK"] = "The Hinterlands",
	["IRONEYE THE INVINCIBLE"] = "Thousand Needles",
	["IRONSPINE"] = "Scarlet Monastery",
	["JADE"] = "Swamp of Sorrows",
	["JALINDE SUMMERDRAKE"] = "The Hinterlands",
	["JED RUNEWATCHER"] = "Blackrock Spire",
	["JIMMY THE BLEEDER"] = "Alterac Mountains",
	["JIN'ZALLAH THE SANDBRINGER"] = "Tanaris",
	["KASHOCH THE REAVER"] = "Winterspring",
	["KASKK"] = "Desolace",
	["KAZON"] = "Redridge Mountains",
	["KING MOSH"] = "Un'Goro Crater",
	["KOVORK"] = "Arathi Highlands",
	["KREGG KEELHAUL"] = "Tanaris",
	["KRELLACK"] = "Silithus",
	["KRETHIS SHADOWSPINNER"] = "Silverpine Forest",
	["KURMOKK"] = "Stranglethorn Vale",
	["LADY HEDERINE"] = "Winterspring",
	["LADY HEDERINE"] = "Winterspring",
	["LADY MOONGAZER"] = "Darkshore",
	["LADY SESSPIRA"] = "Azshara",
	["LADY SZALLAH"] = "Feralas",
	["LADY VESPIA"] = "Ashenvale",
	["LADY VESPIRA"] = "Darkshore",
	["LADY ZEPHRIS"] = "Hillsbrad Foothills",
	["LAPRESS"] = "Silithus",
	["LARGE LOCH CROCOLISK"] = "Loch Modan",
	["LEECH WIDOW"] = "Wetlands",
	["LEPRITHUS"] = "Westfall",
	["LICILLIN"] = "Darkshore",
	["LO'GROSH"] = "Alterac Mountains",
	["LORD ANGLER"] = "Dustwallow Marsh",
	["LORD CAPTAIN WYRMAK"] = "Swamp of Sorrows",
	["LORD CONDAR"] = "Loch Modan",
	["LORD DARKSCYTHE"] = "Eastern Plaguelands",
	["LORD MALATHROM"] = "Duskwood",
	["LORD MALDAZZAR"] = "Western Plaguelands",
	["LORD ROCCOR"] = "Blackrock Depths",
	["LORD SAKRASIS"] = "Stranglethorn Vale",
	["LORD SINSLAYER"] = "Darkshore",
	["LOST ONE CHIEFTAIN"] = "Swamp of Sorrows",
	["LOST ONE COOK"] = "Swamp of Sorrows",
	["LOST SOUL"] = "Tirisfal Glades",
	["LUPOS"] = "Duskwood",
	["MA'RUK WYRMSCALE"] = "Wetlands",
	["MAGISTER HAWKHELM"] = "Azshara",
	["MAGOSH"] = "Loch Modan",
	["MAGRONOS THE UNYIELDING"] = "Blasted Lands",
	["MALFUNCTIONING REAVER"] = "Burning Steppes",
	["MALGIN BARLEYBREW"] = "The Barrens",
	["MARCUS BEL"] = "The Barrens",
	["MARISA DU'PAIGE"] = "Westfall",
	["MASTER DIGGER"] = "Westfall",
	["MASTER FEARDRED"] = "Azshara",
	["MAZZRANACHE"] = "Mulgore",
	["MESHLOK THE HARVESTER"] = "Maraudon",
	["MEZZIR THE HOWLER"] = "Winterspring",
	["MINER JOHNSON"] = "The Deadmines",
	["MIRELOW"] = "Wetlands",
	["MIST HOWLER"] = "Ashenvale",
	["MITH'RETHIS THE ENCHANTER"] = "The Hinterlands",
	["MOJO THE TWISTED"] = "Blasted Lands",
	["MOLOK THE CRUSHER"] = "Arathi Highlands",
	["MOLT THORN"] = "Swamp of Sorrows",
	["MONGRESS"] = "Felwood",
	["MONNOS THE ELDER"] = "Azshara",
	["MORGAINE THE SLY"] = "Elwynn Forest",
	["MOSH'OGG BUTCHER"] = "Stranglethorn Vale",
	["MOTHER FANG"] = "Elwynn Forest",
	["MUAD"] = "Tirisfal Glades",
	["MUGGLEFIN"] = "Ashenvale",
	["MURDEROUS BLISTERPAW"] = "Tanaris",
	["MUSHGOG"] = "Dire Maul",
	["NAL'TASZAR"] = "Stonetalon Mountains",
	["NARAXIS"] = "Duskwood",
	["NARG THE TASKMASTER"] = "Elwynn Forest",
	["NARILLASANZ"] = "Alterac Mountains",
	["NEFARU"] = "Duskwood",
	["NERUBIAN OVERSEER"] = "Eastern Plaguelands",
	["NIMAR THE SLAYER"] = "Arathi Highlands",
	["OAKPAW"] = "Ashenvale",
	["OLD CLIFF JUMPER"] = "The Hinterlands",
	["OLD GRIZZLEGUT"] = "Feralas",
	["OLD VICEJAW"] = "Silverpine Forest",
	["OLM THE WISE"] = "Felwood",
	["OMGORN THE LOST"] = "Tanaris",
	["OOZEWORM"] = "Dustwallow Marsh",
	["PANZOR THE INVINCIBLE"] = "Blackrock Depths",
	["PRIDEWING PATRIARCH"] = "Stonetalon Mountains",
	["PRINCE KELLEN"] = "Desolace",
	["PRINCE NAZJAK"] = "Arathi Highlands",
	["PRINCE RAZE"] = "Ashenvale",
	["PUTRIDIUS"] = "Western Plaguelands",
	["PYROMANCER LOREGRAIN"] = "Blackrock Depths",
	["QIROT"] = "Feralas",
	["QUARTERMASTER ZIGRIS"] = "Blackrock Spire",
	["RAGEPAW"] = "Felwood",
	["RAK'SHIRI"] = "Winterspring",
	["RANGER LORD HAWKSPEAR"] = "Eastern Plaguelands",
	["RATHORIAN"] = "The Barrens",
	["RAVAGE"] = "Blasted Lands",
	["RAVASAUR MATRIARCH"] = "Un'Goro Crater",
	["RAVENCLAW REGENT"] = "Silverpine Forest",
	["RAZORFEN SPEARHIDE"] = "Razorfen Kraul",
	["RAZORMAW MATRIARCH"] = "Wetlands",
	["RAZORTALON"] = "The Hinterlands",
	["REKK'TILAC"] = "Searing Gorge",
	["RESSAN THE NEEDLER"] = "Tirisfal Glades",
	["RETHEROKK THE BERSERKER"] = "The Hinterlands",
	["REX ASHIL"] = "Silithus",
	["RIBCHASER"] = "Redridge Mountains",
	["RIPPA"] = "Stranglethorn Vale",
	["RIPSCALE"] = "Dustwallow Marsh",
	["RO'BARK"] = "Hillsbrad Foothills",
	["ROCKLANCE"] = "The Barrens",
	["ROHH THE SILENT"] = "Redridge Mountains",
	["ROLOCH"] = "Stranglethorn Vale",
	["RORGISH JOWL"] = "Ashenvale",
	["ROT HIDE BRUISER"] = "Silverpine Forest",
	["RUMBLER"] = "Badlands",
	["RUUL ONESTONE"] = "Arathi Highlands",
	["SANDARR DUNEREAVER"] = "Zul'farrak",
	["SCALD"] = "Searing Gorge",
	["SCALE BELLY"] = "Stranglethorn Vale",
	["SCALEBEARD"] = "Azshara",
	["SCARGIL"] = "Hillsbrad Foothills",
	["SCARLET EXECUTIONER"] = "Western Plaguelands",
	["SCARLET HIGH CLERIST"] = "Western Plaguelands",
	["SCARLET INTERROGATOR"] = "Western Plaguelands",
	["SCARLET JUDGE"] = "Western Plaguelands",
	["SCARLET SMITH"] = "Western Plaguelands",
	["SCARSHIELD QUARTERMASTER"] = "Blackrock Mountain",
	["SEEKER AQUALON"] = "Redridge Mountains",
	["SENTINEL AMARASSAN"] = "Stonetalon Mountains",
	["SERGEANT BRASHCLAW"] = "Westfall",
	["SETIS"] = "Silithus",
	["SEWER BEAST"] = "Stormwind City",
	["SHADOWCLAW"] = "Darkshore",
	["SHADOWFORGE COMMANDER"] = "Badlands",
	["SHANDA THE SPINNER"] = "Loch Modan",
	["SHLEIPNARR"] = "Searing Gorge",
	["SIEGE GOLEM"] = "Badlands",
	["SILITHID HARVESTER"] = "The Barrens",
	["SILITHID RAVAGER"] = "Thousand Needles",
	["SINGER"] = "Arathi Highlands",
	["SISTER HATELASH"] = "Mulgore",
	["SISTER RATHTALON"] = "The Barrens",
	["SISTER RIVEN"] = "Stonetalon Mountains",
	["SKARR THE UNBREAKABLE"] = "Dire Maul",
	["SKHOWL"] = "Alterac Mountains",
	["SKUL"] = "Stratholme",
	["SLARK"] = "Westfall",
	["SLAVE MASTER BLACKHEART"] = "Searing Gorge",
	["SLUDGE BEAST"] = "The Barrens",
	["SLUDGINN"] = "Wetlands",
	["SMOLDAR"] = "Searing Gorge",
	["SNAGGLESPEAR"] = "Mulgore",
	["SNARLER"] = "Feralas",
	["SNARLFLARE"] = "Redridge Mountains",
	["SNARLMANE"] = "Silverpine Forest",
	["SNORT THE HECKLER"] = "The Barrens",
	["SORIID THE DEVOURER"] = "Tanaris",
	["SORROW WING"] = "Stonetalon Mountains",
	["SPIRESTONE BATTLE LORD"] = "Blackrock Spire",
	["SPIRESTONE BUTCHER"] = "Blackrock Spire",
	["SPIRESTONE LORD MAGUS"] = "Blackrock Spire",
	["SPITEFLAYER"] = "Blasted Lands",
	["SQUIDDIC"] = "Redridge Mountains",
	["SRI'SKULK"] = "Tirisfal Glades",
	["STAGGON"] = "Desolace",
	["STONE FURY"] = "Alterac Mountains",
	["STONEARM"] = "The Barrens",
	["STONESPINE"] = "Stratholme",
	["STRIDER CLUTCHMOTHER"] = "Darkshore",
	["SWIFTMANE"] = "The Barrens",
	["SWINEGART SPEARHIDE"] = "The Barrens",
	["TAKK THE LEAPER"] = "The Barrens",
	["TAMRA STORMPIKE"] = "Hillsbrad Foothills",
	["TASKMASTER WHIPFANG"] = "Stonetalon Mountains",
	["TERRORSPARK"] = "Burning Steppes",
	["TERROWULF PACKLORD"] = "Ashenvale",
	["THAURIS BALGARR"] = "Burning Steppes",
	["THE BEHEMOTH"] = "Blackrock Mountain",
	["THE EVALCHARR"] = "Azshara",
	["THE HUSK"] = "Western Plaguelands",
	["THE ONGAR"] = "Felwood",
	["THE RAKE"] = "Mulgore",
	["THE RAZZA"] = "Dire Maul",
	["THE REAK"] = "The Hinterlands",
	["THE ROT"] = "Dustwallow Marsh",
	["THORA FEATHERMOON"] = "The Barrens",
	["THREGGIL"] = "Teldrassil",
	["THUNDERSTOMP"] = "The Barrens",
	["THUROS LIGHTFINGERS"] = "Elwynn Forest",
	["TIMBER"] = "Dun Morogh",
	["TORMENTED SPIRIT"] = "Tirisfal Glades",
	["TREGLA"] = "Eversong Woods",
	["TRIGORE THE LASHER"] = "Wailing Caverns",
	["TWILIGHT LORD EVERUN"] = "Silithus",
	["UHK'LOC"] = "Un'Goro Crater",
	["URSOL'LOK"] = "Ashenvale",
	["URUSON"] = "Teldrassil",
	["VARO'THEN'S GHOST"] = "Azshara",
	["VENGEFUL ANCIENT"] = "Stonetalon Mountains",
	["VEREK"] = "Blackrock Depths",
	["VERIFONIX"] = "Stranglethorn Vale",
	["VEYZHAK THE CANNIBAL"] = "Temple of Atal'Hakkar",
	["VILE STING"] = "Thousand Needles",
	["VOLCHAN"] = "Burning Steppes",
	["VULTROS"] = "Westfall",
	["WAR GOLEM"] = "Badlands",
	["WARDER STILGISS"] = "Blackrock Depths",
	["WARLEADER KRAZZILAK"] = "Tanaris",
	["WARLORD KOLKANIS"] = "Durotar",
	["WARLORD THRESH'JIN"] = "Eastern Plaguelands",
	["WATCH COMMANDER ZALAPHIL"] = "Durotar",
	["WEP"] = "Desolace",
	["WITHERHEART THE STALKER"] = "The Hinterlands",
	["ZALAS WITHERBARK"] = "Arathi Highlands",
	["ZARICOTL"] = "Badlands",
	["ZEKKIS"] = "Temple of Atal'Hakkar",
	["ZERILLIS"] = "Zul'Farrak",
	["ZORA"] = "Silithus",
	["ZUL'AREK HATEFOWLER"] = "The Hinterlands",
	["ZUL'BRIN WARPBRANCH"] = "Eastern Plaguelands",
    -- Epoch
	["ACHAK"] = "Dustwallow Marsh",
	["AKANDA"] = "Arathi Highlands",
	["ANCHOR"] = "Tanaris",
	["ARTERIS THE EXILE"] = "Darkshore",
	["ARTURAS"] = "Loch Modan",
	["ARYA DEVOUT"] = "Silverpine Forest",
	["BAEB"] = "Durotar",
	["BAY BEAST"] = "Orgrimmar",
	["BJORGILL"] = "Elwynn Forest",
	["BLACKROCK OUTCAST"] = "Burning Steppes",
	["BLIZZARD BEAR"] = "Dun Morogh",
	["BLYX"] = "Feralas",
	["BOULDERFROST"] = "Winterspring",
	["BRUCE"] = "Tanaris",
	["BYMDOKIC"] = "Western Plaguelands",
	["CACHI"] = "Ashenvale",
	["CANDIRU"] = "The Hinterlands",
	["CHUM"] = "Tanaris",
	["CLACK"] = "Swamp of Sorrows",
	["CL'RVISH"] = "Silithus",
	["CONCOLAR"] = "Alterac Mountains",
	["CORRUPTED ANCIENT"] = "Ashenvale",
	["CORRUPTED TREANT"] = "Teldrassil",
	["CRAZED PROSPECTOR"] = "Silithus",
	["CRESHILL"] = "Silverpine Forest",
	["DAYLOOJ"] = "Un'Goro Crater",
	["DEATHCLAW"] = "Arathi Highlands",
	["DIGIT"] = "Stranglethorn Vale",
	["DRAZ'KEL"] = "Blasted Lands",
	["DUSTER"] = "Westfall",
	["EBB"] = "Dun Morogh",
	["ECHO OF TICHONDRIUS"] = "Felwood",
	["EELIOS"] = "Redridge Mountains",
	["FARMER BLACKWOOD"] = "Eastern Plaguelands",
	["FAY TUE"] = "Alterac Mountains",
	["FEATHERSTORM"] = "Azshara",
	["FELSNAP"] = "Blasted Lands",
	["FIREWATER SALESMAN"] = "Azshara",
	["FLO"] = "Tirisfal Glades",
	["FOE REAPER 8000"] = "Eastern Plaguelands",
	["FOREMAN SHREEV"] = "Stonetalon Mountains",
	["FORLORN JAEDENAR SPIRIT"] = "Felwood",
	["FORLORN PRIESTESS"] = "Winterspring",
	["FROZEN HIGHBORNE SPIRIT"] = "Azshara",
	["GARG THE EXILED"] = "Wetlands",
	["GENA"] = "Stranglethorn Vale",
	["GHOSTSCALE"] = "Silverpine Forest",
	["GIWDEH"] = "Teldrassil",
	["GLOB"] = "The Hinterlands",
	["GONZOR"] = "Hillsbrad Foothills",
	["GREGG"] = "Badlands",
	["GRIMENAIL"] = "Westfall",
	["GROL'THOK"] = "Wetlands",
	["GROSH'MAL"] = "Deadwind Pass",
	["GURUBASHI SPEAKER"] = "Dun Morogh",
	["HEAD OVERSEER BLACKRIVER"] = "Badlands",
	["HEXXIS"] = "Felwood",
	["HOODED FIGURE"] = "Deadwind Pass",
	["HYLO"] = "Hillsbrad Foothills",
	["HYPERION"] = "Un'Goro Crater",
	["ILL KODOCUT"] = "Stonetalon Mountains",
	["INCENDOSAUR BROOD MOTHER"] = "Searing Gorge",
	["INSPECTOR DANIELS"] = "Tirisfal Glades",
	["ITNICS"] = "Stonetalon Mountains",
	["JAZ JR."] = "Mulgore",
	["KADON"] = "Mulgore",
	["KASH"] = "Swamp of Sorrows",
	["KIERA THE SHADE"] = "Blasted Lands",
	["KOAL"] = "Burning Steppes",
	["KOKO"] = "Feralas",
	["KORUT THE MOURNFUL"] = "Desolace",
	["LAEXXARN"] = "Eastern Plaguelands",
	["LEELA"] = "Winterspring",
	["LESHTAR"] = "Azshara",
	["LIGHTMASTER DANIEL"] = "Tol Barad",
	["LORD SATHRATH"] = "Teldrassil",
	["LUUNE"] = "Ashenvale",
	["MAETS"] = "Arathi Highlands",
	["MAEVES"] = "Durotar",
	["MELMAN"] = "The Barrens",
	["MORDECHAI"] = "Redridge Mountains",
	["NAKHAS"] = "Dustwallow Marsh",
	["NEIMOSH"] = "Azshara",
	["NEREID"] = "Thousand Needles",
	["NURGLAR"] = "Loch Modan",
	["NYCTEA"] = "Loch Modan",
	["OURSON"] = "Darkshore",
	["PAGOO"] = "Durotar",
	["PINCHES"] = "Darkshore",
	["PORTOBELLO"] = "Western Plaguelands",
	["PRECIPISE"] = "Elwynn Forest",
	["PTERIOS"] = "The Hinterlands",
	["PYRE"] = "Thousand Needles",
	["RAYTH"] = "Tirisfal Glades",
	["RELIC HUNTER YANTHRESS"] = "Azshara",
	["RISHEK"] = "Desolace",
	["ROCKNADO"] = "Silithus",
	["ROGUE TEACHER MCCONAGILL"] = "Western Plaguelands",
	["RON FOREFIGHT"] = "Redridge Mountains",
	["ROTTENEYE"] = "Feralas",
	["SAAVIS"] = "Burning Steppes",
	["SCALD"] = "Badlands",
	["SCARLET SENIOR FOREMAN"] = "Western Plaguelands",
	["SENIOR"] = "Hillsbrad Foothills",
	["SEWER SLIME"] = "Undercity",
	["SHENGIS"] = "Stranglethorn Vale",
	["SHIMMERSCALE"] = "Swamp of Sorrows",
	["SILITHID LURKER"] = "Tanaris",
	["SIRROCO"] = "Tanaris",
	["SOBECK"] = "Deadwind Pass",
	["SORCERER DAVOS"] = "Elwynn Forest",
	["SPIRIT OF ARU-TALIS"] = "Un'Goro Crater",
	["SPYRO"] = "Wetlands",
	["STARSONG FOLLOWER"] = "Duskwood",
	["STRUTHIO"] = "The Barrens",
	["SWINNUB"] = "Westfall",
	["SZECEK'ZEX"] = "Dustwallow Marsh",
	["TALON"] = "Mulgore",
	["TASKMISTRESS LINA"] = "Blasted Lands",
	["TERRA"] = "Thousand Needles",
	["THE UNKNOWN SOLDIER"] = "Duskwood",
	["TWILIGHT DIPLOMAT"] = "Blasted Lands",
	["URSAUR"] = "Dun Morogh",
	["WATCH LEADER PERCIVEL"] = "Stranglethorn Vale",
	["WATCHER BLOZRUG"] = "Alterac Mountains",
	["ZEKE"] = "The Barrens",
	["ZURKA"] = "Dun Morogh",
    }
else
    -- If the current locale is not recognized, you can define a default table or display an error message
    if DEFAULT_CHAT_FRAME then
    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00unitscan warning:|r " .. "|cffffff9aunrecognized client language, rare list is not populated. Only enGB / enUS clients are currently supported for rare list.|r" .. "|cFFFFFF00 \nYou can still add any units via unitscan commands!|r")
    end
    rare_spawns = {
    }
end


--------------------------------------------------------------------------------
-- Play sound if wasn't played recently.
--------------------------------------------------------------------------------


do
	local last_played
	
	function unitscan.play_sound()
		if not last_played or GetTime() - last_played > 3 then
			PlaySoundFile([[Interface\AddOns\unitscan\assets\Event_wardrum_ogre.ogg]], 'Sound')
			PlaySoundFile([[Sound\Interface\MapPing.wav]], 'Sound')
			last_played = GetTime()
		end
	end
end


--------------------------------------------------------------------------------
-- Main function to scan for targets.
--------------------------------------------------------------------------------


function unitscan.target(name)
	forbidden = false
	TargetUnit(name)
	-- unitscan.print(tostring(UnitHealth(name)) .. " " .. name)
	-- if not deadscan and UnitIsCorpse(name) then
	-- 	return
	-- end
	if forbidden then
		if not found[name] then
			found[name] = true
			--FlashClientIcon()
			unitscan.play_sound()
			unitscan.flash.animation:Play()
			unitscan.discovered_unit = name
			if InCombatLockdown() then
				print("|cFF00FF00unitscan found - |r |cffffff00" .. name .. "|r")
			end
		end
	else
		found[name] = false
	end
end


--------------------------------------------------------------------------------
-- Functions that creates button, and other visuals during alert.
--------------------------------------------------------------------------------


function unitscan.LOAD()
	UIParent:UnregisterEvent'ADDON_ACTION_FORBIDDEN'
	do
		local flash = CreateFrame'Frame'
		unitscan.flash = flash
		flash:Show()
		flash:SetAllPoints()
		flash:SetAlpha(0)
		flash:SetFrameStrata'LOW'
		SetCVar("Sound_EnableErrorSpeech", 0)
		
		local texture = flash:CreateTexture()
		texture:SetBlendMode'ADD'
		texture:SetAllPoints()
		texture:SetTexture[[Interface\FullScreenTextures\LowHealth]]

		flash.animation = CreateFrame'Frame'
		flash.animation:Hide()
		flash.animation:SetScript('OnUpdate', function(self)
			local t = GetTime() - self.t0
			if t <= .5 then
				flash:SetAlpha(t * 2)
			elseif t <= 1 then
				flash:SetAlpha(1)
			elseif t <= 1.5 then
				flash:SetAlpha(1 - (t - 1) * 2)
			else
				flash:SetAlpha(0)
				self.loops = self.loops - 1
				if self.loops == 0 then
					self.t0 = nil
					self:Hide()
				else
					self.t0 = GetTime()
				end
			end
		end)
		function flash.animation:Play()
			if self.t0 then
				self.loops = 2
			else
				self.t0 = GetTime()
				self.loops = 1
			end
			self:Show()
		end
	end
	
	local button = CreateFrame('Button', 'unitscan_button', UIParent, 'SecureActionButtonTemplate')
	-- first code to set left and right click of button
	button:SetAttribute("type1", "macro")
	button:SetAttribute("type2", "macro")
	-- rest of button code
	button:Hide()
	unitscan.button = button
	button:SetPoint('BOTTOM', UIParent, 0, 128)
	button:SetWidth(150)
	button:SetHeight(42)
	button:SetScale(1.25)
	button:SetMovable(true)
	button:SetUserPlaced(true)
	button:SetClampedToScreen(true)

	-- code to enable ctrl-click to move (it has nothing to do with left and right click function)
	button:SetScript('OnMouseDown', function(self)
	    if IsControlKeyDown() then
	        self:RegisterForClicks("AnyDown", "AnyUp")
	        self:StartMoving()
	    end
	end)
	button:SetScript('OnMouseUp', function(self)
	    self:StopMovingOrSizing()
	    self:RegisterForClicks("AnyDown", "AnyUp")
	end) 

	button:SetFrameStrata'LOW'
	button:SetNormalTexture[[Interface\AddOns\unitscan\assets\UI-Achievement-Parchment-Horizontal]]
	
	if isWOTLK or isTBC then
		button:SetBackdrop{
			tile = true,
			edgeSize = 16,
			edgeFile = [[Interface\Tooltips\UI-Tooltip-Border]],
		}
		button:SetBackdropBorderColor(unpack(BROWN))
		button:SetScript('OnEnter', function(self)
			self:SetBackdropBorderColor(unpack(YELLOW))
		end)
		button:SetScript('OnLeave', function(self)
			self:SetBackdropBorderColor(unpack(BROWN))
		end)
	end

	function button:set_target(name)
		-- string that adds name text to the button
		self:SetText(name)
		-- second code to set left and right click of button macro texts
		self:SetAttribute("macrotext1", "/cleartarget\n/targetexact " .. name)
		self:SetAttribute("macrotext2", "/click unitscan_close") -- this is made to click "close" button code for which is defined below
		-- rest of code
		self:Show()
		self.glow.animation:Play()
		self.shine.animation:Play()
	end
	
	do
		local background = button:GetNormalTexture()
		background:SetDrawLayer'BACKGROUND'
		background:ClearAllPoints()
		background:SetPoint('BOTTOMLEFT', 3, 3)
		background:SetPoint('TOPRIGHT', -3, -3)
		background:SetTexCoord(0, 1, 0, .25)
	end
	
	do
		local title_background = button:CreateTexture(nil, 'BORDER')
		title_background:SetTexture[[Interface\AddOns\unitscan\assets\UI-Achievement-Title]]
		title_background:SetPoint('TOPRIGHT', -5, -5)
		title_background:SetPoint('LEFT', 5, 0)
		title_background:SetHeight(18)
		title_background:SetTexCoord(0, .9765625, 0, .3125)
		title_background:SetAlpha(.8)


		--===== Create Title (UNIT name) =====--
		local title = button:CreateFontString(nil, 'OVERLAY')
		title:SetFont(GameFontNormal:GetFont(), 14, 'OUTLINE')

		title:SetShadowOffset(1, -1)
		title:SetPoint('TOPLEFT', title_background, 0, 0)
		title:SetPoint('RIGHT', title_background)
		button:SetFontString(title)

		local subtitle = button:CreateFontString(nil, 'OVERLAY')
		subtitle:SetFont([[Fonts\FRIZQT__.TTF]], 14)
		subtitle:SetTextColor(0, 0, 0)
		subtitle:SetPoint('TOPLEFT', title, 'BOTTOMLEFT', 0, -4)
		subtitle:SetPoint('RIGHT', title)
		subtitle:SetText'Unit Found!'
	end
	
	do
		local model = CreateFrame('PlayerModel', nil, button)
		button.model = model
		model:SetPoint('BOTTOMLEFT', button, 'TOPLEFT', 0, -4)
		model:SetPoint('RIGHT', 0, 0)
		model:SetHeight(button:GetWidth() * .6)
	end
	
	do
		local close = CreateFrame('Button', "unitscan_close", button, 'UIPanelCloseButton')
		close:SetPoint('BOTTOMRIGHT', 5, -5)
		close:SetWidth(32)
		close:SetHeight(32)
		close:SetScale(.8)
		close:SetHitRectInsets(8, 8, 8, 8)
	end
	
	do
		local glow = button.model:CreateTexture(nil, 'OVERLAY')
		button.glow = glow
		glow:SetPoint('CENTER', button, 'CENTER')
		glow:SetWidth(400 / 300 * button:GetWidth())
		glow:SetHeight(171 / 70 * button:GetHeight())
		glow:SetTexture[[Interface\AddOns\unitscan\assets\UI-Achievement-Alert-Glow]]
		glow:SetBlendMode'ADD'
		glow:SetTexCoord(0, .78125, 0, .66796875)
		glow:SetAlpha(0)

		glow.animation = CreateFrame'Frame'
		glow.animation:Hide()
		glow.animation:SetScript('OnUpdate', function(self)
			local t = GetTime() - self.t0
			if t <= .2 then
				glow:SetAlpha(t * 5)
			elseif t <= .7 then
				glow:SetAlpha(1 - (t - .2) * 2)
			else
				glow:SetAlpha(0)
				self:Hide()
			end
		end)
		function glow.animation:Play()
			self.t0 = GetTime()
			self:Show()
		end
	end

	do
		local shine = button:CreateTexture(nil, 'ARTWORK')
		button.shine = shine
		shine:SetPoint('TOPLEFT', button, 0, 8)
		shine:SetWidth(67 / 300 * button:GetWidth())
		shine:SetHeight(1.28 * button:GetHeight())
		shine:SetTexture[[Interface\AddOns\unitscan\assets\UI-Achievement-Alert-Glow]]
		shine:SetBlendMode'ADD'
		shine:SetTexCoord(.78125, .912109375, 0, .28125)
		shine:SetAlpha(0)
		
		shine.animation = CreateFrame'Frame'
		shine.animation:Hide()
		shine.animation:SetScript('OnUpdate', function(self)
			local t = GetTime() - self.t0
			if t <= .3 then
				shine:SetPoint('TOPLEFT', button, 0, 8)
			elseif t <= .7 then
				shine:SetPoint('TOPLEFT', button, (t - .3) * 2.5 * self.distance, 8)
			end
			if t <= .3 then
				shine:SetAlpha(0)
			elseif t <= .5 then
				shine:SetAlpha(1)
			elseif t <= .7 then
				shine:SetAlpha(1 - (t - .5) * 5)
			else
				shine:SetAlpha(0)
				self:Hide()
			end
		end)
		function shine.animation:Play()
			self.t0 = GetTime()
			self.distance = button:GetWidth() - shine:GetWidth() + 8
			self:Show()
			button:SetAlpha(1)
		end
	end
end


--------------------------------------------------------------------------------
-- Function to scan for units with conditions. 
--------------------------------------------------------------------------------


do
	unitscan.last_check = GetTime()
	function unitscan.UPDATE()
		if is_resting then return end
		if not InCombatLockdown() and unitscan.discovered_unit then
			unitscan.button:set_target(unitscan.discovered_unit)
			unitscan.discovered_unit = nil
		end
		if GetTime() - unitscan.last_check >= unitscan_defaults.CHECK_INTERVAL then
			unitscan.last_check = GetTime()
			for name in pairs(unitscan_targets) do
				unitscan.target(name)
			end
			for _, name in pairs(nearby_targets) do
				unitscan.target(name)
			end
		end
	end
end


--------------------------------------------------------------------------------
-- Prints to add prefix to message and color text.
--------------------------------------------------------------------------------


function unitscan.print(msg)
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00/unitscan|r " .. "|cffffff9a" .. msg .. "|r")
    end
end


function unitscan.ignoreprint(msg)
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00/unitscan ignore|r " .. "|cffff0000" .. msg .. "|r")
    end
end

--------------------------------------------------------------------------------
-- Function for sorting targets alphabetically. For user QOL.
--------------------------------------------------------------------------------


function unitscan.sorted_targets()
	local sorted_targets = {}
	for key in pairs(unitscan_targets) do
		tinsert(sorted_targets, key)
	end
	sort(sorted_targets, function(key1, key2) return key1 < key2 end)
	return sorted_targets
end


--------------------------------------------------------------------------------
-- Function to add current target to the scanning list.
--------------------------------------------------------------------------------


function unitscan.toggle_target(name)
	local key = strupper(name)
	if unitscan_targets[key] then
		unitscan_targets[key] = nil
		found[key] = nil
		unitscan.print('- ' .. key)
	elseif key ~= '' then
		unitscan_targets[key] = true
		unitscan.print('+ ' .. key)
	end
end


--------------------------------------------------------------------------------
-- Slash Commands /unitscan
--------------------------------------------------------------------------------

	
SlashCmdList["UNITSCAN"] = function(parameter)
	local _, _, command, args = string.find(parameter, '^(%S+)%s*(.*)$')
	
	--===== Slash to put current player target to the unit scanning list. =====--	
	if command == "target" then
		local targetName = UnitName("target")
		if targetName then
			local key = strupper(targetName)
			if not unitscan_targets[key] then
				unitscan_targets[key] = true
				unitscan.print("+ " .. key)
			else
				unitscan_targets[key] = nil
				unitscan.print("- " .. key)
				found[key] = nil
			end
		else
			unitscan.print("No target selected.")
		end

	--===== Slash to change unit scanning interval. Default is 0.3 =====--	
	elseif command == "interval" then
		local newInterval = tonumber(args)
		if newInterval then
			unitscan_defaults.CHECK_INTERVAL = newInterval
			unitscan.print("Check interval set to " .. newInterval)
		else
			unitscan.print("Invalid interval value. Usage: /unitscan interval <number>")
		end

	--===== Slash Ignore Rare =====--	
	elseif command == "ignore" then
		if args == "" then
			-- print list of ignored NPCs
			if next(unitscan_ignored) == nil then
				print(" ")
			unitscan.ignoreprint("list is empty.")
			else
			print("|cffff0000" .. " Ignore list " .. "|r"  .. "currently contains:")
			for rare in pairs(unitscan_ignored) do
				unitscan.ignoreprint(rare)
			end
		end

			return
		else
	        local rare = string.upper(args)
	        if rare_spawns[rare] == nil then
	            -- rare does not exist in rare_spawns table
	            unitscan.print("|cffffff00" .. args .. "|r" .. " is not a valid rare spawn.")

	            return
	    end

		if unitscan_ignored[rare] then
			-- remove rare from ignore list
			unitscan_ignored[rare] = nil
			unitscan.ignoreprint("- " .. rare)
			unitscan.refresh_nearby_targets()
			found[rare] = nil
		else
			-- add rare to ignore list
			unitscan_ignored[rare] = true
			unitscan.ignoreprint("+ " .. rare)
			unitscan.refresh_nearby_targets()
		end

		return
		end


	--===== Slash to avoid people confusion if they do /unitscan name =====--	
	elseif command == "name" then
		print(" ")
		unitscan.print("replace |cffffff00'name'|r with npc you want to scan.")
		print(" - for example: |cFF00FF00/unitscan|r |cffffff00Hogger|r")

	--===== Slash to only print currently tracked non-rare targets. =====--	
	elseif command == "targets" then
		if unitscan_targets then
			for k, v in pairs(unitscan_targets) do
				unitscan.print(tostring(k))
			end
		end

	--===== Slash to show rare spawns that are currently being scanned. =====--	
	elseif command == "nearby" then
		print(" ")
		unitscan.print("Is someone missing?")
						print(" - Add it to your list with |cFF00FF00/unitscan|r |cffffff00name|r")
				unitscan.print("|cffff0000ignore|r")
				print(" - Adds/removes the rare mob 'name' from the unit scanner |cffff0000ignore list.|r")
				print(" ")
		for key,val in pairs(nearby_targets) do
			if not (val == "Lumbering Horror" or val == "Spirit of the Damned" or val == "Bone Witch") then
				unitscan.print(val)
			end
		end

	--===== Slash to show all avaliable commands =====--	
	elseif command == 'help' then

		print(" ")
		print("|cfff0d440Available commands:|r")

		unitscan.print("target")
		print(" - Adds/removes the name of your |cffffff00current target|r to the scanner.")
		-- print(" ")
		unitscan.print("name")
		print(" - Adds/removes the |cffffff00mob/player 'name'|r from the unit scanner.")
		-- print(" ")
		unitscan.print("nearby")
		print(" - List of |cffffff00rare mob names|r that are being scanned in your current zone.")
		unitscan.print("|cffff0000ignore|r")
				print(" - Adds/removes the rare mob 'name' from the unit scanner |cffff0000ignore list.|r")


	--===== Slash without any arguments (/untiscan) prints currently tracked user-defined units and some basic available slash commands  =====--
	--===== If an agrugment after /unitscan is given, it will add a unit to the scanning targets. =====--
	elseif not command then
		print(" ")
		unitscan.print("|cffffff00help|r")
		print(" - Displays available unitscan |cffffff00commands|r")
		print(" ")
		if unitscan_targets then
			if next(unitscan_targets) == nil then
				unitscan.print("Unit Scanner is currently empty.")
			else
				print(" |cffffff00Unit Scanner|r currently contains:")
				for k, v in pairs(unitscan_targets) do
					unitscan.print(tostring(k))
				end
			end
		end
	else
		unitscan.toggle_target(parameter)
	end
end
SLASH_UNITSCAN1 = "/unitscan"


