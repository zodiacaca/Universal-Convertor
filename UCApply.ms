
/********************
	Apply
********************/

local chk_height = 18

local state_left = false
local state_finger = false
local state_clear = true
local state_name = false
local state_dir = false

local directions = #(90,180,-90)
local dir = 0

GroupBox grp_apply "Apply Infomation" \
pos:[x_pos,y_pos2] width:230 height:(78+chk_height*5)


checkBox chk_left "Include Unpaired Origin Bones" \
pos:[x_pos+offset_x,y_pos2+offset_y] width:200 height:18
tooltip:"Their parents will be reassigned as the world"
on chk_left changed state do
(
	state_left = state
)

checkBox chk_finger "Fast Finger Alignment" \
pos:[x_pos+offset_x,y_pos2+offset_y+chk_height*1] width:200 height:18
tooltip:"Fingers' deltas between new and old will be orthogonalized"
on chk_finger changed state do
(
	state_finger = state
)

checkBox chk_clear "Clear Unused Bones" \
pos:[x_pos+offset_x,y_pos2+offset_y+chk_height*2] width:200 height:18 \
checked:state_clear
on chk_clear changed state do
(
	state_clear = state
)

checkBox chk_name "Change Names Only" \
pos:[x_pos+offset_x,y_pos2+offset_y+chk_height*3] width:200 height:18 
on chk_name changed state do
(
	state_name = state
)

checkBox chk_dir "Change Direction" \
pos:[x_pos+offset_x,y_pos2+offset_y+chk_height*4] width:200 height:18 
on chk_dir changed state do
(
	universal_convertor_ro.rdo_dir.enabled = state
	state_dir = state
	if state then
	(
		dir = directions[universal_convertor_ro.rdo_dir.state]
	)
	else
	(
		dir = 0
	)
)

radioButtons rdo_dir "" pos:[x_pos+offset_x,y_pos2+offset_y+chk_height*4+20] \
labels:#("90","180","-90") \
width:200 height:30 columns:4 \
default:1 enabled:state_dir
on rdo_dir changed stat do
(
	dir = directions[stat]
)

-- apply button
button btn_apply "Apply" pos:[x_pos+offset_x,y_pos2+offset_y+chk_height*4+44] \
width:80 height:26
on btn_apply pressed do
(
	fsource = GetOpenFileName \
	caption:"Select File" \
	types: "Xml (*.)|*.xml|"

	if fsource != undefined then
	(
		readTransforms()
		
		convertInformation = #()
		
		XmlDoc = dotNetObject "System.Xml.XmlDocument"
		XmlDoc.Load fsource
		docEle = XmlDoc.documentElement
		if docEle != undefined and docEle.name == "Root" then
		(
			for i = 0 to docEle.childNodes.count - 1 do
			(
				data = readConvertData docEle.ChildNodes.itemOf[i]
				append convertInformation data
			)
		)

		if state_name then
		(
			clearExclude = #()
			
			for i = 1 to convertInformation.count do
			(
				old = convertInformation[i].old
				new = convertInformation[i].new
				
				bone = getnodebyname old
				if bone != undefined and classof bone == BoneGeometry then
				(
					bone.name = new
					appendIfUnique clearExclude bone
				)
			)
		)
		else
		(
			applyTransforms()
			clearUsed()
		)
		
		if state_dir then
		(
			readTransforms()
			totalframes = animationrange.end as Integer/ticksperframe
			count = oriTransforms.count
			
			for i = 1 to count do
			(
				bone = oriTransforms[i].bone
				if bone != undefined then
				(
					print bone
					for t = 1 to (totalframes + 1) do
					(
						at time (t-1)
						(
							animate on
							(
								rotateZ oriTransforms[i].transform[t] dir
								bone.transform = oriTransforms[i].transform[t]
							)
						)
					)
				)
				updateProgressBar i count
			)
		)
	)
)


-- // functions
fn readTransforms =
(
	oriTransforms = #()
	totalframes = animationrange.end as Integer/ticksperframe
	for obj in objects do
	(
		if classof obj == BoneGeometry then
		(
			trf = #()
			for t = 1 to (totalframes + 1) do
			(
				at time (t - 1)
				(
					append trf obj.transform
				)
			)
			data = oriTransformData()
			data.bone = obj
			data.transform = trf
			append oriTransforms data
		)
	)
)

fn readConvertData node =
(
	data = convertData()
	data.new = (node.attributes.getNamedItem "Target").value
	data.old = (node.attributes.getNamedItem "Origin").value
	data.offset = execute (node.attributes.getNamedItem "Offset").value
	data.delta = execute (node.attributes.getNamedItem "Delta").value
	data.scale = execute (node.attributes.getNamedItem "Scale").value
	data.orth = execute (node.attributes.getNamedItem "Orth").value
	data.length = (node.attributes.getNamedItem "NewLength").value as float
	data.parent = (node.attributes.getNamedItem "NewParent").value
	
	data
)

fn applyTransforms =
(
	clearExclude = #()
	totalframes = animationrange.end as Integer/ticksperframe
	count = convertInformation.count
	
	for i = 1 to count do
	(
		old = convertInformation[i].old
		new = convertInformation[i].new
		
		if old == new then
		(
			if state_left then
			(
				bone = getnodebyname old
				if bone != undefined and classof bone == BoneGeometry then
				(
					bone.parent = undefined
					for t = 1 to (totalframes + 1) do
					(
						at time (t-1)
						(
							animate on
							(
								for ii = 1 to oriTransforms.count do
								(
									if bone == oriTransforms[ii].bone do
									(
										trf = oriTransforms[ii].transform[t]
										scale = convertInformation[i].scale
										trf.row4 = [trf.row4.x * scale.x,trf.row4.y * scale.y,trf.row4.z * scale.z]
										bone.transform = trf
										appendIfUnique clearExclude bone 
									)
								)
							)
						)
					)
				)
			)
		)
		else
		(
			include "UCApplyPaired.ms"
		)
		
		updateProgressBar i count
	)
)

fn orthDeltas ang =
(
	ang.x = orthDelta ang.x
	ang.y = orthDelta ang.y
	ang.z = orthDelta ang.z
	
	ang
)

fn orthDelta ang =
(
	if ang > 0 then
	(
		remainder = mod ang 90
		if remainder > 45 then
		(
			ang += 90 - remainder
		)
		else
		(
			ang -= remainder
		)
	)
	else
	(
		remainder = mod ang 90
		if remainder < -45 then
		(
			ang -= 90 + remainder
		)
		else
		(
			ang += -remainder
		)
	)
	
	ang
)

fn clearUsed =
(
	clearInclude = #()
	for obj in objects do
	(
		if finditem clearExclude obj == 0 and state_clear and classof obj == BoneGeometry then
		(
			append clearInclude obj
		)
	)
	while clearInclude.count > 0 do
	(
		delete clearInclude[clearInclude.count]
		deleteItem clearInclude clearInclude.count
	)
)
