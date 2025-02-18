
-- Create global table and ensure database exists
LobsterQuotes = LobsterQuotes or {}
LobsterQuotesDB = LobsterQuotesDB or {
    quotes = {},
    settings = {
        autoSendOnWipe = true,
        defaultChannel = "RAID",
        guildGroupRequired = true,
        noRepeat = true,
        debug = false,
        lastQuoteSent = nil
    }
}

-- Local variables because thats apparently better performance?
local CreateFrame = CreateFrame
local SendChatMessage = SendChatMessage
local PlaySound = PlaySound
local IsInRaid = IsInRaid
local table = table
local math = math
local string = string

-- Constants
local ADDON_VERSION = "0.7.4"
local PORTRAIT_TEXTURE_ID = 134048 --Icon of a Lobster

-- Quote Management Functions
function LobsterQuotes:AddQuote(content, author)
    if not content then return end
    
    local quote = {
        content = content,
        author = author or "Unknown",
    }
    
    table.insert(LobsterQuotesDB.quotes, quote)
    self:RefreshQuoteDisplay()
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

function LobsterQuotes:InGuildGroup()
    local isInGuildGroup,_,_,_ = InGuildParty()
    if isInGuildGroup == true then
        return true 
    else return false
    end
end

function LobsterQuotes:RequiredGuildGroupMet()
    if LobsterQuotes:InGuildGroup() and LobsterQuotesDB.settings.guildGroupRequired or LobsterQuotes:InGuildGroup() and not LobsterQuotesDB.settings.guildGroupRequired then
        return true
    else return false end
end

function LobsterQuotes:SendRandomQuote(channel)
    local quote = self:GetRandomQuote()
    if not quote then return end
    local message = string.format("%s - %s", quote.content, quote.author)
    local selectedChannel = channel or LobsterQuotesDB.settings.defaultChannel
    SendChatMessage(message, selectedChannel)
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
        local selectedChannel = channel or LobsterQuotesDB.settings.defaultChannel
        local content = LobsterQuotesDB.quotes[index].content
        local author = LobsterQuotesDB.quotes[index].author
        local message = string.format("%s - %s", content, author)
        SendChatMessage(message, selectedChannel)
    end
end

function LobsterQuotes:ShowAddQuoteDialog()
    if self.addQuoteDialog then
        self.addQuoteDialog:Show()
        return
    end
    
    -- Create the dialog frame
    local dialog = CreateFrame("Frame", "LobsterQuotesAddDialog", UIParent, "DefaultPanelTemplate")
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
    
    --Add background texture to quote input
    local quoteBg = dialog:CreateTexture(nil, "BACKGROUND")
    quoteBg:SetPoint("TOPLEFT", quoteEditBox, "TOPLEFT", -5, 5)
    quoteBg:SetPoint("BOTTOMRIGHT", quoteEditBox, "BOTTOMRIGHT", 5, -5)
    quoteBg:SetColorTexture(0, 0, 0, 0.3)
    
    -- Create author input box
    local authorEditBox = CreateFrame("EditBox", nil, dialog)
    authorEditBox:SetPoint("TOPLEFT", quoteEditBox, "BOTTOMLEFT", 0, -30)
    authorEditBox:SetPoint("RIGHT", dialog, "RIGHT", -20, 0)
    authorEditBox:SetHeight(20)
    authorEditBox:SetFontObject("GameFontHighlight")
    authorEditBox:SetAutoFocus(false)
    authorEditBox:SetMaxLetters(50)
    
    -- Add background texture to author input
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
    -- Create main frame
    local frame = CreateFrame("Frame", "LobsterQuotesFrame", UIParent, "PortraitFrameTexturedBaseTemplate")
    frame:SetPoint("CENTER")
    frame:SetSize(500, 580)
    frame.Bg:SetAlpha(0.8)
    
    -- Set title and portrait
    frame.TitleContainer.TitleText:SetText("LobsterQuotes v" .. ADDON_VERSION)
    frame.PortraitContainer.portrait:SetTexture(PORTRAIT_TEXTURE_ID)
    
    -- Make frame movable
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    
    -- Add close button
    frame.closeBtn = CreateFrame("Button", nil, frame, "UIPanelCloseButtonDefaultAnchors")
    
    -- Make frame closeable with Escape key
    table.insert(UISpecialFrames, frame:GetName())
    
    self.mainFrame = frame
    return frame
end

function LobsterQuotes:CreateScrollFrame()
    local container = CreateFrame("ScrollFrame", "LobsterQuotesMainFrameScrollFrame", self.mainFrame, "UIPanelScrollFrameTemplate")
    container:SetPoint("TOPLEFT", self.mainFrame, "TOPLEFT", 15, -60)
    container:SetPoint("BOTTOMRIGHT", self.mainFrame, "BOTTOMRIGHT", -35, 15)  
    
    local content = CreateFrame("Frame", nil, container)
    content:SetSize(container:GetWidth(), 1)
    container:SetScrollChild(content)
    
    self.scrollFrame = content
    self.scrollContainer = container
end


function LobsterQuotes:CreateSettingsDropdown()
    
    local function GeneratorFunction(owner, rootDescription)

        local autoSendBtn = rootDescription:CreateButton("Toggle Auto Sending", function()
            if LobsterQuotesDB.settings.autoSendOnWipe == true then
                LobsterQuotesDB.settings.autoSendOnWipe = false
                print("|cFFee5555[LobsterQuotes]|r Sending on wipe has been |cFFee5555DISABLED|r.")
            else
                LobsterQuotesDB.settings.autoSendOnWipe = true
                print("|cFFee5555[LobsterQuotes]|r Sending on wipe has been |cFF55ee55ENABLED|r.")
            end
        end)
            autoSendBtn:AddInitializer(function(button,description,menu)
                local rightText = button:AttachFontString()
                rightText:SetPoint("RIGHT")
                rightText:SetText("Enabled")
                rightText:SetJustifyH("RIGHT")
                if LobsterQuotesDB.settings.autoSendOnWipe == true then
                    rightText:SetTextColor(0,1,0,1)
                else
                    rightText:SetTextColor(1,0,0,1)
                    rightText:SetText("Disabled")
                end
                local pad = 20
                local width = pad + rightText:GetUnboundedStringWidth()
                local height = 20
                return width, height
            end)
        local guildBtn = rootDescription:CreateButton("Toggle Guild Requirement", function()
            if LobsterQuotesDB.settings.guildGroupRequired == true then
                LobsterQuotesDB.settings.guildGroupRequired = false
                print("|cFFee5555[LobsterQuotes]|r Guildgroup requirement has been |cFFee5555DISABLED|r.")
            else
                LobsterQuotesDB.settings.guildGroupRequired = true
                print("|cFFee5555[LobsterQuotes]|r Guildgroup requirement has been |cFF55ee55ENABLED|r.")
            end
        end)
            guildBtn:AddInitializer(function(button,description,menu)
                local rightText2 = button:AttachFontString()
                rightText2:SetPoint("RIGHT")
                rightText2:SetText("Enabled")
                rightText2:SetJustifyH("RIGHT")
                if LobsterQuotesDB.settings.guildGroupRequired == true then
                    rightText2:SetTextColor(0,1,0,1)
                else
                    rightText2:SetTextColor(1,0,0,1)
                    rightText2:SetText("Disabled")
                end
                local pad2 = 150
                local width2 = pad2 + rightText2:GetUnboundedStringWidth()
                local height2 = 20
                return width2, height2
            end)
        local repeatBtn = rootDescription:CreateButton("Toggle Repeat Protection", function()
            if LobsterQuotesDB.settings.noRepeat == true then
                LobsterQuotesDB.settings.noRepeat = false
                print("|cFFee5555[LobsterQuotes]|r Repetition protection has been |cFFee5555DISABLED|r.")
            else
                LobsterQuotesDB.settings.noRepeat = true
                print("|cFFee5555[LobsterQuotes]|r Repetition protection has been |cFF55ee55ENABLED|r.")
            end
        end)
            repeatBtn:AddInitializer(function(button,description,menu)
                local rightText3 = button:AttachFontString()
                rightText3:SetPoint("RIGHT")
                rightText3:SetText("Enabled")
                rightText3:SetJustifyH("RIGHT")
                if LobsterQuotesDB.settings.noRepeat == true then
                    rightText3:SetTextColor(0,1,0,1)
                else
                    rightText3:SetTextColor(1,0,0,1)
                    rightText3:SetText("Disabled")
                end
                local pad3 = 150
                local width3 = pad3 + rightText3:GetUnboundedStringWidth()
                local height3 = 20
                return width3, height3
            end)
        rootDescription:QueueDivider()
        local channelmenu = rootDescription:CreateButton("Channel selection")
        local raidBtn = channelmenu:CreateButton("RAID", function ()
                LobsterQuotesDB.settings.defaultChannel = "RAID"
                print("Channel has been set to RAID.") end)
        channelmenu:CreateButton("GUILD", function ()
                LobsterQuotesDB.settings.defaultChannel = "GUILD"
                print("Channel has been set to GUILD.") end)
        channelmenu:CreateButton("EMOTE", function ()
                LobsterQuotesDB.settings.defaultChannel = "EMOTE"
                print("Channel has been set to EMOTE.") end)

        rootDescription:QueueDivider()
        rootDescription:CreateButton("Add New Quote", function()
            self:ShowAddQuoteDialog() end)
        rootDescription:CreateButton("Import", function()
            self:ShowImportDialog() end)
       end
    
    local dropdown = CreateFrame("DropdownButton", nil, self.mainFrame, "WowStyle1DropdownTemplate")
    dropdown:SetDefaultText("Configure")
    dropdown:SetPoint("TOP",-120,-30)
    dropdown:SetupMenu(GeneratorFunction)

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

-- Import Dialog
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
    editBox:SetFontObject("ChatFontNormal")
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
    importBtn:SetPoint("BOTTOMRIGHT", dialog, "BOTTOM", -5, 20)
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
    cancelBtn:SetPoint("BOTTOMLEFT", dialog, "BOTTOM", 5, 20)
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
    searchContainer:SetSize(250, 30)
    searchContainer:SetPoint("TOPRIGHT", self.mainFrame, "TOPRIGHT", -40, -28)

    local searchBox = CreateFrame("EditBox", "SearchBox", searchContainer, "SearchBoxTemplate")
    searchBox:SetSize(240, 20)
    searchBox:SetPoint("CENTER")
    searchBox:SetFontObject("GameFontHighlight")
    searchBox:SetAutoFocus(false)
    searchBox.Instructions:SetText("Search Quotes...")

    searchBox:SetScript("OnTextChanged", function(self, userInput)
        local text = self:GetText()
        if text and text ~= "" then
            self.Instructions:Hide()
            LobsterQuotes:FilterQuotes(text)
        else
            LobsterQuotes:RefreshQuoteDisplay()
            self.Instructions:Show()
        end
    end)

    searchBox:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
        self:SetText("")
        LobsterQuotes:RefreshQuoteDisplay()
    end)
    self.searchBox = searchBox
end

function LobsterQuotes:FilterQuotes(searchText)
    if not self.scrollFrame then return end
    
    -- Clear existing quotes display and display the filtered ones
    for _, child in pairs({self.scrollFrame:GetChildren()}) do
        child:Hide()
        child:SetParent(nil)
    end
    
    searchText = searchText:lower()
    local buttonSpace = 70
    local rightPadding = 10
    local availableWidth = self.scrollFrame:GetWidth() - buttonSpace - rightPadding
    
    local totalHeight = 0
    local minQuoteHeight = 30
    local displayIndex = 1 
    
    for i, quote in ipairs(LobsterQuotesDB.quotes) do
        local content = quote.content:lower()
        local author = quote.author:lower()
        
        if content:find(searchText) or author:find(searchText) then
            local quoteFrame = CreateFrame("Frame", nil, self.scrollFrame)
            quoteFrame:SetWidth(self.scrollFrame:GetWidth())
            
            local text = quoteFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
            text:SetPoint("TOPLEFT", quoteFrame, "TOPLEFT", 10, -5)
            text:SetWidth(availableWidth)
            text:SetJustifyH("LEFT")
            text:SetText(string.format("#%d %s - %s", i, quote.content, quote.author))
            
            local textHeight = text:GetStringHeight() + 10
            local frameHeight = math.max(minQuoteHeight, textHeight)
            quoteFrame:SetHeight(frameHeight)
            quoteFrame:SetPoint("TOPLEFT", self.scrollFrame, "TOPLEFT", 0, -totalHeight)
            
            local sendBtn = CreateFrame("Button", nil, quoteFrame, "UIPanelButtonTemplate")
            sendBtn:SetSize(20, 20)
            sendBtn:SetPoint("RIGHT", quoteFrame, "RIGHT", -48, -(frameHeight/2 - 15))
            sendBtn:SetText("S")
            sendBtn:SetScript("OnClick", function()
                self:SendQuote(i)
            end)
            sendBtn:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetText("Send")
                GameTooltip:Show()
            end)
            sendBtn:SetScript("OnLeave", function()
                GameTooltip:Hide()
            end)
            
            local editBtn = CreateFrame("Button", nil, quoteFrame, "UIPanelButtonTemplate")
            editBtn:SetSize(20, 20)
            editBtn:SetPoint("RIGHT", quoteFrame, "RIGHT", -25, -(frameHeight/2 - 15))
            editBtn:SetText("E")
            editBtn:SetScript("OnClick", function()
                self:ShowEditQuoteDialog(i, quote)
            end)
            editBtn:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetText("Edit")
                GameTooltip:Show()
            end)
            editBtn:SetScript("OnLeave", function()
                GameTooltip:Hide()
            end)
            
            local deleteBtn = CreateFrame("Button", nil, quoteFrame, "UIPanelButtonTemplate")
            deleteBtn:SetSize(20, 20)
            deleteBtn:SetPoint("RIGHT", quoteFrame, "RIGHT", -2, -(frameHeight/2 - 15))
            deleteBtn:SetText("D")
            deleteBtn:SetScript("OnClick", function()
                StaticPopup_Show("LOBSTERQUOTES_CONFIRM_DELETE", nil, nil, {index = i})
            end)
            deleteBtn:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetText("Delete")
                GameTooltip:Show()
            end)
            deleteBtn:SetScript("OnLeave", function()
                GameTooltip:Hide()
            end)
            
            totalHeight = totalHeight + frameHeight
            displayIndex = displayIndex + 1
        end
    end
    
    self.scrollFrame:SetHeight(totalHeight)
end



function LobsterQuotes:RefreshQuoteDisplay()
    if not self.scrollFrame then return end
    
    -- Clear existing quotes
    for _, child in pairs({self.scrollFrame:GetChildren()}) do
        child:Hide()
        child:SetParent(nil)
    end
    
    local buttonSpace = 70
    local rightPadding = 10 
    local availableWidth = self.scrollFrame:GetWidth() - buttonSpace - rightPadding
    
    local totalHeight = 0
    local minQuoteHeight = 30
    
    for i, quote in ipairs(LobsterQuotesDB.quotes) do
        local quoteFrame = CreateFrame("Frame", nil, self.scrollFrame)
        quoteFrame:SetWidth(self.scrollFrame:GetWidth())
        
        -- Quote text
        local text = quoteFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        text:SetPoint("TOPLEFT", quoteFrame, "TOPLEFT", 10, -5)
        text:SetWidth(availableWidth)
        text:SetJustifyH("LEFT")
        text:SetText(string.format("#%d %s - %s", i, quote.content, quote.author))
        
        -- Calculate actual text height and set frame height
        local textHeight = text:GetStringHeight() + 10  -- Add padding
        local frameHeight = math.max(minQuoteHeight, textHeight)
        quoteFrame:SetHeight(frameHeight)
        
        quoteFrame:SetPoint("TOPLEFT", self.scrollFrame, "TOPLEFT", 0, -totalHeight)
        
        -- Send button
        local sendBtn = CreateFrame("Button", nil, quoteFrame, "UIPanelButtonTemplate")
        sendBtn:SetSize(20, 20)
        sendBtn:SetPoint("RIGHT", quoteFrame, "RIGHT", -48, -(frameHeight/2 - 15))
        sendBtn:SetText("S")
        sendBtn:SetScript("OnClick", function()
            self:SendQuote(i)
        end)
        sendBtn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText("Send")
            GameTooltip:Show()
        end)
        sendBtn:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
        
        -- Edit button
        local editBtn = CreateFrame("Button", nil, quoteFrame, "UIPanelButtonTemplate")
        editBtn:SetSize(20, 20)
        editBtn:SetPoint("RIGHT", quoteFrame, "RIGHT", -25, -(frameHeight/2 - 15))
        editBtn:SetText("E")
        editBtn:SetScript("OnClick", function()
            self:ShowEditQuoteDialog(i, quote)
        end)
        editBtn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText("Edit")
            GameTooltip:Show()
        end)
        editBtn:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)

        -- Delete button
        local deleteBtn = CreateFrame("Button", nil, quoteFrame, "UIPanelButtonTemplate")
        deleteBtn:SetSize(20, 20)
        deleteBtn:SetPoint("RIGHT", quoteFrame, "RIGHT", -2, -(frameHeight/2 - 15))
        deleteBtn:SetText("D")
        deleteBtn:SetScript("OnClick", function()
            StaticPopup_Show("LOBSTERQUOTES_CONFIRM_DELETE", nil, nil, {index = i})
        end)
        deleteBtn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText("Delete")
            GameTooltip:Show()
        end)
        deleteBtn:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)

        totalHeight = totalHeight + frameHeight
    end
    
    -- Set the scroll frame's content height
    self.scrollFrame:SetHeight(totalHeight)
end

function LobsterQuotes:CreateCommunityButton()
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
    self:CreateScrollFrame()
    self:CreateSettingsDropdown()
    self:CreateSearchBox()
    self:CreateCommunityButton()
    --------------------------------------
end

function LobsterQuotes:PLAYER_LOGIN()
    self:RefreshQuoteDisplay()
end

function LobsterQuotes:ENCOUNTER_END(encounterID, encounterName, difficultyID, groupSize, success)
    if success == 0 and LobsterQuotesDB.settings.autoSendOnWipe and IsInRaid() and LobsterQuotes:RequiredGuildGroupMet() then
        self:SendRandomQuote()
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