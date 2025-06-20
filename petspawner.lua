--[[
    ================================================================================================================
    UNIVERSAL SPAWNER - CUSTOM UI
    ----------------------------------------------------------------------------------------------------------------
    This script creates a custom, professional user interface for the "Visual Pet | Seed | Egg Spawner" library.
    It is designed to be stable, user-friendly, and robust, handling potential errors from the external library
    without crashing.

    Features:
    - Loads the external spawner library safely.
    - Provides a clean, tab-based interface for Pets, Seeds, Eggs, and Actions.
    - Includes a searchable list for each category.
    - Implements all functionalities from the developer's API, including spawning, placing, and spinning.
    - Features a modern, professionally designed UI with interactive elements.
    ================================================================================================================
]]

-- // SERVICES //
-- Get the service for handling user input (mouse clicks, keyboard presses, etc.).
local UserInputService = game:GetService("UserInputService")


-- // LIBRARY LOADING //
-- This section attempts to load the main developer library from GitHub.

local Spawner -- This variable will hold the loaded library object.
-- pcall (protected call) runs the function in a "safe mode". If it errors, the script won't crash.
local success, result = pcall(function()
    -- This line fetches the script from the URL and executes it. The result is assigned to the Spawner variable.
    Spawner = loadstring(game:HttpGet("https://raw.githubusercontent.com/ataturk123/GardenSpawner/refs/heads/main/Spawner.lua", true))()
end)


-- // UI THEME & STYLING //
-- This table centralizes all colors and fonts. Changing a value here will update the entire UI.
local THEME = {
    Background = Color3.fromRGB(24, 25, 28),      -- Darkest background
    Primary = Color3.fromRGB(33, 35, 40),        -- Main panel background
    Secondary = Color3.fromRGB(45, 48, 54),      -- Input boxes, list background
    Accent = Color3.fromRGB(88, 101, 242),       -- Main interactive color
    AccentDark = Color3.fromRGB(71, 82, 196),    -- Darker accent for clicks/secondary actions
    Text = Color3.fromRGB(220, 221, 222),        -- Primary text
    TextSecondary = Color3.fromRGB(148, 152, 158),-- Dimmer text for labels/placeholders
    Error = Color3.fromRGB(231, 76, 60),         -- Color for error messages
    Font = Enum.Font.Gotham,
    FontBold = Enum.Font.GothamBold,
}


-- // INITIALIZATION //
-- This section creates the main UI frames and handles critical loading errors.

-- Clean up any old versions of the UI to prevent duplicates.
if game.CoreGui:FindFirstChild("ProSpawnerUI") then game.CoreGui.ProSpawnerUI:Destroy() end

-- Create the main container for the UI that gets drawn on the screen.
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ProSpawnerUI"
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = game.CoreGui

-- Create the main window frame for the spawner.
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 560, 0, 380)
mainFrame.Position = UDim2.new(0.5, -280, 0.5, -190)
mainFrame.BackgroundColor3 = THEME.Primary
mainFrame.BorderSizePixel = 0
mainFrame.ClipsDescendants = true
mainFrame.Visible = false -- Start hidden.
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 12)
local stroke = Instance.new("UIStroke", mainFrame)
stroke.Color = Color3.fromRGB(15,15,15)
stroke.Thickness = 2
mainFrame.Parent = screenGui

-- CRITICAL ERROR HANDLER: If the 'pcall' failed or the Spawner is nil, show an error and stop.
if not success or not Spawner then
    mainFrame.Visible = true
    mainFrame.BackgroundColor3 = THEME.Secondary
    local errorLabel = Instance.new("TextLabel")
    errorLabel.Size = UDim2.new(1, -20, 1, -20)
    errorLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
    errorLabel.AnchorPoint = Vector2.new(0.5, 0.5)
    errorLabel.BackgroundTransparency = 1
    errorLabel.Font = THEME.FontBold
    errorLabel.TextColor3 = THEME.Error
    errorLabel.TextWrapped = true
    errorLabel.Text = "CRITICAL ERROR\nThe main Spawner library failed to load. This is an issue with the library script itself.\n\nDetails: " .. tostring(result)
    errorLabel.Parent = mainFrame
    return -- Stop the script here.
end


-- // DATA FETCHING & VALIDATION //
-- This section gets the item lists from the loaded Spawner library.

-- This helper function safely calls a function from the Spawner library.
-- It ensures that the returned data is a table, preventing crashes if the library is broken.
local function GetSafeData(func)
    local data = {}
    local callSuccess, result = pcall(func)
    if callSuccess and type(result) == "table" then
        data = result
        table.sort(data)
    else
        -- This warning will appear in the developer console if the library sends bad data.
        warn("Spawner API returned invalid data. Expected a table, got: " .. type(result))
    end
    return data
end

-- [CONNECTION POINT] Get the list of pets, seeds, and eggs from the developer's library.
local pet_names = GetSafeData(function() return Spawner:GetPets() end)
local seed_names = GetSafeData(function() return Spawner:GetSeeds() end)
local egg_names = GetSafeData(function() return Spawner:GetEggs() end)
-- If getting eggs failed, use a hardcoded default list as a fallback.
if #egg_names == 0 then egg_names = { "Night Egg", "Fire Egg", "Ice Egg", "Golden Egg", "Cosmic Egg" } end


-- // UI STRUCTURE & WIDGETS //
-- This section contains functions that create and manage the UI components.

-- Create the header bar at the top of the window.
local header = Instance.new("Frame")
header.Name = "Header"
header.Size = UDim2.new(1, 0, 0, 36)
header.BackgroundColor3 = THEME.Background
header.Parent = mainFrame

-- Create the title text in the header.
local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(1, -10, 1, 0)
title.Position = UDim2.new(0, 10, 0, 0)
title.BackgroundTransparency = 1
title.Font = THEME.FontBold
title.Text = "Universal Spawner"
title.TextColor3 = THEME.Text
title.TextSize = 18
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = header

-- This function makes a UI element draggable using its handle.
function createDraggable(frame, handle)
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            local dragStart = input.Position
            local startPos = frame.Position
            local moveConnection, endConnection
            moveConnection = UserInputService.InputChanged:Connect(function(inputChanged)
                if inputChanged.UserInputType == Enum.UserInputType.MouseMovement or inputChanged.UserInputType == Enum.UserInputType.Touch then
                    local delta = inputChanged.Position - dragStart
                    frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
                end
            end)
            endConnection = UserInputService.InputEnded:Connect(function(inputEnded)
                if inputEnded.UserInputType == Enum.UserInputType.MouseButton1 or inputEnded.UserInputType == Enum.UserInputType.Touch then
                    moveConnection:Disconnect()
                    endConnection:Disconnect()
                end
            end)
        end
    end)
end
createDraggable(mainFrame, header)

-- Create the main container that holds the tab pages.
local contentContainer = Instance.new("Frame")
contentContainer.Name = "ContentContainer"
contentContainer.Size = UDim2.new(1, 0, 1, -80)
contentContainer.Position = UDim2.new(0, 0, 0, 80)
contentContainer.BackgroundTransparency = 1
contentContainer.Parent = mainFrame

-- Create the container that holds the tab buttons.
local tabContainer = Instance.new("Frame")
tabContainer.Name = "TabContainer"
tabContainer.Size = UDim2.new(1, 0, 0, 44)
tabContainer.Position = UDim2.new(0, 0, 0, 36)
tabContainer.BackgroundColor3 = THEME.Primary
tabContainer.Parent = mainFrame
local tabLayout = Instance.new("UIListLayout", tabContainer)
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.VerticalAlignment = Enum.VerticalAlignment.Center
tabLayout.Padding = UDim.new(0, 5)
Instance.new("UIPadding", tabContainer).PaddingLeft = UDim.new(0, 8)

local pages = {} -- A table to store the page frames.
local activeTabButton = nil -- A variable to track the currently active tab.

-- This function handles the logic for switching between tabs.
function SwitchTab(tabButton)
    if activeTabButton then
        activeTabButton.BackgroundColor3 = THEME.Primary
        activeTabButton.TextColor3 = THEME.TextSecondary
        pages[activeTabButton.Name].Visible = false
    end
    tabButton.BackgroundColor3 = THEME.Background
    tabButton.TextColor3 = THEME.Text
    pages[tabButton.Name].Visible = true
    activeTabButton = tabButton
end

-- This function creates a new tab button and its corresponding page.
function CreateTab(name, icon, order)
    local button = Instance.new("TextButton")
    button.Name = name
    button.Size = UDim2.new(0, 100, 1, -10)
    button.BackgroundColor3 = THEME.Primary
    button.Font = THEME.FontBold
    button.Text = " " .. icon .. "  " .. name
    button.TextColor3 = THEME.TextSecondary
    button.TextSize = 14
    button.LayoutOrder = order
    Instance.new("UICorner", button).CornerRadius = UDim.new(0, 6)
    button.Parent = tabContainer
    
    local page = Instance.new("Frame")
    page.Name = name
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.Visible = false
    page.Parent = contentContainer
    pages[name] = page

    button.MouseButton1Click:Connect(function() SwitchTab(button) end)
    return page, button
end

-- This function creates a styled search box.
function CreateSearchBox(parent)
    local box = Instance.new("TextBox")
    box.Size = UDim2.new(1, 0, 0, 34)
    box.BackgroundColor3 = THEME.Background
    box.Font = THEME.Font
    box.PlaceholderText = "Filter..."
    box.PlaceholderColor3 = THEME.TextSecondary
    box.TextColor3 = THEME.Text
    box.TextSize = 14
    box.ClearTextOnFocus = false
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 6)
    Instance.new("UIPadding", box).PaddingLeft = UDim.new(0, 10)
    box.Parent = parent
    return box
end

-- This function creates a styled scrolling frame for lists.
function CreateScrollingList(parent)
    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, 0, 1, -40)
    scroll.Position = UDim2.new(0, 0, 0, 40)
    scroll.BackgroundColor3 = THEME.Secondary
    scroll.BorderSizePixel = 0
    scroll.ScrollBarImageColor3 = THEME.Accent
    scroll.ScrollBarThickness = 5
    Instance.new("UICorner", scroll).CornerRadius = UDim.new(0, 8)
    local layout = Instance.new("UIListLayout", scroll)
    layout.Padding = UDim.new(0, 4)
    layout.SortOrder = Enum.SortOrder.Name
    
    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, 4)
    padding.PaddingRight = UDim.new(0, 4)
    padding.PaddingTop = UDim.new(0, 4)
    padding.PaddingBottom = UDim.new(0, 4)
    padding.Parent = scroll
    
    scroll.Parent = parent
    return scroll
end

-- This function adds a visual hover effect to a button.
function CreateHoverEffect(button)
    local originalColor = button.BackgroundColor3
    button.MouseEnter:Connect(function()
        game:GetService("TweenService"):Create(button, TweenInfo.new(0.2), {BackgroundColor3 = THEME.AccentDark}):Play()
    end)
    button.MouseLeave:Connect(function()
        game:GetService("TweenService"):Create(button, TweenInfo.new(0.2), {BackgroundColor3 = originalColor}):Play()
    end)
end

-- This is the main layout function. It builds the two-panel design for each tab page.
function SetupPageLayout(page, data, createControls)
    local pageState = { Selected = data and data[1] or nil }

    -- Left panel for the list and search box.
    local listFrame = Instance.new("Frame", page)
    listFrame.Size = UDim2.new(0.4, -15, 1, -10)
    listFrame.Position = UDim2.new(0, 10, 0, 5)
    listFrame.BackgroundTransparency = 1

    -- Right panel for the action controls (buttons, input fields).
    local controlsFrame = Instance.new("Frame", page)
    controlsFrame.Size = UDim2.new(0.6, -15, 1, -10)
    controlsFrame.Position = UDim2.new(0.4, 5, 0, 5)
    controlsFrame.BackgroundTransparency = 1
    local controlsLayout = Instance.new("UIListLayout", controlsFrame)
    controlsLayout.Padding = UDim.new(0, 10)
    controlsLayout.VerticalAlignment = Enum.VerticalAlignment.Top

    local searchBox = CreateSearchBox(listFrame)
    local scrollList = CreateScrollingList(listFrame)
    local itemButtons = {}

    -- This function updates the UI when a new item is selected from the list.
    local function updateSelection(button, name)
        pageState.Selected = name
        for _, b in ipairs(itemButtons) do
            b.BackgroundColor3 = (b == button) and THEME.Accent or THEME.Secondary
        end
        pageState.UpdateControls() 
    end
    
    -- This creates the controls on the right panel (e.g., Spawn button).
    pageState.UpdateControls = createControls(controlsFrame, pageState)

    -- Populate the scrolling list with buttons for each item.
    if data and #data > 0 then
        for _, itemName in ipairs(data) do
            local itemButton = Instance.new("TextButton")
            itemButton.Name = itemName
            itemButton.Size = UDim2.new(1, 0, 0, 32)
            itemButton.BackgroundColor3 = THEME.Secondary
            itemButton.Font = THEME.Font
            itemButton.Text = " " .. itemName
            itemButton.TextColor3 = THEME.Text
            itemButton.TextSize = 14
            itemButton.TextXAlignment = Enum.TextXAlignment.Left
            Instance.new("UICorner", itemButton).CornerRadius = UDim.new(0, 6)
            itemButton.Parent = scrollList
            table.insert(itemButtons, itemButton)
            itemButton.MouseButton1Click:Connect(function() updateSelection(itemButton, itemName) end)
        end
        -- Connect the search box to filter the list.
        searchBox:GetPropertyChangedSignal("Text"):Connect(function()
            local query = string.lower(searchBox.Text)
            for _, btn in ipairs(itemButtons) do
                btn.Visible = string.find(string.lower(btn.Name), query, 1, true)
            end
        end)
        -- Select the first item by default.
        updateSelection(itemButtons[1], itemButtons[1].Name)
    else
        -- If no items were loaded, display a message.
        searchBox.Visible = false
        local noItemsLabel = Instance.new("TextLabel", scrollList)
        noItemsLabel.Size = UDim2.new(1, -10, 0, 50)
        noItemsLabel.Position = UDim2.new(0.5, 0, 0, 10)
        noItemsLabel.AnchorPoint = Vector2.new(0.5, 0)
        noItemsLabel.BackgroundTransparency = 1
        noItemsLabel.Font = THEME.Font
        noItemsLabel.TextColor3 = THEME.TextSecondary
        noItemsLabel.TextWrapped = true
        noItemsLabel.Text = "No items found. The developer's library may be offline or broken."
    end
    
    pageState.UpdateControls()
end

-- This function creates a styled text input field with a label above it.
function CreateLabeledInput(parent, labelText)
    local container = Instance.new("Frame", parent)
    container.Size = UDim2.new(1, 0, 0, 55)
    container.BackgroundTransparency = 1
    local layout = Instance.new("UIListLayout", container)
    layout.Padding = UDim.new(0, 5)

    local label = Instance.new("TextLabel", container)
    label.Size = UDim2.new(1, 0, 0, 15)
    label.BackgroundTransparency = 1
    label.Font = THEME.Font
    label.TextColor3 = THEME.TextSecondary
    label.Text = labelText
    label.TextXAlignment = Enum.TextXAlignment.Left

    local input = Instance.new("TextBox", container)
    input.Size = UDim2.new(1, 0, 0, 35)
    input.BackgroundColor3 = THEME.Background
    input.Font = THEME.Font
    input.TextColor3 = THEME.Text
    input.TextSize = 14
    Instance.new("UICorner", input).CornerRadius = UDim.new(0, 6)
    Instance.new("UIPadding", input).PaddingLeft = UDim.new(0, 10)
    return input
end

-- This function creates a styled action button with an icon.
function CreateActionButton(parent, text, icon, isPrimary)
    local button = Instance.new("TextButton", parent)
    button.Size = UDim2.new(1, 0, 0, 35)
    button.BackgroundColor3 = isPrimary and THEME.Accent or THEME.Secondary
    button.Font = THEME.FontBold
    button.Text = " " .. icon .. "  " .. text
    button.TextColor3 = THEME.Text
    button.TextSize = 15
    Instance.new("UICorner", button).CornerRadius = UDim.new(0, 8)
    CreateHoverEffect(button)
    return button
end


-- // PAGE DEFINITIONS //
-- This section defines the content and functionality for each tab.

-- Define the "Pets" tab.
local petsPage, petsTab = CreateTab("Pets", "🐾", 1)
SetupPageLayout(petsPage, pet_names, function(controls, pageState)
    local selectedLabel = Instance.new("TextLabel", controls)
    selectedLabel.Size = UDim2.new(1, 0, 0, 24)
    selectedLabel.Font = THEME.FontBold
    selectedLabel.TextColor3 = THEME.Text
    selectedLabel.TextXAlignment = Enum.TextXAlignment.Left
    selectedLabel.BackgroundTransparency = 1
    selectedLabel.LayoutOrder = 1

    local kgInput = CreateLabeledInput(controls, "Size (KG)")
    kgInput.LayoutOrder = 2
    local ageInput = CreateLabeledInput(controls, "Age")
    ageInput.LayoutOrder = 3
    
    local spawnButton = CreateActionButton(controls, "SPAWN PET", "✨", true)
    spawnButton.LayoutOrder = 10
    
    -- [CONNECTION POINT] This connects the "SPAWN PET" button to the developer's library function.
    spawnButton.MouseButton1Click:Connect(function()
        if not pageState.Selected then return end
        Spawner.SpawnPet(pageState.Selected, tonumber(kgInput.Text) or 1, tonumber(ageInput.Text) or 1)
    end)
    
    -- This function updates the "Selected: ..." text.
    return function()
        selectedLabel.Text = "Selected: " .. (pageState.Selected or "None")
    end
end)

-- Define the "Seeds" tab.
local seedsPage, seedsTab = CreateTab("Seeds", "🌱", 2)
SetupPageLayout(seedsPage, seed_names, function(controls, pageState)
    local selectedLabel = Instance.new("TextLabel", controls)
    selectedLabel.Size = UDim2.new(1, 0, 0, 24)
    selectedLabel.Font = THEME.FontBold
    selectedLabel.TextColor3 = THEME.Text
    selectedLabel.TextXAlignment = Enum.TextXAlignment.Left
    selectedLabel.BackgroundTransparency = 1
    selectedLabel.LayoutOrder = 1

    local buttonContainer = Instance.new("Frame", controls)
    buttonContainer.Size = UDim2.new(1, 0, 0, 80)
    buttonContainer.BackgroundTransparency = 1
    buttonContainer.LayoutOrder = 10
    local buttonLayout = Instance.new("UIListLayout", buttonContainer)
    buttonLayout.Padding = UDim.new(0, 10)

    -- [CONNECTION POINT] Connects the "SPAWN SEED" button.
    CreateActionButton(buttonContainer, "SPAWN SEED", "✨", true).MouseButton1Click:Connect(function() if pageState.Selected then Spawner.SpawnSeed(pageState.Selected) end end)
    -- [CONNECTION POINT] Connects the "PLACE SEED" button.
    CreateActionButton(buttonContainer, "PLACE SEED", "📍", false).MouseButton1Click:Connect(function() if pageState.Selected and Spawner.PlaceSeed then Spawner.PlaceSeed(pageState.Selected) end end)
    
    return function()
        selectedLabel.Text = "Selected: " .. (pageState.Selected or "None")
    end
end)

-- Define the "Eggs" tab.
local eggsPage, eggsTab = CreateTab("Eggs", "🥚", 3)
SetupPageLayout(eggsPage, egg_names, function(controls, pageState)
    local selectedLabel = Instance.new("TextLabel", controls)
    selectedLabel.Size = UDim2.new(1, 0, 0, 24)
    selectedLabel.Font = THEME.FontBold
    selectedLabel.TextColor3 = THEME.Text
    selectedLabel.TextXAlignment = Enum.TextXAlignment.Left
    selectedLabel.BackgroundTransparency = 1
    selectedLabel.LayoutOrder = 1

    local spawnButton = CreateActionButton(controls, "SPAWN EGG", "✨", true)
    spawnButton.LayoutOrder = 10
    
    -- [CONNECTION POINT] Connects the "SPAWN EGG" button.
    spawnButton.MouseButton1Click:Connect(function() if pageState.Selected then Spawner.SpawnEgg(pageState.Selected) end end)
    
    return function()
        selectedLabel.Text = "Selected: " .. (pageState.Selected or "None")
    end
end)

-- Define the "Actions" tab.
local actionsPage, actionsTab = CreateTab("Actions", "🌀", 4)
SetupPageLayout(actionsPage, seed_names, function(controls, pageState)
    local selectedLabel = Instance.new("TextLabel", controls)
    selectedLabel.Size = UDim2.new(1, 0, 0, 24)
    selectedLabel.Font = THEME.FontBold
    selectedLabel.TextColor3 = THEME.Text
    selectedLabel.TextXAlignment = Enum.TextXAlignment.Left
    selectedLabel.BackgroundTransparency = 1
    selectedLabel.LayoutOrder = 1

    local spinButton = CreateActionButton(controls, "SPIN ITEM", "🌀", true)
    spinButton.LayoutOrder = 10
    
    -- [CONNECTION POINT] Connects the "SPIN ITEM" button.
    spinButton.MouseButton1Click:Connect(function()
        if pageState.Selected and Spawner.Spin then Spawner.Spin(pageState.Selected) end
    end)

    return function()
        selectedLabel.Text = "Selected: " .. (pageState.Selected or "None")
    end
end)


-- // FINAL SETUP //
-- Set the default tab and create the toggle button.

-- Set the "Pets" tab to be visible by default when the UI is opened.
SwitchTab(petsTab)

-- Create the floating "⚙️" button to toggle the UI visibility.
local toggleButton = Instance.new("TextButton")
toggleButton.Name = "ToggleUI"
toggleButton.Size = UDim2.new(0, 50, 0, 50)
toggleButton.Position = UDim2.new(0, 20, 0.5, -25)
toggleButton.BackgroundColor3 = THEME.Accent
toggleButton.Font = THEME.FontBold
toggleButton.Text = "⚙️"
toggleButton.TextColor3 = THEME.Text
toggleButton.TextSize = 24
Instance.new("UICorner", toggleButton).CornerRadius = UDim.new(1, 0) -- Makes it a circle.
toggleButton.Parent = screenGui
createDraggable(toggleButton, toggleButton)
CreateHoverEffect(toggleButton)

-- Connect the toggle button's click event to show/hide the main window.
toggleButton.MouseButton1Click:Connect(function()
    mainFrame.Visible = not mainFrame.Visible
end)
