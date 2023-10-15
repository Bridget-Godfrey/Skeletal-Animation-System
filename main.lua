require("skeleton")


local screenCanvas = love.graphics.newCanvas()
screenCanvas:setFilter("nearest", "nearest")
local screenCanvas2 = love.graphics.newCanvas()
screenCanvas2:setFilter("nearest", "nearest")

local pixel_shader = love.graphics.newShader [[
      extern vec2 size;            //vector contains image size, like shader:send('size', {img:getWidth(), img:getHeight()})	
      extern number factor;    //nimber contains sample size, like shader:send('factor', 2), use number is divisible by two
      vec4 effect(vec4 color, Image img, vec2 texture_coords, vec2 pixel_coords){
         vec2 tc = floor(texture_coords * size / factor) * factor / size;
         return Texel(img, tc);
      }
]]


function love.load()
	-- print(love.getVersion())
    love.physics.setMeter(64*2) --the height of a meter our worlds will be 64px

    -- Usage
    HEAD_LEN = 80
    world = love.physics.newWorld(0, 0, true)
    skeleton = Skeleton:new("skeleton", 200, 300, world)
    static_edit = false
    targetBone = nil
    txt = ''
    aFrame = 0
    lockMode = false
    -- b1 = skeleton:addBone("uArm", 110, 0)
    -- b2 = skeleton:addBone("lArm", 50, 0)
    -- skeleton.currentAdditionTarget = skeleton.root
    -- b3 = skeleton:addBone("shoulder", 20, math.pi, 2)
    -- b4 = skeleton:addBone("rArm", 110, math.pi)
    -- b5 = skeleton:addBone("rlArm", 50, math.pi)
    skeleton.currentAdditionTarget = skeleton.root
    l_hip = skeleton:addBone("l_hip", HEAD_LEN*0.25, math.pi, 10, 2)
	l_upper_leg = skeleton:addBone("l_upper_leg",  HEAD_LEN*1.375, 1.92224, 25)
	l_lower_leg = skeleton:addBone("l_lower_leg", HEAD_LEN*1.5, 1.57079, 20)
	l_foot = skeleton:addBone("l_foot", HEAD_LEN*.5, 2.15336)
	skeleton.currentAdditionTarget = skeleton.root
	r_hip = skeleton:addBone("r_hip", HEAD_LEN*0.25, 0, 10, 2)
	r_upper_leg = skeleton:addBone("r_upper_leg",  HEAD_LEN*1.375, 1.26274, 25)
	r_lower_leg = skeleton:addBone("r_lower_leg",  HEAD_LEN*1.5, 1.57079, 20)
	r_foot = skeleton:addBone("r_foot", HEAD_LEN*.5, 0.75697)
	skeleton.currentAdditionTarget = skeleton.root
	lower_torso = skeleton:addBone("lower_torso", HEAD_LEN*0.8, 3*math.pi/2, 30)
	lower_torso.fixture:setDensity(10)
	upper_torso = skeleton:addBone("upper_torso", HEAD_LEN*0.75, 3*math.pi/2, 30)
	lower_torso.fixture:setDensity(10)
	neck = skeleton:addBone("neck", HEAD_LEN*0.25, 3*math.pi/2)
	head = skeleton:addBone("head", HEAD_LEN, 3*math.pi/2)
	skeleton.currentAdditionTarget = upper_torso
	l_shoulder = skeleton:addBone("l_shoulder", HEAD_LEN*.25, 0, 10, 2 )
	l_upper_arm = skeleton:addBone("l_upper_arm", HEAD_LEN*0.9, 1.26274 )
	l_lower_arm = skeleton:addBone("l_lower_arm", HEAD_LEN*0.8, 1.26274 )
	l_hand = skeleton:addBone("l_hand",  HEAD_LEN*0.375, 1.26274)
	skeleton.currentAdditionTarget = upper_torso
	r_shoulder = skeleton:addBone("r_shoulder", HEAD_LEN*.25, math.pi, 10, 2)
	
	
	
	r_upper_arm = skeleton:addBone("r_upper_arm", HEAD_LEN*0.9, 1.92224)
	r_lower_arm = skeleton:addBone("r_lower_arm", HEAD_LEN*0.8, 1.92224)
	r_hand = skeleton:addBone("r_hand", HEAD_LEN*0.375, 1.26274 )
	

	skeleton:addPose("A_POSE", {{"l_hip", math.pi}, {"l_upper_leg",  1.92224}, {"l_lower_leg", 1.57079}, {"l_foot", 2.15336}, {"r_hip", 0}, {"r_upper_leg",  1.26274}, {"r_lower_leg",  1.57079}, {"r_foot", 0.75697}, {"lower_torso", 3*math.pi/2}, {"upper_torso", 3*math.pi/2}, {"neck", 3*math.pi/2}, {"head", 3*math.pi/2}, {"l_shoulder", 0}, {"l_upper_arm", 1.26274 }, {"l_lower_arm", 1.26274 }, {"l_hand",  1.26274}, {"r_shoulder", math.pi}, {"r_upper_arm", 1.92224}, {"r_lower_arm", 1.92224}, {"r_hand", 1.26274 }})


	wave = Simple_Animation:new("l_arm_wave")
	local ll = {"lower_torso", "upper_torso", "l_hand", "l_shoulder", "head", "neck"}
	local ll2 = {"l_upper_arm", "lower_torso", "upper_torso", "l_hand", "l_shoulder", "head", "neck"}
	local spd1 = 2
	local timeScaler = 0.5
	wave:addFrame({{"l_upper_arm", 2*math.pi}, {"l_lower_arm", 6.5*math.pi/4}}, 2*timeScaler, ll)
	-- local dur1 = (6.5*math.pi/4 - 3*math.pi/2)/spd1/
	-- wave:addFrame({{"l_lower_arm", 6.5*math.pi/4}}, (6.5*math.pi/4 - 3*math.pi/2)/spd1, ll2)
	-- wave:addFrame({{"l_upper_arm", 0}, {"l_lower_arm", 7*math.pi/2}}, 0.4, ll)
	wave:addFrame({{"l_lower_arm", 5*math.pi/4}}, (math.abs(5*math.pi/4 - 6.5*math.pi/4)/spd1)*timeScaler, ll2)
	wave:addFrame({{"l_lower_arm", 6.5*math.pi/4}}, (math.abs(6.5*math.pi/4 - 5*math.pi/4)/spd1)*timeScaler, ll2)
	wave:addFrame({{"l_lower_arm", 5*math.pi/4}}, (math.abs(5*math.pi/4 - 6.5*math.pi/4)/spd1)*timeScaler, ll2)
	wave:addFrame({{"l_lower_arm", 6.5*math.pi/4}}, (math.abs(6.5*math.pi/4 - 5*math.pi/4)/spd1)*timeScaler, ll2)
	wave:addFrame({{"l_lower_arm", 0}}, (math.abs(6.5*math.pi/4)/spd1)*timeScaler, ll2)
	wave:addFrame({{"l_upper_arm", 1.2}}, 3*timeScaler, {"lower_torso", "upper_torso", "l_hand", "l_shoulder", "l_lower_arm","head", "neck"})
	wave:addFrame({{}}, 1, {})
	-- wave:addFrame({{"l_lower_arm", 5*math.pi/4}}, 0.8, ll2)
	-- wave:addFrame({{"l_lower_arm", 6*math.pi/4}}, 0.8, ll2)
	-- wave:addFrame({{"l_lower_arm", 5*math.pi/4}}, 0.8, ll2)
	skeleton:addAnimation(wave)
	-- skeleton:addPose("A_POSE", {{"l_hip", math.pi}, {"l_upper_leg",  1.92224}, {"l_lower_leg", 1.57079}, {"l_foot", 2.15336}, {"r_hip", 0}, {"r_upper_leg",  1.26274}, {"r_lower_leg",  1.57079}, {"r_foot", 0.75697}, {"lower_torso", 3*math.pi/2}, {"upper_torso", 3*math.pi/2}, {"neck", 3*math.pi/2}, {"head", 3*math.pi/2}, {"l_shoulder", 0}, {"l_upper_arm", 1.26274 }, {"l_lower_arm", 1.26274 }, {"l_hand",  1.26274}, {"r_shoulder", math.pi}, {"r_upper_arm", 1.92224}, {"r_lower_arm", 1.92224}, {"r_hand", 1.26274 }})
    -- b2 = skeleton:addBone(110, 0, 200+100, 200)
    -- b3 = skeleton:addBone(110, 0, 300, 200)
    -- b0.body:setType("static")
    -- skeleton:addJoint(b0, b1, 50+100, 200)
    -- skeleton:addJoint(b1, b2, 150+100, 200)
    -- skeleton:addJoint(b2, b3, 300, 200)
    mouseJoint = nil
    
    -- world = love.physics.newWorld(0, 0, true)
     -- objects = {} -- table to hold all our physical objects
  
  --let's create the ground
  ground = {}
  ground.body = love.physics.newBody(world, 650/2, 625) --remember, the shape (the rectangle we create next) anchors to the body from its center, so we have to move it to (650/2, 650-50/2)
  ground.shape = love.physics.newRectangleShape(650, 50) --make a rectangle with a width of 650 and a height of 50
  ground.fixture = love.physics.newFixture(ground.body, ground.shape) --attach shape to body
  
  --let's create a ball
  -- objects.ball = {}
  -- objects.ball.body = love.physics.newBody(world, 650/2, 650/2, "dynamic") --place the body in the center of the world and make it dynamic, so it can move around
  -- objects.ball.shape = love.physics.newCircleShape( 20) --the ball's shape has a radius of 20
  -- objects.ball.fixture = love.physics.newFixture(objects.ball.body, objects.ball.shape, 1) -- Attach fixture to body and give it a density of 1.
  -- objects.ball.fixture:setRestitution(0.9) --let the ball bounce
  -- objects.ball.body:setLinearDamping(2)
  -- --let's create a couple blocks to play around with
  -- objects.block1 = {}
  -- objects.block1.body = love.physics.newBody(world, 200, 550, "dynamic")
  -- objects.block1.shape = love.physics.newRectangleShape(0, 0, 50, 100)
  -- objects.block1.fixture = love.physics.newFixture(objects.block1.body, objects.block1.shape, 5) -- A higher density gives it more mass.

  -- objects.block2 = {}
  -- objects.block2.body = love.physics.newBody(world, 200, 400, "dynamic")
  -- objects.block2.shape = love.physics.newRectangleShape(0, 0, 100, 50)
  -- objects.block2.fixture = love.physics.newFixture(objects.block2.body, objects.block2.shape, 2)
  love.graphics.setBackgroundColor(0.41, 0.53, 0.97) --set the background color to a nice blue
  love.window.setMode(650, 650, {vsync = 1}) --set the window dimensions to 650 by 650 with no fullscreen, vsync on, and no antialiasing
	screenCanvas = love.graphics.newCanvas()
	screenCanvas:setFilter("nearest", "nearest")
	screenCanvas2 = love.graphics.newCanvas()
	screenCanvas2:setFilter("nearest", "nearest")

   -- love.window.setMode(screenWidth, screenHeight, )
  -- for _, joint in ipairs(skeleton.joints) do
  --       print(joint.joint:getAnchors())
        
  --   end
--     love.graphics.setShader(love.graphics.newShader [[
--     vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
--         // Get the original color
--         vec4 originalColor = Texel(texture, texture_coords);
        
--         // Downscale each color channel to 5 bits
--         vec4 downscaledColor = floor(originalColor * 31.0 + 0.5) / 31.0;
        
--         // If you want to upscale color back to 8 bits per channel
--         // vec4 upscaledColor = downscaledColor * (255.0 / 31.0);
        
--         return downscaledColor * color;
--     }
-- ]])
	pixel_shader:send('size', {love.graphics.getWidth(), love.graphics.getHeight()})
	pixel_shader:send('factor', 4)
	-- p_shader = love.graphics.newShader (pixel_shader)
	-- 

  
end


function love.draw()
	
	love.graphics.setCanvas(screenCanvas)
	love.graphics.clear(0.41, 0.53, 0.97)
	-- love.graphics.setShader(pixel_shader)
	skeleton:draw()
    -- love.graphics.setColor(1, 1, 1, 1)
    -- for i, bone in ipairs(skeleton.bones) do
    --     love.graphics.setColor(i/#skeleton.bones, i/#skeleton.bones, i/#skeleton.bones, 1)
    --     love.graphics.polygon("fill", bone.body:getWorldPoints(bone.shape:getPoints()))
    -- end
    love.graphics.setColor(1, 0, 0, 0.5)
    for _, joint in ipairs(skeleton.joints) do
        local x1, y1, x2, y2 = joint.joint:getAnchors()
        love.graphics.circle("fill", x1, y1, 3)
        -- love.graphics.circle("fill", x2, y2, 10)
    end
    
    for _, b in ipairs(skeleton.bones) do
        
        love.graphics.setColor(0, 1, 0, 0.5)
        love.graphics.circle("fill", b.comX, b.comY, 3)
        love.graphics.setColor(1, 0, 1, 0.5)
        love.graphics.circle("fill", b.tipX, b.tipY, 3)
        -- love.graphics.circle("fill", x2, y2, 10)
    end
    love.graphics.setColor(1, 1, 0.5, 1)
    love.graphics.polygon("fill", skeleton.root.body:getWorldPoints(skeleton.root.shape:getPoints()))

  love.graphics.setColor(0.28, 0.63, 0.05, 1) -- set the drawing color to green for the ground
  love.graphics.polygon("fill", ground.body:getWorldPoints(ground.shape:getPoints())) -- draw a "filled in" polygon using the ground's coordinates And finally, we can draw the circle that represents the ball and the blocks.
  -- love.graphics.rectangle("fill", 0, 625, 650, 50) -- draw a "filled in" polygon using the ground's coordinates And finally, we can draw the circle that represents the ball and the blocks.
  
  --  --Shader Version Of Effect
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.setCanvas()
  love.graphics.setShader(pixel_shader)
  love.graphics.draw(screenCanvas, 0, 0)
  love.graphics.setShader()


  	-- --  -- Canvas Version Of Effect
  	-- love.graphics.setColor(1, 1, 1, 1)
    -- love.graphics.setCanvas(screenCanvas2)
	-- love.graphics.clear()
	-- love.graphics.draw(screenCanvas, 0, 0, 0, 0.25, 0.25)
	-- love.graphics.setCanvas()
	-- love.graphics.clear()
	-- love.graphics.draw(screenCanvas2, 0, 0, 0, 4, 4)
	
	if aFrame >= 1 then
		if skeleton.currentAnimation then
			aFrame = skeleton.currentAnimation.onFrame
		else
			aFrame = 0
		end
	end

  

  -- love.graphics.setColor(0.76, 0.18, 0.05) --set the drawing color to red for the ball
  -- love.graphics.circle("fill", objects.ball.body:getX(), objects.ball.body:getY(), objects.ball.shape:getRadius())

  -- love.graphics.setColor(0.20, 0.20, 0.20) -- set the drawing color to grey for the blocks
  -- love.graphics.polygon("fill", objects.block1.body:getWorldPoints(objects.block1.shape:getPoints()))
  -- love.graphics.polygon("fill", objects.block2.body:getWorldPoints(objects.block2.shape:getPoints()))

  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.print("FPS: " .. tostring(love.timer.getFPS()) .. "A frame = " .. aFrame, 10, 10)
   love.graphics.print(txt, 400, 50)
end

function love.update(dt)
	  txt = ''
	  for i,bone in ipairs(skeleton.bones) do
  	  if i > 1 then
  	  		local statusVars = ''
  	  		if bone.isMoving then 
  	  			statusVars = statusVars .. " M" 
  	  			if bone.debug_r_dir >= 0 then statusVars = statusVars .. "+ " else statusVars = statusVars .. "- " end
  	  		end
  	  		if bone.isLocked then statusVars = statusVars .. "L " 
  	  		elseif bone.isAnimationLocked then 
  	  			statusVars = statusVars .. "aL " 
  	  			if bone.aLockStatus then statusVars = statusVars .. "=)" end
  	  		end
  	  		if bone.isFrozen then statusVars = statusVars .. "F " end

  	  		statusVars = statusVars .. "  " .. math.floor(bone.targetAngle*100)/100

		  txt = txt .. "\n" .. "bone " .. bone.name .. ": " .. math.floor(bone.angle*100)/100 .. " " .. statusVars --.. "  Ref: " .. tostring(bone.parentJoint.joint:getReactionForce(1/dt ))
		end
	  end
    
     world:update(dt) --this puts the world into motion
     skeleton:update(dt)
     txt = txt .. "\n " .. tostring( lockMode)
     if mouseJoint then
        -- local mouseX, mouseY = love.mouse.getPosition()
        -- 
        if targetBone then 
        	txt = txt .. "\n " .. targetBone.name
        	if targetBone.isRoot then
        		skeleton:setPosition(love.mouse.getPosition())

        	elseif targetBone.boneType == 2 then 
        		mouseJoint:setTarget(love.mouse.getPosition())
        		targetBone.body:setPosition(love.mouse.getPosition())
        		targetBone.x, targetBone.y = love.mouse.getPosition()
        		targetBone.tipX = targetBone.x + math.cos(targetBone.angle)*(0.5*targetBone.length)
			    targetBone.tipY = targetBone.y + math.sin(targetBone.angle)*(0.5*targetBone.length)
        	else
        		mouseJoint:setTarget(love.mouse.getPosition())
        		local cb = targetBone
        		while not cb.isRoot do 
        			cb.body:setAngularVelocity(0)
        			cb.body:setLinearVelocity(0, 0)
        			cb = cb.parent
        		end
        	end
        	-- print("here")
        end
        if not static_edit and love.keyboard.isDown("lshift") and targetBone then
			static_edit = true
			for i,bone in ipairs(skeleton.bones) do
				if bone ~= targetBone then
					 bone:freeze()
				end
			end
		end
    end
  

  --here we are going to create some keyboard events
  -- if love.keyboard.isDown("right") then --press the right arrow key to push the ball to the right
  --   objects.ball.body:applyForce(400, 0)
  -- elseif love.keyboard.isDown("left") then --press the left arrow key to push the ball to the left
  --   objects.ball.body:applyForce(-400, 0)
  -- elseif love.keyboard.isDown("up") then --press the up arrow key to set the ball in the air
  --   objects.ball.body:applyForce(0, -400)
  -- elseif love.keyboard.isDown("down") then --press the up arrow key to set the ball in the air
  --   objects.ball.body:applyForce(0, 400)
  -- end
end



function love.keypressed(key, scancode, isrepeat)
    if key == "r" then
        love.load()
    end
    if key == "right" then
        skeleton.bones[1].body:applyForce(400, 0)
    end

    if key == "escape" then
        love.event.quit(0)
    end

    if key == "p" then
    	
    	-- l_lower_arm.isMoving = true
    	if skeleton.currentAnimation == nil then
    		skeleton:jumpToPose("A_POSE")
	    	skeleton:beginAnimation("l_arm_wave")
	    	local kfs = skeleton.currentAnimation.keyframes
	    	kfs[#kfs] = {skeleton:getPoseAsKeyframe(), 0.3, {}}
	    	aFrame = 1
	    end
    	-- lower_torso:animationLock()
    	-- upper_torso:animationLock()
    	-- l_hand:animationLock()
    	-- l_shoulder:animationLock()
    	-- for i,bone in ipairs(skeleton.bones) do
		-- 	-- table.insert(static_status_list, bone.body:isFixedRotation())
		-- 	if not bone.isMoving then
				 
		-- 		 bone:freeze()
		-- 	end
		-- end
    end

    if key == "q" then
    	-- r_upper_arm.targetAngle = 0
    	-- r_lower_arm.targetAngle = 3*math.pi/2
    	-- r_upper_arm:setAngle(0)
		-- r_lower_arm:setAngle(3*math.pi/2)
		skeleton:jumpToPose("A_POSE")
    	
    end
    if key == "l" then
    	lockMode = not lockMode
    end

end


function love.mousepressed( x, y, button, istouch, presses )
	targetBone = nil
	if lockMode then 
		for i,bone in ipairs(skeleton.bones) do
			if bone.fixture:testPoint(x, y) then
				if bone.isLocked then
					bone:unlock()
					lockMode = false
				else
					bone:lock()
					lockMode = false
				end
				-- bone:freeze()
			end
		end

	elseif skeleton.root.fixture:testPoint(x, y) then 
		mouseJoint = love.physics.newMouseJoint(skeleton.root.body, x, y)
		targetBone = skeleton.root
		skeleton.root.body:setType("dynamic")
		static_edit = true
			for i,bone in ipairs(skeleton.bones) do
				-- table.insert(static_status_list, bone.body:isFixedRotation())
				if bone ~= targetBone then
					 
					 bone:freeze()
				end
			end
	else

		for i,bone in ipairs(skeleton.bones) do
			if bone.fixture:testPoint(x, y) then
				 targetBone = bone
				 mouseJoint = love.physics.newMouseJoint(bone.body, x, y)
			end
		end
		
		if love.keyboard.isDown("lshift") and targetBone then
			if targetBone.boneType == 2 then 
				-- pass
			else
				static_edit = true
				for i,bone in ipairs(skeleton.bones) do
					-- table.insert(static_status_list, bone.body:isFixedRotation())
					if bone ~= targetBone then
						 
						 bone:freeze()
					end
				end
			end
		end
	end

end


function love.mousereleased(x, y, button, istouch, presses)
	if mouseJoint then 
		mouseJoint:destroy()
		skeleton.root.body:setType("static")
		mouseJoint = nil
		for i,bone in ipairs(skeleton.bones) do
			bone.body:setLinearVelocity(0, 0)
		end
	end

	if targetBone and targetBone.boneType == 2 then 
				-- pass
	end

	if static_edit then
		static_edit = false
		for i,bone in ipairs(skeleton.bones) do
				 bone:unfreeze()
		end
	end

end


function love.keyreleased(key, scancode)
	if key == "lshift" and static_edit then
		static_edit = false
		for i,bone in ipairs(skeleton.bones) do
				 bone:unfreeze()
		end
	end
end