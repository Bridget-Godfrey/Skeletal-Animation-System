Bone = {}
Bone.__index = Bone
local BONE_ENUM_NORMAL = 1
local BONE_ENUM_ROOT = 0
local BONE_ENUM_STATIC = 2
local BONE_ENUM_OTHER = 3

JOINT_OFFSET = 0
ROTATION_THRESHOLD = 1/60
LOCK_TRHESHOLD = 1/60

local function shortestRotationDirection(current_angle, target_angle)
    -- Normalize angles to a 0 to 2π range
    current_angle = current_angle % (2 * math.pi)
    target_angle = target_angle % (2 * math.pi)

    -- Calculate the differences
    local diff = target_angle - current_angle
    local diff_mod = (diff + math.pi) % (2 * math.pi) - math.pi
    -- print (math.floor(current_angle/math.pi*100)/100, math.floor(target_angle/math.pi*100)/100, diff_mod)

    return diff_mod
end

local function sign(number)
    if number >= 0 then return 1
    else 
        return -1
    end
end


function Bone:new(length, angle, name, parent, width, boneType, world, x, y)
    local self = setmetatable({}, Bone)

    self.parent = parent or nil
    self.isRoot = false
    if self.parent == nil then
        self.isRoot = true

    end

    self.angle = angle or 0
    self.x = x or parent.tipX - JOINT_OFFSET*math.cos(parent.angle)
    self.y = y or parent.tipY - JOINT_OFFSET*math.sin(parent.angle)
    self.world = world or self.parent.world
    self.refAngle = 0
    self.targetAngle = angle or self.parent.angle or 0
    self.width = width or self.parent.width or 10
    self.length = length or 10
    self.boneType = boneType or BONE_ENUM_NORMAL
    if self.isRoot then
        self.boneType = BONE_ENUM_ROOT
        self.width = 20
    end

    local physType = "dynamic"
    if self.boneType == BONE_ENUM_ROOT then
        physType = "static"
        self.refAngle = angle or 0
    end

    self.name = name or "DEFAULT_NAME"
    self.layer = 0
    self.status = 0
    self.joints = {}
    self.children = {}
    
    self.tipX = self.x + self.length * math.cos(self.angle)
    self.tipY = self.y + self.length * math.sin(self.angle)
    self.comX, self.comY = self.x  + ((self.length/2) * math.cos(self.angle)), self.y  + ((self.length/2) * math.sin(self.angle))
    self.body = love.physics.newBody(self.world, self.x  + ((self.length/2) * math.cos(self.angle))  , self.y + ((self.length/2) * math.sin(self.angle)), physType)
    self.body:setSleepingAllowed(true)
    self.body:setLinearDamping(15)
    self.body:setAngularDamping(15)
    
    
    self.shape = love.physics.newRectangleShape(0, 0, self.length, self.width)  -- Assuming a simple rectangle shape for visualization
    self.body:setAngle(self.angle)
    self.fixture = love.physics.newFixture(self.body, self.shape)
    self.fixture:setGroupIndex(-5)
    if self.boneType == BONE_ENUM_STATIC then 
        self.body:setLinearDamping(1500)
        self.body:setAngularDamping(1500)
        self.fixture:setDensity(30)
    end
    self.body:resetMassData()
    if self.boneType == BONE_ENUM_STATIC or self.boneType == BONE_ENUM_ROOT then
        self.body:setFixedRotation(true)
    end
    -- print(self.name, self.x, self.y,  "Density:", self.fixture:getDensity( ))

    self.rotationSpeed = 1
    self.lockDiff = 0
    self.isFrozen, self.isLocked, self.aLockMode, self.aLockStatus, self.isMoving, self.isAnimationLocked = false
    self.oldRotationStatus = self.body:isFixedRotation()


    self.debug_r_dir = 0

    self.parentJoint = {}


    return self
end


function Bone:getX()
    return self.x
end
 
function Bone:getY()
    return self.y
end

function Bone:freeze()
    if not self.isFrozen then
        self.isFrozen = true
        self.oldRotationStatus = self.body:isFixedRotation()
        if self.boneType == BONE_ENUM_NORMAL then
            self.body:setFixedRotation(true)
        end
            
        
    end
end

function Bone:lock()
    self.lockDiff = self.parent.angle - self.angle
    self.isLocked = true
    -- self.body:setFixedRotation(true)
    -- self.body:setActive(false)
end
function Bone:unlock()
    self.isLocked = false
    -- self.body:setActive(true)
end


function Bone:animationLock()
    self.lockDiff = self.parent.angle - self.angle
    self.isAnimationLocked = true
    -- self.body:setFixedRotation(true)
    -- self.body:setActive(false)
end
function Bone:animationUnlock()
    self.isAnimationLocked = false
    self.aLockMode = false
    self.aLockStatus = false
    -- self.body:setActive(true)
end

function Bone:setTargetAngle(theta, duration, animation)
    local duration = duration or 1
    self.aLockMode = animation or false
    self.aLockStatus = false
    -- print("setting", self.name, "to angle", theta, "over", duration, "seconds")
    if not self.isLocked and not self.isFrozen and not self.isRoot and self.boneType == 1 then
        local angleDelta = math.abs(theta - self.angle)
        self.targetAngle = theta

        self.isMoving = true
        self.rotationSpeed = angleDelta/duration
    end
end

function Bone:setAngle(theta)
    self.body:setAngle(theta)
    self.angle = theta
    self.targetAngle = theta
    self.x = (self.parent.tipX)  + ((self.length/2) * math.cos(self.angle))
    self.y = (self.parent.tipY) + ((self.length/2) * math.sin(self.angle))
    self.body:setPosition(self.x, self.y)
    self.tipX = self.x + math.cos(self.angle)*(0.5*self.length)
    self.tipY = self.y + math.sin(self.angle)*(0.5*self.length)

    for _,c in ipairs(self.children) do
            
            c:setAngle(c.angle)

            self.body:setAngularVelocity(0)
            self.body:setLinearVelocity(0, 0)
            self.parent.body:setAngularVelocity(0)
            self.parent.body:setLinearVelocity(0, 0)

        end
end


function Bone:unfreeze()
    if self.isFrozen then
        self.isFrozen = false
        if self.boneType == BONE_ENUM_NORMAL then
            self.body:setFixedRotation(self.oldRotationStatus)
        end
    end
end


function Bone:update(dt)
    if not self.isRoot then
        self.angle = self.body:getAngle()%(2*math.pi)
    end
    if self.isLocked or self.isAnimationLocked then
        self.isMoving = true
        self.targetAngle = self.parent.angle - self.lockDiff
        -- self:setAngle(self.parent.angle - self.lockDiff)
    end
    self.x = self.body:getX()
    self.y = self.body:getY()
    self.tipX = self.x + math.cos(self.angle)*(0.5*self.length)
    self.tipY = self.y + math.sin(self.angle)*(0.5*self.length)
    self.comX, self.comY = self.body:getPosition()
    if not self.isRoot and self.isMoving then
        local thr = ROTATION_THRESHOLD
        local rspd = self.rotationSpeed
        if self.isLocked or self.isAnimationLocked then
            thr = LOCK_TRHESHOLD
            rspd = 1*dt
        end
        thr = thr/dt

        if math.abs (math.deg(self.angle) - math.deg(self.targetAngle)) >= thr then
            local r_dir = sign(shortestRotationDirection(self.angle, self.targetAngle))
            -- if math.abs (math.deg(self.angle) - math.deg(self.targetAngle)) > ROTATION_THRESHOLD*2 then rspd = self.rotationSpeed*2 end
            -- if math.abs (math.deg(self.angle) - math.deg(self.targetAngle)) < ROTATION_THRESHOLD*2 then rspd = self.rotationSpeed/2 end
            if not self.isLocked and self.debug_r_dir ~= r_dir then
                self.rotationSpeed = self.rotationSpeed/2
                rspd = self.rotationSpeed
            end
            self.parentJoint.joint:setMotorSpeed(r_dir*rspd)
            self.debug_r_dir = r_dir

            
            self.parentJoint.joint:setMotorEnabled(true)
            self.parentJoint.joint:setMaxMotorTorque( 500000 )
            self.isMoving = true
        else
            if self.aLockMode then 
                self:animationLock() 
                self.aLockStatus = true
            end
            -- print(self.name, "stopped\n", self.angle)
            self.parentJoint.joint:setMotorSpeed(0)
            self.parentJoint.joint:setMotorEnabled(false)
            self.body:setAngularVelocity(0)
            self.body:setLinearVelocity(0, 0)
            self.parent.body:setAngularVelocity(0)
            self.parentJoint.joint:setMaxMotorTorque(500)
            self.parent.body:setLinearVelocity(0, 0)
            self.isMoving = false
            -- self:setAngle(self.targetAngle)
            self.targetAngle = self.angle

        end
    else
        self.targetAngle = self.angle
    end


end


function Bone:draw()

        --DEBUG DRAWINGS
        
        if self.isMoving and not self.isAnimationLocked then
            love.graphics.setColor(1, 0.5, 0, 0.5)
            local a1 = self.angle
            local a2 = self.targetAngle
            love.graphics.setColor(1, 0.5, 0, 0.5)
            if self.debug_r_dir >= 0 then
               
                love.graphics.setColor(0, 0.5, 1, 0.5)
                
                 if a2 <= a1 then a2 = a2 + 2*math.pi end
            else
                if a1 <= a2 then a1 = a1 + 2*math.pi end
                -- love.graphics.arc( "fill", self.parent.tipX, self.parent.tipY, 20, a1, a2, 20 )
            end
            love.graphics.arc( "fill", self.parent.tipX, self.parent.tipY, 20, a1, a2, 20 )
        end

        love.graphics.setColor(0.8549019607843137, 0.7372549019607844, 0.5803921568627451)

        -- if self.isLocked then
        --     love.graphics.setColor(1, 0, 0, 1)
        -- elseif  self.isAnimationLocked then
        --     love.graphics.setColor(1, 0, 0.5, 1)
        -- end

        love.graphics.polygon("fill", self.body:getWorldPoints(self.shape:getPoints()))

end