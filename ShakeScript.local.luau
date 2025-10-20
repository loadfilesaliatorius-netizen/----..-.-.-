while true do
	local cam = workspace.CurrentCamera
	cam.CFrame=cam.CFrame*CFrame.Angles(math.random(-12,12)/360,math.random(-12,12)/360,math.random(-12,12)/360)
	cam.FieldOfView=math.random(69,71)
	task.wait()
end