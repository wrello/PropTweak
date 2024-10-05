-- made by wrello, 10/5/2024
-- v1.0.0

--------------
-- INSTANCE --
--------------
type ValidValueType = boolean | number | string | Vector3 | CFrame | Instance | BrickColor | Color3 | Ray
type PropTweakInstanceType = {
	tweak: (
		refName: string, 
		propPath: string, 
		customUpdateFn: ((inst: Instance, updateVal: ValidValueType, srcProp: any) -> ())?) -> (PropTweakInstanceType)
}

local VAL_TYPE_TO_INST_TYPE = {
	["boolean"] = "BoolValue",
	["number"] = "NumberValue",
	["string"] = "StringValue",
	["Vector3"] = "Vector3Value",
	["CFrame"] = "CFrameValue",
	["Instance"] = "ObjectValue",
	["BrickColor"] = "BrickColorValue",
	["Color3"] = "Color3Value",
	["Ray"] = "RayValue",
}

local function ChildFromPath(parent, path, matchFn)
	if not matchFn then
		local child = parent

		local function forEachMatch(m)
			local v = child[m]
			child = if v ~= nil then v else child[tonumber(m)]
		end

		string.gsub(path, "[^.]+", forEachMatch)

		return child
	else
		local matched = false
		local final = {
			Name = parent.Name,
			Value = parent
		}
		local prev, next = final, nil

		local function forEachMatch(m)
			local v = final.Value[m]
			local t = { 
				Name = m,
				Value = if v ~= nil then v else final.Value[tonumber(m)] 
			}

			if not matched and matchFn(final, t) then
				matched = true
				prev, next = final, t
			end

			final = t
		end

		string.gsub(path, "[^.]+", forEachMatch)

		return prev, next, final
	end
end

local PropTweakInstance = {} 
PropTweakInstance.__index = PropTweakInstance

function PropTweakInstance_new(registryFolder)
	local newPropTweakInstance = setmetatable({}, PropTweakInstance)
	newPropTweakInstance._registryFolder = registryFolder
	newPropTweakInstance._root = registryFolder.Parent

	do -- Making sure we can use dot notation to call functions
		for k, v in PropTweakInstance do
			newPropTweakInstance[k] = function(...)
				return v(newPropTweakInstance, ...)
			end
		end
	end

	return newPropTweakInstance
end

function PropTweakInstance:tweak(refName, propPath, customUpdateFn)
	-- Matching the source instance and property name from the 'propPath'
	local ok, prev, next, final = pcall(ChildFromPath, self._root, propPath, function(prev, next)
		return not prev.Value:FindFirstChild(next.Name)
	end)
	assert(ok, `{prev}\n\n[PropTweak] Invalid 'propPath' "{propPath}"`)
	
	local srcInst, srcProp, srcPropPath, srcVal = prev.Value, next.Name, propPath:match(`^.*({next.Name}.*)$`), final.Value

	local propType = typeof(srcVal) 
	local refInstType = VAL_TYPE_TO_INST_TYPE[propType]
	assert(refInstType, `\n\n[PropTweak] Unsupported property type "{propType}"`)

	local updateSrc; do -- Setting the update function depending on if `customUpdateFn` exists or if the property is writable
		if customUpdateFn then
			updateSrc = function(newRefVal)
				customUpdateFn(srcInst, newRefVal, srcInst[srcProp])
			end
		else
			-- This determines if we can manually set the property on the source instance
			-- E.g. "Size.X" ~= "Size"
			local propWritable = srcPropPath == srcProp
			if propWritable then
				updateSrc = function(newRefVal)
					srcInst[srcProp] = newRefVal
				end
			else
				warn(`[PropTweak] Property "{srcPropPath}" is not writable. Add a 'customUpdateFn' if you want to update the property "{srcInst}" when you change the {refInstType} value instance.`)
			end
		end
	end

	local refInst = self._registryFolder:FindFirstChild(refName)
	if refInst then -- If the reference instance already exists, we will load the value that's in it into the source instance
		if updateSrc then
			updateSrc(refInst.Value)
		end
	else -- Creating the reference instance
		refInst = Instance.new(refInstType)
		refInst.Name = refName
		refInst.Value = srcVal
		refInst.Parent = self._registryFolder
	end

	do -- Syncing the source instance and reference instance's values
		srcInst:GetPropertyChangedSignal(srcProp):Connect(function()
			refInst.Value = ChildFromPath(srcInst, srcPropPath)
		end)
		
		if updateSrc then
			refInst.Changed:Connect(updateSrc)
		end
	end
	
	return self
end

-----------
-- CLASS --
-----------
local PropTweakClass = {}

--[[
	Creates a new registry folder inside the `parent` and returns the new prop tweak associated with it.
]]
function PropTweakClass.root(parent: Instance): PropTweakInstanceType
	local registryFolderName = `{parent.Name}_PropTweak`
	local registryFolder = parent:FindFirstChild(registryFolderName)
	if not registryFolder then
		registryFolder = Instance.new("Folder")
		registryFolder.Name = registryFolderName
		registryFolder.Parent = parent
	end
	return PropTweakInstance_new(registryFolder)
end

return PropTweakClass
