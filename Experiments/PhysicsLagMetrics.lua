--[[
node.js server borrowed from discord


[8:53 AM] extremePotPlant: Ill post my code so anyone else trying to get the HTTP working can copy
[8:56 AM] extremePotPlant:
-- Tick function that will be executed every logic tick
counter = 0
text = "[ [ [STARTING] ] ]"

function httpReply(port, request_body, response_body)

    if(response_body == "" or response_body == nil) then
        text = "[ [ [BLANK or NILL] ] ]"
    else
            text = response_body
    end
            
end


function onTick()
    counter = counter + 1
    if(counter > 300)then --request about every 5s
        async.httpGet(80, "/testpath")
        counter = 0
    end
    
end

-- Draw function that will be executed when this script renders to a screen
function onDraw()
    w = screen.getWidth()                  -- Get the screen's width and height
    h = screen.getHeight()                    
    screen.drawTextBox(3, 3, w, h, text, -1, -1)
end
[8:57 AM] extremePotPlant: Then on the node.js side:
const http = require("http");
const url = require('url');

const host = 'localhost';
const port = 80;

const requestListener = function (req, res) {
    res.setHeader("Content-Type", "text/plain");
    console.log("Routing: " + req.url);
    switch(url.parse(req.url,true).pathname){
        case "/testpath":
            res.writeHead(200);
            res.end("Hello Stormworks!");
            break;
        default:
            res.writeHead(200);
            res.end("Unrouted Path");
            break;

    }
    
    console.log("Server responded to request.");
};


const server = http.createServer(requestListener);
server.listen(port, host, () => {
    console.log(`Server is running on http://${host}:${port}`);
});
[9:03 AM] extremePotPlant: Now that we have it there we can now use the URL module to parse data like sensor readings.
[9:07 AM] Krolon:

[9:07 AM] Krolon: btw, does anyone have an idea why does it start with cnt equal to minmal value allowed by "max(min("?
[9:07 AM] Krolon: like it's extra annoying and comes out of seemingly nowhere
[9:08 AM] Krolon: why isn't it just 0
[9:09 AM] Krolon: issue doesn't exist on the lua.flaffipony.rocks
[9:09 AM] Krolon: only in game
[9:09 AM] Krolon: when vehicle spawns


local f = 0
local p = ""
function onDraw()
  async.httpGet(80, "http://127.0.0.1/main.php?channel=0&frame="..f)
  local w=0
  local h=0
  for ii=1, string.len(p), 2 do
    rgb = string.byte(p, ii + 1) | string.byte(p, ii) << 8
    r =  (rgb >> 11) & 31
    g = (rgb >> 5) & 63
    b = rgb & 31
    r2 = (r * 527 + 23) >> 6
    g2 = (g * 259 + 33) >> 6
    b2 = (b * 527 + 23) >> 6
    screen.setColor(r2, g2, b2, 122)
    screen.drawRect(w,h,1,1)
    w=w+1
    if w==160 then
      w=0
      h=h+1
    end
  end
  f = f + 1
  if f == 994 then
    f = 0
  end
 end
function httpReply(port, request_body, rb)
  p=rb
end

********


frame = 0
w = 0
h = 0
pixels = {}
function onTick()
    async.httpGet(80, "http://127.0.0.1/main.php?frame="..frame)
end

function onDraw()
    w = 0
    h = 0
    for ii = 1, 96 * 160 do
        screen.setColor(pixels[ii][1], pixels[ii][2], pixels[ii][3])
        screen.drawRect(w,h,1,1)
        w = w + 1
        if w == 159 then
            w = 0
            h = h + 1
        end
    end
    frame = frame + 1
    if frame == 994 then
        frame = 0
    end
end
    
function httpReply(port, request_body, response_body)
    pixels2 = response_body
    pixels = {}
    t = 1
    color = {}
    for gg = 1, #pixels2 do
        if pixels2:sub(gg,gg) == "," then --If end of color
            color[t] = color[t].tonumber()
            t = t + 1
        else 
            if pixels2:sub(gg,gg) == ";" then --If end of pixel color
                pixels[#pixels] = color
                color = {}
                t = 1
            else --Else
                color[t] = color[t]..pixels2:sub(gg,gg)
            end
        end
    end
end

function updatescreen(url)
    async.httpGet(2032, url)

    function httpReply(port, request_body, response_body)
        text=response_body
    end
end
x=0
text="awaiting response"
function onTick()
    trans=input.getNumber(2)
    xcord=input.getNumber(3)
    ycord=input.getNumber(4)
    url="http://localhost:2032?xcord="..xcord.."&ycord="..ycord.."&trans="..trans
    x=x+1
    if x>=180 then
        updatescreen(url)
        x=0
    end
end
    
function onDraw()
    w=screen.getWidth()
    h=screen.getHeight()
    screen.drawText(1,1,text)
    screen.drawTextBox(1,20,w-2,h/2,url)
end

-- Tick function that will be executed every logic tick
counter = 0
text = "[[[STARTING]]]"

function httpReply(port, request_body, response_body)

    if(response_body == "" or response_body == nil) then
        text = "[[[BLANK or NILL]]]"
    else
            text = response_body
    end
            
end


function onTick()
    counter = counter + 1
    if(counter > 300)then --request about every 5s
        async.httpGet(80, "/testpath")
        counter = 0
    end
    
end

-- Draw function that will be executed when this script renders to a screen
function onDraw()
    w = screen.getWidth()                  -- Get the screen's width and height
    h = screen.getHeight()                    
    screen.drawTextBox(3, 3, w, h, text, -1, -1)
end




--]]