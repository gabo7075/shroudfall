local module = {}

local players = game:GetService("Players")

local currentTime = 0
local paused = false

function module.countDown(wantedTime)
	currentTime = wantedTime
	while currentTime > 0 do
		if not paused then
			local plrs = players:GetPlayers()
			for i = 1, #plrs do
				plrs[i].PlayerGui:WaitForChild("TimeGui"):WaitForChild("TextLabel").Text = currentTime
			end
			print(currentTime.." seconds remain.")
			currentTime -= 1
		end
		task.wait(1)
	end
end

function module.addTime(int)
	if int and type(int) == "number" and math.floor(int) == int then
		currentTime += int
		print("Time set to "..currentTime.." seconds.")
	end
end

function module.setTime(int)
	if int and type(int) == "number" and math.floor(int) == int then
		currentTime = int
		print("Time set to "..int.." seconds.")
	end
end

function module.skipTime()
	currentTime = 0
	print("Skipped Timer.")
end

function module.pauseTime()
	paused = true
	print("Timer Paused")
end

function module.unpauseTime()
	paused = false
	print("Timer Unpaused")
end

function module.getCurrentTime()
	return currentTime
end

return module