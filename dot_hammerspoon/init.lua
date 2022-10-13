require("hs.ipc")

hyper = {"alt", "shift", "command", "control"}

-- Caffeine Replacement
hs.hotkey.bind({"cmd", "alt", "ctrl", "shift"}, "I", function()
  hs.caffeinate.set("displayIdle", true, true)
  hs.caffeinate.set("systemIdle", true, true)
  hs.caffeinate.set("system", true, true)
  hs.alert.show("Preventing Sleep")
end)
hs.hotkey.bind({"cmd", "alt", "ctrl", "shift"}, "O", function()
  hs.caffeinate.set("displayIdle", false, true)
  hs.caffeinate.set("systemIdle", false, true)
  hs.caffeinate.set("system", false, true)
  hs.alert.show("Allowing Sleep")
end)

--- start quick open applications
function open_app(name)
    return function()
        hs.application.launchOrFocus(name)
        if name == 'Finder' then
            hs.appfinder.appFromName(name):activate()
        end
    end
end

--- quick open applications
hs.hotkey.bind(hyper, "w", open_app("Google Chrome"))
hs.hotkey.bind(hyper, "e", open_app("Alacritty"))
hs.hotkey.bind(hyper, "r", open_app("Notion"))
hs.hotkey.bind(hyper, "d", open_app("Finder"))
hs.hotkey.bind(hyper, "t", open_app("Todoist"))

function applicationWatcher(appName, eventType, appObject)
    if (eventType == hs.application.watcher.activated) then
        if (appName == "Finder") then
            -- Bring all Finder windows forward when one gets activated
            appObject:selectMenuItem({"Window", "Bring All to Front"})
        end
    end
end
appWatcher = hs.application.watcher.new(applicationWatcher)
appWatcher:start()

-- yabai section

--# helpers
function yabai(args, completion)
	local yabai_output = ""
	local yabai_error = ""
	-- Runs in background very fast
	local yabai_task = hs.task.new("/opt/homebrew/bin/yabai",nil, function(task, stdout, stderr)
		--print("stdout:"..stdout, "stderr:"..stderr)
		if stdout ~= nil then yabai_output = yabai_output..stdout end
		if stderr ~= nil then yabai_error = yabai_error..stderr end
		return true
	end, args)
	if type(completion) == "function" then
		yabai_task:setCallback(function() completion(yabai_output, yabai_error) end)
	end
	yabai_task:start()
end

--# Main chooser
local mainChooser = hs.chooser.new(function(option)
	if option ~= nil then
		if option.action == "reload" then
			hs.reload()
		elseif option.action == "toggle_gap" then
			yabai({"-m", "space", "--toggle", "padding"}, function() yabai({"-m", "space", "--toggle", "gap"}) end)
		end
	end
end):choices({
{
	text = "Toggle Gap",
	subText = "Toggles padding and gaps around the current space",
	action = "toggle_gap"
},
{
	text = "Reload",
	subText = "Reload Hammerspoon configuration",
	action = "reload"
},
})

--# open main chooser
hs.hotkey.bind(hyper, hs.keycodes.map["space"], nil, function() mainChooser:show() end)

--# change window focus to direction
hs.hotkey.bind({"alt"}, "l", function() yabai({"-m", "window", "--focus", "east"}) end)  
hs.hotkey.bind({"alt"}, "h", function() yabai({"-m", "window", "--focus", "west"}) end) 
hs.hotkey.bind({"alt"}, "k", function() yabai({"-m", "window", "--focus", "north"}) end)  
hs.hotkey.bind({"alt"}, "j", function() yabai({"-m", "window", "--focus", "south"}) end)  

-- moving windoows
hs.hotkey.bind({"shift", "alt"}, "l", function() yabai({"-m", "window", "--warp", "east"}) end)  
hs.hotkey.bind({"shift", "alt"}, "h", function() yabai({"-m", "window", "--warp", "west"}) end) 
hs.hotkey.bind({"shift", "alt"}, "k", function() yabai({"-m", "window", "--warp", "north"}) end)  
hs.hotkey.bind({"shift", "alt"}, "j", function() yabai({"-m", "window", "--warp", "south"}) end)  

-- resizing windows section
hs.hotkey.bind(hyper, "f", function() yabai({"-m", "window", "--toggle", "zoom-fullscreen"}) end)  
hs.hotkey.bind({"lctrl", "alt"}, "h", function() 
  yabai({"-m", "window", "--resize", "left:-50:0"}) 
  yabai({"-m", "window", "--resize", "right:-50:0"})
end)
hs.hotkey.bind({"lctrl", "alt"}, "l", function() 
  yabai({"-m", "window", "--resize", "left:50:0"}) 
  yabai({"-m", "window", "--resize", "right:50:0"})
end)
hs.hotkey.bind({"lctrl", "alt"}, "j", function() 
  yabai({"-m", "window", "--resize", "bottom:0:50"}) 
  yabai({"-m", "window", "--resize", "top:0:50"})
end)
hs.hotkey.bind({"lctrl", "alt"}, "k", function() 
  yabai({"-m", "window", "--resize", "bottom:0:-50"}) 
  yabai({"-m", "window", "--resize", "top:0:-50"})
end)

hs.hotkey.bind({"lctrl", "alt"}, "e", function() yabai({"-m", "space", "--balance", ""}) end)  

-- selecting layout
hs.hotkey.bind({"lctrl", "alt"}, "a", function() yabai({"-m", "space", "--layout", "bsp"}) end)  
hs.hotkey.bind({"lctrl", "alt"}, "d", function() yabai({"-m", "space", "--layout", "float"}) end)  
hs.hotkey.bind({"lctrl", "alt"}, "s", function() yabai({"-m", "space", "--layout", "stack"}) end)  

-- rotating windows
hs.hotkey.bind({"alt"}, "r", function() yabai({"-m", "space", "--rotate", "270"}) end)  
hs.hotkey.bind({"shift", "alt"}, "r", function() yabai({"-m", "space", "--rotate", "90"}) end)  

-- toggle floating
hs.hotkey.bind({"alt"}, "t", function()
  yabai({"-m", "window", "--toggle", "float"})
  yabai({"-m", "window", "--grid", "4:4:1:1:2:2"})
end)  


-- move window to space 
hs.hotkey.bind({"alt", "shift"}, "1", function() 
  yabai({"-m", "window", "--space", "1"})
end)  
hs.hotkey.bind({"alt", "shift"}, "2", function() 
  yabai({"-m", "window", "--space", "2"})
end)  
hs.hotkey.bind({"alt", "shift"}, "3", function() 
  yabai({"-m", "window", "--space", "3"})
end)  
hs.hotkey.bind({"alt", "shift"}, "4", function() 
  yabai({"-m", "window", "--space", "4"})
end)  
hs.hotkey.bind({"alt", "shift"}, "5", function() 
  yabai({"-m", "window", "--space", "5"})
end)  
hs.hotkey.bind({"alt", "shift"}, "5", function() 
  yabai({"-m", "window", "--space", "5"})
end)  
hs.hotkey.bind({"alt", "shift"}, "6", function() 
  yabai({"-m", "window", "--space", "6"})
end)  
hs.hotkey.bind({"alt", "shift"}, "7", function() 
  yabai({"-m", "window", "--space", "7"})
end)  
hs.hotkey.bind({"alt", "shift"}, "8", function() 
  yabai({"-m", "window", "--space", "8"})
end)  
hs.hotkey.bind({"alt", "shift"}, "9", function() 
  yabai({"-m", "window", "--space", "9"})
end)  
