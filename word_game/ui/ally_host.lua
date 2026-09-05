--[[
	word_game/ui/ally_host.lua - Speech host for the ally portrait (Aleisha).
]]

local Layout = require("word_game.ui.layout")
local CharacterSpeech = require("word_game.ui.character_speech")
local state = require("word_game.model.state")

local AllyHost = EaseNode:derive("AllyHost")

local BUBBLE_ALIGN = "tm"
local TAIL_ALONG = 0.82

function AllyHost:construct()
	EaseNode.construct(self, 0, 0, 0.28, 0.2)
	self.children = {}
	self.config = {}
	self.talking = false
	self.states.drag.can = false
	self.states.collide.can = false
	self.states.visible = false
	self:set_container(G.ROOM)
end

function AllyHost:apply_screen_position()
	local rect = Layout.ally_portrait_rect()
	self.T.w = 0.28
	self.T.h = 0.2
	self.T.x = rect.x + rect.w * 0.50 - self.T.w * 0.5
	self.T.y = rect.y + rect.h * 0.70 - self.T.h * 0.5
	self:hard_set_T(self.T.x, self.T.y, self.T.w, self.T.h)
	self:place_tail_on_portrait_edge()
end

function AllyHost:bubble_offset()
	local rect = Layout.ally_portrait_rect()
	local bubble = self.children.speech_bubble
	local bw = (bubble and bubble.T and bubble.T.w) or 2.4
	local host_cx = self.T.x + self.T.w * 0.5
	local wanted_x = rect.x + rect.w - TAIL_ALONG * bw
	return {
		x = wanted_x - host_cx + bw * 0.5,
		y = (rect.y + rect.h * 0.32) - self.T.y,
	}
end

function AllyHost:add_speech_bubble(text_key, loc_vars)
	if self.children.speech_bubble then
		self.children.speech_bubble:remove()
	end
	self.config.speech_bubble_align = {
		align = BUBBLE_ALIGN,
		offset = self:bubble_offset(),
		parent = self,
	}
	self.children.speech_bubble = LayoutView{
		definition = CharacterSpeech.bubble_definition(text_key, loc_vars),
		config = self.config.speech_bubble_align,
	}
	self.children.speech_bubble:set_role{
		role_type = "Minor",
		xy_bond = "Weak",
		r_bond = "Strong",
		major = self,
	}
	self.children.speech_bubble.states.visible = true
	self.children.speech_bubble.states.collide.can = false
	CharacterSpeech.pop_bubble(self.children.speech_bubble)
	self:place_tail_on_portrait_edge()
end

function AllyHost:place_tail_on_portrait_edge()
	local bubble = self.children.speech_bubble
	local root = bubble and bubble.root_node
	if not (root and root.config) then return end

	local offset = self:bubble_offset()
	local align = self.config.speech_bubble_align
	if align and align.offset then
		align.offset.x = offset.x
		align.offset.y = offset.y
	end
	if bubble.alignment and bubble.alignment.offset then
		bubble.alignment.offset.x = offset.x
		bubble.alignment.offset.y = offset.y
		if bubble.alignment.prev_offset then
			bubble.alignment.prev_offset.x = nil
		end
	end
	if bubble.align_to_major then
		bubble:align_to_major()
	end

	local rect = Layout.ally_portrait_rect()
	local edge_y = rect.y + rect.h * 0.5
	local by = (bubble.T and bubble.T.y) or 0
	local bh = (bubble.T and bubble.T.h) or 0
	root.config.speech_tail_along = TAIL_ALONG
	root.config.speech_tail_reach = math.max(0.2, edge_y - (by + bh))
end

function AllyHost:remove_speech_bubble()
	if self.children.speech_bubble then
		self.children.speech_bubble:remove()
		self.children.speech_bubble = nil
	end
end

function AllyHost:draw()
	if not self.states.visible then return end
	if self.children.speech_bubble then
		self.children.speech_bubble:draw()
	end
	track_hit_target(self)
end

function AllyHost.ensure()
	local rs = state.get()
	local want = rs and rs.stage3_cinematic and rs.stage3_ally_visible
	if G.STATE ~= G.STATES.TABLE_BOARD or not want then
		if G.ally_host then
			G.ally_host.states.visible = false
			G.ally_host:remove_speech_bubble()
		end
		return
	end
	if not G.ally_host then
		G.ally_host = AllyHost()
	end
	G.ally_host.states.visible = true
	G.ally_host:apply_screen_position()
end

function AllyHost.draw_pass()
	local host = G.ally_host
	if not host or not host.states.visible then return end
	love.graphics.push()
	host:translate_container()
	host:draw()
	love.graphics.pop()
end

function AllyHost.say(text_key, loc_vars)
	AllyHost.ensure()
	local host = G.ally_host
	if not host or not host.states.visible then return end
	host.talking = false
	host:remove_speech_bubble()
	host:add_speech_bubble(text_key, loc_vars)
	host:pulse(0.06, 0.04)
	host:apply_screen_position()
end

function AllyHost.clear()
	if G.ally_host then
		G.ally_host:remove_speech_bubble()
		G.ally_host.states.visible = false
	end
end

return AllyHost
