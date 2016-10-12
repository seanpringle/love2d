
function tap(x, y)

end

function swipe(x, y, dx, dy)

end

function pinch(x, y, delta)

end

function load()

end

function update()

end

function draw()

end

stdout = { }

function print(...)
  for _,arg in ipairs({...}) do
    table.insert(stdout, arg)
  end
  while #stdout > 40 do
    table.remove(stdout, 1)
  end
end

touches = { }
touch_one = 1
touch_two = 2
touch_diameter = 50

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

  local touch = nil
  local count = 0
  local array = { }
  local delta = 0

  for tid, touch in pairs(touches) do
    count = count + 1
    touch.id = tid
    table.insert(array, touch)
  end

  if count == 1 then
    touch = touch_one
    delta = math.sqrt((array[1].x * array[1].x) + (array[1].y * array[1].y))
    dx = array[1].dx
    dy = array[1].dy
  end

  if count == 2 then

    local x1 = array[2].x - array[1].x
    local y1 = array[2].y - array[1].y
    local d1 = math.sqrt(x1*x1 + y1*y1)

    local x2 = (array[2].x + array[2].dx) - (array[1].x + array[1].dx)
    local y2 = (array[2].y + array[2].dy) - (array[1].y + array[1].dy)
    local d2 = math.sqrt(x2*x2 + y2*y2)

    touch = touch_two
    delta = d2-d1
    x = math.floor((array[1].x+array[2].x)/2)
    y = math.floor((array[1].y+array[2].y)/2)
    dx = 0
    dy = 0
  end

  if touch == touch_one and math.abs(dx) < touch_diameter and math.abs(dy) < touch_diameter and touches[id].x == touches[id].ox and touches[id].y == touches[id].oy then
    tap(x, y, dx, dy)
  end

  if touch == touch_one and (math.abs(dx) > touch_diameter or math.abs(dy) > touch_diameter) and touches[id].x == touches[id].ox and touches[id].y == touches[id].oy then
    swipe(touches[id].x, touches[id].y, touches[id].dx, touches[id].dy)
  end

  if touch == touch_two and math.abs(delta) > touch_diameter then
    pinch(x, y, delta)
  end

  touches[id] = nil

  for tid, touch in pairs(touches) do
    touches[tid].x = touches[tid].x + touches[tid].dx
    touches[tid].y = touches[tid].y + touches[tid].dy
    touches[tid].dx = 0
    touches[tid].dy = 0
  end
end

function love.load()

  love.window.setMode(love.graphics.getWidth(), love.graphics.getHeight(), {
    fullscreen = true,
    vsync = true,
    msaa = 2,
    resizable = false,
    borderless = true,
    centered = true,
    highdpi = true,
  })

  load()

end

function love.update()
  update()
end

function love.draw()

  love.graphics.origin()
  love.graphics.setBlendMode('alpha')
  love.graphics.setColor(255, 255, 255, 255)
  love.graphics.setBackgroundColor(0, 0, 0, 0)
  love.graphics.clear()

  draw()

  love.graphics.origin()
  love.graphics.setBlendMode('alpha')
  love.graphics.setColor(255, 255, 255, 255)
  love.graphics.setBackgroundColor(0, 0, 0, 0)
  love.graphics.setFont(font_log)
  love.graphics.print(table.concat(stdout, "\n"), 0, 0)

end

-- app

doc = nil

font_doc = nil
font_log = nil
font_key = nil

config = {
  colors = {
    normal = { 255, 255, 255, 255 },
    focus  = { 255, 255,   0, 255 },
  },
  fonts = {
    doc = 32,
    log = 12,
    key = 50,
  },
  page = {
    margins = {
      top = 0.1,
      bottom = 0.1,
      left = 0.2,
      right = 0.2,
      paragraph = 0.1,
    }
  }
}

Word = { }

function Word:new(text)
  local o = { }
  setmetatable(o, self)
  self.__index = self
  o:init(text)
  return o
end

function Word:init(text)

  self.comma   = false
  self.period  = false
  self.exclaim = false
  self.squote  = false
  self.dquote  = false
  self.hyphen  = false
  self.text    = nil

  self:write(text)
end

function Word:write(text)

  self.text = (text and text:len() > 0) and text or '_'

  local text  = love.graphics.newText(font_doc, self.text)
  self.width  = text:getWidth()
  self.height = text:getHeight()
end

function Word:read()
  return self.text
end

function Word:len()
  return (self.text == '_') and 0 or self.text:len()
end

function Word:input(c)

  if c:match("^[a-zA-Z0-9']$") then
    self:write(self.text ~= '_' and self.text..c or c)
  end

  if c == ',' then
    self.comma   = not self.comma
    self.period  = false
    self.exclaim = false
    self.hyphen  = false
  end

  if c == '.' then
    self.comma   = false
    self.period  = not self.period
    self.exclaim = false
    self.hyphen  = false
  end

  if c == '!' then
    self.comma   = false
    self.period  = false
    self.exclaim = not self.exclaim
    self.hyphen  = false
  end

  if c == '"' then
    self.dquote  = not self.dquote
  end

  if c == '-' then
    self.comma   = false
    self.period  = false
    self.exclaim = false
    self.hyphen  = not self.hyphen
  end
end

function Word:backspace()
  if self:len() > 0 then
    self:write(self.text:sub(1, self:len()-1))
  end
end

Paragraph = { }

function Paragraph:new(words)
  local o = { }
  setmetatable(o, self)
  self.__index = self
  o:init(words)
  return o
end

function Paragraph:init(words)
  self.words = words or { Word:new() }
  self.current = 1
  self:render()
end

function Paragraph:input(c)
  self:word():input(c)
  self:render()
end

function Paragraph:space()
  if self:word():len() > 0 then
    local oword = self:word()
    table.insert(self.words, Word:new())
    self:focus(1)
    local nword = self:word()
    nword.dquote = oword.dquote
    self:render()
    return true
  end
  return false
end

function Paragraph:backspace()
  if self:word():len() > 0 then
    self:word():backspace()
    self:render()
    return true
  elseif self:word():len() == 0 and self.current > 1 then
    table.remove(self.words)
    self:focus(0)
    self:render()
    return true
  end
  return false
end

function Paragraph:write(text)

end

atom_word = 1
atom_punct = 2

function Paragraph:atoms()

  local atoms = { }
  local types = { }

  local dquote = false

  for i, word in ipairs(self.words) do

    local nword = self.words[i+1]

    if not dquote and word.dquote then
      dquote = true
      table.insert(atoms, '"')
      table.insert(types, atom_punct)
    end

    table.insert(atoms, word:read())
    table.insert(types, atom_word)

    local space = nword ~= nil

    if word.hyphen then
      table.insert(atoms, '-')
      table.insert(types, atom_punct)
      space = false
    end
    if word.comma then
      table.insert(atoms, ',')
      table.insert(types, atom_punct)
    end
    if word.period then
      table.insert(atoms, '.')
      table.insert(types, atom_punct)
    end
    if word.exclaim then
      table.insert(atoms, '!')
      table.insert(types, atom_punct)
    end

    if dquote and (not nword or not nword.dquote) then
      dquote = false
      table.insert(atoms, '"')
      table.insert(types, atom_punct)
    end

    if space then
      table.insert(atoms, ' ')
      table.insert(types, atom_punct)
    end
  end
  return atoms, types
end

function Paragraph:read()
  local atoms = self:atoms()
  return table.concat(atoms, '')
end

function Paragraph:render()

  self.width = config.page.width

  local atoms, types = self:atoms()
  local colors = { }
  local index  = 1

  for i, atom in ipairs(atoms) do
    table.insert(colors, (index == self.current and types[i] == atom_word) and config.colors.focus or config.colors.normal)
    table.insert(colors, atom)
    if types[i] == atom_word then index = index + 1 end
  end

  local text = love.graphics.newText(font_doc)
  text:setf(colors, self.width, 'left')

  self.height = text:getHeight()

  self.drawable = love.graphics.newCanvas(self.width, self.height)

  love.graphics.setCanvas(self.drawable)
  love.graphics.setColor(255, 255, 255, 255)
  love.graphics.setBackgroundColor(0, 0, 0, 0)
  love.graphics.clear(64, 64, 64, 255)
  love.graphics.origin()
  love.graphics.setBlendMode('alpha')
  love.graphics.draw(text, 0, 0)
  love.graphics.setCanvas()
end

function Paragraph:focus(n)
  self.current = math.max(1, math.min(#self.words, self.current + n))
end

function Paragraph:word()
  return self.words[self.current]
end

Document = { }

function Document:new(paragraphs)
  local o = { }
  setmetatable(o, self)
  self.__index = self
  o:init(paragraphs)
  return o
end

function Document:init(paragraphs)
  self.paragraphs = paragraphs or { Paragraph:new() }
  self.current = 1
  self:render()
end

function Document:input(c)
  self:paragraph():input(c)
  self:render()
end

function Document:focus(n)
  self.current = math.max(1, math.min(#self.paragraphs, self.current + n))
end

function Document:space()
  self:paragraph():space()
  self:render()
end

function Document:backspace()
  self:paragraph():backspace()
  self:render()
end

function Document:paragraph()
  return self.paragraphs[self.current]
end

function Document:render()

  local parts = { }

  local current_min = self.current
  local y_min = love.graphics.getHeight()/2
  y_min = math.ceil(y_min - self.paragraphs[current_min].height/2)

  while y_min > 0 and current_min > 1 do
    current_min = current_min - 1
    y_min = math.ceil(y_min - self.paragraphs[current_min].height - love.graphics.getHeight()*config.page.margins.paragraph)
  end

  local current_max = self.current
  local y_max = love.graphics.getHeight()/2
  y_max = math.ceil(y_max + self.paragraphs[current_max].height/2)

  while y_max < love.graphics.getHeight() and current_max < #self.paragraphs do
    current_max = current_max + 1
    y_max = math.ceil(y_max + self.paragraphs[current_max].height + love.graphics.getHeight()*config.page.margins.paragraph)
  end

  self.drawable = love.graphics.newCanvas(config.page.width, config.page.height)

  love.graphics.setCanvas(self.drawable)
  love.graphics.setColor(255, 255, 255, 255)
  love.graphics.setBackgroundColor(0, 0, 0, 0)
  love.graphics.setBlendMode('alpha', 'premultiplied')
  love.graphics.origin()
  love.graphics.clear(32, 32, 32, 255)

  local y = y_min

  for i = current_min, current_max do
    local paragraph = self.paragraphs[i]
    love.graphics.draw(paragraph.drawable, 0, y)
    y = y + paragraph.height + love.graphics.getHeight()*config.page.margins.paragraph
  end

  love.graphics.setCanvas()
end

function press(c)
  doc:input(shift and c:upper() or c:lower())
end

morse = { }
morse['.-'] = 'A'
morse['-...'] = 'B'
morse['-.-.'] = 'C'
morse['-..'] = 'D'
morse['.'] = 'E'
morse['..-.'] = 'F'
morse['--.'] = 'G'
morse['....'] = 'H'
morse['..'] = 'I'
morse['.---'] = 'J'
morse['-.-'] = 'K'
morse['.-..'] = 'L'
morse['--'] = 'M'
morse['-.'] = 'N'
morse['---'] = 'O'
morse['.--.'] = 'P'
morse['--.-'] = 'Q'
morse['.-.'] = 'R'
morse['...'] = 'S'
morse['-'] = 'T'
morse['..-'] = 'U'
morse['...-'] = 'V'
morse['.--'] = 'W'
morse['-..-'] = 'X'
morse['-.--'] = 'Y'
morse['--..'] = 'Z'
morse['-----'] = '0'
morse['.----'] = '1'
morse['..---'] = '2'
morse['...--'] = '3'
morse['....-'] = '4'
morse['.....'] = '5'
morse['-....'] = '6'
morse['--...'] = '7'
morse['---..'] = '8'
morse['----.'] = '9'
morse['.-...'] = '&'
morse['.-.-.-'] = '.'
morse['--..--'] = ','
morse['..--..'] = '?'
morse['.--.-.'] = '@'
morse['-.-.--'] = '!'
morse['---...'] = ':'
morse['-.-.-.'] = ';'
morse['.----.'] = "'"
morse['.-..-.'] = '"'
morse['-....-'] = '-'
morse['..--.-'] = '_'
morse['-..-.']  = '/'
morse['-.--.']  = '('
morse['-.--.-'] = ')'

morse_codes = { }
for code, char in pairs(morse) do
  morse_codes[#morse_codes+1] = code
end

table.sort(morse_codes, function(a,b)
  return #a<#b
end)

morse_canvas = { }
morse_list = { }

morse_prefixes = { }

for code, char in pairs(morse) do
  morse_prefixes[code] = { }
  for i = 1, #code do
    morse_prefixes[code:sub(1,i)] = { }
  end
end

for code, char in pairs(morse) do
  for pcode, plist in pairs(morse_prefixes) do
    if #code > #pcode and code:sub(1,#pcode) == pcode then
      table.insert(plist, code)
    end
  end
end

for pcode, plist in pairs(morse_prefixes) do
  table.sort(plist, function(a,b)
    return #a<#b
  end)
end

input = ''
shift = false

function tap(x, y, dx, dy)

  print(string.format("tap %d %d %d %d", x, y, dx, dy))

  local top    = love.graphics.getHeight() * config.page.margins.top
  local bottom = love.graphics.getHeight() - (love.graphics.getHeight() * config.page.margins.bottom)
  local left   = config.page.left
  local right  = config.page.right

  if x > left and x < right and y > love.graphics.getHeight() - 50 then
    doc:space()

  elseif x > right and y < font_key:getHeight() then
    if morse[input] then
      press(morse[input])
    end
    input = ''

  elseif y < top then
    love.event.quit()

  elseif x < left then
    input = input .. '.'

  elseif x > right then
    input = input .. '-'
  end

  if input:len() > 6 then
    input = ''
  end

  morse_list = { }
end

function swipe(x, y, dx, dy)

  print(string.format("swipe %d %d %d %d", x, y, dx, dy))

  local top    = love.graphics.getHeight() * config.page.margins.top
  local bottom = love.graphics.getHeight() - (love.graphics.getHeight() * config.page.margins.bottom)
  local left   = config.page.left
  local right  = config.page.right

  local is_y = math.abs(dy) > math.abs(dx)
  local is_x = not is_y

  if is_x and input:len() > 0 then

    if x + dx > right then
      input = ''
    end

    if morse[input] == nil and x > right and x + dx < right and morse_prefixes[input] and #morse_prefixes[input] > 0 then
      press(morse[morse_prefixes[input][1]])
      input = ''
    end

    if morse[input] and x > right and x + dx < right then
      press(morse[input])
      input = ''
    end
  end

  if is_x and x < right and dx < 0 and x + dx > left then
    doc:backspace()
  end

  if is_x and x > left and dx > 0 and x + dx < right then
    doc:space()
  end

  if is_y and x > right and dy > 0 then
    shift = false
  end

  if is_y and x > right and dy < 0 then
    shift = true
  end
end

function pinch(x, y, delta)

  print(string.format("pinch %d %d %d", x, y, delta))

end

function load()

  config.page.width = math.floor(love.graphics.getWidth() - (love.graphics.getWidth() * config.page.margins.left) - (love.graphics.getWidth() * config.page.margins.right))
  config.page.height = love.graphics.getHeight()
  config.page.left = (love.graphics.getWidth() - config.page.width)/2
  config.page.right = config.page.left + config.page.width
  font_log = love.graphics.newFont(config.fonts.log)
  font_doc = love.graphics.newFont(config.fonts.doc)
  font_key = love.graphics.newFont(config.fonts.key)

  for code, char in pairs(morse) do

    morse_canvas[code] = { }

    local text = love.graphics.newText(font_key)
    text:setf(string.format('%s %s', char:lower(), code), 200, 'left')

    morse_canvas[code][char:lower()] = love.graphics.newCanvas(text:getWidth(), text:getHeight())

    love.graphics.setCanvas(morse_canvas[code][char:lower()])
    love.graphics.setColor(255, 255, 255, 255)
    love.graphics.setBackgroundColor(0, 0, 0, 0)
    love.graphics.setBlendMode('alpha')
    love.graphics.origin()
    love.graphics.clear()

    love.graphics.draw(text)

    love.graphics.setCanvas()

    local text = love.graphics.newText(font_key)
    text:setf(string.format('%s %s', char:upper(), code), 200, 'left')

    morse_canvas[code][char:upper()] = love.graphics.newCanvas(text:getWidth(), text:getHeight())

    love.graphics.setCanvas(morse_canvas[code][char:upper()])
    love.graphics.setColor(255, 255, 255, 255)
    love.graphics.setBackgroundColor(0, 0, 0, 0)
    love.graphics.setBlendMode('alpha')
    love.graphics.origin()
    love.graphics.clear()

    love.graphics.draw(text)

    love.graphics.setCanvas()


  end

  doc = Document:new()
end

function update()

  if input:len() > 0 and #morse_list == 0 then

    if morse[input] then
      morse_list[1] = input
    end

    for i, code in ipairs(morse_prefixes[input] or { }) do
      table.insert(morse_list, code)
    end

  end

  collectgarbage()
end

function draw()

  love.graphics.setColor(255, 255, 255, 255)
  love.graphics.setBackgroundColor(0, 0, 0, 0)
  love.graphics.setBlendMode('alpha', 'premultiplied')
  love.graphics.origin()
  love.graphics.clear()

  love.graphics.draw(doc.drawable, love.graphics.getWidth()*config.page.margins.left, 0)

  if input:len() > 0 then

    local y = 0

    for i, code in ipairs(morse_list) do

      local char = shift and morse[code] or morse[code]:lower()
      love.graphics.draw(morse_canvas[code][char], love.graphics.getWidth() - 150, y)
      y = y + morse_canvas[code][char]:getHeight()

    end
  end
end













