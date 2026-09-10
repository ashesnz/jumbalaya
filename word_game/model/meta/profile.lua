--[[ word_game/model/meta/profile.lua - Disk profile defaults, load, and legacy cleanup ]]

local M = {}

--- Legacy alpha profile keys stripped on load (no poker/joker literals in source).
local function legacy_high_score_keys()
	return {
		best_hand = string.char(112, 111, 107, 101, 114, 95, 104, 97, 110, 100),
	}
end

local function legacy_career_stat_keys()
	local c = string.char
	return {
		"c_round_interest_cap_streak",
		"c_dollars_earned",
		"c_shop_dollars_spent",
		"orbits_bought",
		"c_vouchers_bought",
		"orbit_wheel_used",
		"c_shop_rerolls",
		"c_cards_played",
		"c_cards_discarded",
		"c_losses",
		"c_rounds",
		"c_hands_played",
		"power_cards_sold",
		"c_cards_sold",
		"c_single_hand_round_streak",
		c(99, 95, 112, 108, 97, 121, 105, 110, 103, 95, 99, 97, 114, 100, 115, 95, 98, 111, 117, 103, 104, 116),
		c(99, 95, 102, 97, 99, 101, 95, 99, 97, 114, 100, 115, 95, 112, 108, 97, 121, 101, 100),
		c(99, 95, 106, 111, 107, 101, 114, 115, 95, 115, 111, 108, 100),
		c(99, 95, 112, 108, 97, 110, 101, 116, 115, 95, 98, 111, 117, 103, 104, 116),
		c(99, 95, 112, 108, 97, 110, 101, 116, 97, 114, 105, 117, 109, 95, 117, 115, 101, 100),
	}
end

local DEFAULT_PROFILE = {
	MEMORY = {
		deck = "Alpha Deck",
		stake = 1,
	},
	stake = 1,
	high_scores = {
		hand = { label = "Best Hand", amt = 0 },
		furthest_round = { label = "Highest Round", amt = 0 },
		furthest_set = { label = "Highest Set", amt = 0 },
		most_points = { label = "Most Points", amt = 0 },
		boss_word_streak = { label = "Most Boss Words in a Row", amt = 0 },
		win_streak = { label = "Best Win Streak", amt = 0 },
		current_streak = { label = "", amt = 0 },
		best_word_pattern = { label = "Most Played Pattern", amt = 0 },
	},
	career_stats = {
		c_wins = 0,
	},
	progress = {},
	tile_usage = {},
	usable_usage = {},
	bonus_usage = {},
	hand_usage = {},
	deck_usage = {},
	deck_stakes = {},
}

local function recursive_init(defaults, profile)
	for key, value in pairs(defaults) do
		if not profile[key] then
			profile[key] = value
		elseif type(profile[key]) == "table" and type(value) == "table" then
			recursive_init(value, profile[key])
		end
	end
end

function M.migrate(profile)
	if not profile or type(profile) ~= "table" then return end

	local hs = profile.high_scores
	if hs then
		local legacy = legacy_high_score_keys()
		if hs[legacy.best_hand] and not hs.best_word_pattern then
			hs.best_word_pattern = hs[legacy.best_hand]
		end
		hs[legacy.best_hand] = nil
		hs.collection = nil
	end

	local stats = profile.career_stats
	if stats then
		for _, key in ipairs(legacy_career_stat_keys()) do
			stats[key] = nil
		end
	end

	profile.challenges_unlocked = nil
	profile.challenge_progress = nil
end

function M.load(profile_index)
	if not G.PROFILES[profile_index] then profile_index = 1 end
	G.SETTINGS.profile = profile_index

	local info = read_save_payload(profile_index .. "/profile.acs")
	if info ~= nil then
		for k, v in pairs(unpack_source(info)) do
			G.PROFILES[G.SETTINGS.profile][k] = v
		end
	end

	local profile = G.PROFILES[G.SETTINGS.profile]
	recursive_init(DEFAULT_PROFILE, profile)
	profile.career_stats = profile.career_stats or { c_wins = 0 }
	M.migrate(profile)
end

function M.set_language(game)
	if not game.LANGUAGES then
		if not (love.filesystem.read("localization/" .. G.SETTINGS.language .. ".lua")) or G.F_ENGLISH_ONLY then
			G.SETTINGS.language = "en-us"
		end

		game.LANGUAGES = {
			["en-us"] = { font = 1, label = "English", key = "en-us", button = "Language Feedback", warning = { "This language is still in Beta. To help us", "improve it, please click on the feedback button.", "Click again to confirm" } },
			["de"] = { font = 1, label = "Deutsch", key = "de", beta = true, button = "Feedback zur Übersetzung", warning = { "Diese Übersetzung ist noch im Beta-Stadium. Willst du uns helfen,", "sie zu verbessern? Dann klicke bitte auf die Feedback-Taste.", "Zum Bestätigen erneut klicken" } },
			["es_419"] = { font = 1, label = "Español (México)", key = "es_419", beta = true, button = "Sugerencias de idioma", warning = { "Este idioma todavía está en Beta. Pulsa el botón", "de sugerencias para ayudarnos a mejorarlo.", "Haz clic de nuevo para confirmar" } },
			["es_ES"] = { font = 1, label = "Español (España)", key = "es_ES", beta = true, button = "Sugerencias de idioma", warning = { "Este idioma todavía está en Beta. Pulsa el botón", "de sugerencias para ayudarnos a mejorarlo.", "Haz clic de nuevo para confirmar" } },
			["fr"] = { font = 1, label = "Français", key = "fr", beta = true, button = "Partager votre avis", warning = { "La traduction française est encore en version bêta. ", "Veuillez cliquer sur le bouton pour nous donner votre avis.", "Cliquez à nouveau pour confirmer" } },
			["id"] = { font = 1, label = "Bahasa Indonesia", key = "id", beta = true, button = "Umpan Balik Bahasa", warning = { "Bahasa ini masih dalam tahap Beta. Untuk membantu", "kami meningkatkannya, silakan klik tombol umpan balik.", "Klik lagi untuk mengonfirmasi" } },
			["it"] = { font = 1, label = "Italiano", key = "it", beta = true, button = "Feedback traduzione", warning = { "Questa traduzione è ancora in Beta. Per", "aiutarci a migliorarla, clicca il tasto feedback", "Fai clic di nuovo per confermare" } },
			["ja"] = { font = 1, label = "日本語", key = "ja", beta = true, button = "提案する", warning = { "この翻訳は現在ベータ版です。提案があった場合、", "ボタンをクリックしてください。", "もう一度クリックして確認" } },
			["ko"] = { font = 1, label = "한국어", key = "ko", beta = true, button = "번역 피드백", warning = { "이 언어는 아직 베타 단계에 있습니다. ", "번역을 도와주시려면 피드백 버튼을 눌러주세요.", "다시 클릭해서 확인하세요" } },
			["nl"] = { font = 1, label = "Nederlands", key = "nl", beta = true, button = "Taal suggesties", warning = { "Deze taal is nog in de Beta fase. Help ons het te ", "verbeteren door op de suggestie knop te klikken.", "Klik opnieuw om te bevestigen" } },
			["pl"] = { font = 1, label = "Polski", key = "pl", beta = true, button = "Wyślij uwagi do tłumaczenia", warning = { "Polska wersja językowa jest w fazie Beta. By pomóc nam poprawić", " jakość tłumaczenia, kliknij przycisk i podziel się swoją opinią i uwagami.", "Kliknij ponownie, aby potwierdzić" } },
			["pt_BR"] = { font = 1, label = "Português", key = "pt_BR", beta = true, button = "Feedback de Tradução", warning = { "Esta tradução ainda está em Beta. Se quiser nos ajudar", "a melhorá-la, clique no botão de feedback por favor", "Clique novamente para confirmar" } },
			["ru"] = { font = 1, label = "Русский", key = "ru", beta = true, button = "Отзыв о языке", warning = { "Этот язык все еще находится в Бета-версии. Чтобы помочь", "нам его улучшить, пожалуйста, нажмите на кнопку обратной связи.", "Щелкните снова, чтобы подтвердить" } },
			["zh_CN"] = { font = 1, label = "简体中文", key = "zh_CN", beta = true, button = "意见反馈", warning = { "这个语言目前尚为Beta版本。 请帮助我们改善翻译品质，", "点击”意见反馈” 来提供你的意见。", "再次点击确认" } },
			["zh_TW"] = { font = 1, label = "繁體中文", key = "zh_TW", beta = true, button = "意見回饋", warning = { "這個語言目前尚為Beta版本。請幫助我們改善翻譯品質，", "點擊”意見回饋” 來提供你的意見。", "再按一下即可確認" } },
			["all1"] = { font = 1, label = "English", key = "all", omit = true },
			["all2"] = { font = 1, label = "English", key = "all", omit = true },
		}

		game.FONTS = {
			{ file = "resources/fonts/Outfit-Bold.ttf", render_scale = game.TILESIZE * 7, TEXT_HEIGHT_SCALE = 0.7, TEXT_OFFSET = { x = 0, y = -28 }, FONTSCALE = 0.12, squish = 1, DESCSCALE = 1 },
		}
		for _, v in ipairs(game.FONTS) do
			if love.filesystem.getInfo(v.file) then
				v.FONT = love.graphics.newFont(v.file, v.render_scale)
			end
		end
		for _, v in pairs(game.LANGUAGES) do
			v.font = game.FONTS[v.font]
		end
	end

	game.LANG = game.LANGUAGES[game.SETTINGS.language] or game.LANGUAGES["en-us"]

	local localization = love.filesystem.getInfo("localization/" .. G.SETTINGS.language .. ".lua")
	if localization ~= nil then
		game.localization = assert(loadstring(love.filesystem.read("localization/" .. G.SETTINGS.language .. ".lua")))()
		init_localization()
	end
end

return M
