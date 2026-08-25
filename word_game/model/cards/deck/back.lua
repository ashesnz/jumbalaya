local Back = {}
local back_instance = {}
back_instance.__index = back_instance

function Back.new(center)
	return setmetatable({
		name = center.name,
		pos = center.pos,
		effect = {center = center},
	}, back_instance)
end

function back_instance:change_to(center)
	self.name = center.name
	self.pos = center.pos
	self.effect.center = center
end

function back_instance:apply_to_run()
end

function back_instance:save()
	return {name = self.name}
end

return Back