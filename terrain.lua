cfg = {
  seed = 1000,
  cell = {
    x = 5,
    y = 4,
  },
  map = {
    x = 200,
    y = 200,
    z = 10,
    sealevel = 3,
    snowline = 9,
  },
}

stdout = { }

function print(...)
  for _,arg in ipairs({...}) do
    table.insert(stdout, arg)
  end
  while #stdout > 40 do
    table.remove(stdout, 1)
  end
end

HeightMap = { }

function HeightMap:new(x, y)

  local map = { x = math.floor(x), y = math.floor(y) }

  setmetatable(map, self)
  self.__index = self

  map:init()

  return map
end

function HeightMap:init()

  self.zmin = 0
  self.zmax = 0

  for x = 1,self.x do
    self[x] = { }
    for y = 1,self.y do
      self[x][y] = 0
    end
  end
end

function HeightMap:template(src)

  self.zmin = 100
  self.zmax = 0

  for x = 1,self.x do
    for y = 1,self.y do

      local sx = math.min(src.x, math.max(1, math.ceil(src.x / self.x * x)));
      local sy = math.min(src.y, math.max(1, math.ceil(src.y / self.y * y)));
      self[x][y] = src[sx][sy]

      self.zmin = math.min(self.zmin, self[x][y])
      self.zmax = math.max(self.zmax, self[x][y])
    end
  end
end

function HeightMap:elevate(factor)

  self.zmin = 100
  self.zmax = 0

  for x = 1,self.x do
    for y = 1,self.y do
      self[x][y] = math.floor(self[x][y] * factor)
      self.zmin = math.min(self.zmin, self[x][y])
      self.zmax = math.max(self.zmax, self[x][y])
    end
  end
end

function HeightMap:seed(seed, range)

  love.math.setRandomSeed(seed)

  self.zmin = 100
  self.zmax = 0

  for x = 1,self.x do
    for y = 1,self.y do
      self[x][y] = self[x][y] + math.floor(love.math.random(range))
      self.zmin = math.min(self.zmin, self[x][y])
      self.zmax = math.max(self.zmax, self[x][y])
    end
  end
end

function HeightMap:smooth()

  local remap = { }

  for x = 1,self.x do
    remap[x] = { }
    for y = 1,self.x do
      remap[x][y] = self[x][y]
    end
  end

  self.zmin = 100
  self.zmax = 0

  for x = 1,self.x do

    for y = 1,self.x do

      local sibs = 1
      local height = self[x][y]

      if x >      1 and y >      1 then height = height + self[x-1][y-1] sibs = sibs+1 end
      if x >      1                then height = height + self[x-1][y+0] sibs = sibs+1 end
      if x >      1 and y < self.y then height = height + self[x-1][y+1] sibs = sibs+1 end
      if                y >      1 then height = height + self[x+0][y-1] sibs = sibs+1 end
      if                y < self.y then height = height + self[x+0][y+1] sibs = sibs+1 end
      if x < self.x and y >      1 then height = height + self[x+1][y-1] sibs = sibs+1 end
      if x < self.x                then height = height + self[x+1][y+0] sibs = sibs+1 end
      if x < self.x and y < self.y then height = height + self[x+1][y+1] sibs = sibs+1 end

      remap[x][y] = math.floor(height / sibs)

      self.zmin = math.min(self.zmin, remap[x][y])
      self.zmax = math.max(self.zmax, remap[x][y])
    end
  end

  for x = 1,self.x do
    for y = 1,self.x do
      self[x][y] = remap[x][y] - self.zmin
    end
  end

  self.zmax = self.zmax - self.zmin
end

Unit = { }
units = { }

function Unit:new()

  local unit = { id = #units+1 }

  setmetatable(unit, self)
  self.__index = self

  unit:init()

  return unit
end

function Unit:init()
  self.x = 1
  self.y = 1
  self.dx = 0
  self.dy = 0
end

Immotile = Unit:new()

function Immotile:new()

end

Motile = Unit:new()

function Motile:init()

end

Group = { }
groups = { }

function Group:new(o)

  local group = { id = #groups+1 }

  setmetatable(group, self)
  self.__index = self

  group:init()

  return group
end

smap1 = HeightMap:new(cfg.map.x/16, cfg.map.y/16)
smap1:seed(cfg.seed, cfg.map.z)
smap1:smooth()

smap2 = HeightMap:new(cfg.map.x/8, cfg.map.y/8)
smap2:template(smap1)
smap2:seed(cfg.seed, cfg.map.z/2)
smap2:smooth()

smap3 = HeightMap:new(cfg.map.x/4, cfg.map.y/4)
smap3:template(smap2)
smap3:seed(cfg.seed, cfg.map.z/4)
smap3:smooth()

map = HeightMap:new(cfg.map.x, cfg.map.y)
map:template(smap3)
map:seed(cfg.seed, cfg.map.z/6)
map:elevate(1.2)
map:smooth()
map:smooth()
--map:smooth()

cell = {
  x = cfg.cell.x,
  y = cfg.cell.y,
}

cell.px = function(x)
  return cell.x * x
end

cell.py = function(y)
  return cell.y * y
end

love.window.setMode(cell.px(map.x), cell.py(map.y), {
  fullscreen = true,
  vsync = true,
  msaa = 2,
  resizable = false,
  borderless = false,
  centered = true,
  highdpi = true,
})

camera = {
  x = map.x/2,
  y = map.y/2,
  dx = 0,
  dy = 0,
  delta = 0,
  zoom = 1.0,
  zoom_min = 0.5,
  zoom_max = 10.0,
}

touches = { }
touch_one = 1
touch_two = 2
touch_sensitivity = 0.5

function touch()

  local touch = nil
  local count = 0
  local array = { }

  for id, touch in pairs(touches) do
    count = count + 1
    touch.id = id
    table.insert(array, touch)
  end

  if count == 1 then
    local delta = math.sqrt((array[1].x * array[1].x) + (array[1].y * array[1].y))
    return touch_one, delta, array[1].dx, array[1].dy
  end

  if count == 2 then

    local x = array[2].x - array[1].x
    local y = array[2].y - array[1].y
    local d1 = math.sqrt(x*x + y*y)

    local x = (array[2].x + array[2].dx) - (array[1].x + array[1].dx)
    local y = (array[2].y + array[2].dy) - (array[1].y + array[1].dy)
    local d2 = math.sqrt(x*x + y*y)

    return touch_two, d2-d1
  end

  return nil
end

function tap(x, y)



end

function love.touchpressed(id, x, y, dx, dy)

  for id, touch in pairs(touches) do
    touches[id].x = touches[id].x + touches[id].dx
    touches[id].y = touches[id].y + touches[id].dy
    touches[id].dx = 0
    touches[id].dy = 0
  end

  touches[id] = {
    x = x,
    y = y,
    ox = x,
    oy = y,
    dx = 0,
    dy = 0,
  }
end

function love.touchmoved(id, x, y, dx, dy)
  touches[id].dx = x - touches[id].x
  touches[id].dy = y - touches[id].y
end

function love.touchreleased(id, x, y, dx, dy)

  love.touchmoved(id, x, y, dx, dy)

  local touch, delta, dx, dy = touch()

  if touch == touch_one and dx < (touch_sensitivity*10) and dy < (touch_sensitivity*10) and touches[id].x == touches[id].ox and touches[id].y == touches[id].oy then
    tap(x, y)
  end

  for id, touch in pairs(touches) do
    touches[id].x = touches[id].x + touches[id].dx
    touches[id].y = touches[id].y + touches[id].dy
    touches[id].dx = 0
    touches[id].dy = 0
  end

  touches[id] = nil
end

function love.update()

  local touch, delta, dx, dy = touch()
  local scale = 1/camera.zoom

  if touch == touch_one then

    camera.x = math.min(map.x, math.max(0, camera.x - (dx-camera.dx)/cfg.cell.x*scale))
    camera.y = math.min(map.y, math.max(0, camera.y - (dy-camera.dy)/cfg.cell.y*scale))
    camera.dx = dx
    camera.dy = dy
    camera.delta = 0

  elseif touch == touch_two then

    if delta > camera.delta then
      camera.zoom = math.min(camera.zoom_max, camera.zoom+((delta-camera.delta)/scale/(touch_sensitivity*1000)))
    elseif delta < camera.delta then
      camera.zoom = math.max(camera.zoom_min, camera.zoom-((camera.delta-delta)/scale/(touch_sensitivity*1000)))
    end

    camera.dx = 0
    camera.dy = 0
    camera.delta = delta

  else
    camera.dx = 0
    camera.dy = 0
    camera.delta = 0
  end
end

map.canvas = nil

function map_render()

  map.canvas = love.graphics.newCanvas(cell.px(map.x), cell.py(map.y))
  map.canvas:setFilter("linear", "nearest")

  love.graphics.setCanvas(map.canvas)
  love.graphics.clear()

  for x = 1,map.x do
    for y = 1,map.y do

      local z = map[x][y]

      local r = 64 + z * 10
      local g = 64 + z * 10
      local b = 64 + z * 10

      if z <= cfg.map.sealevel then
        b = 255
      end

      if z >= cfg.map.snowline then
        r = r + 32
        g = g + 32
        b = b + 32
      end

      if z > cfg.map.sealevel and z < cfg.map.snowline then
        g = g + 32
      end

      love.graphics.setColor(r, g, b, 255)
      love.graphics.rectangle("fill", cell.px(x-1), cell.py(y-1), cell.x, cell.y)
    end
  end

  love.graphics.setCanvas()
end

map_render()

function love.draw()

  love.graphics.translate(love.graphics.getWidth()/2 + cell.px(-camera.x*camera.zoom), love.graphics.getHeight()/2 + cell.py(-camera.y*camera.zoom))
  love.graphics.scale(camera.zoom)

  love.graphics.clear()
  love.graphics.setColor(255, 255, 255, 255)
  love.graphics.setBackgroundColor(0, 0, 0, 255)
  love.graphics.setBlendMode("alpha", "premultiplied")
  love.graphics.draw(map.canvas)

  love.graphics.origin()

  for id, touch in pairs(touches) do
    love.graphics.circle("fill", touch.x + touch.dx, touch.y + touch.dy, 20)
  end

  love.graphics.origin()
  love.graphics.setBlendMode('alpha')
  love.graphics.setColor(255, 255, 255, 255)
  love.graphics.print(table.concat(stdout, "\n"), love.graphics.getWidth()-250, 0)

end
















