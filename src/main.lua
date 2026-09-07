--[[
    Fluent Interface Suite - Versão Reconstruída
    Interface moderna e personalizável para Roblox
    
    Autor: dawid (reconstruído)
    License: MIT
    GitHub: https://github.com/dawid-scripts/Fluent
]]

local FluentUI = {}
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

-- ============================================================================
-- TEMAS PADRÃO
-- ============================================================================

local Themes = {
    Dark = {
        Name = "Dark",
        Accent = Color3.fromRGB(96, 205, 255),
        AcrylicMain = Color3.fromRGB(60, 60, 60),
        AcrylicBorder = Color3.fromRGB(90, 90, 90),
        AcrylicNoise = 0.9,
        TitleBarLine = Color3.fromRGB(75, 75, 75),
        Tab = Color3.fromRGB(120, 120, 120),
        Element = Color3.fromRGB(120, 120, 120),
        ElementBorder = Color3.fromRGB(35, 35, 35),
        InElementBorder = Color3.fromRGB(90, 90, 90),
        ElementTransparency = 0.87,
        Text = Color3.fromRGB(240, 240, 240),
        SubText = Color3.fromRGB(170, 170, 170),
        Hover = Color3.fromRGB(120, 120, 120),
        HoverChange = 0.07,
        Dialog = Color3.fromRGB(45, 45, 45),
        DialogHolder = Color3.fromRGB(35, 35, 35),
        Input = Color3.fromRGB(160, 160, 160),
    },
    
    Light = {
        Name = "Light",
        Accent = Color3.fromRGB(0, 103, 192),
        AcrylicMain = Color3.fromRGB(200, 200, 200),
        AcrylicBorder = Color3.fromRGB(120, 120, 120),
        AcrylicNoise = 0.96,
        TitleBarLine = Color3.fromRGB(160, 160, 160),
        Tab = Color3.fromRGB(90, 90, 90),
        Element = Color3.fromRGB(255, 255, 255),
        ElementBorder = Color3.fromRGB(180, 180, 180),
        InElementBorder = Color3.fromRGB(150, 150, 150),
        ElementTransparency = 0.65,
        Text = Color3.fromRGB(0, 0, 0),
        SubText = Color3.fromRGB(40, 40, 40),
        Hover = Color3.fromRGB(50, 50, 50),
        HoverChange = 0.16,
        Dialog = Color3.fromRGB(255, 255, 255),
        DialogHolder = Color3.fromRGB(240, 240, 240),
        Input = Color3.fromRGB(200, 200, 200),
    },
    
    Rose = {
        Name = "Rose",
        Accent = Color3.fromRGB(180, 55, 90),
        AcrylicMain = Color3.fromRGB(40, 40, 40),
        AcrylicBorder = Color3.fromRGB(130, 90, 110),
        AcrylicNoise = 0.92,
        TitleBarLine = Color3.fromRGB(140, 85, 105),
        Tab = Color3.fromRGB(180, 140, 160),
        Element = Color3.fromRGB(200, 120, 170),
        ElementBorder = Color3.fromRGB(110, 70, 85),
        InElementBorder = Color3.fromRGB(120, 90, 90),
        ElementTransparency = 0.86,
        Text = Color3.fromRGB(240, 240, 240),
        SubText = Color3.fromRGB(170, 170, 170),
        Hover = Color3.fromRGB(200, 120, 170),
        HoverChange = 0.04,
        Dialog = Color3.fromRGB(120, 50, 75),
        DialogHolder = Color3.fromRGB(95, 40, 60),
        Input = Color3.fromRGB(200, 120, 170),
    },
    
    Aqua = {
        Name = "Aqua",
        Accent = Color3.fromRGB(60, 165, 165),
        AcrylicMain = Color3.fromRGB(20, 20, 20),
        AcrylicBorder = Color3.fromRGB(50, 100, 100),
        AcrylicNoise = 0.92,
        TitleBarLine = Color3.fromRGB(60, 120, 120),
        Tab = Color3.fromRGB(140, 180, 180),
        Element = Color3.fromRGB(110, 160, 160),
        ElementBorder = Color3.fromRGB(40, 70, 70),
        InElementBorder = Color3.fromRGB(80, 110, 110),
        ElementTransparency = 0.84,
        Text = Color3.fromRGB(240, 240, 240),
        SubText = Color3.fromRGB(170, 170, 170),
        Hover = Color3.fromRGB(110, 160, 160),
        HoverChange = 0.04,
        Dialog = Color3.fromRGB(40, 80, 80),
        DialogHolder = Color3.fromRGB(30, 60, 60),
        Input = Color3.fromRGB(110, 160, 160),
    }
}

-- ============================================================================
-- GERENCIADOR DE TEMAS PERSONALIZADOS
-- ============================================================================

local ThemeManager = {}
ThemeManager.CustomThemes = {}

function ThemeManager:AddCustomTheme(name, themeData)
    assert(name, "Nome do tema é obrigatório")
    assert(themeData, "Dados do tema são obrigatórios")
    assert(themeData.Accent, "Cor de destaque (Accent) é obrigatória")
    
    self.CustomThemes[name] = themeData
    themeData.Name = name
    return self
end

function ThemeManager:AddGradientTheme(name, colorStart, colorEnd, properties)
    local themeData = {
        Name = name,
        Accent = colorStart,
        GradientStart = colorStart,
        GradientEnd = colorEnd,
    }
    
    -- Copiar propriedades padrão
    for key, value in pairs(Themes.Dark) do
        if not themeData[key] then
            themeData[key] = value
        end
    end
    
    -- Aplicar propriedades personalizadas
    if properties then
        for key, value in pairs(properties) do
            themeData[key] = value
        end
    end
    
    self.CustomThemes[name] = themeData
    return self
end

function ThemeManager:GetTheme(name)
    if Themes[name] then
        return Themes[name]
    elseif self.CustomThemes[name] then
        return self.CustomThemes[name]
    else
        return Themes.Dark
    end
end

function ThemeManager:GetAllThemes()
    local all = {}
    for name, theme in pairs(Themes) do
        all[name] = theme
    end
    for name, theme in pairs(self.CustomThemes) do
        all[name] = theme
    end
    return all
end

-- ============================================================================
-- BIBLIOTECA PRINCIPAL
-- ============================================================================

FluentUI.Version = "2.0.0"
FluentUI.OpenFrames = {}
FluentUI.Options = {}
FluentUI.ThemeManager = ThemeManager
FluentUI.Themes = Themes
FluentUI.CustomThemes = ThemeManager.CustomThemes
FluentUI.CurrentTheme = "Dark"
FluentUI.Window = nil

-- ============================================================================
-- FUNÇÕES UTILITÁRIAS
-- ============================================================================

function FluentUI:SafeCallback(callback, ...)
    if not callback then return end
    local success, err = pcall(callback, ...)
    if not success then
        local start, finish = err:find(":%d+: ")
        if not finish then
            warn("Erro de callback: " .. err)
        else
            warn("Erro de callback: " .. err:sub(finish + 1))
        end
    end
end

function FluentUI:Round(value, decimals)
    if decimals == 0 then
        return math.floor(value)
    end
    local str = tostring(value)
    local dotIndex = str:find("%.")
    if dotIndex then
        return tonumber(str:sub(1, dotIndex + decimals))
    else
        return value
    end
end

function FluentUI:GetIcon(iconName)
    -- Retorna o assetId do ícone Lucide
    local Icons = {
        ["lucide-settings"] = "rbxassetid://10709810948",
        ["lucide-home"] = "rbxassetid://10723407389",
        ["lucide-save"] = "rbxassetid://10734941499",
        ["lucide-trash"] = "rbxassetid://10747362393",
    }
    return Icons["lucide-" .. iconName] or nil
end

-- ============================================================================
-- CRIAÇÃO DA JANELA
-- ============================================================================

function FluentUI:CreateWindow(config)
    assert(config.Title, "Título da janela é obrigatório")
    
    if self.Window then
        warn("Você não pode criar mais de uma janela")
        return nil
    end
    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "FluentUI"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = RunService:IsStudio() and Players.LocalPlayer.PlayerGui or game:GetService("CoreGui")
    
    -- Proteger GUI
    if protectgui then
        protectgui(screenGui)
    elseif syn and syn.protect_gui then
        syn.protect_gui(screenGui)
    end
    
    local window = {
        Name = config.Title,
        SubTitle = config.SubTitle or "",
        Size = config.Size or UDim2.fromOffset(800, 600),
        Position = UDim2.fromOffset(200, 200),
        Root = screenGui,
        Tabs = {},
        TabCount = 0,
        SelectedTab = 0,
    }
    
    setmetatable(window, {__index = self})
    
    self.Window = window
    self:SetTheme(config.Theme or "Dark")
    
    return window
end

-- ============================================================================
-- GERENCIAMENTO DE TEMAS
-- ============================================================================

function FluentUI:SetTheme(themeName)
    if not self.Window then return end
    self.CurrentTheme = themeName
    local theme = self.ThemeManager:GetTheme(themeName)
    
    -- Aplicar tema a todos os elementos
    for frame, properties in pairs(self._ThemeObjects or {}) do
        for property, themeProp in pairs(properties) do
            if theme[themeProp] then
                frame[property] = theme[themeProp]
            end
        end
    end
end

function FluentUI:GetThemeProperty(propertyName)
    local theme = self.ThemeManager:GetTheme(self.CurrentTheme)
    return theme[propertyName] or Color3.new(1, 1, 1)
end

-- ============================================================================
-- CRIAÇÃO DE ABAS
-- ============================================================================

function FluentUI:AddTab(title, icon)
    if not self.Window then return nil end
    
    self.Window.TabCount = self.Window.TabCount + 1
    local tabId = self.Window.TabCount
    
    local tab = {
        ID = tabId,
        Name = title,
        Icon = icon,
        Elements = {},
        Container = Instance.new("ScrollingFrame"),
    }
    
    tab.Container.Name = "TabContainer"
    tab.Container.Size = UDim2.fromScale(1, 1)
    tab.Container.BackgroundTransparency = 1
    tab.Container.BorderSizePixel = 0
    tab.Container.Parent = self.Window.Root
    
    self.Window.Tabs[tabId] = tab
    
    return tab
end

-- ============================================================================
-- CRIAÇÃO DE ELEMENTOS
-- ============================================================================

function FluentUI:AddButton(tab, title, callback)
    callback = callback or function() end
    
    local button = Instance.new("TextButton")
    button.Name = title
    button.Text = title
    button.Size = UDim2.new(1, 0, 0, 36)
    button.BackgroundColor3 = self:GetThemeProperty("Element")
    button.TextColor3 = self:GetThemeProperty("Text")
    button.Font = Enum.Font.GothamMedium
    button.TextSize = 14
    button.Parent = tab.Container
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = button
    
    button.MouseButton1Click:Connect(function()
        self:SafeCallback(callback)
    end)
    
    return button
end

function FluentUI:AddToggle(tab, title, default, callback)
    callback = callback or function() end
    default = default or false
    
    local container = Instance.new("Frame")
    container.Name = title
    container.Size = UDim2.new(1, 0, 0, 36)
    container.BackgroundColor3 = self:GetThemeProperty("Element")
    container.Parent = tab.Container
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = container
    
    local label = Instance.new("TextLabel")
    label.Text = title
    label.Size = UDim2.new(0.7, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = self:GetThemeProperty("Text")
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 14
    label.Parent = container
    
    local toggleButton = Instance.new("TextButton")
    toggleButton.Size = UDim2.new(0, 50, 0, 24)
    toggleButton.AnchorPoint = Vector2.new(1, 0.5)
    toggleButton.Position = UDim2.new(1, -10, 0.5, 0)
    toggleButton.BackgroundColor3 = default and self:GetThemeProperty("Accent") or Color3.fromRGB(100, 100, 100)
    toggleButton.TextTransparency = 1
    toggleButton.Parent = container
    
    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(0, 4)
    toggleCorner.Parent = toggleButton
    
    local isToggled = default
    
    toggleButton.MouseButton1Click:Connect(function()
        isToggled = not isToggled
        toggleButton.BackgroundColor3 = isToggled and self:GetThemeProperty("Accent") or Color3.fromRGB(100, 100, 100)
        self:SafeCallback(callback, isToggled)
    end)
    
    return {
        Container = container,
        ToggleButton = toggleButton,
        GetValue = function() return isToggled end,
        SetValue = function(value) 
            isToggled = value
            toggleButton.BackgroundColor3 = isToggled and self:GetThemeProperty("Accent") or Color3.fromRGB(100, 100, 100)
        end
    }
end

function FluentUI:AddSlider(tab, title, min, max, default, callback)
    callback = callback or function() end
    default = default or min
    
    local container = Instance.new("Frame")
    container.Name = title
    container.Size = UDim2.new(1, 0, 0, 50)
    container.BackgroundColor3 = self:GetThemeProperty("Element")
    container.Parent = tab.Container
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = container
    
    local label = Instance.new("TextLabel")
    label.Text = title
    label.Size = UDim2.new(1, 0, 0, 20)
    label.BackgroundTransparency = 1
    label.TextColor3 = self:GetThemeProperty("Text")
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 12
    label.Parent = container
    
    local sliderBar = Instance.new("Frame")
    sliderBar.Size = UDim2.new(1, -20, 0, 4)
    sliderBar.Position = UDim2.new(0, 10, 0, 30)
    sliderBar.BackgroundColor3 = self:GetThemeProperty("InElementBorder")
    sliderBar.Parent = container
    
    local sliderFill = Instance.new("Frame")
    sliderFill.Size = UDim2.new(0, 0, 1, 0)
    sliderFill.BackgroundColor3 = self:GetThemeProperty("Accent")
    sliderFill.Parent = sliderBar
    
    local sliderButton = Instance.new("TextButton")
    sliderButton.Size = UDim2.new(0, 12, 0, 12)
    sliderButton.Position = UDim2.new(0, -6, 0.5, -6)
    sliderButton.BackgroundColor3 = self:GetThemeProperty("Accent")
    sliderButton.TextTransparency = 1
    sliderButton.Parent = sliderFill
    
    local value = default
    
    local function updateSlider(newValue)
        value = math.clamp(newValue, min, max)
        local percentage = (value - min) / (max - min)
        sliderFill.Size = UDim2.new(percentage, 0, 1, 0)
        self:SafeCallback(callback, value)
    end
    
    sliderButton.MouseButton1Down:Connect(function()
        local mouse = Players.LocalPlayer:GetMouse()
        while UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
            local relativePos = mouse.X - sliderBar.AbsolutePosition.X
            local newValue = min + ((relativePos / sliderBar.AbsoluteSize.X) * (max - min))
            updateSlider(newValue)
            game:GetService("RunService").RenderStepped:Wait()
        end
    end)
    
    updateSlider(default)
    
    return {
        Container = container,
        GetValue = function() return value end,
        SetValue = updateSlider
    }
end

function FluentUI:AddInput(tab, title, placeholder, callback)
    callback = callback or function() end
    
    local container = Instance.new("Frame")
    container.Name = title
    container.Size = UDim2.new(1, 0, 0, 36)
    container.BackgroundColor3 = self:GetThemeProperty("Element")
    container.Parent = tab.Container
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = container
    
    local label = Instance.new("TextLabel")
    label.Text = title
    label.Size = UDim2.new(0.3, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = self:GetThemeProperty("Text")
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 12
    label.Parent = container
    
    local textBox = Instance.new("TextBox")
    textBox.PlaceholderText = placeholder or ""
    textBox.Size = UDim2.new(0.65, 0, 0, 24)
    textBox.Position = UDim2.new(0.32, 0, 0.5, -12)
    textBox.AnchorPoint = Vector2.new(0, 0.5)
    textBox.BackgroundColor3 = self:GetThemeProperty("Input")
    textBox.TextColor3 = self:GetThemeProperty("Text")
    textBox.Font = Enum.Font.Gotham
    textBox.TextSize = 12
    textBox.Parent = container
    
    local textBoxCorner = Instance.new("UICorner")
    textBoxCorner.CornerRadius = UDim.new(0, 3)
    textBoxCorner.Parent = textBox
    
    textBox.FocusLost:Connect(function()
        self:SafeCallback(callback, textBox.Text)
    end)
    
    return {
        Container = container,
        TextBox = textBox,
        GetValue = function() return textBox.Text end,
        SetValue = function(text) textBox.Text = text end
    }
end

-- ============================================================================
-- GERENCIAMENTO DE NOTIFICAÇÕES
-- ============================================================================

function FluentUI:Notify(title, message, duration)
    local notification = Instance.new("Frame")
    notification.Name = "Notification"
    notification.Size = UDim2.fromOffset(300, 80)
    notification.Position = UDim2.new(1, -320, 0, 20)
    notification.BackgroundColor3 = self:GetThemeProperty("Dialog")
    notification.Parent = self.Window.Root
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = notification
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Text = title
    titleLabel.Size = UDim2.new(1, -20, 0, 20)
    titleLabel.Position = UDim2.fromOffset(10, 10)
    titleLabel.BackgroundTransparency = 1
    titleLabel.TextColor3 = self:GetThemeProperty("Text")
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 14
    titleLabel.Parent = notification
    
    local messageLabel = Instance.new("TextLabel")
    messageLabel.Text = message
    messageLabel.Size = UDim2.new(1, -20, 0, 50)
    messageLabel.Position = UDim2.fromOffset(10, 30)
    messageLabel.BackgroundTransparency = 1
    messageLabel.TextColor3 = self:GetThemeProperty("SubText")
    messageLabel.Font = Enum.Font.Gotham
    messageLabel.TextSize = 12
    messageLabel.TextWrapped = true
    messageLabel.Parent = notification
    
    duration = duration or 5
    task.delay(duration, function()
        notification:Destroy()
    end)
end

-- ============================================================================
-- DESTRUIÇÃO
-- ============================================================================

function FluentUI:Destroy()
    if self.Window then
        self.Window.Root:Destroy()
        self.Window = nil
    end
end

-- ============================================================================
-- EXPORTAR
-- ============================================================================

if getgenv then
    getgenv().FluentUI = FluentUI
end

return FluentUI
