script_name('RW Manager')
script_author('akionka')
script_version('1.3')
script_version_number(4)
script_description([[{FFFFFF}Данный скрипт разработан Akionka с использованием кода от FYP'а, а также с использованием идей коммьюнити Trinity GTA.
В данный момент скрипт умеет:
 - В автоматическом режиме подключаться к последнему каналу
 - Управлять каналами. Более подробно Вы сможете ознакомиться с этим функционалом в {2980b0}/rwm{FFFFFF}.

Вероятно, скрипт имеет баги, поэтому прошу о всех найденных багах писать мне в личку (ссылки в {2980b0}/rwm{FFFFFF}).]])
local update_log = [[{2980b9}v1.0 [20.01.2019]{FFFFFF}
I. Скрипт автоматически подключается к каналу после релога.
II. Также, появилось крутое меню {2980b0}/rwm{FFFFFF}
{2980b9}v1.1 [26.01.2019]{FFFFFF}
I. Minor fixes
{2980b9}v1.2 [28.01.2019]{FFFFFF}
I. Пофиксил ссылку на телеграм]]
local sf = require 'sampfuncs'
local sampev = require 'lib.samp.events'
local encoding = require 'encoding'
local inicfg = require 'inicfg'
local cjson = require 'cjson'
local dlstatus = require('moonloader').download_status
encoding.default = 'cp1251'
u8 = encoding.UTF8

local ini = inicfg.load({
	settings = {
		connecttolast = true,
		savedata = true,
		showstarms = true,
		autoupdate = true,
		last = nil
	},
}, "\\rwm\\settings")

local ini2 = inicfg.load({}, "\\rwm\\channels")

local my_dialog = {
    {
		title = ini.settings.connecttolast and u8:decode("[RWM]: Режим автоматического подключения к последнему каналу — {00FF00}включен{FFFFFF}") or u8:decode("[RWM]: Режим автоматического подключения к последнему каналу — {FF0000}выключен{FFFFFF}"),
        onclick = function(menu, row)
					ini.settings.connecttolast = not ini.settings.connecttolast
					inicfg.save(ini, "\\rwm\\settings")
					updatemenu()
					return true
        end
    },
    {
		title = u8:decode("[RWM]: Подключиться к последнему каналу"),
        onclick = function(menu, row)
					if ini.settings.last ~= nil then sampSendChat("/rwave leave") sampSendChat("/rwave join "..ini.settings.last)
					else sampAddChatMessage(u8:decode("[RWM]: {FF0000}Error! {FFFFFF}Отсутствуют данные о послнедем подключенном канале"), -1) end
					updatemenu()
					return true
        end
    },
    {
		title = u8:decode("[RWM]: Менеджер каналов"),
		submenu = {
			title = u8:decode("{2980b9}Radio Wave Manager | Менеджер каналов"),
			onclick = function(menu, row, submenu)
				return false
			end,
			{
				-- Создать новый канал
			},
			{
				-- !!!Пустое место!!!
			},
		}
    },
    {
        title = u8:decode(" "),
        onclick = function(menu, row)
					return true
        end
    },
    {
        title = u8:decode("О скрипте"),
        onclick = function(menu, row)
					sampShowDialog(31411, u8:decode("{2980b9}Radio Wave Manager | О скрипте"), u8:decode(thisScript().description), u8:decode("Окей"), "", DIALOG_STYLE_MSGBOX)
					return false
        end
    },
    {
        title = u8:decode("Update log"),
        onclick = function(menu, row)
					sampShowDialog(31410, u8:decode("{2980b9}Radio Wave Manager | Update Log"), u8:decode(update_log), u8:decode("Окей"), "", DIALOG_STYLE_MSGBOX)
					return false
        end
    },
    {
        title = u8:decode("Доп. настройки"),
		submenu = {
			title = u8:decode("{2980b9}Radio Wave Manager | Доп. настройки"),
			onclick = function(menu, row, submenu)
				submenu[1].title = ini.settings.autoupdate and u8:decode("Автообновление — {00FF00}включено{FFFFFF}") or u8:decode("Автообновление — {FF0000}выключено{FFFFFF}")
				submenu[2].title = ini.settings.showstarms and u8:decode("Приветственное сообщение — {00FF00}включено{FFFFFF}") or u8:decode("Приветственное сообщение — {FF0000}выключено{FFFFFF}")
				submenu[3].title = u8:decode("Проверить обновления. Текущая версия: "..thisScript().version)
			end,
			{
				title = ini.settings.autoupdate and u8:decode("Автообновление — {00FF00}включено{FFFFFF}") or u8:decode("Автообновление — {FF0000}выключено{FFFFFF}"),
				onclick = function(menu, row)
					ini.settings.autoupdate = not ini.settings.autoupdate
					inicfg.save(ini, "\\rwm\\settings")
					menu[row].title = ini.settings.autoupdate and u8:decode("Автообновление — {00FF00}включено{FFFFFF}") or u8:decode("Автообновление — {FF0000}выключено{FFFFFF}")
					return true
				end,
			},
			{
				title = ini.settings.showstarms and u8:decode("Приветственное сообщение — {00FF00}включено{FFFFFF}") or u8:decode("Приветственное сообщение — {FF0000}выключено{FFFFFF}"),
				onclick = function(menu, row)
					ini.settings.showstarms = not ini.settings.showstarms
					inicfg.save(ini, "\\rwm\\settings")
					menu[row].title = ini.settings.showstarms and u8:decode("Приветственное сообщение — {00FF00}включено{FFFFFF}") or u8:decode("Приветственное сообщение — {FF0000}выключено{FFFFFF}")
					return true
				end,
			},
			{
				title = u8:decode("Проверить обновления. Текущая версия: {2980b9}"..thisScript().version.."{FFFFFF}"),
				onclick = function(menu, row)
					update()
					while updateinprogess ~= false do wait(100) end
					return false
				end,
			},
		}
    },
    {
        title = u8:decode(" "),
        onclick = function(menu, row)
						return true
        end
    },
    {
        title = u8:decode("Bug Report [VK]"),
        onclick = function(menu, row)
					os.execute('explorer "https://vk.com/id358870950"')
					return true
        end
    },
    {
        title = u8:decode("Bug Report [Telegram]"),
        onclick = function(menu, row)
					os.execute('explorer "https://teleg.run/akionka"')
					return true
        end
    },
}

function sampev.onServerMessage(color, text)
	if color == -1347440641 and text == u8:decode("{ffffff}С возвращением, вы успешно вошли в свой аккаунт.") and ini.settings.connecttolast and ini.settings.last ~= nil then
		sampSendChat(u8:decode("/rwave join "..ini.settings.last))
	end
end

function main()
	if not isSampfuncsLoaded() or not isSampLoaded() then return end
  while not isSampAvailable() do wait(0) end

	updatemenu()

	sampRegisterChatCommand("rwm", function() lua_thread.create(function() updatemenu() submenus_show(my_dialog, u8:decode("{2980b9}Radio Wave Manager")) end) end)
	sampRegisterChatCommand("rwave", function(params)
		params = trim(params)
		local arg1, arg2, arg3 = params:match(u8:decode("^(%w+)%s+(%w+)%s+(%w+)"))
		if arg1 == nil and arg2 == nil and arg3 == nil then
			local arg1, arg2  = params:match(u8:decode("^(%w+)%s+(%w+)"))
			local arg3 = ""
		end
		if arg1 == "join" then
			sampSendChat("/rwave "..arg1.." "..arg2.." "..arg3)
			ini.settings.last = arg2.." "..arg3
			inicfg.save(ini, "\\rwm\\settings")
		else
			sampSendChat("/rwave "..params)
		end
	end)

	if ini.settings.showstarms then
		sampAddChatMessage(u8:decode("[RWM]: Скрипт {00FF00}успешно{FFFFFF} загружен. Версия: {2980b9}"..thisScript().version.."{FFFFFF}."), -1)
		sampAddChatMessage(u8:decode("[RWM]: Автор - {2980b9}Akionka{FFFFFF}. Выключить данное сообщение можно в {2980b9}/rwm{FFFFFF}."), -1)
	end

	update()
	while updateinprogess ~= false do wait(0) end

	while true do
		wait(0)
		local result, button, list, input = sampHasDialogRespond(31410)
		if result then
			updatemenu()
			submenus_show(my_dialog, u8:decode("{2980b9}Radio Wave Manager"))
		end
		local result, button, list, input = sampHasDialogRespond(31411)
		if result then
			updatemenu()
			submenus_show(my_dialog, u8:decode("{2980b9}Radio Wave Manager"))
		end
	end
end

function updatemenu()
	my_dialog[1].title = ini.settings.connecttolast and u8:decode("[RWM]: Режим автоматического подключения к последнему каналу — {00FF00}включен{FFFFFF}") or u8:decode("[RWM]: Режим автоматического подключения к последнему каналу — {FF0000}выключен{FFFFFF}")
	my_dialog[2].title = u8:decode("[RWM]: Подключиться к последнему каналу")
	my_dialog[3].title = u8:decode("[RWM]: Менеджер каналов")
	my_dialog[3].submenu = {title = u8:decode("{2980b9}Radio Wave Manager | Менеджер каналов")}
	table.insert(my_dialog[3].submenu, {
		title = u8:decode("[RWM]: Добавить новый канал"),
		onclick = function()
					sampShowDialog(31412, u8:decode("{2980b9}Radio Wave Manager | Добавление нового канала"), u8:decode("{FFFFFF}Если вы хотите добавить новый канал в свой список, то введите ниже его ID и пароль через пробел.\n\nПример: {2980b9}123 QWERTY{FFFFFF}.\n\nЕсли у канала нет пароля, то ничего введите просто ID канала."), u8:decode("Готово"), u8:decode("Назад"), DIALOG_STYLE_INPUT)
					local dialog_create = false
					while not dialog_create do
						wait(0)
						local result, button, list, input = sampHasDialogRespond(31412)
						if result then
							if button == 1 then
								local id, pass = trim(input):match(u8:decode("(%d+) (%S+)"))
								if id ~= nil then
									table.insert(ini2, {id = id, pass = pass, name = "Без имени"})
									inicfg.save(ini2, "\\rwm\\channels")
									dialog_create = true
									updatemenu()
									submenus_show(my_dialog, u8:decode("{2980b9}Radio Wave Manager"))
								elseif trim(input):match(u8:decode("(%d+)")) ~= nil then
									table.insert(ini2, {id = trim(input):match(u8:decode("(%d+)")), pass = " ", name = "Без имени"})
									inicfg.save(ini2, "\\rwm\\channels")
									dialog_create = true
									updatemenu()
									submenus_show(my_dialog, u8:decode("{2980b9}Radio Wave Manager"))
								else
									sampShowDialog(31412, u8:decode("{2980b9}Radio Wave Manager | Добавление нового канала"), u8:decode("{FFFFFF}Если вы хотите добавить новый канал в свой список, то введите ниже его ID и пароль через пробел.\n\nПример: {2980b9}123 QWERTY{FFFFFF}.\n\nЕсли у канала нет пароля, то ничего введите просто ID канала."), u8:decode("Готово"), u8:decode("Назад"), DIALOG_STYLE_INPUT)
								end
							else
								submenus_show(my_dialog, u8:decode("{2980b9}Radio Wave Manager"))
							end
						end
					end
					return false
				end
		})
	table.insert(my_dialog[3].submenu, {
			title = u8:decode(" "),
			onclick = function()
				return true
			end
		})
	table.foreach(ini2, function(key, val)
		table.insert(my_dialog[3].submenu, {
			title = u8:decode("[RWM]: {2980b9}"..val["name"].." {FFFFFF}[{2980b9}"..val["id"].."{FFFFFF}]"),
			submenu = {
				title = u8:decode("{2980b9}Radio Wave Manager | {2980b9}"..val["name"].." {FFFFFF}[{2980b9}"..val["id"].."{FFFFFF}]"),
				{
					title = u8:decode("{FFFFFF}Подключиться"),
					onclick = function(menu, row)
						sampSendChat("/rwave leave")
						sampSendChat("/rwave join "..val["id"].." "..val["pass"])
						return true
					end,
				},
				{
					title = u8:decode("{FFFFFF}Переименовать"),
					onclick = function(menu, row)
						sampShowDialog(31412, u8:decode("{2980b9}Radio Wave Manager | Переименование"), u8:decode("{FFFFFF}Если вы хотите переименовать канал {2980b9}"..val["name"].."{FFFFFF}, то введите ниже его новое название.\n\nПример: {2980b9}Мой крутой канал!{FFFFFF}."), u8:decode("Готово"), u8:decode("Назад"), DIALOG_STYLE_INPUT)
						local dialog_rename = false
						while not dialog_rename do
							wait(0)
							local result, button, list, input = sampHasDialogRespond(31412)
							if result then
								if button == 1 and #trim(input) ~= 0 then
									ini2[key]["name"] = input
									inicfg.save(ini2, "\\rwm\\channels")
									my_dialog[3].submenu[key+2].title = u8:decode(u8:decode("[RWM]: {2980b9}"..trim(input).." {FFFFFF}[{2980b9}"..val["id"].."{FFFFFF}]"))
									dialog_rename = true
									updatemenu()
									submenus_show(my_dialog, u8:decode("{2980b9}Radio Wave Manager"))
								else
									dialog_rename = true
									updatemenu()
									submenus_show(my_dialog, u8:decode("{2980b9}Radio Wave Manager"))
								end
							end
						end
						return false
					end,
				},
				{
					title = u8:decode("{FFFFFF}Сменить пароль"),
					onclick = function(menu, row)
						sampShowDialog(31412, u8:decode("{2980b9}Radio Wave Manager | Смена пароля"), u8:decode("{FFFFFF}Если вы хотите сменить пароль к каналу {2980b9}"..val["name"].."{FFFFFF}, то введите ниже его ниже.\n\nПример: {2980b9}mybrandnewpassword{FFFFFF}."), u8:decode("Готово"), u8:decode("Назад"), DIALOG_STYLE_INPUT)
						local dialog_chngpass = false
						while not dialog_chngpass do
							wait(0)
							local result, button, list, input = sampHasDialogRespond(31412)
							if result then
								if button == 1 and #trim(input) ~= 0 then
									if trim(input):find("%s") == nil then
										ini2[key]["pass"] = trim(input)
										inicfg.save(ini2, "\\rwm\\channels")
										sampAddChatMessage(u8:decode("[RWM]: Вы успешно изменили пароль к каналу {2980b9}"..val["name"].."{FFFFFF} на {2980b9}"..trim(input).."{FFFFFF}."), -1)
										dialog_chngpass = true
										updatemenu()
										submenus_show(my_dialog, u8:decode("{2980b9}Radio Wave Manager"))
									else
										sampAddChatMessage(u8:decode("[RWM]: {FF0000}Error! {FFFFFF}Пароль не может содержать пробелы."), -1)
										dialog_chngpass = true
										updatemenu()
										submenus_show(my_dialog, u8:decode("{2980b9}Radio Wave Manager"))
									end
								else
									dialog_chngpass = true
									updatemenu()
									submenus_show(my_dialog, u8:decode("{2980b9}Radio Wave Manager"))
								end
							end
						end
						return false
					end,
				},
				{
					title = u8:decode("{FF0000}Удалить"),
					onclick = function(menu, row)
						sampShowDialog(31412, u8:decode("{2980b9}Radio Wave Manager | Удаление"), u8:decode("{FFFFFF}Вы действительно хотите удалить канал {2980b9}"..val["name"].."{FFFFFF}?"), u8:decode("Да"), u8:decode("Нет"), DIALOG_STYLE_MSGBOX)
						local dialog_del = false
						while not dialog_del do
							wait(0)
							local result, button, list, input = sampHasDialogRespond(31412)
							if result then
								if button == 1 then
									table.remove(ini2, key)
									os.remove(getWorkingDirectory().."\\config\\rwm\\channels.ini")
									inicfg.save(ini2, "\\rwm\\channels")
									table.remove(my_dialog[3].submenu, key+2)
									dialog_del = true
									updatemenu()
									submenus_show(my_dialog, u8:decode("{2980b9}Radio Wave Manager"))
								else
									dialog_del = true
									updatemenu()
									submenus_show(my_dialog, u8:decode("{2980b9}Radio Wave Manager"))
								end
							end
						end
						return false
					end,
				},
			},
		})
	end)
end
function trim(s)
    return (string.gsub(s, "^%s*(.-)%s*$", "%1"))
end
function update()
	local fpath = os.getenv('TEMP') .. '\\RWM-version.json'
	downloadUrlToFile('https://raw.githubusercontent.com/Akionka/rwm/master/version.json', fpath, function(id, status, p1, p2)
		if status == dlstatus.STATUS_ENDDOWNLOADDATA then
			local f = io.open(fpath, 'r')
			if f then
				local info = decodeJson(f:read('*a'))
				if info and info.version then
					version = info.version
					version_num = info.version_num
					if version_num > thisScript().version_num then
						sampAddChatMessage(u8:decode("[RWM]: Найдено объявление. Текущая версия: {2980b9}"..thisScript().version.."{FFFFFF}, новая версия: {2980b9}"..version.."{FFFFFF}. Начинаю закачку."), -1)
						lua_thread.create(goupdate)
						updateinprogess = false
					else
						sampAddChatMessage(u8:decode("[RWM]: У вас установлена самая свежая версия скрипта."), -1)
						updateinprogess = false
					end
				end
			end
		end
	end)
end
function goupdate()
	wait(300)
	downloadUrlToFile("https://raw.githubusercontent.com/Akionka/rwm/master/rwm.lua", thisScript().path, function(id3, status1, p13, p23)
		if status1 == dlstatus.STATUS_ENDDOWNLOADDATA then
			sampAddChatMessage(u8:decode('[RWM]: Новая версия установлена! Чтобы скрипт обновился нужно либо перезайти в игру, либо ...'), -1)
			sampAddChatMessage(u8:decode('[RWM]: ... если у вас есть автоперезагрузка скриптов, то новая версия уже готова и снизу вы увидите приветственное сообщение.'), -1)
			sampAddChatMessage(u8:decode('[RWM]: Если что-то пошло не так, то сообщите мне об этом в VK или Telegram > {2980b0}vk.com/akionka teleg.run/akionka{FFFFFF}.'), -1)
			updateinprogess = false
		end
	end)
end
--Спасибо FYP за енту крутую хуету:)
function submenus_show(menu, caption, select_button, close_button, back_button)
    select_button, close_button, back_button = select_button or u8:decode("Выбрать"), close_button or u8:decode("Закрыть"), back_button or u8:decode("Назад")
    prev_menus = {}
    function display(menu, id, caption)
        local string_list = {}
        for i, v in ipairs(menu) do
            table.insert(string_list, type(v.submenu) == "table" and v.title .. "  >>" or v.title)
        end
        sampShowDialog(id, caption, table.concat(string_list, "\n"), select_button, (#prev_menus > 0) and back_button or close_button, sf.DIALOG_STYLE_LIST)
        repeat
            wait(0)
            local result, button, list = sampHasDialogRespond(id)
            if result then
                if button == 1 and list ~= -1 then
                    local item = menu[list + 1]
                    if type(item.submenu) == "table" then -- submenu
                        table.insert(prev_menus, {menu = menu, caption = caption})
                        if type(item.onclick) == "function" then
                            item.onclick(menu, list + 1, item.submenu)
                        end
                        return display(item.submenu, id + 1, item.submenu.title and item.submenu.title or item.title)
                    elseif type(item.onclick) == "function" then
                        local result = item.onclick(menu, list + 1)
                        if not result then return result end
                        return display(menu, id, caption)
                    end
                else -- if button == 0
                    if #prev_menus > 0 then
                        local prev_menu = prev_menus[#prev_menus]
                        prev_menus[#prev_menus] = nil
                        return display(prev_menu.menu, id - 1, prev_menu.caption)
                    end
                    return false
                end
            end
        until result
    end
    return display(menu, 31337, caption or menu.title)
end
