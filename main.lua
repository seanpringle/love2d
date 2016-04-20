cfg = {
  seed = 1000,
  cell = {
    x = 10,
    y = 9,
  },
  map = {
    x = 100,
    y = 100,
    z = 10,
  },
}

HeightMap = { }

function HeightMap:new(x, y)

  local map = { x = x, y = y }
  
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

smap = HeightMap:new(cfg.map.x/10, cfg.map.y/10)
smap:seed(cfg.seed, cfg.map.z)
smap:smooth()
smap:elevate(1.5)

map = HeightMap:new(cfg.map.x, cfg.map.y)
map:template(smap)
map:seed(cfg.seed, cfg.map.z)

while map.zmax > cfg.map.z do
  map:smooth()
end

cell = {
  x = cfg.cell.x,
  y = cfg.cell.y,
}

cell.px = function(x)
  return cell.x * (x-1)
end

cell.py = function(y)
  return cell.y * (y-1)
end

love.window.setMode(cell.px(map.x+1), cell.py(map.y+1), {
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

function love.draw()

  love.graphics.translate(camera.x, camera.y)
  love.graphics.scale(camera.zoom)

  for x = 1,map.x do
    for y = 1,map.y do
      
      local z = map[x][y]
      
      local r = 64 + z * 10
      local g = 64 + z * 10
      local b = 64 + z * 10

      if z < 4 then
        b = 255
      end

      if z > 8 then
        r = r + 32
        g = g + 32
        b = b + 32
      end

      if z >= 4 and z <= 8 then
        g = g + 32
      end

      love.graphics.setColor(r, g, b, 255)
      love.graphics.rectangle("fill", cell.px(x), cell.py(y), cell.x, cell.y)
    end
  end
end
