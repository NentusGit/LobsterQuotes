
-- Create global table and ensure database exists
LobsterQuotes = LobsterQuotes or {}
LobsterQuotesDB = LobsterQuotesDB or {
    quotes = {},
    settings = {
        autoSendOnWipe = true,
        defaultChannel = "RAID",
        guildGroupRequired = true,
        noRepeat = true,
        requireRaid = true,
        debug = false,
        lastQuoteSent = {}
    }
}

-- Local variables because thats apparently better performance?
local CreateFrame = CreateFrame
local SendChatMessage = C_ChatInfo.SendChatMessage
local PlaySound = PlaySound
local table = table
local math = math
local string = string

-- Constants
local PORTRAIT_TEXTURE_ID = 7966624 --132482 --134048 --Icon of a Lobster
local ROW_HEIGHT_COLLAPSED = 30
local ROW_HEIGHT_EXPANDED = 90

-- Quote Management Functions
function LobsterQuotes:AddQuote(content, author)
    if not content then return end
    table.insert(LobsterQuotesDB.quotes, {
        content = content,
        author = author or "Unknown",
    })
    self:RefreshQuoteDisplay()
end

function LobsterQuotes:RemoveQuote(index)
    if index and LobsterQuotesDB.quotes[index] then
        table.remove(LobsterQuotesDB.quotes, index)
        self:RefreshQuoteDisplay()
    end
end

function LobsterQuotes:EditQuote(index, content, author)
    if index and LobsterQuotesDB.quotes[index] then
        LobsterQuotesDB.quotes[index].content = content
        LobsterQuotesDB.quotes[index].author = author
        self:RefreshQuoteDisplay()
    end
end

function LobsterQuotes:SendQuote(index, channel)
    if index and LobsterQuotesDB.quotes[index] then
        local quote = LobsterQuotesDB.quotes[index]
        local message = string.format("%s - %s", quote.content, quote.author)
        SendChatMessage(message, channel or LobsterQuotesDB.settings.defaultChannel)
    end
end

function LobsterQuotes:GetRandomQuote() -- With repetiton protection if LobsterQuotesDB.settings.noRepeat is true
    local quotes = LobsterQuotesDB.quotes
    if #quotes == 0 then return nil end

    if LobsterQuotesDB.settings.noRepeat and #quotes > 1 then
        local availableQuotes = {}
        for i = 1, #quotes do
            if i ~= LobsterQuotesDB.settings.lastQuoteSent then
                table.insert(availableQuotes, i)
            end
        end
        local selectedQuote = availableQuotes[math.random(#availableQuotes)]
        LobsterQuotesDB.settings.lastQuoteSent = selectedQuote
        return quotes[selectedQuote]
    else
        local selectedQuote = math.random(#quotes)
        LobsterQuotesDB.settings.lastQuoteSent = selectedQuote
        return quotes[selectedQuote]
    end
end

function LobsterQuotes:SendRandomQuote(channel)
    local quote = self:GetRandomQuote()
    if not quote then
        self:Debug("SendRandomQuote failed because empty quote list?")return end
    local message = string.format("%s - %s", quote.content, quote.author)
    local selectedChannel = channel or LobsterQuotesDB.settings.defaultChannel
    if IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then
        selectedChannel = "INSTANCE_CHAT"
    end
    self:Debug("Sending to channel=%s", selectedChannel)
    SendChatMessage(message, selectedChannel)
end

function LobsterQuotes:Debug(msg,...)
    if not LobsterQuotesDB.settings.debug then return end
    print(string.format("|cff00ccffDebug:|r "..msg,...))
end

function LobsterQuotes:IsInRaid()
    if LobsterQuotesDB.settings.debug then
        self:Debug("IsInRaid() bypassed for solo testing")
        return true
    end
    return IsInRaid()
end

function LobsterQuotes:InGuildGroup()
    return IsInGuildGroup()
end

function LobsterQuotes:RequiredGuildGroupMet()
    if LobsterQuotesDB.settings.guildGroupRequired then
        return self:InGuildGroup()
    end
    return true
end


function LobsterQuotes:ShowAddQuoteDialog()
    if self.addQuoteDialog then
        self.addQuoteDialog:Show()
        return
    end
    
    local dialog = CreateFrame("Frame", "LobsterQuotesAddDialog", UIParent, "DefaultPanelTemplate")
    dialog:SetSize(400, 240)
    dialog:SetPoint("CENTER")
    dialog:SetFrameStrata("DIALOG")
    
    dialog:EnableMouse(true)
    dialog:SetMovable(true)
    dialog:RegisterForDrag("LeftButton")
    dialog:SetScript("OnDragStart", dialog.StartMoving)
    dialog:SetScript("OnDragStop", dialog.StopMovingOrSizing)
    
    dialog.TitleContainer.TitleText:SetText("Add New Quote")
    
    -- Create quote input box
    local quoteEditBox = CreateFrame("EditBox", nil, dialog)
    quoteEditBox:SetPoint("TOPLEFT", dialog.Bg, "TOPLEFT", 20, -40)
    quoteEditBox:SetPoint("BOTTOMRIGHT", dialog, "RIGHT", -20, 5)
    quoteEditBox:SetHeight(50)
    quoteEditBox:SetFontObject("GameFontHighlight")
    quoteEditBox:SetAutoFocus(false)
    quoteEditBox:SetMaxLetters(240)
    quoteEditBox:SetMultiLine(true)
    
    local quoteBg = dialog:CreateTexture(nil, "BACKGROUND")
    quoteBg:SetPoint("TOPLEFT", quoteEditBox, "TOPLEFT", -5, 5)
    quoteBg:SetPoint("BOTTOMRIGHT", quoteEditBox, "BOTTOMRIGHT", 5, -5)
    quoteBg:SetColorTexture(0, 0, 0, 0.3)
    
    local authorEditBox = CreateFrame("EditBox", nil, dialog)
    authorEditBox:SetPoint("TOPLEFT", quoteEditBox, "BOTTOMLEFT", 0, -30)
    authorEditBox:SetPoint("RIGHT", dialog, "RIGHT", -20, 0)
    authorEditBox:SetHeight(20)
    authorEditBox:SetFontObject("GameFontHighlight")
    authorEditBox:SetAutoFocus(false)
    authorEditBox:SetMaxLetters(50)
    
    local authorBg = dialog:CreateTexture(nil, "BACKGROUND")
    authorBg:SetPoint("TOPLEFT", authorEditBox, "TOPLEFT", -5, 5)
    authorBg:SetPoint("BOTTOMRIGHT", authorEditBox, "BOTTOMRIGHT", 5, -5)
    authorBg:SetColorTexture(0, 0, 0, 0.3)
    
    -- Add labels
    local quoteLabel = dialog:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    quoteLabel:SetPoint("BOTTOMLEFT", quoteEditBox, "TOPLEFT", 0, 5)
    quoteLabel:SetText("Quote:")
    
    local authorLabel = dialog:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    authorLabel:SetPoint("BOTTOMLEFT", authorEditBox, "TOPLEFT", 0, 5)
    authorLabel:SetText("Author:")
    
    -- Create Save button
    local saveBtn = CreateFrame("Button", nil, dialog, "UIPanelButtonTemplate")
    saveBtn:SetSize(100, 25)
    saveBtn:SetPoint("BOTTOMRIGHT", dialog, "BOTTOM", -5, 20)
    saveBtn:SetText("Save")
    saveBtn:SetScript("OnClick", function()
        local quoteText = quoteEditBox:GetText()
        local authorText = authorEditBox:GetText()
        
        if quoteText and quoteText ~= "" then
            self:AddQuote(quoteText, authorText ~= "" and authorText or nil)
            PlaySound(624) -- SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON
            dialog:Hide()
            quoteEditBox:SetText("")
            authorEditBox:SetText("")
        end
    end)
    
    -- Create Cancel button
    local cancelBtn = CreateFrame("Button", nil, dialog, "UIPanelButtonTemplate")
    cancelBtn:SetSize(100, 25)
    cancelBtn:SetPoint("BOTTOMLEFT", dialog, "BOTTOM", 5, 20)
    cancelBtn:SetText("Cancel")
    cancelBtn:SetScript("OnClick", function()
        dialog:Hide()
        quoteEditBox:SetText("")
        authorEditBox:SetText("")
    end)
    
    -- Setup edit box behavior
    local function OnEscapePressed(self)
        self:ClearFocus()
    end
    local function OnEnterPressed(self)
        saveBtn:Click()
    end
    quoteEditBox:SetScript("OnEscapePressed", OnEscapePressed)
    quoteEditBox:SetScript("OnEnterPressed", OnEnterPressed)
    authorEditBox:SetScript("OnEscapePressed", OnEscapePressed)
    authorEditBox:SetScript("OnEnterPressed", OnEnterPressed)
    
    -- Store the dialog frame reference
    self.addQuoteDialog = dialog
    
    -- Make dialog closeable with Escape key
    table.insert(UISpecialFrames, dialog:GetName())
end

-- UI Creation and Management
function LobsterQuotes:CreateMainFrame()
    local frame = CreateFrame("Frame", "LobsterQuotesFrame", UIParent, "PortraitFrameTexturedBaseTemplate")
    frame:SetPoint("CENTER")
    frame:SetSize(550, 500)
    frame.Bg:SetAlpha(1)
    
    frame.TitleContainer.TitleText:SetText("LobsterQuotes Snek Edition") --.. ADDON_VERSION)
    frame.PortraitContainer.portrait:SetTexture(PORTRAIT_TEXTURE_ID)
    
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    
    frame.closeBtn = CreateFrame("Button", nil, frame, "UIPanelCloseButtonDefaultAnchors")
    
    -- Make frame closeable with Escape key
    table.insert(UISpecialFrames, frame:GetName())
    
    self.mainFrame = frame
    return frame
end

function LobsterQuotes:CreateScrollBox()
    local scrollBox = CreateFrame("Frame", "LobsterQuotesScrollBox", self.mainFrame, "WowScrollBoxList")
    scrollBox:SetPoint("TOPLEFT", self.mainFrame, "TOPLEFT", 10, -60)
    scrollBox:SetPoint("BOTTOMRIGHT", self.mainFrame, "BOTTOMRIGHT", -24, 20)
    scrollBox.bg = scrollBox:CreateTexture(nil,"BACKGROUND")
    scrollBox.bg:SetAllPoints()
    scrollBox.bg:SetColorTexture(0,0,0,0.1)

    local scrollBar = CreateFrame("EventFrame", nil, self.mainFrame, "MinimalScrollBar")
    scrollBar:SetPoint("TOPLEFT", scrollBox, "TOPRIGHT", 7,0)
    scrollBar:SetPoint("BOTTOMLEFT", scrollBox, "BOTTOMRIGHT", 2,0)
    --scrollBar:SetHideIfUnscrollable(true)
    local view = CreateScrollBoxListLinearView()

    view:SetElementExtentCalculator(function(dataIndex, elementData)
        if elementData.expanded then
            return ROW_HEIGHT_EXPANDED
        end
        return ROW_HEIGHT_COLLAPSED
    end)

    view:SetElementInitializer("Frame", function(frame, elementData)
        if not frame.bg then
            frame.bg = frame:CreateTexture(nil, "BACKGROUND")
            frame.bg:SetAllPoints()
        end
        if elementData.index % 2 == 0 then
            frame.bg:SetColorTexture(0,0,0,0.10)
        else   
            frame.bg:SetColorTexture(1,1,1,0.05)
        end

        if not frame.text then
            frame.text = frame:CreateFontString(nil,"ARTWORK", "GameFontHighlight")
            frame.text:SetPoint("TOPLEFT", frame, "TOPLEFT", 10,-8)
            frame.text:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -10,8)
            frame.text:SetJustifyH("LEFT")
            frame.text:SetJustifyV("TOP")
            frame.text:SetWordWrap(true)
        end

        if elementData.expanded then
            frame.text:SetMaxLines(0)
        else
            frame.text:SetMaxLines(1)
        end
        frame.text:SetText(string.format("#%d %s - %s", elementData.index, elementData.content, elementData.author))

        -- Expand on leftclick and Send/Edit/Delete menu on rightclick
        frame:EnableMouse(true)
        frame:SetScript("OnMouseDown", function(self, button)
            if button == "LeftButton" then
                elementData.expanded = not elementData.expanded
                scrollBox:Rebuild(true)
            elseif button == "RightButton" then
                MenuUtil.CreateContextMenu(self, function(ownerRegion, rootDescription)
                    rootDescription:CreateTitle(string.format("Quote #%d", elementData.index))
                    rootDescription:CreateButton("Send", function()
                        LobsterQuotes:SendQuote(elementData.index)
                    end) 
                    rootDescription:CreateButton("Edit", function()
                        LobsterQuotes:ShowEditQuoteDialog(elementData.index, elementData)
                    end) 
                    rootDescription:CreateDivider()
                    rootDescription:CreateButton("Delete", function()
                        StaticPopup_Show("LOBSTERQUOTES_CONFIRM_DELETE", nil,nil,{index = elementData.index})
                    end)
                end)
            end  
        end)

        if not frame.highlight then
            frame.highlight = frame:CreateTexture(nil, "HIGHLIGHT")
            frame.highlight:SetAllPoints()
            frame.highlight:SetColorTexture(0,1,0,0.05)
        end

    end)

    ScrollUtil.InitScrollBoxListWithScrollBar(scrollBox, scrollBar, view)
    self.scrollBox = scrollBox
    
end

function LobsterQuotes:BuildDataProvider(filterText)
    local elements = {}
    local search = filterText and filterText:lower()
    for i, quote in ipairs(LobsterQuotesDB.quotes) do
        if not search
            or quote.content:lower():find(search, 1, true)
            or quote.author:lower():find(search,1, true)
        then
            table.insert(elements, {
                index = i,
                content = quote.content,
                author = quote.author,
                expanded = false,
            })
        end
    end
        return CreateDataProvider(elements)
end

function LobsterQuotes:RefreshQuoteDisplay()
    if not self.scrollBox then return end
    local search = self.searchBox and self.searchBox:GetText()
    local filterText = (search and search ~= "") and search or nil
    self.scrollBox:SetDataProvider(
        self:BuildDataProvider(filterText),
        ScrollBoxConstants.RetainScrollPosition
    )

end


function LobsterQuotes:CreateSettingsDropdown()
    local function GeneratorFunction(owner, rootDescription)
        
        -- Helper
        local function CreateToggleButton(label, settingKey, tooltipText)
            local btn = rootDescription:CreateButton(label, function()
                LobsterQuotesDB.settings[settingKey] = not LobsterQuotesDB.settings[settingKey]
                return MenuResponse.Refresh
            end)
            btn:AddInitializer(function(button, description, menu)
                local rightText = button:AttachFontString()
                rightText:SetPoint("RIGHT")
                rightText:SetJustifyH("RIGHT")
                if LobsterQuotesDB.settings[settingKey] then
                    rightText:SetText("Enabled")
                    rightText:SetTextColor(0,1,0,1)
                else
                    rightText:SetText("Disabled")
                    rightText:SetTextColor(1,0,0,1)
                end
                local width = 200 --+ rightText:GetUnboundedStringWidth()
                return width, 20
            end)
            if tooltipText then
                btn:SetTooltip(function(tooltip, elementDescription)
                    GameTooltip_AddHighlightLine(tooltip,tooltipText)
                end)
            end
        end

        CreateToggleButton("Auto Send", "autoSendOnWipe")
        CreateToggleButton("Only Send In Raid", "requireRaid")
        rootDescription:CreateDivider()
        CreateToggleButton("Require A Guild Group", "guildGroupRequired")
        CreateToggleButton("Repeat Protection", "noRepeat")
        rootDescription:CreateDivider()
        rootDescription:CreateButton("Add New Quote", function() self:ShowAddQuoteDialog() end)
        rootDescription:CreateButton("Import", function() self:ShowImportDialog() end)
        rootDescription:CreateDivider()
        CreateToggleButton("DEBUG", "debug", "Will bypass Only Send In Raid if enabled to allow testing solo.")

        

    end    
    
    local dropdown = CreateFrame("DropdownButton", nil, self.mainFrame, "WowStyle1DropdownTemplate")
    dropdown:SetDefaultText("Settings")
    dropdown:SetPoint("TOP",-150,-30)
    dropdown:SetupMenu(GeneratorFunction)

    self.SettingsDropdown = dropdown
end

function LobsterQuotes:CreateChannelDropdown()
    local channels = {"RAID","GUILD","PARTY"}
    local dropdown = CreateFrame("DropdownButton",nil,self.mainFrame, "WowStyle1DropdownTemplate")
    dropdown:SetPoint("LEFT",self.SettingsDropdown,"RIGHT",15,0)
    dropdown:SetDefaultText("Channel")
    dropdown:SetupMenu(function(owner, rootDescription)
        rootDescription:CreateTitle("Send Channel")
        for _, ch in ipairs(channels) do
            rootDescription:CreateRadio(ch, 
            function() return LobsterQuotesDB.settings.defaultChannel == ch end,
            function()
                LobsterQuotesDB.settings.defaultChannel = ch
                self:Debug("Default channel changed to %s", ch) 
            end
        )
        end
    end)
    self.channelDropdown = dropdown
end

function LobsterQuotes:ShowEditQuoteDialog(index, quote)
    if not quote then return end
    
    local dialog = CreateFrame("Frame", "LobsterQuotesEditDialog" .. index, UIParent, "DefaultPanelTemplate")
    dialog:SetSize(400, 240)
    dialog:SetPoint("CENTER")
    dialog:SetFrameStrata("DIALOG")
    
    -- Make it movable
    dialog:EnableMouse(true)
    dialog:SetMovable(true)
    dialog:RegisterForDrag("LeftButton")
    dialog:SetScript("OnDragStart", dialog.StartMoving)
    dialog:SetScript("OnDragStop", dialog.StopMovingOrSizing)
    
    -- Set the title
    dialog.TitleContainer.TitleText:SetText("Edit Quote #" .. index)
    
    -- Create quote input box
    local quoteEditBox = CreateFrame("EditBox", nil, dialog)
    quoteEditBox:SetPoint("TOPLEFT", dialog.Bg, "TOPLEFT", 20, -40)
    quoteEditBox:SetPoint("BOTTOMRIGHT", dialog, "RIGHT", -20, 5)
    quoteEditBox:SetHeight(20)
    quoteEditBox:SetFontObject("GameFontHighlight")
    quoteEditBox:SetAutoFocus(false)
    quoteEditBox:SetMaxLetters(240)
    quoteEditBox:SetText(quote.content)
    quoteEditBox:SetMultiLine(true)
    
    -- Add quote background texture
    local quoteBg = dialog:CreateTexture(nil, "BACKGROUND")
    quoteBg:SetPoint("TOPLEFT", quoteEditBox, "TOPLEFT", -5, 5)
    quoteBg:SetPoint("BOTTOMRIGHT", quoteEditBox, "BOTTOMRIGHT", 5, -5)
    quoteBg:SetColorTexture(0, 0, 0, 0.3)
    
    -- Create author input box
    local authorEditBox = CreateFrame("EditBox", nil, dialog)
    authorEditBox:SetPoint("TOPLEFT", quoteEditBox, "BOTTOMLEFT", 0, -30)
    authorEditBox:SetPoint("RIGHT", dialog, "RIGHT", -20, 5)
    authorEditBox:SetHeight(20)
    authorEditBox:SetFontObject("GameFontHighlight")
    authorEditBox:SetAutoFocus(false)
    authorEditBox:SetMaxLetters(50)
    authorEditBox:SetText(quote.author)
    
    -- Add author background texture
    local authorBg = dialog:CreateTexture(nil, "BACKGROUND")
    authorBg:SetPoint("TOPLEFT", authorEditBox, "TOPLEFT", -5, 5)
    authorBg:SetPoint("BOTTOMRIGHT", authorEditBox, "BOTTOMRIGHT", 5, -5)
    authorBg:SetColorTexture(0, 0, 0, 0.3)
    
    -- Add labels
    local quoteLabel = dialog:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    quoteLabel:SetPoint("BOTTOMLEFT", quoteEditBox, "TOPLEFT", 0, 6)
    quoteLabel:SetText("Quote:")
    
    local authorLabel = dialog:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    authorLabel:SetPoint("BOTTOMLEFT", authorEditBox, "TOPLEFT", 0, 6)
    authorLabel:SetText("Author:")
    
    -- Create Save button
    local saveBtn = CreateFrame("Button", nil, dialog, "UIPanelButtonTemplate")
    saveBtn:SetSize(100, 25)
    saveBtn:SetPoint("BOTTOMRIGHT", dialog, "BOTTOM", -5, 20)
    saveBtn:SetText("Save")
    saveBtn:SetScript("OnClick", function()
        local quoteText = quoteEditBox:GetText()
        local authorText = authorEditBox:GetText()
        
        if quoteText and quoteText ~= "" then
            self:EditQuote(index, quoteText, authorText ~= "" and authorText or "Unknown")
            PlaySound(624)
            dialog:Hide()
        end
    end)
    
    -- Create Cancel button
    local cancelBtn = CreateFrame("Button", nil, dialog, "UIPanelButtonTemplate")
    cancelBtn:SetSize(100, 25)
    cancelBtn:SetPoint("BOTTOMLEFT", dialog, "BOTTOM", 5, 20)
    cancelBtn:SetText("Cancel")
    cancelBtn:SetScript("OnClick", function()
        dialog:Hide()
    end)
    
    -- Make dialog closeable with Escape key
    table.insert(UISpecialFrames, dialog:GetName())
end

StaticPopupDialogs["LOBSTERQUOTES_CONFIRM_DELETE"] = {
    text = "Are you sure you want to delete this quote?",
    button1 = "Yes",
    button2 = "No",
    OnAccept = function(self, data)
        LobsterQuotes:RemoveQuote(data.index)
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

local function parseQuote(quoteString)
    -- Simple quote parser that assumes format: "quote text - author"
    local content, author = quoteString:match("(.+)%s+-%s+(.+)")
    if not content then
        -- If no author format found, use entire string as content
        return {
            content = quoteString,
            author = "Unknown"
        }
    end
    return {
        content = content,
        author = author
    }
end

function LobsterQuotes:ImportQuotesFromString(quotesString)
    local imported = 0
    local failed = 0
    
    -- Split string by newlines
    for line in quotesString:gmatch("[^\r\n]+") do
        if line:trim() ~= "" then
            local quote = parseQuote(line)
            if quote.content then
                table.insert(LobsterQuotesDB.quotes, quote)
                imported = imported + 1
            else
                failed = failed + 1
            end
        end
    end
    
    self:RefreshQuoteDisplay()
    return imported, failed
end

function LobsterQuotes:ShowImportDialog()
    if self.importDialog then
        self.importDialog:Show()
        return
    end
    
    local dialog = CreateFrame("Frame", "LobsterQuotesImportDialog", UIParent, "BasicFrameTemplate")
    dialog:SetSize(400, 300)
    dialog:SetPoint("CENTER")
    dialog:SetFrameStrata("DIALOG")
    dialog:EnableMouse(true)
    dialog:SetMovable(true)
    dialog:RegisterForDrag("LeftButton")
    dialog:SetScript("OnDragStart", dialog.StartMoving)
    dialog:SetScript("OnDragStop", dialog.StopMovingOrSizing)
    
    dialog.TitleText:SetText("Import Quotes")
    
    -- Create import text area
    local scrollFrame = CreateFrame("ScrollFrame", nil, dialog, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", dialog.Bg, "TOPLEFT", 20, -30)
    scrollFrame:SetPoint("BOTTOMRIGHT", dialog, "BOTTOMRIGHT", -40, 60)
    
    local editBox = CreateFrame("EditBox", nil, scrollFrame)
    editBox:SetMultiLine(true)
    editBox:SetFontObject("GameFontHighlight")
    editBox:SetWidth(scrollFrame:GetWidth())
    editBox:SetAutoFocus(false)
    
    scrollFrame:SetScrollChild(editBox)

    -- Add background texture to import input
    local importBg = dialog:CreateTexture(nil, "BACKGROUND")
    importBg:SetPoint("TOPLEFT", editBox, "TOPLEFT", -5, 5)
    importBg:SetPoint("BOTTOMRIGHT", dialog, "BOTTOMRIGHT", -40, 45)
    importBg:SetColorTexture(0, 0, 0, 0.3)

    -- Import button
    local importBtn = CreateFrame("Button", nil, dialog, "UIPanelButtonTemplate")
    importBtn:SetSize(100, 25)
    importBtn:SetPoint("BOTTOMRIGHT", dialog, "BOTTOM", -5, 10)
    importBtn:SetText("Import")
    importBtn:SetScript("OnClick", function()
        local text = editBox:GetText()
        local imported, failed = self:ImportQuotesFromString(text)
        print(string.format("Imported %d quotes. %d failed to import.", imported, failed))
        dialog:Hide()
        editBox:SetText("")
    end)
    
    -- Cancel button
    local cancelBtn = CreateFrame("Button", nil, dialog, "UIPanelButtonTemplate")
    cancelBtn:SetSize(100, 25)
    cancelBtn:SetPoint("BOTTOMLEFT", dialog, "BOTTOM", 5, 10)
    cancelBtn:SetText("Cancel")
    cancelBtn:SetScript("OnClick", function()
        dialog:Hide()
        editBox:SetText("")
    end)
    
    self.importDialog = dialog
    
    -- Make dialog closeable with Escape key
    table.insert(UISpecialFrames, dialog:GetName())
end

--Quote filter system
function LobsterQuotes:CreateSearchBox()
    local searchContainer = CreateFrame("Frame", "SearchFrame", self.mainFrame)
    searchContainer:SetSize(180, 30)
    searchContainer:SetPoint("TOPRIGHT", self.mainFrame, "TOPRIGHT", -20, -26)

    local searchBox = CreateFrame("EditBox", "SearchBox", searchContainer, "SearchBoxTemplate")
    searchBox:SetSize(170, 20)
    searchBox:SetPoint("CENTER")
    searchBox:SetFontObject("GameFontHighlight")
    searchBox:SetAutoFocus(false)
    searchBox.Instructions:SetText("Search Quotes...")

    searchBox:SetScript("OnTextChanged", function(self, userInput)
        LobsterQuotes:RefreshQuoteDisplay()
        local text = self:GetText()
        if text and text ~= "" then
            self.Instructions:Hide()
        else
            self.Instructions:Show()
        end
    end)

    searchBox:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
        self:SetText("")
    end)
    self.searchBox = searchBox
end


function LobsterQuotes:CreateCommunityButton()
    if not CommunitiesFrame or not CommunitiesFrame.GuildInfoTab then return end
    local button = CreateFrame("Button", "LobsterQuotesCommunityButton", CommunitiesFrame, "UIPanelBorderedButtonTemplate")--"ActionButtonTemplate")
    button.Icon:SetTexture(PORTRAIT_TEXTURE_ID)
    button:SetSize(38,38)
    button:SetPoint("TOPLEFT", CommunitiesFrame.GuildInfoTab, "BOTTOMLEFT", 0, -140)
    button:SetScript("OnClick", function()
        if LobsterQuotes.mainFrame then
            LobsterQuotes.mainFrame:SetShown(not LobsterQuotes.mainFrame:IsShown())
        end
    end)
end

-- Event Handling
function LobsterQuotes:Initialize()
    self.eventFrame = CreateFrame("Frame")
    self.eventFrame:RegisterEvent("PLAYER_LOGIN")
    self.eventFrame:RegisterEvent("ENCOUNTER_END")
    self.eventFrame:SetScript("OnEvent", function(_, event, ...)
        if self[event] then
            self[event](self, ...)
        end
    end)
    self:CreateMainFrame()
    self:CreateScrollBox()
    self:CreateSettingsDropdown()
    self:CreateChannelDropdown()
    self:CreateSearchBox()
    self:CreateCommunityButton()
    --------------------------------------
end

function LobsterQuotes:PLAYER_LOGIN()
    self:RefreshQuoteDisplay()
end

function LobsterQuotes:ENCOUNTER_END(_,_,_,_,success)
    self:Debug("ENCOUNTER_END fired. success=%d autoSend=%s inRaid=%s guildMet=%s",
    success,
    tostring(LobsterQuotesDB.settings.autoSendOnWipe),
    tostring(self:IsInRaid()),
    tostring(self:RequiredGuildGroupMet()))

    if success == 0
        and LobsterQuotesDB.settings.autoSendOnWipe
        and self:IsInRaid()
        and self:RequiredGuildGroupMet()
    then
        self:Debug("All Conditions met, starting quote sequence...")
        local function AttemptSend()
            if InCombatLockdown() then
                self:Debug("Still in CombatLockdown, trying again in 0.5 seconds...")
                C_Timer.After(0.5, AttemptSend)
            else
                self:Debug("No longer CombatLocked, sending now.")
                self:SendRandomQuote()
            end
        end
        C_Timer.After(0.3,AttemptSend)
    else
        self:Debug("Conditions NOT met.")
    end
end



-- Slash Commands
SLASH_LOBSTERQUOTES1 = "/lq"
SlashCmdList.LOBSTERQUOTES = function(msg)
    if LobsterQuotes.mainFrame then
        LobsterQuotes.mainFrame:SetShown(not LobsterQuotes.mainFrame:IsShown())
    end
end

-- Initialize the addon
LobsterQuotes:Initialize()