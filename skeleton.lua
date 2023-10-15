Skeleton = {}
Skeleton.__index = Skeleton

require("bone")

require("skel_animation")

function deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
        setmetatable(copy, deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

Joint = {}
Joint.__index = Joint


function Joint:new(body1, body2, x, y, angle)
    
    local joint = love.physics.newRevoluteJoint(body1.body, body2.body, x, y, x, y, false, angle or 0)
    joint:setMaxMotorTorque( 10 )

    local obj = {joint = joint}
    setmetatable(obj, Joint)
    return obj
end




function Skeleton:new(name, x, y, world)
	 local self = setmetatable({}, Skeleton)
	 self.name = name or "UNNAMED_SKELETON"
	 self.bones = {}
	 self.joints = {}
	 self.jointLookup = {}
	 self.status = 0
	 self.boneNames = {}
	 self.boneIDs = {}
	 self.bonesByName = {}
	 self.layers = {}
	 self.poses = {}


	 self.world = world or 1
	 self.y = y or 1
	 self.x = x or 1
	 -- (len, theta, name, parent, width, boneType, world, x, y)
	 self.root = Bone:new(20, 0, self.name .. "_ROOT", nil, 10, 0, self.world, self.x, self.y)
	 
	 self.boneNames[1] = self.name .. "_ROOT"
	 self.boneIDs[self.name .. "_ROOT"]  = 1
	 self.bonesByName[self.name .. "_ROOT"] = self.root
	 self.bones[1] = self.root
	 self.jointLookup[self.name .. "_ROOT"] = {}

	 self.currentAdditionTarget = self.root

	 return self

end


function Skeleton:addBone(name, len, angle, width, boneType, parent )

	local name = name or self.name .. "_BONE_" .. (#self.bones + 1)
	local len = len or 20
	local angle = angle or 0
	local parent = parent or self.currentAdditionTarget
	local width = width or 10
	local boneType = boneType or 1
	local newBone = Bone:new(len, angle, name, parent, width, boneType)

	self.jointLookup[name] = {}
	self.bones[#self.bones+1] = newBone
	self.boneNames[#self.bones] = name
	self.boneIDs[name] = #self.bones
	self.bonesByName[name] = newBone

	local jointX, jointY = parent.tipX - JOINT_OFFSET*0.5*math.cos(angle), parent.tipY - JOINT_OFFSET*0.5*math.cos(angle)
	local joint = Joint:new(parent, newBone, jointX, jointY, angle)  -- Or use jointX2, jointY2 if they should match
    -- print (parent.name .. "-o-" .. name .. "  theta: " .. angle)

    table.insert(self.joints, joint)
    table.insert(parent.children, newBone)
    self.jointLookup[name][parent.name] = joint
    self.jointLookup[parent.name][name] = joint
    self.currentAdditionTarget = newBone
    newBone.parentJoint = joint
    newBone.angle = (newBone.parent.angle + newBone.parentJoint.joint:getJointAngle( ))%(2*math.pi)
    newBone.targetAngle = newBone.angle


    self.animations = {}
    self.currentAnimation = nil
    self.queuedFrame = nil
    self.frameQueue = {}
    self.currentFrame = nil
    self.animated = false

    -- newBone:setAngle(angle)
    return newBone

end


function Skeleton:recomputePosition()
end

function Skeleton:setPosition(newX, newY)
	local newX = newX or self.x
	local newY = newY or self.y
	local deltaX = newX - self.x
	local deltaY = newY - self.y
	for _, bone in ipairs(self.bones) do
		bone.body:setPosition(bone.x + deltaX, bone.y + deltaY)
		bone.body:setLinearVelocity(0, 0)
    end
    self.x = newX
    self.y = newY
end

function Skeleton:update(dt)
	-- for _, child in ipairs(self.root.children) do
	-- 	-- compAngle(child)
	-- 	-- child:update(dt)
    -- end
    local inMotion = false
    for _, child in ipairs(self.bones) do
		child:update(dt)
		if child.isMoving and not child.isAnimationLocked then 
			inMotion = true
		end
    end

    if self.animated and not inMotion then
    	for _, b in ipairs(self.bones) do
    		b:animationUnlock()
    	end
    	self:setToKeyframe(self.currentAnimation:currentKeyframe())
    	self:transformToKeyframe(self.currentAnimation:nextKeyframe())
    elseif not inMotion then
    	for _, b in ipairs(self.bones) do
    		b:animationUnlock()
    	end
    end
end



function Skeleton:addPose (poseName, poseList)
	self.poses[poseName] = poseList
end


function Skeleton:addAnimation(a)

		self.animations[a.name] =  a
end


function Skeleton:beginAnimation(a_name)
	self.currentAnimation = self.animations[a_name]
	self.animated = true
	self.currentFrame = self.currentAnimation:nextKeyframe()
	self:transformToKeyframe(self.currentFrame)
end

function Skeleton:jumpToPose (poseName)

	if self.poses[poseName] then 
		print ("setting", self.name, "to pose", poseName)
		for i,v in ipairs(self.poses[poseName]) do
			
			self.bones[self.boneIDs[v[1]]]:setAngle(v[2])
		end
	end
	-- self:lock()
end

function Skeleton:lock()
	for i=2, #self.bones do
		self.bones[i]:lock()
	end
end

function Skeleton:unlock()
	for i=2, #self.bones do
		self.bones[i]:unlock()
	end
end

function Skeleton:alock()
	for i=2, #self.bones do
		self.bones[i]:animationLock()
	end
end

function Skeleton:aunlock()
	for i=2, #self.bones do
		self.bones[i]:animationUnlock()
	end
end


function Skeleton:transformToPose (poseName, duration)
	if self.poses[poseName] then 
		print ("setting", self.name, "to pose", poseName, "over", duration, "seconds")
		for i,v in ipairs(self.poses[poseName]) do
			
			self.bones[self.boneIDs[v[1]]]:setTargetAngle(v[2], duration)
		end
	end
end

function Skeleton:transformToKeyframe (keyframe)
	if keyframe == nil then
		self.animated = false
		self.currentAnimation.onFrame = 0

		self.currentAnimation = nil
		self.currentFrame = nil
		self:alock()
		-- self:lock()

		return 1
	end
	local dur = keyframe[2] or 1 

	-- self:unlock()
		
		for i,v in ipairs(keyframe[1]) do
			
			self.bonesByName[v[1]]:setTargetAngle(v[2], dur, true)
		end
		for i, v in ipairs(keyframe[3]) do
			self.bonesByName[v]:animationLock()
		end
end


function Skeleton:getPoseAsKeyframe()
	local kf = {}
	for i=2, #self.bones do
		table.insert(kf, {self.bones[i].name, self.bones[i].angle})
	end
	return kf
end


function Skeleton:setToKeyframe (kf)

	if kf then 
		-- print ("setting", self.name, "to pose", poseName)
		for i,v in ipairs(kf[1]) do
			self.bonesByName[v[1]]:animationUnlock()
			self.bonesByName[v[1]]:setAngle(v[2])
		end
	end
	-- self:lock()
end

function Skeleton:draw()
	for _, child in ipairs(self.bones) do
		love.graphics.setColor(0.8549019607843137, 0.7372549019607844, 0.5803921568627451)
		child:draw()
    end
end