--[[
	app/startup/profile.lua - Profile load and language setup.
]]

local DEAD_CAREER_STATS = {
	"c_round_interest_cap_streak",
	"c_dollars_earned",
	"c_shop_dollars_spent",
	"orbits_bought",
	"c_playing_cards_bought",
	"c_vouchers_bought",
	"orbit_wheel_used",
	"c_shop_rerolls",
	"c_cards_played",
	"c_cards_discarded",
	"c_losses",
	"c_rounds",
	"c_hands_played",
	"c_face_cards_played",
	"power_cards_sold",
	"c_cards_sold",
	"c_single_hand_round_streak",
	-- Legacy keys merged on load; strip if still present.
	"c_planets_bought",
	"c_planetarium_used",
	"c_jokers_sold",
}

local function trim_profile(profile)
	if not profile then return end
	local stats = profile.career_stats
	if stats then
		for _, key in ipairs(DEAD_CAREER_STATS) do
			stats[key] = nil
		end
	end
	local high_scores = profile.high_scores
	if high_scores then
		if high_scores.poker_hand and not high_scores.best_word_pattern then
			high_scores.best_word_pattern = high_scores.poker_hand
		end
		high_scores.collection = nil
		high_scores.poker_hand = nil
	end
	profile.challenges_unlocked = nil
	profile.challenge_progress = nil
end

function Game:load_profile(_profile)
	if not G.PROFILES[_profile] then _profile = 1 end
	G.SETTINGS.profile = _profile

	local info = read_save_payload(_profile..'/profile.acs')
	if info ~= nil then
		for k, v in pairs(unpack_source(info)) do
			G.PROFILES[G.SETTINGS.profile][k] = v
		end
	end

	local temp_profile = {
		MEMORY = {
			deck = 'Alpha Deck',
			stake = 1,
		},
		stake = 1,

		high_scores = {
			hand = {label = 'Best Hand', amt = 0},
			furthest_round = {label = 'Highest Round', amt = 0},
			furthest_set = {label = 'Highest Set', amt = 0},
			most_points = {label = 'Most Points', amt = 0},
			boss_word_streak = {label = 'Most Boss Words in a Row', amt = 0},
			win_streak = {label = 'Best Win Streak', amt = 0},
			current_streak = {label = '', amt = 0},
			best_word_pattern = {label = 'Most Played Pattern', amt = 0}
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

	local recursive_init
	recursive_init = function(t1, t2)
		for k, v in pairs(t1) do
			if not t2[k] then
				t2[k] = v
			elseif type(t2[k]) == 'table' and type(v) == 'table' then
				recursive_init(v, t2[k])
			end
		end
	end

	local profile = G.PROFILES[G.SETTINGS.profile]
	recursive_init(temp_profile, profile)

	-- Migrate legacy stat keys from older profile saves.
	local stats = profile.career_stats or {}
	profile.career_stats = stats
	local legacy_stats = {
		c_planets_bought = "orbits_bought",
		c_planetarium_used = "orbit_wheel_used",
		c_jokers_sold = "power_cards_sold",
	}
	for old_key, new_key in pairs(legacy_stats) do
		if stats[old_key] ~= nil then
			stats[new_key] = (stats[new_key] or 0) + stats[old_key]
			stats[old_key] = nil
		end
	end
	local high_scores = profile.high_scores
	if high_scores and high_scores.poker_hand and not high_scores.best_word_pattern then
		high_scores.best_word_pattern = high_scores.poker_hand
	end
	trim_profile(profile)
end

function Game:set_language()
	if not self.LANGUAGES then
		if not (love.filesystem.read('localization/'..G.SETTINGS.language..'.lua')) or G.F_ENGLISH_ONLY then
			G.SETTINGS.language = 'en-us'
		end

		self.LANGUAGES = {
			['en-us'] = {font = 1, label = "English", key = 'en-us', button = "Language Feedback", warning = {'This language is still in Beta. To help us','improve it, please click on the feedback button.', 'Click again to confirm'}},
			['de'] = {font = 1, label = "Deutsch", key = 'de', beta = true, button = "Feedback zur Übersetzung", warning = {'Diese Übersetzung ist noch im Beta-Stadium. Willst du uns helfen,','sie zu verbessern? Dann klicke bitte auf die Feedback-Taste.', "Zum Bestätigen erneut klicken"}},
			['es_419'] = {font = 1, label = "Español (México)", key = 'es_419', beta = true, button = "Sugerencias de idioma", warning = {'Este idioma todavía está en Beta. Pulsa el botón','de sugerencias para ayudarnos a mejorarlo.', "Haz clic de nuevo para confirmar"}},
			['es_ES'] = {font = 1, label = "Español (España)", key = 'es_ES', beta = true, button = "Sugerencias de idioma", warning = {'Este idioma todavía está en Beta. Pulsa el botón','de sugerencias para ayudarnos a mejorarlo.', "Haz clic de nuevo para confirmar"}},
			['fr'] = {font = 1, label = "Français", key = 'fr', beta = true, button = "Partager votre avis", warning = {'La traduction française est encore en version bêta. ','Veuillez cliquer sur le bouton pour nous donner votre avis.', "Cliquez à nouveau pour confirmer"}},
			['id'] = {font = 1, label = "Bahasa Indonesia", key = 'id', beta = true, button = "Umpan Balik Bahasa", warning = {'Bahasa ini masih dalam tahap Beta. Untuk membantu','kami meningkatkannya, silakan klik tombol umpan balik.', "Klik lagi untuk mengonfirmasi"}},
			['it'] = {font = 1, label = "Italiano", key = 'it', beta = true, button = "Feedback traduzione", warning = {'Questa traduzione è ancora in Beta. Per','aiutarci a migliorarla, clicca il tasto feedback', "Fai clic di nuovo per confermare"}},
			['ja'] = {font = 1, label = "日本語", key = 'ja', beta = true, button = "提案する", warning = {'この翻訳は現在ベータ版です。提案があった場合、','ボタンをクリックしてください。', "もう一度クリックして確認"}},
			['ko'] = {font = 1, label = "한국어", key = 'ko', beta = true, button = "번역 피드백", warning = {'이 언어는 아직 베타 단계에 있습니다. ','번역을 도와주시려면 피드백 버튼을 눌러주세요.', "다시 클릭해서 확인하세요"}},
			['nl'] = {font = 1, label = "Nederlands", key = 'nl', beta = true, button = "Taal suggesties", warning = {'Deze taal is nog in de Beta fase. Help ons het te ','verbeteren door op de suggestie knop te klikken.', "Klik opnieuw om te bevestigen"}},
			['pl'] = {font = 1, label = "Polski", key = 'pl', beta = true, button = "Wyślij uwagi do tłumaczenia", warning = {'Polska wersja językowa jest w fazie Beta. By pomóc nam poprawić',' jakość tłumaczenia, kliknij przycisk i podziel się swoją opinią i uwagami.', "Kliknij ponownie, aby potwierdzić"}},
			['pt_BR'] = {font = 1, label = "Português", key = 'pt_BR', beta = true, button = "Feedback de Tradução", warning = {'Esta tradução ainda está em Beta. Se quiser nos ajudar','a melhorá-la, clique no botão de feedback por favor', "Clique novamente para confirmar"}},
			['ru'] = {font = 1, label = "Русский", key = 'ru', beta = true, button = "Отзыв о языке", warning = {'Этот язык все еще находится в Бета-версии. Чтобы помочь','нам его улучшить, пожалуйста, нажмите на кнопку обратной связи.', "Щелкните снова, чтобы подтвердить"}},
			['zh_CN'] = {font = 1, label = "简体中文", key = 'zh_CN', beta = true, button = "意见反馈", warning = {'这个语言目前尚为Beta版本。 请帮助我们改善翻译品质，','点击”意见反馈” 来提供你的意见。', "再次点击确认"}},
			['zh_TW'] = {font = 1, label = "繁體中文", key = 'zh_TW', beta = true, button = "意見回饋", warning = {'這個語言目前尚為Beta版本。請幫助我們改善翻譯品質，','點擊”意見回饋” 來提供你的意見。', "再按一下即可確認"}},
			['all1'] = {font = 1, label = "English", key = 'all', omit = true},
			['all2'] = {font = 1, label = "English", key = 'all', omit = true},
		}

		self.FONTS = {
			{file = "resources/fonts/Outfit-Bold.ttf", render_scale = self.TILESIZE*7, TEXT_HEIGHT_SCALE = 0.7, TEXT_OFFSET = {x=0,y=-28}, FONTSCALE = 0.12, squish = 1, DESCSCALE = 1},
		}
		for _, v in ipairs(self.FONTS) do
			if love.filesystem.getInfo(v.file) then
				v.FONT = love.graphics.newFont(v.file, v.render_scale)
			end
		end
		for _, v in pairs(self.LANGUAGES) do
			v.font = self.FONTS[v.font]
		end
	end

	self.LANG = self.LANGUAGES[self.SETTINGS.language] or self.LANGUAGES['en-us']

	local localization = love.filesystem.getInfo('localization/'..G.SETTINGS.language..'.lua')
	if localization ~= nil then
		self.localization = assert(loadstring(love.filesystem.read('localization/'..G.SETTINGS.language..'.lua')))()
		init_localization()
	end
end
