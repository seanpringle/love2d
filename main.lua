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

terrain = { }

function terrain.new (tx, ty)

  local map = {
    x = tx,
    y = ty,
    zmin = 0,
    zmax = 0,
  }

  for x = 1,tx do
    map[x] = { }
    for y = 1,ty do
      map[x][y] = 0
    end
  end

  return map
end

function terrain.template (map, src)

  map.zmin = 100
  map.zmax = 0

  for x = 1,map.x do
    for y = 1,map.y do

      local sx = math.min(src.x, math.max(1, math.ceil(src.x / map.x * x)));
      local sy = math.min(src.y, math.max(1, math.ceil(src.y / map.y * y)));
      map[x][y] = src[sx][sy]

      map.zmin = math.min(map.zmin, map[x][y])
      map.zmax = math.max(map.zmax, map[x][y])
    end
  end
end

function terrain.elevate (map, factor)

  map.zmin = 100
  map.zmax = 0

  for x = 1,map.x do
    for y = 1,map.y do
      map[x][y] = math.floor(map[x][y] * factor)
      map.zmin = math.min(map.zmin, map[x][y])
      map.zmax = math.max(map.zmax, map[x][y])
    end
  end
end

function terrain.seed (map, seed, range)

  love.math.setRandomSeed(seed)

  map.zmin = 100
  map.zmax = 0

  for x = 1,map.x do
    for y = 1,map.y do
      map[x][y] = map[x][y] + math.floor(love.math.random(range))
      map.zmin = math.min(map.zmin, map[x][y])
      map.zmax = math.max(map.zmax, map[x][y])
    end
  end
end

function terrain.smooth(map)

  local remap = { }

  for x = 1,map.x do
    remap[x] = { }
    for y = 1,map.x do
      remap[x][y] = map[x][y]
    end
  end

  map.zmin = 100
  map.zmax = 0

  for x = 1,map.x do

    for y = 1,map.x do

      local sibs = 1
      local height = map[x][y]

      if x >     1 and y >     1 then height = height + map[x-1][y-1] sibs = sibs+1 end
      if x >     1               then height = height + map[x-1][y+0] sibs = sibs+1 end
      if x >     1 and y < map.y then height = height + map[x-1][y+1] sibs = sibs+1 end
      if               y >     1 then height = height + map[x+0][y-1] sibs = sibs+1 end
      if               y < map.y then height = height + map[x+0][y+1] sibs = sibs+1 end
      if x < map.x and y >     1 then height = height + map[x+1][y-1] sibs = sibs+1 end
      if x < map.x               then height = height + map[x+1][y+0] sibs = sibs+1 end
      if x < map.x and y < map.y then height = height + map[x+1][y+1] sibs = sibs+1 end

      remap[x][y] = math.floor(height / sibs)

      map.zmin = math.min(map.zmin, remap[x][y])
      map.zmax = math.max(map.zmax, remap[x][y])
    end
  end

  for x = 1,map.x do
    for y = 1,map.x do
      map[x][y] = remap[x][y] - map.zmin
    end
  end

  map.zmax = map.zmax - map.zmin

end

smap = terrain.new(cfg.map.x/10, cfg.map.y/10)
terrain.seed(smap, cfg.seed, cfg.map.z)
terrain.smooth(smap)
terrain.elevate(smap, 1.5)

map = terrain.new(cfg.map.x, cfg.map.y)
terrain.template(map, smap)
terrain.seed(map, cfg.seed, cfg.map.z)

while map.zmax > cfg.map.z do
  terrain.smooth(map)
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

function love.draw()

  for x = 1,map.x do
    for y = 1,map.y do
      local z = map[x][y]
      local r = 64 + z * 10
      local g = 64 + z * 10
      local b = 64 + z * 10
      love.graphics.setColor(r, g, b, 255)
      love.graphics.rectangle("fill", cell.px(x), cell.py(y), cell.x, cell.y)
    end
  end
end
