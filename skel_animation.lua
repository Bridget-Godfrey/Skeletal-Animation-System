-- skel_animation.lua

Simple_Animation = {}
Simple_Animation.__index = Simple_Animation

function Simple_Animation:new(name)
	local self = setmetatable({}, Simple_Animation)
	self.name = name or "UNNAMED_Simple_ANIMATION"
	self.keyframes = {}
	self.onFrame = 0
	self.numFrames = 0
	self.startTime = 0
	self.dur = 0
	self.endTime = 0
	return self
end

function Simple_Animation:nextKeyframe()
	self.onFrame = self.onFrame + 1
	if self.onFrame == 1 then 
		self.startTime = love.timer.getTime()
		self.endTime = self.startTime + self.dur
	end
	if self.onFrame > self.numFrames or self.endTime - love.timer.getTime() < -0.5 then
		return nil
	end
	return self.keyframes[self.onFrame]
end

function Simple_Animation:currentKeyframe()
	-- self.onFrame = self.onFrame + 1
	-- if self.onFrame == 1 then 
	-- 	self.startTime = love.timer.getTime()
	-- 	self.endTime = self.startTime + self.dur
	-- end
	-- if self.onFrame > self.numFrames then
	-- 	return nil
	-- end
	return self.keyframes[self.onFrame]
end

function Simple_Animation:addFrame(pose, duration, lock)
	self.numFrames = self.numFrames + 1
	self.dur = self.dur + duration
	local lockList = lock or {}
	table.insert(self.keyframes, {pose, duration, lockList})
end




Physics_Animation = {}
Physics_Animation.__index = Physics_Animation


local actions = {"MoveToPoint", "RotateToAngle", "ApplyForceToCOM", "SetPose", ""}


function Physics_Animation:new(name)
	local self = setmetatable({}, Simple_Animation)
	self.name = name or "UNNAMED_Simple_ANIMATION"
	self.keyframes = {}
	self.onFrame = 0
	self.numFrames = 0
	self.startTime = 0
	self.dur = 0
	self.endTime = 0




	return self
end