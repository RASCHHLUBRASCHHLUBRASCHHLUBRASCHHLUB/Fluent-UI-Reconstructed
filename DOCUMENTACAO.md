# Fluent UI - Documentação Completa

## 📋 Índice
1. [Introdução](#introdução)
2. [Instalação](#instalação)
3. [Uso Básico](#uso-básico)
4. [Temas](#temas)
5. [Elementos](#elementos)
6. [Exemplos](#exemplos)
7. [API Completa](#api-completa)

---

## Introdução

**Fluent UI** é uma biblioteca de interface de usuário moderna e personalizável para Roblox Lua. Ela fornece uma forma fácil de criar interfaces visuais com suporte a múltiplos temas, gradientes personalizados e diversos elementos interativos.

### Características Principais
- ✨ Temas pré-configurados (Dark, Light, Rose, Aqua)
- 🎨 Suporte a temas personalizados com gradientes
- 🖱️ Elementos interativos (Botões, Toggles, Sliders, etc)
- 🎯 Sistema de abas organizado
- 📱 Interface responsiva
- 🔧 Fácil de personalizar

---

## Instalação

### Via GitHub
```lua
local FluentUI = require(game:GetService("ServerScriptService"):WaitForChild("FluentUI"))
```

### Via URL (LocalScript)
```lua
local FluentUI = loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/RASCHHLUBRASCHHLUBRASCHHLUBRASCHHLUB/Fluent-UI-Reconstructed/main/src/main.lua"))()
```

---

## Uso Básico

### Criar uma Janela

```lua
local FluentUI = require(script.Parent.FluentUI)

-- Criar janela principal
local window = FluentUI:CreateWindow({
    Title = "Minha Aplicação",
    SubTitle = "v1.0.0",
    Size = UDim2.fromOffset(800, 600),
    Theme = "Dark"
})

-- Agora você pode adicionar abas e elementos
```

### Adicionar uma Aba

```lua
local tab = window:AddTab("Principal", "lucide-home")
```

---

## Temas

### Temas Padrão Disponíveis

#### 1. Dark (Padrão)
Tema escuro com cores neutras.
```lua
window:SetTheme("Dark")
```

#### 2. Light
Tema claro, ideal para uso diurno.
```lua
window:SetTheme("Light")
```

#### 3. Rose
Tema com cores rosa/magenta.
```lua
window:SetTheme("Rose")
```

#### 4. Aqua
Tema com cores azul-petróleo.
```lua
window:SetTheme("Aqua")
```

### Criar Tema Personalizado

```lua
-- Tema personalizado básico
FluentUI.ThemeManager:AddCustomTheme("MeuTema", {
    Accent = Color3.fromRGB(255, 100, 50),          -- Cor de destaque (obrigatória)
    AcrylicMain = Color3.fromRGB(30, 30, 30),
    AcrylicBorder = Color3.fromRGB(80, 80, 80),
    TitleBarLine = Color3.fromRGB(100, 100, 100),
    Tab = Color3.fromRGB(100, 100, 100),
    Element = Color3.fromRGB(110, 110, 110),
    ElementBorder = Color3.fromRGB(50, 50, 50),
    Text = Color3.fromRGB(240, 240, 240),
    SubText = Color3.fromRGB(170, 170, 170),
    Dialog = Color3.fromRGB(40, 40, 40),
    Input = Color3.fromRGB(150, 150, 150),
})

window:SetTheme("MeuTema")
```

### Criar Tema com Gradiente

```lua
-- Tema gradiente
FluentUI.ThemeManager:AddGradientTheme(
    "Gradiente Sunset",
    Color3.fromRGB(255, 140, 0),      -- Cor inicial (laranja)
    Color3.fromRGB(255, 69, 0),       -- Cor final (vermelho-laranja)
    {
        Text = Color3.fromRGB(255, 255, 255),
        SubText = Color3.fromRGB(200, 200, 200),
        Element = Color3.fromRGB(100, 100, 100),
    }
)

window:SetTheme("Gradiente Sunset")
```

---

## Elementos

### 1. Botão

```lua
local tab = window:AddTab("Elementos")

window:AddButton(tab, "Clique em Mim", function()
    FluentUI:Notify("Sucesso", "Botão clicado!", 3)
end)
```

### 2. Toggle (Interruptor)

```lua
local toggle = window:AddToggle(tab, "Ativar Recurso", false, function(value)
    print("Toggle ativado:", value)
end)

-- Obter valor
print(toggle:GetValue())

-- Definir valor
toggle:SetValue(true)
```

### 3. Slider (Controle Deslizante)

```lua
local slider = window:AddSlider(
    tab,
    "Volume",
    0,      -- Mínimo
    100,    -- Máximo
    50,     -- Valor padrão
    function(value)
        print("Valor do slider:", value)
    end
)

-- Obter valor
print(slider:GetValue())

-- Definir valor
slider:SetValue(75)
```

### 4. Input (Campo de Texto)

```lua
local input = window:AddInput(
    tab,
    "Nome",
    "Digite seu nome aqui",
    function(value)
        print("Texto inserido:", value)
    end
)

-- Obter valor
print(input:GetValue())

-- Definir valor
input:SetValue("João")
```

### 5. Notificação

```lua
FluentUI:Notify("Título", "Mensagem de notificação", 5)
```

---

## Exemplos

### Exemplo 1: Aplicação Completa

```lua
local FluentUI = require(script.Parent.FluentUI)

-- Criar janela
local window = FluentUI:CreateWindow({
    Title = "Gerenciador",
    SubTitle = "v2.0.0",
    Size = UDim2.fromOffset(900, 700),
    Theme = "Dark"
})

-- Adicionar temas personalizados
FluentUI.ThemeManager:AddGradientTheme(
    "Neon Blue",
    Color3.fromRGB(0, 255, 255),
    Color3.fromRGB(0, 100, 200),
    { Text = Color3.fromRGB(255, 255, 255) }
)

-- Aba 1: Configurações
local configTab = window:AddTab("Configurações", "lucide-settings")

window:AddToggle(configTab, "Modo Escuro", true, function(value)
    window:SetTheme(value and "Dark" or "Light")
end)

window:AddSlider(configTab, "Brilho", 0, 100, 50, function(value)
    print("Brilho ajustado para: " .. value)
end)

-- Aba 2: Informações
local infoTab = window:AddTab("Informações", "lucide-home")

local nameInput = window:AddInput(infoTab, "Nome do Jogador", "Anônimo", function(value)
    FluentUI:Notify("Info", "Nome atualizado para: " .. value, 3)
end)

window:AddButton(infoTab, "Salvar Configurações", function()
    local name = nameInput:GetValue()
    FluentUI:Notify("Salvo", "Configurações de " .. name .. " salvas!", 4)
end)

-- Aba 3: Temas
local themesTab = window:AddTab("Temas", "lucide-palette")

window:AddButton(themesTab, "Tema Dark", function()
    window:SetTheme("Dark")
    FluentUI:Notify("Tema", "Alterado para Dark", 2)
end)

window:AddButton(themesTab, "Tema Light", function()
    window:SetTheme("Light")
    FluentUI:Notify("Tema", "Alterado para Light", 2)
end)

window:AddButton(themesTab, "Tema Rose", function()
    window:SetTheme("Rose")
    FluentUI:Notify("Tema", "Alterado para Rose", 2)
end)

window:AddButton(themesTab, "Tema Neon Blue", function()
    window:SetTheme("Neon Blue")
    FluentUI:Notify("Tema", "Alterado para Neon Blue", 2)
end)
```

### Exemplo 2: Sistema de Configurações

```lua
local FluentUI = require(script.Parent.FluentUI)

local window = FluentUI:CreateWindow({
    Title = "Sistema de Config",
    Theme = "Aqua"
})

-- Criar tema personalizado para este app
FluentUI.ThemeManager:AddCustomTheme("Config Theme", {
    Accent = Color3.fromRGB(100, 200, 150),
    Element = Color3.fromRGB(80, 80, 90),
    Text = Color3.fromRGB(255, 255, 255),
    SubText = Color3.fromRGB(150, 150, 150),
    Dialog = Color3.fromRGB(50, 50, 60),
})

window:SetTheme("Config Theme")

local mainTab = window:AddTab("Principal")

-- Configurações
local config = {
    autoAttack = false,
    volume = 50,
    playerName = "Player"
}

-- Criar controles
local autoAttackToggle = window:AddToggle(mainTab, "Auto Attack", config.autoAttack, function(value)
    config.autoAttack = value
end)

local volumeSlider = window:AddSlider(mainTab, "Volume de Som", 0, 100, config.volume, function(value)
    config.volume = value
end)

local nameInput = window:AddInput(mainTab, "Nome do Jogador", "Player", function(value)
    config.playerName = value
end)

-- Botão de salvar
window:AddButton(mainTab, "Salvar Config", function()
    FluentUI:Notify("Sucesso", "Configurações salvas!", 3)
    print("Config atual:", config)
end)

window:AddButton(mainTab, "Resetar Config", function()
    config.autoAttack = false
    config.volume = 50
    config.playerName = "Player"
    autoAttackToggle:SetValue(false)
    volumeSlider:SetValue(50)
    nameInput:SetValue("Player")
    FluentUI:Notify("Info", "Configurações resetadas", 3)
end)
```

### Exemplo 3: Tema Gradiente Avançado

```lua
local FluentUI = require(script.Parent.FluentUI)

-- Criar vários temas gradientes
FluentUI.ThemeManager:AddGradientTheme(
    "Sunset Paradise",
    Color3.fromRGB(255, 165, 0),
    Color3.fromRGB(220, 20, 60),
    {
        Text = Color3.fromRGB(255, 255, 255),
        Element = Color3.fromRGB(100, 60, 40),
    }
)

FluentUI.ThemeManager:AddGradientTheme(
    "Ocean Deep",
    Color3.fromRGB(0, 105, 148),
    Color3.fromRGB(70, 130, 180),
    {
        Text = Color3.fromRGB(255, 255, 255),
        Element = Color3.fromRGB(50, 80, 120),
    }
)

FluentUI.ThemeManager:AddGradientTheme(
    "Forest Green",
    Color3.fromRGB(34, 139, 34),
    Color3.fromRGB(0, 100, 0),
    {
        Text = Color3.fromRGB(255, 255, 255),
        Element = Color3.fromRGB(50, 100, 50),
    }
)

local window = FluentUI:CreateWindow({
    Title = "Tema Gradiente",
    Theme = "Sunset Paradise"
})

local tab = window:AddTab("Temas")

for themeName, _ in pairs(FluentUI.ThemeManager:GetAllThemes()) do
    window:AddButton(tab, "Tema: " .. themeName, function()
        window:SetTheme(themeName)
        FluentUI:Notify("Tema", "Alterado para: " .. themeName, 2)
    end)
end
```

---

## API Completa

### Window (Janela)

```lua
-- Criar janela
local window = FluentUI:CreateWindow({
    Title = string,           -- Título da janela (obrigatório)
    SubTitle = string,        -- Subtítulo (opcional)
    Size = UDim2,             -- Tamanho (padrão: 800x600)
    Theme = string            -- Tema inicial (padrão: "Dark")
})

-- Definir tema
window:SetTheme("NomeDotema")

-- Obter propriedade de tema
local cor = FluentUI:GetThemeProperty("Accent")

-- Adicionar aba
local tab = window:AddTab("Nome da Aba", "icone")

-- Destruir janela
window:Destroy()
```

### Elementos

```lua
-- Botão
window:AddButton(tab, "Texto", function()
    -- Callback
end)

-- Toggle
local toggle = window:AddToggle(tab, "Texto", true, function(value)
    -- Callback com boolean
end)
toggle:GetValue()      -- Retorna boolean
toggle:SetValue(true)  -- Define boolean

-- Slider
local slider = window:AddSlider(tab, "Texto", 0, 100, 50, function(value)
    -- Callback com número
end)
slider:GetValue()      -- Retorna número
slider:SetValue(75)    -- Define número

-- Input
local input = window:AddInput(tab, "Texto", "Placeholder", function(value)
    -- Callback com string
end)
input:GetValue()       -- Retorna string
input:SetValue("novo") -- Define string

-- Notificação
FluentUI:Notify("Título", "Mensagem", 5) -- duracao em segundos
```

### Temas

```lua
-- Adicionar tema personalizado
FluentUI.ThemeManager:AddCustomTheme("NomeTema", {
    Accent = Color3,
    Element = Color3,
    Text = Color3,
    -- ... outras propriedades
})

-- Adicionar tema com gradiente
FluentUI.ThemeManager:AddGradientTheme("NomeTema", colorStart, colorEnd, {
    -- propriedades customizadas
})

-- Obter tema
local tema = FluentUI.ThemeManager:GetTheme("NomeTema")

-- Obter todos os temas
local todos = FluentUI.ThemeManager:GetAllThemes()
```

### Funções Utilitárias

```lua
-- Executar callback com segurança
FluentUI:SafeCallback(funcao, ...)

-- Arredondar número
local rounded = FluentUI:Round(3.14159, 2) -- retorna 3.14

-- Obter ícone Lucide
local icon = FluentUI:GetIcon("home") -- retorna asset ID
```

---

## Cores Disponíveis no Tema

Cada tema possui as seguintes propriedades de cor:

| Propriedade | Descrição |
|---|---|
| `Accent` | Cor principal de destaque |
| `AcrylicMain` | Cor principal da interface |
| `AcrylicBorder` | Cor das bordas |
| `Text` | Cor do texto principal |
| `SubText` | Cor do texto secundário |
| `Element` | Cor dos elementos |
| `ElementBorder` | Cor das bordas dos elementos |
| `Tab` | Cor das abas |
| `Dialog` | Cor dos diálogos |
| `DialogHolder` | Cor do fundo dos diálogos |
| `Input` | Cor dos campos de entrada |

---

## 🐛 Resolução de Problemas

### Interface não aparece
```lua
-- Certifique-se de que a janela foi criada corretamente
if window then
    print("Janela criada com sucesso")
else
    print("Erro ao criar janela")
end
```

### Tema não muda
```lua
-- Verifique se o tema existe
window:SetTheme("Dark") -- Use um tema padrão ou custom existente
```

### Elemento não funciona
```lua
-- Use SafeCallback para debug
FluentUI:SafeCallback(function()
    -- seu código aqui
end)
```

---

## 📝 Licença

MIT License - Veja LICENSE para detalhes

---

## 🤝 Contribuições

Contribuições são bem-vindas! Por favor, faça um fork e crie um pull request.

---

**Última Atualização:** 2026-09-07
**Versão:** 2.0.0
