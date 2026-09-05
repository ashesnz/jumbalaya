--[[
	word_game/ui/guest_host.lua - Speech host for the guest portrait (Marco).
]]

local Layout = require("word_game.ui.layout")
local CharacterSpeech = require("word_game.ui.character_speech")
local state = require("word_game.model.state")

local GuestHost = EaseNode:derive("GuestHost")

local BUBBLE_ALIGN = "tm"
local TAIL_ALONG = 0.82

function GuestHost:construct()
	EaseNode.construct(self, 0, 0, 0.28, 0.2)
	self.children = {}
	self.config = {}
	self.talking = false
	self.states.drag.can = false
	self.states.collide.can = false
	self.states.visible = false
	self:set_container(G.ROOM)
end

function GuestHost:apply_screen_position()
	local rect = Layout.guest_portrait_rect()
	self.T.w = 0.28
	self.T.h = 0.2
	self.T.x = rect.x + rect.w * 0.50 - self.T.w * 0.5
	self.T.y = rect.y + rect.h * 0.70 - self.T.h * 0.5
	self:hard_set_T(self.T.x, self.T.y, self.T.w, self.T.h)
	self:place_tail_on_portrait_edge()
end

function GuestHost:bubble_offset()
	local rect = Layout.guest_portrait_rect()
	local bubble = self.children.speech_bubble
	local bw = (bubble and bubble.T and bubble.T.w) or 2.4
	local host_cx = self.T.x + self.T.w * 0.5
	local wanted_x = rect.x + rect.w - TAIL_ALONG * bw
	return {
		x = wanted_x - host_cx + bw * 0.5,
		y = (rect.y + rect.h * 0.32) - self.T.y,
	}
end

function GuestHost:add_speech_bubble(text_key, loc_vars)
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

function GuestHost:place_tail_on_portrait_edge()
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

	local rect = Layout.guest_portrait_rect()
	local edge_y = rect.y + rect.h * 0.5
	local by = (bubble.T and bubble.T.y) or 0
	local bh = (bubble.T and bubble.T.h) or 0
	root.config.speech_tail_along = TAIL_ALONG
	root.config.speech_tail_reach = math.max(0.2, edge_y - (by + bh))
end

function GuestHost:remove_speech_bubble()
	if self.children.speech_bubble then
		self.children.speech_bubble:remove()
		self.children.speech_bubble = nil
	end
end

function GuestHost:draw()
	if not self.states.visible then return end
	if self.children.speech_bubble then
		self.children.speech_bubble:draw()
	end
	track_hit_target(self)
end

function GuestHost.ensure()
	local rs = state.get()
	local want = rs and rs.stage3_cinematic and rs.stage3_guest_visible
	if G.STATE ~= G.STATES.TABLE_BOARD or not want then
		if G.guest_host then
			G.guest_host.states.visible = false
			G.guest_host:remove_speech_bubble()
		end
		return
	end
	if not G.guest_host then
		G.guest_host = GuestHost()
	end
	G.guest_host.states.visible = true
	G.guest_host:apply_screen_position()
end

function GuestHost.draw_pass()
	local host = G.guest_host
	if not host or not host.states.visible then return end
	love.graphics.push()
	host:translate_container()
	host:draw()
	love.graphics.pop()
end

function GuestHost.say(text_key, loc_vars)
	GuestHost.ensure()
	local host = G.guest_host
	if not host or not host.states.visible then return end
	host.talking = false
	host:remove_speech_bubble()
	host:add_speech_bubble(text_key, loc_vars)
	host:pulse(0.06, 0.04)
	host:apply_screen_position()
end

function GuestHost.clear()
	if G.guest_host then
		G.guest_host:remove_speech_bubble()
		G.guest_host.states.visible = false
	end
end

return GuestHost
