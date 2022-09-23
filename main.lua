ray = {}
function love.load()
  WWIDTH, WHEIGHT = love.window.getDesktopDimensions()
  imageShip = love.graphics.newImage("ship.png")
  imageShipWidth, imageShipHeight = imageShip:getDimensions()
  COORD_INFINITE = 199999
  drawDebug = false

  R2D = 180/math.pi
  PPM = 50
  --Thrusters
  TF = 25
  TB = -25
  TL = -25/2
  TR = 25/2
  
  Tradius = math.sqrt(TF^2+TL^2)

  TFLphi = math.atan2(TL,TF)
  TFRphi = math.atan2(TR,TF)
  TBLphi = math.atan2(TL,TB)
  TBRphi = math.atan2(TR,TB)
  TMphi  = math.atan2(0,TB)
  TBphi  = math.atan2(0,TF)

  --Forces
  FFLphi = math.atan2(TF,0)
  FFRphi = math.atan2(TB,0)
  FBLphi = math.atan2(TF,0)
  FBRphi = math.atan2(TB,0)
  FMphi  = math.atan2(0,TF)
  FBphi  = math.atan2(0,TB)

  AutoRotate = true
  Acc = 0.0001
  GoalX, GoalY = 10,0
  GoalPhi = 0
  HUDradius = 125
  HUDradiusStart = 80
  HUDradiusStop = 95
  HUDr = math.sqrt(HUDradius^2+HUDradius^2)
  HUDrStart = math.sqrt(HUDradiusStart^2+HUDradiusStart^2)
  HUDrStop =  math.sqrt(HUDradiusStop^2+HUDradiusStop^2)
  MAXAV = 51

  UpdateLidar=true
  Lidar = {}
  LidarPhi = 0
  LidarR = 7500

  for i=0,360,1 do
    Lidar[i]=1
  end

  timeAsteroids = 0
  timeAsteroidsParticles = 0

  Asteroid = {}
  AsteroidMax = 100

  Particle = {}
  ParticleIndex = 0
  ParticleMax = 100

  Bullet = {}
  BulletIndex = 0
  BulletMax = 5

  love.window.setMode(WWIDTH,WHEIGHT,{fullscreen=true})
  love.graphics.setBackgroundColor(0, 0, 0)
  love.graphics.setPointSize(3)
  math.randomseed(love.timer.getTime())
  initWorld()
end

function initWorld()
  love.physics.setMeter(PPM)
  world = love.physics.newWorld(0, 0, true)

  player = {}
  player.body = love.physics.newBody(world, 0, 0, "dynamic")
  local shape = love.physics.newRectangleShape(0,-34,150,6)
  local shape2 = love.physics.newRectangleShape(0,34,150,6)
  local shape3 = love.physics.newRectangleShape(56,-22,7,12)
  local shape4 = love.physics.newRectangleShape(56,22,7,12)
  local shape5 = love.physics.newRectangleShape(-67,0,15,15)
  local shape6 = love.physics.newRectangleShape(-55,0,5,55)
  player.fixture = love.physics.newFixture(player.body, shape, 1)
  player.fixture2 = love.physics.newFixture(player.body, shape2, 1)
  player.fixture3 = love.physics.newFixture(player.body, shape3, 1)
  player.fixture4 = love.physics.newFixture(player.body, shape4, 1)
  player.fixture5 = love.physics.newFixture(player.body, shape5, 1)
  player.fixture6 = love.physics.newFixture(player.body, shape6, 1)
  player.fixture:setRestitution(0.1)
  player.fixture:setUserData("Player1")
  player.fixture2:setRestitution(0.1)
  player.fixture2:setUserData("Player2")
  player.fixture3:setUserData("Player3")
  player.fixture4:setUserData("Player4")
  player.fixture5:setUserData("Player5")
  player.fixture6:setUserData("Player6")
  player.damage=0

  function player:rotR(spd)
    local x,y = self.body:getPosition()
    local phi = self.body:getAngle() -- FL, BR
    self.body:applyForce(Tradius*math.cos(FFLphi+phi)*spd, Tradius*math.sin(FFLphi+phi)*spd,x+(Tradius*math.cos(TFLphi+phi)),y+(Tradius*math.sin(TFLphi+phi)))
    self.body:applyForce(Tradius*math.cos(FBRphi+phi)*spd, Tradius*math.sin(FBRphi+phi)*spd,x+(Tradius*math.cos(TBRphi+phi)),y+(Tradius*math.sin(TBRphi+phi)))
  end
  function player:rotL(spd)
    local x,y = self.body:getPosition()
    local phi = self.body:getAngle() -- BL, FR
    self.body:applyForce(Tradius*math.cos(FBLphi+phi)*spd, Tradius*math.sin(FBLphi+phi)*spd,x+(Tradius*math.cos(TBLphi+phi)),y+(Tradius*math.sin(TBLphi+phi)))
    self.body:applyForce(Tradius*math.cos(FFRphi+phi)*spd, Tradius*math.sin(FFRphi+phi)*spd,x+(Tradius*math.cos(TFRphi+phi)),y+(Tradius*math.sin(TFRphi+phi)))
  end
  function player:left(spd)
    local x,y = self.body:getPosition()
    local phi = self.body:getAngle() -- FR, BR
    self.body:applyForce(Tradius*math.cos(FFRphi+phi)*spd, Tradius*math.sin(FFRphi+phi)*spd,x+(Tradius*math.cos(TFRphi+phi)),y+(Tradius*math.sin(TFRphi+phi)))
    self.body:applyForce(Tradius*math.cos(FBRphi+phi)*spd, Tradius*math.sin(FBRphi+phi)*spd,x+(Tradius*math.cos(TBRphi+phi)),y+(Tradius*math.sin(TBRphi+phi)))
  end
  function player:right(spd)
    local x,y = self.body:getPosition()
    local phi = self.body:getAngle() -- FL, BL
    self.body:applyForce(Tradius*math.cos(FFLphi+phi)*spd, Tradius*math.sin(FFLphi+phi)*spd,x+(Tradius*math.cos(TFLphi+phi)),y+(Tradius*math.sin(TFLphi+phi)))
    self.body:applyForce(Tradius*math.cos(FBLphi+phi)*spd, Tradius*math.sin(FBLphi+phi)*spd,x+(Tradius*math.cos(TBLphi+phi)),y+(Tradius*math.sin(TBLphi+phi)))
  end
  function player:fwd(spd)
    local x,y = self.body:getPosition()
    local phi = self.body:getAngle()
    spd=spd*3
    self.body:applyForce(Tradius*math.cos(FMphi+phi)*spd, Tradius*math.sin(FMphi+phi)*spd,x+(Tradius*math.cos(TMphi+phi)),y+(Tradius*math.sin(TMphi+phi)))--Main
  end
  function player:bck(spd)
    local x,y = self.body:getPosition()
    local phi = self.body:getAngle()
    spd=spd*2
    self.body:applyForce(Tradius*math.cos(FBphi+phi)*spd, Tradius*math.sin(FBphi+phi)*spd,x+(Tradius*math.cos(TBphi+phi)),y+(Tradius*math.sin(TBphi+phi)))--Back
  end
  function player:aslow(spd)
    local x,y = self.body:getPosition()
    local phi = self.body:getAngle()
    local mod = self.body:getAngularVelocity()
    if mod < 0 then
      self:rotR(spd)
    elseif mod > 0 then
      self:rotL(spd)
    end
  end
  function player:shoot()
    local x,y = self.body:getPosition()
    local phi = self.body:getAngle()
    --local vx,vy = self.body:getLinearVelocity()

    local dirX,dirY = 100*math.cos(phi),100*math.sin(phi)

    spawnBullet(x+dirX,y+dirY,dirX,dirY,phi)
  end

  world:setCallbacks(beginContact, endContact, preSolve, postSolve)

  for i=1,ParticleMax-1,1 do
    Particle[i]={x=0,y=0}
  end

  for i=0,AsteroidMax,1 do
    local asteroid = {}
    local r = math.random(15,75)
    local x = 0
    local y = COORD_INFINITE+i*160
    asteroid.body = love.physics.newBody(world, x, y, "dynamic")
    local shape = love.physics.newCircleShape(0, 0, r)
    asteroid.fixture = love.physics.newFixture(asteroid.body, shape, 2-(75/r))
    asteroid.fixture:setUserData("Asteroid"..i)
    asteroid.damage=0
    Asteroid[i]=asteroid
  end
end

function love.update(dt)
  world:update(dt)
  
  local x,y = player.body:getPosition()
  local phi = player.body:getAngle()*R2D%360
  local phiV = player.body:getAngularVelocity()*R2D
  local Vx, Vy = player.body:getLinearVelocity()
  local Mx, My = love.mouse.getPosition()
  local spd = 1

  for i,k in pairs(Asteroid) do
    if Asteroid[i].damage>0 then
      Asteroid[i].fixture:getShape():setRadius(math.max(Asteroid[i].fixture:getShape():getRadius()-5,5))
      if Asteroid[i].fixture:getShape():getRadius()<=20 then
        Asteroid[i].body:setMass(0.1)
      end
      Asteroid[i].damage=0
    end
  end

  for i,b in pairs(Bullet) do
    b.damage=b.damage+1
    if b.damage>0 then
      b.body:setPosition(0,COORD_INFINITE)
    end
  end

  if timeAsteroids<love.timer.getTime()-1 then
    timeAsteroids = love.timer.getTime()
    local phi = math.random(0,360)
    local radius = math.random(2000,7000)
    addAsteroid(radius*math.cos(phi/R2D)+x,radius*math.sin(phi/R2D)+y)
  end
  
  if timeAsteroidsParticles<love.timer.getTime()-(1-math.min(math.sqrt(math.abs(Vx^2+Vy^2))/500,1)) then
    timeAsteroidsParticles=love.timer.getTime()
    local phidif = math.random(60,-60)/R2D
    local Vphi = math.atan2(Vy,Vx)
    local px = WWIDTH*math.cos(Vphi+phidif)*0.6
    local py = WHEIGHT*math.sin(Vphi+phidif)*0.6
    Particle[ParticleIndex] = {x=px+x,y=py+y}
    ParticleIndex=(ParticleIndex+1)%ParticleMax
  end

  if love.mouse.isDown(1) then
    GoalX = Mx-WWIDTH/2
    GoalY = My-WHEIGHT/2
  end

  if love.keyboard.isDown("lshift") then
    spd = 0.1
  elseif love.keyboard.isDown("lctrl") then
    spd = 2
  end

  if love.keyboard.isDown("a") then
    player:left(spd)
  elseif love.keyboard.isDown("d") then
    player:right(spd)
  elseif love.keyboard.isDown("q") then
    player:rotL(spd)
  elseif love.keyboard.isDown("e") then
    player:rotR(spd)
  end

  if love.keyboard.isDown("w") then
    player:fwd(spd)
  elseif love.keyboard.isDown("s") then
    player:bck(spd)
  elseif love.keyboard.isDown("x") then
    player:aslow(spd)
  elseif love.keyboard.isDown("r") then
    GoalX = -Vx
    GoalY = -Vy
  elseif love.keyboard.isDown("f") then
    GoalX = Vx
    GoalY = Vy
  end

  if UpdateLidar then
    LidarPhi=(LidarPhi+5)%365
    for i=1,5,1 do
      Lx = LidarR*math.cos((LidarPhi+i)/R2D)
      Ly = LidarR*math.sin((LidarPhi+i)/R2D)
      world:rayCast(x, y, x+Lx, y+Ly, ray[i])
      Lidar[LidarPhi+i]=1
      if math.abs(phiV)>360 then Lidar[LidarPhi+i]=math.random(1,25+math.min(math.max(math.abs(phiV/2)-360,0),80))/100 end
    end
  end

  if AutoRotate then
    GoalPhi = math.atan2(GoalY,GoalX)*R2D%360
    if GoalPhi > phi+Acc or GoalPhi < phi-Acc then
      local distR = math.abs((GoalPhi - (phi+phiV*1)+360)%360)
      local distL = math.abs(((phi+phiV*1) - GoalPhi+360)%360)
      if math.abs(phiV)>MAXAV then
        player:aslow(1)
      elseif distR - distL > 0 and distL >= 1 then
        player:rotL(1)
      elseif distL - distR > 0 and distR >= 1 then
        player:rotR(1)
      elseif distR - distL > 0 then
        player:rotL(math.min(distL,1))
      elseif distL - distR >= 0 then
        player:rotR(math.min(distR,1))
      end
    end
  end
end

function love.draw()
  local x,y = player.body:getPosition()
  local vx,vy = player.body:getLinearVelocity()
  local angle = player.body:getAngle()
  local phi = player.body:getAngle()*R2D%360
  local Mx, My = love.mouse.getPosition()

  love.graphics.translate(math.floor(-x+WWIDTH/2),math.floor(-y+WHEIGHT/2))--Objects

  love.graphics.setColor(1,1,1)

  for i,p in pairs(Particle) do
    love.graphics.points(p.x,p.y)
  end

  love.graphics.draw(imageShip,x+math.cos(angle),y+math.sin(angle),angle,1,1,imageShipWidth/2,imageShipHeight/2)
  
  if drawDebug then
    love.graphics.polygon("line",player.body:getWorldPoints(player.fixture:getShape():getPoints()))
    love.graphics.polygon("line",player.body:getWorldPoints(player.fixture2:getShape():getPoints()))
    love.graphics.polygon("line",player.body:getWorldPoints(player.fixture3:getShape():getPoints()))
    love.graphics.polygon("line",player.body:getWorldPoints(player.fixture4:getShape():getPoints()))
    love.graphics.polygon("line",player.body:getWorldPoints(player.fixture5:getShape():getPoints()))
    love.graphics.polygon("line",player.body:getWorldPoints(player.fixture6:getShape():getPoints()))
    love.graphics.polygon("line",player.body:getWorldPoints(player.fixture7:getShape():getPoints()))
  end

  love.graphics.setColor(0.1, 0.1, 0.1)--grey
  --Asteroids
  for i=0,AsteroidMax,1 do
    local asteroid = Asteroid[i]
    if asteroid then
      love.graphics.circle("fill", asteroid.body:getX(), asteroid.body:getY(), asteroid.fixture:getShape():getRadius())
    end
  end

  love.graphics.setColor(0.1,1,0.1)--green

  for i,b in pairs(Bullet) do
    love.graphics.polygon("fill",b.body:getWorldPoints(b.fixture:getShape():getPoints()))
  end

  love.graphics.print(string.format("X %.1f Y %.1f",x/PPM,y/PPM),x-WWIDTH/2+50,y-WHEIGHT/2+50)
  love.graphics.print(string.format("Angle %.2f",phi),x-WWIDTH/2+50,y-WHEIGHT/2+70)

  love.graphics.line(x,y,x+vx/2,y+vy/2)--vector
  love.graphics.circle("line",x,y,HUDradius)--circle
  --goal line
  love.graphics.line(x+HUDrStart*math.cos(GoalPhi/R2D),y+HUDrStart*math.sin(GoalPhi/R2D),x+HUDrStop*math.cos(GoalPhi/R2D),y+HUDrStop*math.sin(GoalPhi/R2D))
  --current angle
  love.graphics.line(x+HUDrStart*math.cos(angle),y+HUDrStart*math.sin(angle),x+HUDrStop*math.cos(angle),y+HUDrStop*math.sin(angle))

  --lidar lines
  if UpdateLidar then
    for i=0,360,1 do
      if Lidar[i]~=1 then
        love.graphics.setColor(1-math.min(Lidar[i],1),math.min(Lidar[i],1),0.1)
        love.graphics.line(x+HUDradius*math.cos(i/R2D),y+HUDradius*math.sin(i/R2D),x+math.cos(i/R2D)*(120+Lidar[i]*50),y+math.sin(i/R2D)*(120+Lidar[i]*50))
      end
    end
  end
end

function love.keypressed(key, scancode, isrepeat)
  if key == "escape" then
    love.event.quit(0)
  elseif key == "tab" then
    AutoRotate = not AutoRotate
  elseif key == "l" then
    UpdateLidar = not UpdateLidar
  elseif key == "space" then
    player:shoot()
  end
end

function beginContact(a, b, coll)
  if string.sub(b:getUserData(),1,6)=="Player" or string.sub(a:getUserData(),1,6)=="Player" then
    local vx, vy = 0,0
    if string.sub(b:getUserData(),1,6)=="Player" then
      vx, vy = b:getBody():getLinearVelocity()
      vx2, vy2 = a:getBody():getLinearVelocity()
      vx=vx-vx2
      vy=vy-vy2
    else
      vx, vy = a:getBody():getLinearVelocity()
      vx2, vy2 = b:getBody():getLinearVelocity()
      vx=vx-vx2
      vy=vy-vy2
    end
    local r = math.sqrt(vx^2+vy^2)
    if r>250 then
      AutoRotate = false
      UpdateLidar = false
      for i=0,#Lidar,1 do
        if math.random(1,8)<3 then
          Lidar[i]=math.random(1,75)/100
        end
      end
    end
    player.damage=player.damage+1
  end
  if string.sub(b:getUserData(),1,6)=="Bullet" or string.sub(a:getUserData(),1,6)=="Bullet" then
    if string.sub(b:getUserData(),1,6)=="Bullet" then
      Bullet[tonumber(string.sub(b:getUserData(),7,9))].damage=1
    elseif string.sub(a:getUserData(),1,6)=="Bullet" then
      Bullet[tonumber(string.sub(a:getUserData(),7,9))].damage=1
    end
    if string.sub(b:getUserData(),1,8)=="Asteroid" then
      Asteroid[tonumber(string.sub(b:getUserData(),9,14))].damage=Asteroid[tonumber(string.sub(b:getUserData(),9,14))].damage+1
    elseif string.sub(a:getUserData(),1,8)=="Asteroid" then
      Asteroid[tonumber(string.sub(a:getUserData(),9,14))].damage=Asteroid[tonumber(string.sub(a:getUserData(),9,14))].damage+1
    end
  end
end

function endContact(a, b, coll)
end

function preSolve(a, b, coll)
end

function postSolve(a, b, coll, normalimpulse, tangentimpulse)
end

ray[1] = function(fixture, x, y, xn, yn, fraction)
  if fraction<=0.05 then return -1 end
  Lidar[LidarPhi-4]=fraction
  return 0
end
ray[2] = function(fixture, x, y, xn, yn, fraction)
  if fraction<=0.05 then return -1 end
  Lidar[LidarPhi-3]=fraction
  return 0
end
ray[3] = function(fixture, x, y, xn, yn, fraction)
  if fraction<=0.05 then return -1 end
  Lidar[LidarPhi-2]=fraction
  return 0
end
ray[4] = function(fixture, x, y, xn, yn, fraction)
  if fraction<=0.05 then return -1 end
  Lidar[LidarPhi-1]=fraction
  return 0
end
ray[5] = function(fixture, x, y, xn, yn, fraction)
  if fraction<=0.05 then return -1 end
  Lidar[LidarPhi-0]=fraction
  return 0
end

function addAsteroid(x,y)
  local px, py = player.body:getPosition()
  local index = 0
  local r = 0
  for i,a in pairs(Asteroid) do
    local ax, ay = a.body:getPosition()
    ax=ax-px
    ay=ay-py
    local ar = math.sqrt(ax^2+ay^2)
    if ar>r then
      index=i
      r=ar
    end
  end
  Asteroid[index].fixture:getBody():setPosition(x,y)
end

function spawnBullet(x,y,vx,vy,phi)
  local it = {}
  it.body = love.physics.newBody(world, x, y, "dynamic")
  local shape = love.physics.newRectangleShape(0,0,16,2)
  it.fixture = love.physics.newFixture(it.body, shape, 0.1)
  it.fixture:setRestitution(1)
  it.fixture:setUserData("Bullet"..BulletIndex)
  it.body:applyForce(vx,vy)
  it.body:setAngle(phi)
  it.body:setBullet(true)
  it.damage=-50
  Bullet[BulletIndex]=it
  BulletIndex=(BulletIndex+1)%BulletMax
  return it
end

function f10(x)
  return string.format("%.10f",x)
end

function s10(str)
  return string.sub(str,1,10)
end
