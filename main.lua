ray = {}
function love.load()
  WWIDTH, WHEIGHT = love.window.getDesktopDimensions()
  imageShip = love.graphics.newImage("ship.png")
  imageShipWidth, imageShipHeight = imageShip:getDimensions()

  R2D = 180/math.pi
  PPM = 50
  --Thrusters
  TF = 75
  TB = -75
  TL = -75/2
  TR = 75/2
  
  Tradius = math.sqrt(TF^2+TL^2)

  TFLphi = math.atan2(TL,TF)
  TFRphi = math.atan2(TR,TF)
  TBLphi = math.atan2(TL,TB)
  TBRphi = math.atan2(TR,TB)
  TMphi  = math.atan2(0,-75)

  --Forces
  FFLphi = math.atan2(75,0)
  FFRphi = math.atan2(-75,0)
  FBLphi = math.atan2(75,0)
  FBRphi = math.atan2(-75,0)
  FMphi  = math.atan2(0,75)

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
  MAXAV = 105

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
  AsteroidIndex = 0
  AsteroidMax = 100

  Particle = {}
  ParticleIndex = 0
  ParticleMax = 100

  Bullet = {}
  BulletIndex = 0
  BulletMax = 5

  love.window.setMode(WWIDTH,WHEIGHT,{fullscreen=true})
  love.graphics.setBackgroundColor(0, 0, 0)
  love.graphics.setPointSize(2)
  initWorld()
end

function initWorld()
  love.physics.setMeter(PPM)
  world = love.physics.newWorld(0, 0, true)

  player = {}
  player.body = love.physics.newBody(world, 0, 0, "dynamic")
  player.shape = love.physics.newRectangleShape(0,0,150,75)
  player.fixture = love.physics.newFixture(player.body, player.shape, 1)
  player.fixture:setRestitution(0.1)
  player.fixture:setUserData("Player")

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
  function player:aslow(spd)
    local x,y = self.body:getPosition()
    local phi = self.body:getAngle()
    local mod = self.body:getAngularVelocity()
    if mod < 0 then
      self.rotR(spd)
    elseif mod > 0 then
      self.rotL(spd)
    end
  end
  function player:shoot()
    local x,y = self.body:getPosition()
    local phi = self.body:getAngle()
    local vx,vy = self.body:getLinearVelocity()

    local dirX,dirY = 100*math.cos(phi),100*math.sin(phi)

    spawnBullet(x+dirX,y+dirY,dirX,dirY,phi)
  end
  function player:damage()
  end

  world:setCallbacks(beginContact, endContact, preSolve, postSolve)

  for i=1,ParticleMax-1,1 do
    Particle[i]={x=0,y=0}
  end

  for i=0,AsteroidMax,1 do
    local asteroid = {}
    function asteroid:damage()
      self.shape:setRadius(self.shape:getRadius()-1)
    end
    local r = math.random(15,75)
    local x = 0
    local y = 199999+i*80
    asteroid.body = love.physics.newBody(world, x, y, "dynamic")
    asteroid.shape = love.physics.newCircleShape(0, 0, r)
    asteroid.fixture = love.physics.newFixture(asteroid.body, asteroid.shape, 2-(75/r))
    asteroid.fixture:setUserData("Asteroid"..i)
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

  
  if timeAsteroids<love.timer.getTime()-1 then
    timeAsteroids = love.timer.getTime()
    local phi = math.random(0,360)
    local radius = math.random(2000,7500)
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
    LidarPhi=(LidarPhi+5)%355
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
      local distR = math.abs((GoalPhi - (phi+phiV*0.75)+360)%360)
      local distL = math.abs(((phi+phiV*0.75) - GoalPhi+360)%360)
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
    love.graphics.polygon("fill",b.body:getWorldPoints(b.shape:getPoints()))
  end

  love.graphics.print(string.format("X %.1f Y %.1f",x,y),x-WWIDTH/2+50,y-WHEIGHT/2+50)
  love.graphics.print(string.format("Angle %.5f",phi),x-WWIDTH/2+50,y-WHEIGHT/2+70)

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
    if r>225 then
      AutoRotate = false
      UpdateLidar = false
      for i=0,#Lidar,1 do
        if math.random(1,8)<3 then
          Lidar[i]=math.random(1,75)/100
        end
      end
    end
  end
  if string.sub(b:getUserData(),1,6)=="Bullet" or string.sub(a:getUserData(),1,6)=="Bullet" then
    if string.sub(b:getUserData(),1,8)=="Asteroid" then
      Asteroid[tonumber(string.sub(b:getUserData(),9,14))]:damage()
    elseif string.sub(a:getUserData(),1,8)=="Asteroid" then
      Asteroid[tonumber(string.sub(a:getUserData(),9,14))]:damage()
    elseif string.sub(b:getUserData(),1,6)=="Player" or string.sub(a:getUserData(),1,6)=="Player" then
      player:damage()
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
  Lidar[LidarPhi-4]=fraction
  return 0
end
ray[2] = function(fixture, x, y, xn, yn, fraction)
  Lidar[LidarPhi-3]=fraction
  return 0
end
ray[3] = function(fixture, x, y, xn, yn, fraction)
  Lidar[LidarPhi-2]=fraction
  return 0
end
ray[4] = function(fixture, x, y, xn, yn, fraction)
  Lidar[LidarPhi-1]=fraction
  return 0
end
ray[5] = function(fixture, x, y, xn, yn, fraction)
  Lidar[LidarPhi-0]=fraction
  return 0
end

function addAsteroid(x,y)
  AsteroidIndex=(AsteroidIndex+1)%AsteroidMax
  Asteroid[AsteroidIndex].fixture:getBody():setPosition(x,y)
end

function setPlayer(it,idx)
  obj[idx]=it
end

function getPlayer(idx)
  return obj[idx]
end

function subPlayer(idx)
  if obj[idx] then
    obj[idx].body:destroy()
    obj[idx]=nil
  end
end

function createPlayer(idx)
  local it = {}
  it.body = love.physics.newBody(world, 0, 0, "dynamic")
  it.shape = love.physics.newRectangleShape(0,0,100,50)
  it.fixture = love.physics.newFixture(it.body, it.shape, 1)
  it.fixture:setRestitution(0.9)
  it.fixture:setUserData("Player "..idx)
  return it
end

function spawnBullet(x,y,vx,vy,phi)
  local it = {}
  it.body = love.physics.newBody(world, x, y, "dynamic")
  it.shape = love.physics.newRectangleShape(0,0,8,2)
  it.fixture = love.physics.newFixture(it.body, it.shape, 0.1)
  it.fixture:setRestitution(1)
  it.fixture:setUserData("Bullet")
  it.body:applyForce(vx,vy)
  it.body:setAngle(phi)
  it.body:setBullet(true)
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

function genPoints(n,r1,r2)
  local points = {}
  for i=1,n,1 do
    local phi = math.random(0,360)
    local radius = math.random(r1,r2)
    points[i]={}
    points[i].x=(radius*math.cos(phi/R2D))
    points[i].y=(radius*math.sin(phi/R2D))
  end
  return points
end

function movePoints(points, x, y)
  local newPoints = {}
  for i,p in pairs(points) do
    p.x=p.x+x
    p.y=p.y+y
    newPoints[i]=p
  end
  return newPoints
end

function removePoints(points, x, y, r)
  points = movePoints(points,-x,-y)
  local newPoints = {}
  local n = 1
  for i,p in pairs(points) do 
    local pr = math.sqrt(p.x^2+p.y^2)
    if pr>r then
      newPoints[n]=p
      n=n+1
    end
  end
  newPoints = movePoints(newPoints,x,y)
  return newPoints
end

function genAsteroids(play, num)
  local points = {}
  local n = 1
  for i,p in pairs(play) do
    local tmp = genPoints(math.ceil(num/#play),2000,7500)
    tmp=movePoints(tmp,p.x,p.y)
    for j,p1 in pairs(tmp) do
      points[n]=p1
      n=n+1
    end
  end
  for i,p in pairs(play) do
    points = removePoints(points,p.x,p.y,1500)
  end
  if #points==0 then
    print("LOOP")
    points=genAsteroids(play, num)
  end
  return points
end
