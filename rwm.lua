script_name('RW Manager')
script_author('akionka')
script_version('1.4')
script_version_number(5)

local sampev   = require 'lib.samp.events'
local encoding = require 'encoding'
local inicfg   = require 'inicfg'
local imgui    = require 'imgui'
local dlstatus = require 'moonloader'.download_status
encoding.default = 'cp1251'
u8 = encoding.UTF8

local updatelog = {
  {
    version = 'v 1.0 [20.01.2019]',
    update  = '\tI. Скрипт автоматически подключается к каналу после релога\n\tII. Также, появилось крутое меню /rwm'
  },
  {
    version = 'v 1.1 [26.01.2019]',
    update  = '\tI. Небольшие фиксы'
  },
  {
    version = 'v 1.2 [28.01.2019]',
    update  = '\tI. Пофиксил ссылку на Telegram'
  },
  {
    version = 'v 1.4 [13.03.2019]',
    update  = '\tI. Обновил систему обновлений\n\tII. Переехали с диалогов на ImGui\n\tIII. Вроде улучшил скрипт, но это не точно'
  }
}

local updatesavaliable = false

local ini = inicfg.load({
  settings = {
    connecttolast = true,
    savedata      = true,
    startmsg      = true,
    last          = nil
  },
}, "rwm")

local channels      = {}
local channel_buffs = {}

local main_window_state = imgui.ImBool(false)
local log_window_state  = imgui.ImBool(false)
local cat_window_state  = imgui.ImBool(false)
local startmsg          = imgui.ImBool(ini.settings.startmsg)
local connecttolast     = imgui.ImBool(ini.settings.connecttolast)
local text              = imgui.ImBuffer(256)
local selected          = 0
function imgui.OnDrawFrame()
  if main_window_state.v then
    imgui.Begin(thisScript().name.." v"..thisScript().version, main_window_state, imgui.WindowFlags.AlwaysAutoResize)
    if imgui.Button('Подключиться к последнему каналу') then
      if ini.settings.last ~= nil then
        sampSendChat("/rwave leave")
        sampSendChat("/rwave join "..ini.settings.last)
      else
        sampAddChatMessage(u8:decode("[RWM]: {FF0000}Error! {FFFFFF}Отсутствуют данные о послнедем подключенном канале"), -1)
      end
    end
    if imgui.Button('Менеджер каналов') then
      cat_window_state.v = not cat_window_state.v
    end
    if imgui.CollapsingHeader('Дополнительные настройки') then
      if imgui.Checkbox('Режим автоматического подключения к последнему каналу', connecttolast) then
        ini.settings.connecttolast = connecttolast.v
        inicfg.save(ini, 'rwm')
      end
      if imgui.Checkbox('Стартовое сообщение', startmsg) then
        ini.settings.startmsg = startmsg.v
        inicfg.save(ini, "rwm")
      end
      imgui.Separator()
      if updatesavaliable then
        if imgui.Button('Скачать обновление') then
          update('https://raw.githubusercontent.com/Akionka/rwm/master/rwm.lua')
          main_window_state.v = false
        end
      else
        if imgui.Button('Проверить обновление') then
          checkupdates('https://raw.githubusercontent.com/Akionka/rwm/master/version.json')
        end
      end
      if imgui.Button('Update log') then log_window_state.v = not log_window_state.v end
      imgui.Separator()
      if imgui.Button('Bug report [VK]') then os.execute('explorer "https://vk.com/akionka"') end
      if imgui.Button('Bug report [Telegram]') then os.execute('explorer "https://teleg.run/akionka"') end
    end
    imgui.End()
  end
  if log_window_state.v then
    local resX, resY = getScreenResolution()
    imgui.SetNextWindowPos(imgui.ImVec2(resX / 2, resY / 2), imgui.Cond.Always, imgui.ImVec2(0.5, 0.5))
    imgui.SetNextWindowSize(imgui.ImVec2(400, 250))
    imgui.Begin(thisScript().name.." v"..thisScript().version..' | Update log', log_window_state, imgui.WindowFlags.NoResize)
    for i, v in ipairs(updatelog) do
      imgui.Text(v['version'])
      imgui.Text(v['update'])
    end
    imgui.End()
  end
  if cat_window_state.v then
    local resX, resY = getScreenResolution()
    imgui.SetNextWindowPos(imgui.ImVec2(resX / 2, resY / 2), imgui.Cond.Always, imgui.ImVec2(0.5, 0.5))
    imgui.Begin(thisScript().name.." v"..thisScript().version..' | Менеджер каналов', cat_window_state, imgui.WindowFlags.AlwaysAutoResize)
    imgui.BeginGroup()
      imgui.BeginChild('Catalog', imgui.ImVec2(150, 150 - imgui.GetItemsLineHeightWithSpacing() - 1), true)
        for i, v in ipairs(channels) do
          if imgui.Selectable(v['name']..'##'..i, selected == i) then selected = i end
        end
      imgui.EndChild()
      imgui.BeginChild('New', imgui.ImVec2(150, 0), false)
        if imgui.Button('Добавить ещё') then
          local temptable = {name = imgui.ImBuffer(64), pass = imgui.ImBuffer(64), id = imgui.ImBuffer(64)}
          temptable['name'].v = 'Без названия'
          temptable['pass'].v = 'QWERTY'
          temptable['id'].v = '0'
          table.insert(channel_buffs, temptable)
          table.insert(channels, {name = 'Без названия', pass = 'QWERTY', id = '0'})
          selected = #channels
        end
      imgui.EndChild()
    imgui.EndGroup()
    imgui.SameLine()
    imgui.BeginChild('Settings', imgui.ImVec2(300, 150), true)
    if selected ~= 0 then
      imgui.InputText('ID##'..selected, channel_buffs[selected]['id'], imgui.InputTextFlags.CharsDecimal)
      imgui.InputText('Название##'..selected, channel_buffs[selected]['name'])
      imgui.InputText('Пароль##'..selected, channel_buffs[selected]['pass'], imgui.InputTextFlags.CharsNoBlank)
      if imgui.Button('Сохранить##'..selected) then
        local fpath = getWorkingDirectory()..'\\config\\rwm\\channels.json'
        if doesFileExist(fpath) then
          local f = io.open(fpath, 'w+')
          if f then
            channels[selected]['id'] = channel_buffs[selected]['id'].v
            channels[selected]['name'] = channel_buffs[selected]['name'].v
            channels[selected]['pass'] = channel_buffs[selected]['pass'].v
            f:write(encodeJson(channels)):close()
          else
            sampAddChatMessage(u8:decode('[RWM]: Что-то пошло не так :('), -1)
          end
        else
          sampAddChatMessage(u8:decode('[RWM]: Что-то пошло не так :('), -1)
        end
      end
      imgui.SameLine()
      if imgui.Button('Удалить##'..selected) then
        local fpath = getWorkingDirectory()..'\\config\\rwm\\channels.json'
        if doesFileExist(fpath) then
          local f = io.open(fpath, 'w+')
          if f then
            local temp = selected
            if selected == #channels then selected = selected - 1 end
            table.remove(channels, temp)
            table.remove(channel_buffs, temp)
            f:write(encodeJson(channels)):close()
          else
            sampAddChatMessage(u8:decode('[RWM]: Что-то пошло не так :('), -1)
          end
        else
          sampAddChatMessage(u8:decode('[RWM]: Что-то пошло не так :('), -1)
        end
      end
    end
    imgui.EndChild()
    imgui.End()
  end
end

function sampev.onServerMessage(color, text)
  if color == -1347440641 and text == u8:decode('{ffffff}С возвращением, вы успешно вошли в свой аккаунт.') and ini.settings.connecttolast and ini.settings.last ~= nil then
    sampSendChat(u8:decode('/rwave join '..ini.settings.last))
  end
end

function main()
  if not isSampfuncsLoaded() or not isSampLoaded() then return end
  while not isSampAvailable() do wait(0) end

  checkupdates('https://raw.githubusercontent.com/Akionka/rwm/master/version.json')

  if ini.settings.startmsg then
    sampAddChatMessage(u8:decode('[RWM]: Скрипт {00FF00}успешно{FFFFFF} загружен. Версия: {2980b9}'..thisScript().version..'{FFFFFF}.'), -1)
    sampAddChatMessage(u8:decode('[RWM]: Автор - {2980b9}Akionka{FFFFFF}. Выключить данное сообщение можно в {2980b9}/rwm{FFFFFF}.'), -1)
  end

  local fpath = getWorkingDirectory()..'\\config\\rwm\\channels.json'
  if doesFileExist(fpath) then
    local f = io.open(fpath, 'r')
    if f then
      channels = decodeJson(f:read('*a'))
      f:close()
      channel_buffs = {}
      for i, v in ipairs(channels) do
        local temptable = {name = imgui.ImBuffer(64), pass = imgui.ImBuffer(64), id = imgui.ImBuffer(64)}
        temptable['name'].v = v['name'] or 'Без имени'
        temptable['pass'].v = v['pass'] or 'QWERTY'
        temptable['id'].v   = tostring(v['id'])
        table.insert(channel_buffs, temptable)
      end
    end
  else
    sampAddChatMessage(u8:decode('[RWM]: Отсутствует файл со списком каналов по пути {2980b0}'..fpath..'{FFFFFF}.'), -1)
    sampAddChatMessage(u8:decode('[RWM]: Скрипт автоматически создаст шаблонный файл.'), -1)
    local f = io.open(fpath, 'w+')
    if f then
      f:write(encodeJson({{name = 'Без названия', id = 1, pass = 'QWERTY'}, {name = 'Без названия', id = 2, pass = 'QWERTY'}})):close()
      local temptable = {name = imgui.ImBuffer(64), pass = imgui.ImBuffer(64), id = imgui.ImBuffer(64)}
      channel_buffs = {}
      channels = {{name = 'Без названия', pass = 'QWERTY', id = '1'}, {name = 'Без названия', pass = 'QWERTY', id = '2'}}
      temptable['name'].v = 'Без названия'
      temptable['pass'].v = 'QWERTY'
      temptable['id'].v   = '1'
      table.insert(channel_buffs, temptable)
      temptable['id'].v   = '2'
      table.insert(channel_buffs, temptable)
    else
      sampAddChatMessage(u8:decode('[RWM]: Что-то пошло не так :('), -1)
    end
  end

  sampRegisterChatCommand('rwm', function()
    main_window_state.v = not main_window_state.v
  end)

  sampRegisterChatCommand('rwave', function(params)
    params = trim(params)
    local arg1, arg2, arg3 = params:match(u8:decode('(%w+)%s+(%w+)%s+(%w+)'))
    if arg1 == nil and arg2 == nil and arg3 == nil then
      local arg1, arg2  = params:match(u8:decode('(%w+)%s+(%w+)'))
      local arg3 = ""
    end
    if arg1 == 'join' then
      sampSendChat('/rwave '..arg1..' '..arg2..' '..arg3)
      ini.settings.last = arg2.." "..arg3
      inicfg.save(ini, 'rwm')
    else
      sampSendChat('/rwave '..params)
    end
  end)

  while true do
    wait(0)
    imgui.Process = main_window_state.v
  end
end

function trim(s)
    return (string.gsub(s, '^%s*(.-)%s*$', '%1'))
end

function checkupdates(json)
  local fpath = os.getenv('TEMP')..'\\'..thisScript().name..'-version.json'
  if doesFileExist(fpath) then os.remove(fpath) end
  downloadUrlToFile(json, fpath, function(_, status, _, _)
    if status == dlstatus.STATUSEX_ENDDOWNLOAD then
      if doesFileExist(fpath) then
        local f = io.open(fpath, 'r')
        if f then
          local info = decodeJson(f:read('*a'))
          local updateversion = info.version_num
          f:close()
          os.remove(fpath)
          if updateversion > thisScript().version_num then
            updatesavaliable = true
            sampAddChatMessage(u8:decode('[RWM]: Найдено объявление. Текущая версия: {2980b9}'..thisScript().version..'{FFFFFF}, новая версия: {2980b9}'..info.version..'{FFFFFF}.'), -1)
            return true
          else
            updatesavaliable = false
            sampAddChatMessage(u8:decode('[RWM]: У вас установлена самая свежая версия скрипта.'), -1)
          end
        else
          updatesavaliable = false
          sampAddChatMessage(u8:decode('[RWM]: Что-то пошло не так, упс. Попробуйте позже.'), -1)
        end
      end
    end
  end)
end

function update(url)
  downloadUrlToFile(url, thisScript().path, function(_, status1, _, _)
    if status1 == dlstatus.STATUS_ENDDOWNLOADDATA then
      sampAddChatMessage(u8:decode('[RWM]: Новая версия установлена! Чтобы скрипт обновился нужно либо перезайти в игру, либо ...'), -1)
      sampAddChatMessage(u8:decode('[RWM]: ... если у вас есть автоперезагрузка скриптов, то новая версия уже готова и снизу вы увидите приветственное сообщение.'), -1)
      sampAddChatMessage(u8:decode('[RWM]: Если что-то пошло не так, то сообщите мне об этом в VK или Telegram > {2980b0}vk.com/akionka teleg.run/akionka{FFFFFF}.'), -1)
      thisScript():reload()
    end
  end)
end
