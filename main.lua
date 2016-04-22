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

print(map.zmin.." "..map.zmax)

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
  fullscreen = false,
  vsync = true,
  msaa = 2,
  resizable = false,
  borderless = false,
  centered = true,
  highdpi = true,
})

camera = {
  x = 0,
  y = 0,
  zoom = 1.0,
}

function love.update()

  -- zoom
  if love.keyboard.isDown("e") then
    camera.zoom = math.min(4, camera.zoom+0.1)
  elseif love.keyboard.isDown("q") then
    camera.zoom = math.max(1, camera.zoom-0.1)
  end

  -- move horiz
  if love.keyboard.isDown("a") then
    camera.x = math.max(0, camera.x-cfg.cell.x)
  elseif love.keyboard.isDown("d") then
    camera.x = math.min(map.x-1, camera.x+cfg.cell.x)
  end

  -- move vert
  if love.keyboard.isDown("w") then
    camera.y = math.max(0, camera.y-cfg.cell.y)
  elseif love.keyboard.isDown("s") then
    camera.y = math.min(map.y-1, camera.y+cfg.cell.y)
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

  love.graphics.translate(cell.px(-camera.x*camera.zoom), cell.py(-camera.y*camera.zoom))
  love.graphics.scale(camera.zoom)

  love.graphics.clear()
  love.graphics.setColor(255, 255, 255, 255)
  love.graphics.setBackgroundColor(0, 0, 0, 255)
  love.graphics.setBlendMode("alpha", "premultiplied")
  love.graphics.draw(map.canvas)

end
