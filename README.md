## Problem:

I'm always annoyed with tweaking properties on vehicles because I have to dive into "CustomPhysicalProperties" and alike quite often during runtime only for my changes to cease to exist next play session.

## Solution:
I created an, I believe, elegant solution that puts all properties you want to modify into one "registry" folder as value instances which will auto update the properties when changed. You can then just copy the folder during runtime and paste it into the vehicle in studio after the play session ends to save changes.

## The goal:

- Automatically load values from the registry folder into properties on start (if the registry folder and those values exist)
- Automatically update properties based on changes to the values in the registry folder and vice versa
- Have a simple, intuitive API to create registry folder and values at runtime

## Working API:
```lua
local PropTweak = require(script.PropTweak) -- Module name is "PropTweak"

local vehicleModel = script.Parent -- The current script is inside of a vehicle

PropTweak.root(vehicleModel) -- Parent the registry folder to the vehicle

  -- Setup a property tweak for FrontRightWheel.Massless
  .tweak("FrontRightWheelMassless", "FrontRightWheel.Massless") -- Automatically creates a bool value in the registry folder that, when changed, updates FrontRightWheel.Massless

  -- Setup a property tweak for FrontRightWheel.CustomPhysicalProperties.Density
  -- Note: Need a custom update function because FrontRightWheel.CustomPhysicalProperties.Density is readonly
  .tweak("FrontRightWheelDensity", "FrontRightWheel.CurrentPhysicalProperties.Density", function(inst, updateVal, srcProp)
    inst.CustomPhysicalProperties = PhysicalProperties.new(
      updateVal, -- New density
      srcProp.Friction, -- Old friction
      srcProp.Elasticity) -- Old elasticity
  end)
```
All cleaned up:
```lua
local PropTweak = require(script.PropTweak)

local vehicleModel = script.Parent

PropTweak.root(vehicleModel)
  .tweak("FrontRightWheelMassless", "FrontRightWheel.Massless")
  .tweak("FrontRightWheelDensity", "FrontRightWheel.CurrentPhysicalProperties.Density", function(inst, updateVal, srcProp)
    inst.CustomPhysicalProperties = PhysicalProperties.new(
      updateVal,
      srcProp.Friction,
      srcProp.Elasticity)
  end)
```
Created registry folder:
![image](https://github.com/user-attachments/assets/227a25a2-9578-4945-bf59-4f40d7e23178)
