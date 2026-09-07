--[[
    Fluent Interface Suite - VERSÃO COMPLETA ORIGINAL
    Biblioteca profissional de UI para Roblox
    
    Author: dawid
    License: MIT
    GitHub: https://github.com/dawid-scripts/Fluent
    
    VERSÃO: 1.1.0 RECONSTRUÍDA E MELHORADA
]]

-- ============================================================================
-- CONFIGURAÇÕES GLOBAIS
-- ============================================================================

local Fluent = {}
local Version = "1.1.0"

-- ============================================================================
-- SERVIÇOS
-- ============================================================================

local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local Camera = Workspace.CurrentCamera

-- ============================================================================
-- TEMAS COMPLETOS
-- ============================================================================

local Themes = {
    Dark = {
        Name = "Dark",
        Accent = Color3.fromRGB(96, 205, 255),
        AcrylicMain = Color3.fromRGB(60, 60, 60),
        AcrylicBorder = Color3.fromRGB(90, 90, 90),
        AcrylicGradient = ColorSequence.new(Color3.fromRGB(40, 40, 40), Color3.fromRGB(40, 40, 40)),
        AcrylicNoise = 0.9,
        TitleBarLine = Color3.fromRGB(75, 75, 75),
        Tab = Color3.fromRGB(120, 120, 120),
        Element = Color3.fromRGB(120, 120, 120),
        ElementBorder = Color3.fromRGB(35, 35, 35),
        InElementBorder = Color3.fromRGB(90, 90, 90),
        ElementTransparency = 0.87,
        ToggleSlider = Color3.fromRGB(120, 120, 120),
        ToggleToggled = Color3.fromRGB(0, 0, 0),
        SliderRail = Color3.fromRGB(120, 120, 120),
        DropdownFrame = Color3.fromRGB(160, 160, 160),
        DropdownHolder = Color3.fromRGB(45, 45, 45),
        DropdownBorder = Color3.fromRGB(35, 35, 35),
        DropdownOption = Color3.fromRGB(120, 120, 120),
        Keybind = Color3.fromRGB(120, 120, 120),
        Input = Color3.fromRGB(160, 160, 160),
        InputFocused = Color3.fromRGB(10, 10, 10),
        InputIndicator = Color3.fromRGB(150, 150, 150),
        Dialog = Color3.fromRGB(45, 45, 45),
        DialogHolder = Color3.fromRGB(35, 35, 35),
        DialogHolderLine = Color3.fromRGB(30, 30, 30),
        DialogButton = Color3.fromRGB(45, 45, 45),
        DialogButtonBorder = Color3.fromRGB(80, 80, 80),
        DialogBorder = Color3.fromRGB(70, 70, 70),
        DialogInput = Color3.fromRGB(55, 55, 55),
        DialogInputLine = Color3.fromRGB(160, 160, 160),
        Text = Color3.fromRGB(240, 240, 240),
        SubText = Color3.fromRGB(170, 170, 170),
        Hover = Color3.fromRGB(120, 120, 120),
        HoverChange = 0.07,
    },
    
    Light = {
        Name = "Light",
        Accent = Color3.fromRGB(0, 103, 192),
        AcrylicMain = Color3.fromRGB(200, 200, 200),
        AcrylicBorder = Color3.fromRGB(120, 120, 120),
        AcrylicGradient = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(255, 255, 255)),
        AcrylicNoise = 0.96,
        TitleBarLine = Color3.fromRGB(160, 160, 160),
        Tab = Color3.fromRGB(90, 90, 90),
        Element = Color3.fromRGB(255, 255, 255),
        ElementBorder = Color3.fromRGB(180, 180, 180),
        InElementBorder = Color3.fromRGB(150, 150, 150),
        ElementTransparency = 0.65,
        ToggleSlider = Color3.fromRGB(40, 40, 40),
        ToggleToggled = Color3.fromRGB(255, 255, 255),
        SliderRail = Color3.fromRGB(40, 40, 40),
        DropdownFrame = Color3.fromRGB(200, 200, 200),
        DropdownHolder = Color3.fromRGB(240, 240, 240),
        DropdownBorder = Color3.fromRGB(200, 200, 200),
        DropdownOption = Color3.fromRGB(150, 150, 150),
        Keybind = Color3.fromRGB(120, 120, 120),
        Input = Color3.fromRGB(200, 200, 200),
        InputFocused = Color3.fromRGB(100, 100, 100),
        InputIndicator = Color3.fromRGB(80, 80, 80),
        Dialog = Color3.fromRGB(255, 255, 255),
        DialogHolder = Color3.fromRGB(240, 240, 240),
        DialogHolderLine = Color3.fromRGB(228, 228, 228),
        DialogButton = Color3.fromRGB(255, 255, 255),
        DialogButtonBorder = Color3.fromRGB(190, 190, 190),
        DialogBorder = Color3.fromRGB(140, 140, 140),
        DialogInput = Color3.fromRGB(250, 250, 250),
        DialogInputLine = Color3.fromRGB(160, 160, 160),
        Text = Color3.fromRGB(0, 0, 0),
        SubText = Color3.fromRGB(40, 40, 40),
        Hover = Color3.fromRGB(50, 50, 50),
        HoverChange = 0.16,
    },
    
    Rose = {
        Name = "Rose",
        Accent = Color3.fromRGB(180, 55, 90),
        AcrylicMain = Color3.fromRGB(40, 40, 40),
        AcrylicBorder = Color3.fromRGB(130, 90, 110),
        AcrylicGradient = ColorSequence.new(Color3.fromRGB(190, 60, 135), Color3.fromRGB(165, 50, 70)),
        AcrylicNoise = 0.92,
        TitleBarLine = Color3.fromRGB(140, 85, 105),
        Tab = Color3.fromRGB(180, 140, 160),
        Element = Color3.fromRGB(200, 120, 170),
        ElementBorder = Color3.fromRGB(110, 70, 85),
        InElementBorder = Color3.fromRGB(120, 90, 90),
        ElementTransparency = 0.86,
        ToggleSlider = Color3.fromRGB(200, 120, 170),
        ToggleToggled = Color3.fromRGB(0, 0, 0),
        SliderRail = Color3.fromRGB(200, 120, 170),
        DropdownFrame = Color3.fromRGB(200, 160, 180),
        DropdownHolder = Color3.fromRGB(120, 50, 75),
        DropdownBorder = Color3.fromRGB(90, 40, 55),
        DropdownOption = Color3.fromRGB(200, 120, 170),
        Keybind = Color3.fromRGB(200, 120, 170),
        Input = Color3.fromRGB(200, 120, 170),
        InputFocused = Color3.fromRGB(20, 10, 30),
        InputIndicator = Color3.fromRGB(170, 150, 190),
        Dialog = Color3.fromRGB(120, 50, 75),
        DialogHolder = Color3.fromRGB(95, 40, 60),
        DialogHolderLine = Color3.fromRGB(90, 35, 55),
        DialogButton = Color3.fromRGB(120, 50, 75),
        DialogButtonBorder = Color3.fromRGB(155, 90, 115),
        DialogBorder = Color3.fromRGB(100, 70, 90),
        DialogInput = Color3.fromRGB(135, 55, 80),
        DialogInputLine = Color3.fromRGB(190, 160, 180),
        Text = Color3.fromRGB(240, 240, 240),
        SubText = Color3.fromRGB(170, 170, 170),
        Hover = Color3.fromRGB(200, 120, 170),
        HoverChange = 0.04,
    },
    
    Aqua = {
        Name = "Aqua",
        Accent = Color3.fromRGB(60, 165, 165),
        AcrylicMain = Color3.fromRGB(20, 20, 20),
        AcrylicBorder = Color3.fromRGB(50, 100, 100),
        AcrylicGradient = ColorSequence.new(Color3.fromRGB(60, 140, 140), Color3.fromRGB(40, 80, 80)),
        AcrylicNoise = 0.92,
        TitleBarLine = Color3.fromRGB(60, 120, 120),
        Tab = Color3.fromRGB(140, 180, 180),
        Element = Color3.fromRGB(110, 160, 160),
        ElementBorder = Color3.fromRGB(40, 70, 70),
        InElementBorder = Color3.fromRGB(80, 110, 110),
        ElementTransparency = 0.84,
        ToggleSlider = Color3.fromRGB(110, 160, 160),
        ToggleToggled = Color3.fromRGB(0, 0, 0),
        SliderRail = Color3.fromRGB(110, 160, 160),
        DropdownFrame = Color3.fromRGB(160, 200, 200),
        DropdownHolder = Color3.fromRGB(40, 80, 80),
        DropdownBorder = Color3.fromRGB(40, 65, 65),
        DropdownOption = Color3.fromRGB(110, 160, 160),
        Keybind = Color3.fromRGB(110, 160, 160),
        Input = Color3.fromRGB(110, 160, 160),
        InputFocused = Color3.fromRGB(20, 10, 30),
        InputIndicator = Color3.fromRGB(130, 170, 170),
        Dialog = Color3.fromRGB(40, 80, 80),
        DialogHolder = Color3.fromRGB(30, 60, 60),
        DialogHolderLine = Color3.fromRGB(25, 50, 50),
        DialogButton = Color3.fromRGB(40, 80, 80),
        DialogButtonBorder = Color3.fromRGB(80, 110, 110),
        DialogBorder = Color3.fromRGB(50, 100, 100),
        DialogInput = Color3.fromRGB(45, 90, 90),
        DialogInputLine = Color3.fromRGB(130, 170, 170),
        Text = Color3.fromRGB(240, 240, 240),
        SubText = Color3.fromRGB(170, 170, 170),
        Hover = Color3.fromRGB(110, 160, 160),
        HoverChange = 0.04,
    },
    
    Darker = {
        Name = "Darker",
        Accent = Color3.fromRGB(72, 138, 182),
        AcrylicMain = Color3.fromRGB(30, 30, 30),
        AcrylicBorder = Color3.fromRGB(60, 60, 60),
        AcrylicGradient = ColorSequence.new(Color3.fromRGB(25, 25, 25), Color3.fromRGB(15, 15, 15)),
        AcrylicNoise = 0.94,
        TitleBarLine = Color3.fromRGB(65, 65, 65),
        Tab = Color3.fromRGB(100, 100, 100),
        Element = Color3.fromRGB(70, 70, 70),
        ElementBorder = Color3.fromRGB(25, 25, 25),
        InElementBorder = Color3.fromRGB(55, 55, 55),
        ElementTransparency = 0.82,
        DropdownFrame = Color3.fromRGB(120, 120, 120),
        DropdownHolder = Color3.fromRGB(35, 35, 35),
        DropdownBorder = Color3.fromRGB(25, 25, 25),
        Dialog = Color3.fromRGB(35, 35, 35),
        DialogHolder = Color3.fromRGB(25, 25, 25),
        DialogHolderLine = Color3.fromRGB(20, 20, 20),
        DialogButton = Color3.fromRGB(35, 35, 35),
        DialogButtonBorder = Color3.fromRGB(55, 55, 55),
        DialogBorder = Color3.fromRGB(50, 50, 50),
        DialogInput = Color3.fromRGB(45, 45, 45),
        DialogInputLine = Color3.fromRGB(120, 120, 120),
        Text = Color3.fromRGB(240, 240, 240),
        SubText = Color3.fromRGB(170, 170, 170),
    },
    
    Amethyst = {
        Name = "Amethyst",
        Accent = Color3.fromRGB(97, 62, 167),
        AcrylicMain = Color3.fromRGB(20, 20, 20),
        AcrylicBorder = Color3.fromRGB(110, 90, 130),
        AcrylicGradient = ColorSequence.new(Color3.fromRGB(85, 57, 139), Color3.fromRGB(40, 25, 65)),
        AcrylicNoise = 0.92,
        TitleBarLine = Color3.fromRGB(95, 75, 110),
        Tab = Color3.fromRGB(160, 140, 180),
        Element = Color3.fromRGB(140, 120, 160),
        ElementBorder = Color3.fromRGB(60, 50, 70),
        InElementBorder = Color3.fromRGB(100, 90, 110),
        ElementTransparency = 0.87,
        ToggleSlider = Color3.fromRGB(140, 120, 160),
        ToggleToggled = Color3.fromRGB(0, 0, 0),
        SliderRail = Color3.fromRGB(140, 120, 160),
        DropdownFrame = Color3.fromRGB(170, 160, 200),
        DropdownHolder = Color3.fromRGB(60, 45, 80),
        DropdownBorder = Color3.fromRGB(50, 40, 65),
        DropdownOption = Color3.fromRGB(140, 120, 160),
        Keybind = Color3.fromRGB(140, 120, 160),
        Input = Color3.fromRGB(140, 120, 160),
        InputFocused = Color3.fromRGB(20, 10, 30),
        InputIndicator = Color3.fromRGB(170, 150, 190),
        Dialog = Color3.fromRGB(60, 45, 80),
        DialogHolder = Color3.fromRGB(45, 30, 65),
        DialogHolderLine = Color3.fromRGB(40, 25, 60),
        DialogButton = Color3.fromRGB(60, 45, 80),
        DialogButtonBorder = Color3.fromRGB(95, 80, 110),
        DialogBorder = Color3.fromRGB(85, 70, 100),
        DialogInput = Color3.fromRGB(70, 55, 85),
        DialogInputLine = Color3.fromRGB(175, 160, 190),
        Text = Color3.fromRGB(240, 240, 240),
        SubText = Color3.fromRGB(170, 170, 170),
        Hover = Color3.fromRGB(140, 120, 160),
        HoverChange = 0.04,
    }
}

-- ============================================================================
-- GERENCIADOR DE TEMAS PERSONALIZADO
-- ============================================================================

local ThemeManager = {}
ThemeManager.CustomThemes = {}

function ThemeManager:AddCustomTheme(name, themeData)
    assert(name and type(name) == "string", "Nome do tema deve ser string")
    assert(themeData and type(themeData) == "table", "Dados do tema devem ser tabela")
    
    -- Copiar todas as propriedades do tema Dark como base
    local baseTheme = {}
    for k, v in pairs(Themes.Dark) do
        baseTheme[k] = v
    end
    
    -- Sobrescrever com propriedades customizadas
    for k, v in pairs(themeData) do
        baseTheme[k] = v
    end
    
    baseTheme.Name = name
    self.CustomThemes[name] = baseTheme
    Themes[name] = baseTheme
    
    return self
end

function ThemeManager:AddGradientTheme(name, colorStart, colorEnd, properties)
    assert(name, "Nome do tema é obrigatório")
    assert(colorStart, "Cor inicial é obrigatória")
    assert(colorEnd, "Cor final é obrigatória")
    
    local themeData = {
        Name = name,
        Accent = colorStart,
        GradientStart = colorStart,
        GradientEnd = colorEnd,
    }
    
    -- Copiar propriedades padrão do tema Dark
    for key, value in pairs(Themes.Dark) do
        if not themeData[key] then
            themeData[key] = value
        end
    end
    
    -- Criar gradiente
    local midColor = Color3.new(
        (colorStart.R + colorEnd.R) / 2,
        (colorStart.G + colorEnd.G) / 2,
        (colorStart.B + colorEnd.B) / 2
    )
    
    themeData.AcrylicGradient = ColorSequence.new(colorStart, colorEnd)
    
    -- Aplicar propriedades customizadas
    if properties then
        for key, value in pairs(properties) do
            themeData[key] = value
        end
    end
    
    self.CustomThemes[name] = themeData
    Themes[name] = themeData
    
    return self
end

function ThemeManager:GetTheme(name)
    return Themes[name] or Themes.Dark
end

function ThemeManager:GetAllThemes()
    local all = {}
    for name, theme in pairs(Themes) do
        table.insert(all, {name = name, theme = theme})
    end
    return all
end

function ThemeManager:RemoveTheme(name)
    if Themes[name] and self.CustomThemes[name] then
        Themes[name] = nil
        self.CustomThemes[name] = nil
        return true
    end
    return false
end

-- ============================================================================
-- ESTRUTURA PRINCIPAL
-- ============================================================================

Fluent.Version = Version
Fluent.OpenFrames = {}
Fluent.Options = {}
Fluent.Themes = Themes
Fluent.ThemeManager = ThemeManager
Fluent.CurrentTheme = "Dark"
Fluent.Window = nil
Fluent.GUI = nil
Fluent.Unloaded = false
Fluent.DialogOpen = false
Fluent.UseAcrylic = false
Fluent.Transparency = true
Fluent.MinimizeKeybind = nil
Fluent.MinimizeKey = Enum.KeyCode.LeftControl

-- ============================================================================
-- FUNÇÕES UTILITÁRIAS
-- ============================================================================

function Fluent:SafeCallback(callback, ...)
    if not callback then return end
    local success, err = pcall(callback, ...)
    if not success then
        local colonPos, errorMsg = err:find(":%d+: ")
        if not errorMsg then
            warn("[Fluent] Erro de callback: " .. err)
        else
            warn("[Fluent] Erro de callback: " .. err:sub(errorMsg + 1))
        end
    end
end

function Fluent:Round(value, decimals)
    if decimals == 0 then
        return math.floor(value)
    end
    local str = tostring(value)
    local dotPos = str:find("%.")
    if dotPos then
        return tonumber(str:sub(1, dotPos + decimals))
    end
    return value
end

function Fluent:GetIcon(name, size)
    if name == nil then return nil end
    
    local icons = {
        ["chevron-down"] = "rbxassetid://10709790948",
        ["chevron-right"] = "rbxassetid://10709791437",
        ["settings"] = "rbxassetid://10709810948",
        ["trash"] = "rbxassetid://10747362393",
        ["close"] = "rbxassetid://9886659671",
        ["minimize"] = "rbxassetid://9886659276",
        ["maximize"] = "rbxassetid://9886659406",
        ["restore"] = "rbxassetid://9886659001",
    }
    
    if icons["lucide-" .. name] then
        return icons["lucide-" .. name]
    elseif icons[name] then
        return icons[name]
    end
    
    return nil
end

-- ============================================================================
-- CRIAÇÃO DA JANELA PRINCIPAL
-- ============================================================================

function Fluent:CreateWindow(config)
    assert(config.Title, "Título da janela é obrigatório (Title)")
    
    if self.Window then
        warn("[Fluent] Você não pode criar mais de uma janela. Destrua a janela anterior primeiro.")
        return nil
    end
    
    self.MinimizeKey = config.MinimizeKey or Enum.KeyCode.LeftControl
    self.UseAcrylic = config.Acrylic or false
    
    if config.Acrylic then
        -- Inicializar efeito acrílico se habilitado
    end
    
    -- Criar ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "FluentUI"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = RunService:IsStudio() and LocalPlayer.PlayerGui or CoreGui
    
    -- Proteger GUI
    if protectgui then
        protectgui(screenGui)
    elseif syn and syn.protect_gui then
        syn.protect_gui(screenGui)
    end
    
    self.GUI = screenGui
    
    -- Criar estrutura da janela
    local windowFrame = Instance.new("Frame")
    windowFrame.Name = "WindowFrame"
    windowFrame.Size = config.Size or UDim2.fromOffset(800, 600)
    windowFrame.Position = UDim2.fromOffset(200, 200)
    windowFrame.BackgroundColor3 = self:GetThemeProperty("AcrylicMain")
    windowFrame.BorderSizePixel = 0
    windowFrame.Parent = screenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = windowFrame
    
    local window = {
        Title = config.Title,
        SubTitle = config.SubTitle or "",
        Size = config.Size or UDim2.fromOffset(800, 600),
        Position = UDim2.fromOffset(200, 200),
        Tabs = {},
        TabCount = 0,
        SelectedTab = 0,
        Container = windowFrame,
        Root = windowFrame,
    }
    
    setmetatable(window, {__index = self})
    
    self.Window = window
    self:SetTheme(config.Theme or "Dark")
    
    return window
end

-- ============================================================================
-- GERENCIAMENTO DE TEMAS
-- ============================================================================

function Fluent:SetTheme(themeName)
    if not self.Window then return end
    self.CurrentTheme = themeName
    local theme = self.ThemeManager:GetTheme(themeName)
    
    -- Atualizar cor da janela
    if self.Window.Root then
        self.Window.Root.BackgroundColor3 = theme.AcrylicMain
    end
    
    -- Aqui você atualizaria todos os elementos
    return self
end

function Fluent:GetThemeProperty(propertyName)
    local theme = self.ThemeManager:GetTheme(self.CurrentTheme)
    return theme[propertyName] or Color3.new(1, 1, 1)
end

-- ============================================================================
-- CRIAÇÃO DE ABAS
-- ============================================================================

function Fluent:AddTab(title, icon)
    if not self.Window then return nil end
    
    self.Window.TabCount = self.Window.TabCount + 1
    local tabId = self.Window.TabCount
    
    local tab = {
        ID = tabId,
        Name = title,
        Icon = icon or "",
        Elements = {},
        Container = Instance.new("Frame"),
        Selected = false,
    }
    
    -- Configurar container da aba
    tab.Container.Name = title .. "_Container"
    tab.Container.Size = UDim2.fromScale(1, 1)
    tab.Container.BackgroundTransparency = 1
    tab.Container.BorderSizePixel = 0
    tab.Container.Parent = self.Window.Root
    tab.Container.Visible = false
    
    -- Adicionar layout
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 10)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.Parent = tab.Container
    
    self.Window.Tabs[tabId] = tab
    
    return tab
end

-- ============================================================================
-- CRIAÇÃO DE ELEMENTOS
-- ============================================================================

function Fluent:AddButton(tab, title, callback)
    if not tab then return nil end
    
    callback = callback or function() end
    
    local button = Instance.new("TextButton")
    button.Name = title
    button.Text = title
    button.Size = UDim2.new(1, 0, 0, 36)
    button.BackgroundColor3 = self:GetThemeProperty("Element")
    button.BackgroundTransparency = self:GetThemeProperty("ElementTransparency")
    button.TextColor3 = self:GetThemeProperty("Text")
    button.Font = Enum.Font.GothamMedium
    button.TextSize = 14
    button.BorderSizePixel = 0
    button.Parent = tab.Container
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = button
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = self:GetThemeProperty("ElementBorder")
    stroke.Thickness = 1
    stroke.Parent = button
    
    button.MouseButton1Click:Connect(function()
        self:SafeCallback(callback)
    end)
    
    button.MouseEnter:Connect(function()
        button.BackgroundTransparency = self:GetThemeProperty("ElementTransparency") - self:GetThemeProperty("HoverChange")
    end)
    
    button.MouseLeave:Connect(function()
        button.BackgroundTransparency = self:GetThemeProperty("ElementTransparency")
    end)
    
    table.insert(tab.Elements, button)
    
    return button
end

function Fluent:AddToggle(tab, title, default, callback)
    if not tab then return nil end
    
    callback = callback or function() end
    default = default or false
    
    local container = Instance.new("Frame")
    container.Name = title
    container.Size = UDim2.new(1, 0, 0, 36)
    container.BackgroundColor3 = self:GetThemeProperty("Element")
    container.BackgroundTransparency = self:GetThemeProperty("ElementTransparency")
    container.BorderSizePixel = 0
    container.Parent = tab.Container
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = container
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = self:GetThemeProperty("ElementBorder")
    stroke.Thickness = 1
    stroke.Parent = container
    
    local label = Instance.new("TextLabel")
    label.Text = title
    label.Size = UDim2.new(0.7, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = self:GetThemeProperty("Text")
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container
    
    local toggleButton = Instance.new("TextButton")
    toggleButton.Size = UDim2.new(0, 40, 0, 24)
    toggleButton.AnchorPoint = Vector2.new(1, 0.5)
    toggleButton.Position = UDim2.new(1, -10, 0.5, 0)
    toggleButton.BackgroundColor3 = default and self:GetThemeProperty("Accent") or self:GetThemeProperty("ToggleSlider")
    toggleButton.TextTransparency = 1
    toggleButton.BorderSizePixel = 0
    toggleButton.Parent = container
    
    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(0, 4)
    toggleCorner.Parent = toggleButton
    
    local toggleIndicator = Instance.new("Frame")
    toggleIndicator.Size = UDim2.fromOffset(18, 18)
    toggleIndicator.Position = default and UDim2.new(0, 18, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)
    toggleIndicator.BackgroundColor3 = self:GetThemeProperty("Text")
    toggleIndicator.BorderSizePixel = 0
    toggleIndicator.Parent = toggleButton
    
    local indicatorCorner = Instance.new("UICorner")
    indicatorCorner.CornerRadius = UDim.new(0, 3)
    indicatorCorner.Parent = toggleIndicator
    
    local isToggled = default
    
    local function updateToggle(value)
        isToggled = value
        toggleButton.BackgroundColor3 = isToggled and self:GetThemeProperty("Accent") or self:GetThemeProperty("ToggleSlider")
        
        local tweenInfo = TweenInfo.new(
            0.2,
            Enum.EasingStyle.Quad,
            Enum.EasingDirection.Out
        )
        
        local tween = TweenService:Create(
            toggleIndicator,
            tweenInfo,
            { Position = isToggled and UDim2.new(0, 18, 0.5, -9) or UDim2.new(0, 2, 0.5, -9) }
        )
        tween:Play()
        
        self:SafeCallback(callback, isToggled)
    end
    
    toggleButton.MouseButton1Click:Connect(function()
        updateToggle(not isToggled)
    end)
    
    table.insert(tab.Elements, container)
    
    return {
        Container = container,
        ToggleButton = toggleButton,
        GetValue = function() return isToggled end,
        SetValue = updateToggle,
    }
end

function Fluent:AddSlider(tab, title, min, max, default, callback)
    if not tab then return nil end
    
    callback = callback or function() end
    default = math.clamp(default or min, min, max)
    
    local container = Instance.new("Frame")
    container.Name = title
    container.Size = UDim2.new(1, 0, 0, 50)
    container.BackgroundColor3 = self:GetThemeProperty("Element")
    container.BackgroundTransparency = self:GetThemeProperty("ElementTransparency")
    container.BorderSizePixel = 0
    container.Parent = tab.Container
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = container
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = self:GetThemeProperty("ElementBorder")
    stroke.Thickness = 1
    stroke.Parent = container
    
    local label = Instance.new("TextLabel")
    label.Text = title
    label.Size = UDim2.new(1, -20, 0, 18)
    label.Position = UDim2.fromOffset(10, 5)
    label.BackgroundTransparency = 1
    label.TextColor3 = self:GetThemeProperty("Text")
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container
    
    local valueLabel = Instance.new("TextLabel")
    valueLabel.Text = tostring(default)
    valueLabel.Size = UDim2.new(0, 50, 0, 18)
    valueLabel.Position = UDim2.new(1, -60, 0, 5)
    valueLabel.BackgroundTransparency = 1
    valueLabel.TextColor3 = self:GetThemeProperty("SubText")
    valueLabel.Font = Enum.Font.Gotham
    valueLabel.TextSize = 11
    valueLabel.Parent = container
    
    local sliderBar = Instance.new("Frame")
    sliderBar.Size = UDim2.new(1, -20, 0, 4)
    sliderBar.Position = UDim2.fromOffset(10, 28)
    sliderBar.BackgroundColor3 = self:GetThemeProperty("SliderRail")
    sliderBar.BorderSizePixel = 0
    sliderBar.Parent = container
    
    local sliderBarCorner = Instance.new("UICorner")
    sliderBarCorner.CornerRadius = UDim.new(1, 0)
    sliderBarCorner.Parent = sliderBar
    
    local sliderFill = Instance.new("Frame")
    sliderFill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    sliderFill.BackgroundColor3 = self:GetThemeProperty("Accent")
    sliderFill.BorderSizePixel = 0
    sliderFill.Parent = sliderBar
    
    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(1, 0)
    fillCorner.Parent = sliderFill
    
    local sliderButton = Instance.new("TextButton")
    sliderButton.Size = UDim2.fromOffset(12, 12)
    sliderButton.Position = UDim2.new((default - min) / (max - min), -6, 0.5, -6)
    sliderButton.BackgroundColor3 = self:GetThemeProperty("Accent")
    sliderButton.TextTransparency = 1
    sliderButton.BorderSizePixel = 0
    sliderButton.Parent = sliderFill
    
    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 6)
    buttonCorner.Parent = sliderButton
    
    local value = default
    local isDragging = false
    
    local function updateSlider(newValue)
        value = math.clamp(newValue, min, max)
        local percentage = (value - min) / (max - min)
        
        sliderFill.Size = UDim2.new(percentage, 0, 1, 0)
        sliderButton.Position = UDim2.new(percentage, -6, 0.5, -6)
        valueLabel.Text = tostring(self:Round(value, 1))
        
        self:SafeCallback(callback, value)
    end
    
    sliderButton.MouseButton1Down:Connect(function()
        isDragging = true
    end)
    
    UserInputService.InputEnded:Connect(function(input, gameProcessed)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            isDragging = false
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input, gameProcessed)
        if isDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local relativePos = Mouse.X - sliderBar.AbsolutePosition.X
            local newValue = min + ((relativePos / sliderBar.AbsoluteSize.X) * (max - min))
            updateSlider(newValue)
        end
    end)
    
    sliderBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local relativePos = Mouse.X - sliderBar.AbsolutePosition.X
            local newValue = min + ((relativePos / sliderBar.AbsoluteSize.X) * (max - min))
            updateSlider(newValue)
            isDragging = true
        end
    end)
    
    table.insert(tab.Elements, container)
    
    return {
        Container = container,
        GetValue = function() return value end,
        SetValue = updateSlider,
    }
end

function Fluent:AddTextbox(tab, title, placeholder, callback)
    if not tab then return nil end
    
    callback = callback or function() end
    
    local container = Instance.new("Frame")
    container.Name = title
    container.Size = UDim2.new(1, 0, 0, 36)
    container.BackgroundColor3 = self:GetThemeProperty("Input")
    container.BackgroundTransparency = 0.1
    container.BorderSizePixel = 0
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
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container
    
    local textBox = Instance.new("TextBox")
    textBox.PlaceholderText = placeholder or ""
    textBox.Size = UDim2.new(0.65, -10, 0, 24)
    textBox.Position = UDim2.new(0.32, 0, 0.5, -12)
    textBox.AnchorPoint = Vector2.new(0, 0.5)
    textBox.BackgroundColor3 = self:GetThemeProperty("Element")
    textBox.TextColor3 = self:GetThemeProperty("Text")
    textBox.PlaceholderColor3 = self:GetThemeProperty("SubText")
    textBox.Font = Enum.Font.Gotham
    textBox.TextSize = 12
    textBox.BorderSizePixel = 0
    textBox.Parent = container
    
    local textBoxCorner = Instance.new("UICorner")
    textBoxCorner.CornerRadius = UDim.new(0, 3)
    textBoxCorner.Parent = textBox
    
    local indicator = Instance.new("Frame")
    indicator.Size = UDim2.new(1, -4, 0, 2)
    indicator.Position = UDim2.new(0, 2, 1, -2)
    indicator.BackgroundColor3 = self:GetThemeProperty("InputIndicator")
    indicator.BackgroundTransparency = 1
    indicator.BorderSizePixel = 0
    indicator.Parent = textBox
    
    textBox.FocusLost:Connect(function()
        self:SafeCallback(callback, textBox.Text)
    end)
    
    textBox.Focused:Connect(function()
        indicator.BackgroundTransparency = 0
    end)
    
    textBox.FocusLost:Connect(function()
        indicator.BackgroundTransparency = 1
    end)
    
    table.insert(tab.Elements, container)
    
    return {
        Container = container,
        TextBox = textBox,
        GetValue = function() return textBox.Text end,
        SetValue = function(text) textBox.Text = text end,
    }
end

-- ============================================================================
-- NOTIFICAÇÕES
-- ============================================================================

function Fluent:Notify(config)
    config = config or {}
    
    local title = config.Title or "Notificação"
    local content = config.Content or ""
    local subContent = config.SubContent or ""
    local duration = config.Duration or 5
    
    local notification = Instance.new("Frame")
    notification.Name = "Notification"
    notification.Size = UDim2.fromOffset(300, 100)
    notification.Position = UDim2.new(1, -320, 1, -120)
    notification.BackgroundColor3 = self:GetThemeProperty("Dialog")
    notification.BorderSizePixel = 0
    notification.Parent = self.GUI or LocalPlayer.PlayerGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = notification
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = self:GetThemeProperty("DialogBorder")
    stroke.Thickness = 1
    stroke.Parent = notification
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Text = title
    titleLabel.Size = UDim2.new(1, -20, 0, 20)
    titleLabel.Position = UDim2.fromOffset(10, 10)
    titleLabel.BackgroundTransparency = 1
    titleLabel.TextColor3 = self:GetThemeProperty("Text")
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 14
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = notification
    
    local contentLabel = Instance.new("TextLabel")
    contentLabel.Text = content
    contentLabel.Size = UDim2.new(1, -20, 0, 30)
    contentLabel.Position = UDim2.fromOffset(10, 32)
    contentLabel.BackgroundTransparency = 1
    contentLabel.TextColor3 = self:GetThemeProperty("SubText")
    contentLabel.Font = Enum.Font.Gotham
    contentLabel.TextSize = 12
    contentLabel.TextXAlignment = Enum.TextXAlignment.Left
    contentLabel.TextWrapped = true
    contentLabel.Parent = notification
    
    local closeButton = Instance.new("TextButton")
    closeButton.Text = "×"
    closeButton.Size = UDim2.fromOffset(20, 20)
    closeButton.Position = UDim2.new(1, -25, 0, 5)
    closeButton.BackgroundTransparency = 1
    closeButton.TextColor3 = self:GetThemeProperty("Text")
    closeButton.TextSize = 18
    closeButton.Font = Enum.Font.GothamBold
    closeButton.Parent = notification
    
    closeButton.MouseButton1Click:Connect(function()
        notification:Destroy()
    end)
    
    if duration and duration > 0 then
        task.delay(duration, function()
            if notification.Parent then
                notification:Destroy()
            end
        end)
    end
    
    return notification
end

-- ============================================================================
-- DESTRUIÇÃO
-- ============================================================================

function Fluent:Destroy()
    if self.GUI then
        self.GUI:Destroy()
        self.GUI = nil
    end
    self.Window = nil
    self.Unloaded = true
end

-- ============================================================================
-- EXPORTAR
-- ============================================================================

if getgenv then
    getgenv().Fluent = Fluent
end

return Fluent
