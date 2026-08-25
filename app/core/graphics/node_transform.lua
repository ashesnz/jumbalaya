function push_node_transform(moveable, scale, rotate, offset, _)
	love.graphics.push()
	love.graphics.scale(G.TILESCALE * G.TILESIZE)
	local parallax = moveable.parallax_shift
		or (moveable.parent and moveable.parent.parallax_shift)
		or {x = 0, y = 0}
	love.graphics.translate(
		moveable.VT.x + moveable.VT.w / 2 + (offset and offset.x or 0) + parallax.x,
		moveable.VT.y + moveable.VT.h / 2 + (offset and offset.y or 0) + parallax.y)
	if moveable.VT.r ~= 0 or moveable.bounce or rotate then
		love.graphics.rotate(moveable.VT.r + (rotate or 0))
	end
	love.graphics.translate(
		-scale * moveable.VT.w * moveable.VT.scale / 2,
		-scale * moveable.VT.h * moveable.VT.scale / 2)
	love.graphics.scale(moveable.VT.scale * scale)
end
