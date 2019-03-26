
/********************
	Matching
********************/

listBox list_ori "Origin Skeleton" pos:list_ori_pos \
width:list_ori_shape.x height:200 \
toolTip:"Right-Click Tag Fingers"
listBox list_tgt "Target Skeleton" pos:[10,10] \
width:list_tgt_shape.x height:200 \
listBox list_left "Remain Bones" pos:list_left_pos \
width:list_left_shape.x height:200 \

struct undoData
(
	tgtCopy,
	oriCopy,
	leftCopy
)

local pos_x = list_ori_pos.x + list_ori_shape.x + 15
local pos_y = 20
local offset_x = 8
local offset_y = 20
local height = 60
local check_gap = 20

local undoSeq = 0
local undoLimit = 0
local maxUndo = 5

local tgtSel = 1
local oriSel = 1
local leftSel = 1
local detectFinger = true

local targetSkeletonCopy = #()
local pairedSkeletonCopy = #()
local remainSkeletonCopy = #()
local undoArray = #()

local storeLastArrays
local getTransformData
local getTransformDataLeft
local getDelta
local zeroFloats
local zeroFloat
local adjustRightPos
local isFinger


-- // origin group
GroupBox grp_ori "Paired Skeleton Operate" \
pos:[pos_x,pos_y] width:240 height:52

-- origin remove button
button btn_ori_remove "Drop to List Down" pos:[pos_x+offset_x,pos_y+offset_y] \
width:110 height:24
on btn_ori_remove pressed do
(
	storeLastArrays()
	
	if pairedSkeleton[oriSel] != "-skip-" then
	(
		skeleton = deepcopy remainSkeleton
		for i = 1 to skeleton.count do
		(
			remainSkeleton[i+1] = skeleton[i]
		)
		if findString pairedSkeleton[oriSel] "[F]" == 1 then
		(
			pairedSkeleton[oriSel] = subString pairedSkeleton[oriSel] 4 pairedSkeleton[oriSel].count
		)
		remainSkeleton[1] = pairedSkeleton[oriSel]
		pairedSkeleton[oriSel] = "-skip-"
		list_ori.items = pairedSkeleton
		list_left.items = remainSkeleton
	)
)

-- // remain group
GroupBox grp_left "Remain Bones Operate" \
pos:[pos_x,pos_y+height] width:240 height:(52+check_gap)

checkBox chk_finger "Detect Fingers" \
pos:[pos_x+offset_x,pos_y+18+height] width:200 height:18 \
checked:detectFinger
on chk_finger changed state do
(
	detectFinger = state
)

-- remain add buttton
button btn_left_add "Add to Paired List" pos:[pos_x+offset_x,pos_y+offset_y+check_gap+height] \
width:110 height:24
on btn_left_add pressed do
(
	storeLastArrays()
	
	if isFinger remainSkeleton[leftSel] and detectFinger then
	(
		for i = 1 to 3 do
		(
			if pairedSkeleton[oriSel+i-1] == "-skip-" then
			(
				remainSkeleton[leftSel] = "[F]" + remainSkeleton[leftSel]
				pairedSkeleton[oriSel+i-1] = remainSkeleton[leftSel]
				list_ori.items = pairedSkeleton
				list_left.items = deleteItem remainSkeleton leftSel
			)
			else
			(
				append remainSkeleton pairedSkeleton[oriSel+i-1]
				remainSkeleton[leftSel] = "[F]" + remainSkeleton[leftSel]
				pairedSkeleton[oriSel+i-1] = remainSkeleton[leftSel]
				deleteItem remainSkeleton leftSel
				list_ori.items = pairedSkeleton
				list_left.items = remainSkeleton
			)
		)
	)
	else
	(
		if pairedSkeleton[oriSel] == "-skip-" then
		(
			pairedSkeleton[oriSel] = remainSkeleton[leftSel]
			list_ori.items = pairedSkeleton
			list_left.items = deleteItem remainSkeleton leftSel
		)
		else
		(
			append remainSkeleton pairedSkeleton[oriSel]
			pairedSkeleton[oriSel] = remainSkeleton[leftSel]
			deleteItem remainSkeleton leftSel
			list_ori.items = pairedSkeleton
			list_left.items = remainSkeleton
		)
	)
)

-- // button save
button btn_save "OK, save them to file" pos:[pos_x+110,pos_y+check_gap+height*2] \
width:130 height:28
on btn_save pressed do
(
	try
	(
		XmlDoc = dotNetObject "System.Xml.XmlDocument"
		root = XmlDoc.createElement "Root"
		XmlDoc.appendChild root
		
		count = targetSkeleton.count
		for i = 1 to count do
		(
			data = getTransformData i
			
			newElement = XmlDoc.createElement "Data"

			-- set attributes on the new elements
			newElement.setAttribute "Target" data.new
			newElement.setAttribute "Origin" data.old
			newElement.setAttribute "Offset" (data.offset as string)
			newElement.setAttribute "Delta" (data.delta as string)
			newElement.setAttribute "Scale" (data.scale as string)
			newElement.setAttribute "Orth" (data.orth as string)
			newElement.setAttribute "NewLength" (data.length as string)
			newElement.setAttribute "NewParent" data.parent
			
			-- append the new element to the root element. 
			root.appendChild newElement
		)
		
		for i = 1 to remainSkeleton.count do
		(
			data = getTransformDataLeft i
			
			newElement = XmlDoc.createElement "Data"

			-- set attributes on the new elements
			newElement.setAttribute "Target" data.new
			newElement.setAttribute "Origin" data.old
			newElement.setAttribute "Offset" (data.offset as string)
			newElement.setAttribute "Delta" (data.delta as string)
			newElement.setAttribute "Scale" (data.scale as string)
			newElement.setAttribute "Orth" (data.orth as string)
			newElement.setAttribute "NewLength" (data.length as string)
			newElement.setAttribute "NewParent" data.parent
			
			-- append the new element to the root element. 
			root.appendChild newElement
		)
		
		f_path = getSavePath caption:"Choose the file directory"
		if f_path != undefined then
		(
			f_path += "//convert_info.xml"
			XmlDoc.save f_path
		)
	)
	catch
	(
		universal_convertor_ro.rcSaveTemp()
		messageBox "Failed to generate information, but lists saved." \
		title:"Generate failed" beep:true
	)
)


-- // selections
on list_tgt selected sel do
(
	tgtSel = sel
	adjustRightPos()
)

on list_ori selected sel do
(
	oriSel = sel
	
	name = pairedSkeleton[sel]
	if findString name "[F]" == 1 then
	(
		name = subString name 4 name.count
		
	)
	bone = getnodebyname name
	if bone != undefined then
	(
		if (classof $) == Editable_mesh then
		(
			skinOps.selectBoneByNode $.modifiers[#skin] bone
		)
		else
		(
			select bone
		)
	)
	
	adjustRightPos()
)

on list_left selected sel do
(
	leftSel = sel
	
	bone = getnodebyname remainSkeleton[sel]
	if bone != undefined then
	(
		if (classof $) == Editable_mesh then
		(
			skinOps.selectBoneByNode $.modifiers[#skin] bone
		)
		else
		(
			select bone
		)
	)
)


-- // right clicks
on list_tgt rightClick sel do
(
	list_tgt.selection = sel
	tgtSel = sel
	popUpMenu UC_RC_tgt
)

on list_ori rightClick sel do
(
	list_ori.selection = sel
	oriSel = sel
	popUpMenu UC_RC_ori
)

on list_left rightClick sel do
(
	list_left.selection = sel
	leftSel = sel
	popUpMenu UC_RC_left
)


-- // open event
on mathching_dialog_ro open do
(
	targetSkeletonCopy = #()
	pairedSkeletonCopy = #()
	remainSkeletonCopy = #()
	
	list_ori.items = pairedSkeleton
	list_tgt.items = targetSkeleton
	list_left.items = remainSkeleton
	list_ori.height = list_ori_shape.y
	list_tgt.height = list_tgt_shape.y
	list_left.height = list_left_shape.y
	
	undoArray = #()
	
	for i = 1 to maxUndo do
	(
		undoArray[i] = undoData()
	)
)


-- // functions
fn storeLastArrays =
(
	if undoSeq < maxUndo then
	(
		undoSeq += 1
	)
	else
	(
		undoSeq = 1
	)
	if undoLimit < maxUndo then
	(
		undoLimit += 1
	)
	undoArray[undoSeq].tgtCopy = deepCopy targetSkeleton
	undoArray[undoSeq].oriCopy = deepCopy pairedSkeleton
	undoArray[undoSeq].leftCopy = deepCopy remainSkeleton
)

fn getTransformData i =
(
	-- initialize data
	data = convertData()
	data.new = ""
	data.old = ""
	data.offset = [0,0,0]
	data.delta = undefined
	data.scale = [1,1,1]
	data.orth = false
	data.length = 1
	data.parent = ""
	
	-- remove "-"s
	new = targetSkeleton[i]
	while findString new "-" == 1 do
	(
		new = substring new 2 (new.count - 1)
	)
	new = getnodebyname new
	old = pairedSkeleton[i]
	if findString old "[F]" == 1 then
	(
		old = subString old 4 old.count
		data.orth = true
	)
	
	old = getnodebyname old
	if classof old == BoneGeometry then
	(
		data.old = old.name
		old_scale = old.transform.scalepart		-- scale matters
		data.scale = old_scale
		if classof new == BoneGeometry then
		(
			data.new = new.name
			new_scale = new.transform.scalepart
			mat_old = scale old.transform [1/old_scale.x,1/old_scale.y,1/old_scale.z]
			mat_new = scale new.transform [1/new_scale.x,1/new_scale.y,1/new_scale.z]
			data.delta = zeroFloats (getDelta mat_old mat_new)
			data.length = new.length
			if new.parent == undefined then
			(
				data.offset = zeroFloats new.position
			)
			else
			(
				mat1 = new.parent.transform
				mat2 = new.transform
				mat = mat2 * (inverse mat1)
				data.offset = zeroFloats mat.row4
				data.parent = new.parent.name
			)
		)
	)
	else
	(
		if classof new == BoneGeometry then
		(
			data.new = new.name
			data.length = new.length
			if new.parent == undefined then
			(
				data.offset = zeroFloats new.position
				data.delta = new.transform as quat
			)
			else
			(
				mat1 = new.parent.transform
				mat2 = new.transform
				mat = mat2 * (inverse mat1)
				data.offset = zeroFloats mat.row4
				data.delta = mat as quat
				data.parent = new.parent.name
			)
		)
	)
	
	data
)

fn getTransformDataLeft i =
(
	data = convertData()
	data.new = ""
	data.old = ""
	data.offset = [0,0,0]
	data.delta = undefined
	data.scale = [1,1,1]
	data.length = 1
	data.orth = false
	data.parent = ""
	
	old = getnodebyname remainSkeleton[i]
	
	if classof old == BoneGeometry then
	(
		data.new = old.name
		old_scale = old.transform.scalepart
		data.scale = old_scale
		if old.parent == undefined then
		(
			data.offset = zeroFloats old.position
			trf = old.transform
			scale trf [1/old_scale.x,1/old_scale.y,1/old_scale.z]
			data.delta = trf as quat
		)
		else
		(
			parent_scale = old.parent.transform.scalepart
			mat1 = scale old.parent.transform [1/parent_scale.x,1/parent_scale.y,1/parent_scale.z]
			mat2 = scale old.transform [1/old_scale.x,1/old_scale.y,1/old_scale.z]
			mat = mat2 * (inverse mat1)
			data.offset = zeroFloats mat.row4
-- 			data.delta = mat as quat
			data.delta = zeroFloats (mat as eulerangles)
			data.parent = old.parent.name
		)
		data.old = old.name
	)
	
	data
)

fn getDelta old new =
(
	ang = new * (inverse old)
	
	ang = ang as eulerangles
)

fn zeroFloats point3 =
(
	point3.x = zeroFloat point3.x
	point3.y = zeroFloat point3.y
	point3.z = zeroFloat point3.z
	
	point3
)

fn zeroFloat float =
(
	if abs float < 0.001 then
	(
		float = 0
	)
	
	float
)

fn isFinger bone =
(
	is = false
	
	if matchPattern bone pattern:"*finger*" then
	(
		is = true
	)
	else if matchPattern bone pattern:"*thumb*" then
	(
		is = true
	)
	else if matchPattern bone pattern:"*index*" then
	(
		is = true
	)
	else if matchPattern bone pattern:"*middle*" then
	(
		is = true
	)
	else if matchPattern bone pattern:"*ring*" then
	(
		is = true
	)
	else if matchPattern bone pattern:"*pinky*" then
	(
		is = true
	)
	else
	(
		is = false
	)
	
	is
)

fn adjustRightPos =
(
-- 	mathching_dialog_ro.grp_tgt.pos.y = pos_y+mathching_dialog_ro.scrollPos
-- 	mathching_dialog_ro.btn_tgt_remove.pos.y = pos_y+20+mathching_dialog_ro.scrollPos
	mathching_dialog_ro.grp_ori.pos.y = pos_y+mathching_dialog_ro.scrollPos
	mathching_dialog_ro.btn_ori_remove.pos.y = pos_y+offset_y+mathching_dialog_ro.scrollPos
	mathching_dialog_ro.grp_left.pos.y = pos_y+height+mathching_dialog_ro.scrollPos
	mathching_dialog_ro.chk_finger.pos.y = pos_y+18+height+mathching_dialog_ro.scrollPos
	mathching_dialog_ro.btn_left_add.pos.y = pos_y+offset_y+check_gap+height+mathching_dialog_ro.scrollPos
	mathching_dialog_ro.btn_save.pos.y = pos_y+check_gap+height*2+mathching_dialog_ro.scrollPos
	mathching_dialog_ro.list_left.pos.y = list_left_pos.y+16+mathching_dialog_ro.scrollPos
)
