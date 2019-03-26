
/********************
	Generate
********************/

GroupBox grp_generate "Generate Infomation" \
pos:[x_pos,y_pos] width:230 height:142

-- // pick group
GroupBox grp_pick "Pick Up Skeleton" \
pos:[x_pos+gap_x,y_pos+gap_y] width:(230-gap_x*2) height:52

-- source button
button btn_origin "Source" pos:[x_pos+gap_x+offset_x,y_pos+gap_y+offset_y] \
width:50 height:26 \
toolTip:"Select Origin Bones"
on btn_origin pressed do
(
	checkName()
	
	originSkeleton = #()
	-- get the root bones first
	for sel in selection do
	(
		if classof sel == BoneGeometry then
		(
			if sel.parent == undefined then
			(
				sel.WireColor = color 255 255 0
				append originSkeleton sel.name
			)
		)
	)
	-- find all children
	count = originSkeleton.count
	for i = 1 to count do
	(
		bone = getnodebyname originSkeleton[i]
		if classof bone == BoneGeometry then
		(
			findChildrenOrigin bone.name
		)
		updateProgressBar i count
	)
)

-- label
label lbl_pick "->" pos:[x_pos+gap_x+offset_x+55,y_pos+gap_y+offset_y+6] \
width:20 height:20

-- target button
button btn_target "Target" pos:[x_pos+gap_x+offset_x+55+17,y_pos+gap_y+offset_y] \
width:50 height:26 \
toolTip:"Select Target Bones"
on btn_target pressed do
(
	checkName()
	
	hasScaled = ""
	targetSkeleton = #()
	for sel in selection do
	(
		if classof sel == BoneGeometry then
		(
			if sel.parent == undefined then
			(
				scaled = checkTargetScale sel
				if scaled.count > 0 then
				(
					hasScaled = scaled
					messageBox (scaled+" has been scaled, abort.") \
					title:"You shouldn't have done that" beep:true
					exit
				)
				else
				(
					sel.WireColor = color 0 0 255
					append targetSkeleton sel.name
				)
			)
		)
	)
	count = targetSkeleton.count
	for i = 1 to count do
	(
		if hasScaled.count == 0 then
		(
			bone = getnodebyname targetSkeleton[i]
			if classof bone == BoneGeometry then
			(
				scaled = checkTargetScale bone
				if scaled.count > 0 then
				(
					hasScaled = scaled
					messageBox (scaled+" has been scaled, abort.") \
					title:"You shouldn't have done that" beep:true
					exit
				)
				else
				(
					findChildrenTarget bone.name 1
				)
			)
		)
		updateProgressBar i count
	)
)

-- // pair group
GroupBox grp_match "Get Pairs" \
pos:[x_pos+gap_x,y_pos+gap_y+height] width:(230-gap_x*2) height:52

-- pair button
button btn_match "Match" pos:[x_pos+gap_x+offset_x,y_pos+gap_y+height+offset_y] \
width:80 height:26
on btn_match pressed do
(
	name = checkNames()
	if name.count > 0 then
	(
		if queryBox ("\""+name+"\""+" duplicated name, continue?") \
		title:"Matching Box Checker" beep:true then
		(
			openDialog()
		)
	)
	else
	(
		openDialog()
	)
)


-- // functions
fn checkName =
(
	found = ""
	for obj in objects do
	(
		if classof obj == BoneGeometry then
		(
			if findString obj.name "-" == 1 then
			(
				if found.count > 0 then
				(
					found += "\n"
					found += "\n"
				)
				found += "String " + "\"-\"" + " found at the fisrt place in " + "\"" + obj.name + "\"" + "."
			)
			else if findString obj.name "[F]" == 1 then
			(
				if found.count > 0 then
				(
					found += "\n"
					found += "\n"
				)
				found += "String " + "\"[F]\"" + " found at the fisrt place in " + "\"" + obj.name + "\"" + "."
			)
		)
	)
	
	if found.count > 0 then
	(
		messageBox found \
		title:"Please check these names" beep:true
	)
)

fn checkNames =
(
	names = #()
	repeat = ""
	for obj in objects do
	(
		found = findItem names obj.name
		if found > 0 then
		(
			repeat = obj.name
			exit
		)
		else
		(
			append names obj.name
		)
	)
	
	repeat
)

fn checkTargetScale bone =
(
	scaled = ""
	if classof bone == BoneGeometry then
	(
		if abs ((length bone.transform.scalepart) - 1.73205) > 0.001 then
		(
			scaled = bone.name
		)
	)
	
	scaled
)

fn openDialog =
(
	offset_1 = 0
	offset_2 = 0
	
	pairedSkeleton = #()
	remainSkeleton = #()
	
	-- pair bones
	count = targetSkeleton.count
	for i = 1 to count do
	(
		pair = autoPair targetSkeleton[i]
		pairedSkeleton[i] = "-skip-"
		for ii = 1 to originSkeleton.count do
		(
			if autoPair originSkeleton[ii] == pair and pair != undefined then
			(
				if findItem pairedSkeleton originSkeleton[ii] == 0 then
				(
					pairedSkeleton[i] = originSkeleton[ii]
				)
			)
		)
		updateProgressBar i count
	)
	for i = 1 to originSkeleton.count do
	(
		if findItem pairedSkeleton originSkeleton[i] == 0 then
		(
			append remainSkeleton originSkeleton[i]
		)
	)
	
	-- adjust heights
	tall = targetSkeleton.count * 14
	if tall > 200 then
	(
		list_ori_shape.y = tall
		list_tgt_shape.y = tall
	)
	
	-- adjust widths
	-- offset_1 and list 1 width
	c_array = #()
	if targetSkeleton.count > 1 then
	(
		for i = 1 to targetSkeleton.count do
		(
			append c_array targetSkeleton[i].count
		)
		count = amax c_array
		if count * 6.2 > 200 then
		(
			list_tgt_shape.x = count * 6.2
			offset_1 = count * 6.2 - 200
		)
	)
	-- offset_2, list 2 position and width and rollout width
	c_array = #()
	if pairedSkeleton.count > 1 then
	(
		for i = 1 to pairedSkeleton.count do
		(
			append c_array pairedSkeleton[i].count
		)
		count = amax c_array
		if count * 6.2 > 200 then
		(
			list_ori_shape.x = count * 6.2
			offset_2 = count * 6.2 - 200
		)
		list_ori_pos.x = offset_1 + 220
		mathching_dialog_ro_shape.x = (offset_1 + offset_2) + 700
		list_left_pos.x = offset_1 + offset_2 + 440
	)
	
	-- create matching dialog
	if mathching_dialog_rf != undefined do closeRolloutFloater mathching_dialog_rf
	mathching_dialog_rf = newRolloutFloater "" mathching_dialog_ro_shape.x 700 20 20
	addRollout mathching_dialog_ro mathching_dialog_rf
)

fn findChildrenOrigin boneName =
(
	bone = getnodebyname boneName
	if classof bone == BoneGeometry then
	(
		for i = 1 to bone.children.count do
		(
			bone.children[i].WireColor = color 255 255 0
			append originSkeleton bone.children[i].name
			findChildrenOrigin bone.children[i].name
		)
	)
)

fn findChildrenTarget boneName level =
(
	bone = getnodebyname boneName
	-- show level depth
	str = ""
	for c = 1 to level do
	(
		str += "-"
	)
	-- loop
	if classof bone == BoneGeometry then
	(
		for i = 1 to bone.children.count do
		(
			if hasScaled.count == 0 then
			(
				scaled = checkTargetScale bone.children[i]
				if scaled.count > 0 then
				(
					hasScaled = scaled
					messageBox (scaled+" has been scaled, abort.") \
					title:"You shouldn't have done that" beep:true
					exit
				)
				else
				(
					bone.children[i].WireColor = color 0 0 255
					append targetSkeleton (str + bone.children[i].name)
					findChildrenTarget bone.children[i].name (level + 1)
				)
			)
		)
	)
)

fn autoPair boneName =
(
	bone = undefined
	
	-- base name tag
	for n = 1 to nameSets.count do
	(
		for a = 1 to nameSets[n].alternative.count do
		(
			if findString boneName nameSets[n].alternative[a] != undefined then
			(
				bone = nameSets[n].bone
				for exc = 1 to nameSets[n].exclude.count do
				(
					if findString boneName nameSets[n].exclude[exc] != undefined then
					(
						bone = undefined
					)
				)
			)
		)
		if bone != undefined then
		(
			exit
		)
	)
	
	-- extend name tag
	for n = 1 to nameExtends.count do
	(
		for a = 1 to nameExtends[n].alternative.count do
		(
			if findString boneName nameExtends[n].alternative[a] != undefined then
			(
				if bone != undefined then
				(
					bone += nameExtends[n].extend
				)
			)
		)
	)
	
	bone
)
