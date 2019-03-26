
/******************************
	Universal Convertor
******************************/

clearListener()

-- macroScript universalConvertor category:"Custom Tools"
-- (

mathching_dialog_rf = undefined
mathching_dialog_ro = undefined

list_tgt_shape = [200,200]
list_ori_shape = [200,200]
list_left_shape = [200,400]
list_ori_pos = [220,10]
list_left_pos = [440,200]
mathching_dialog_ro_shape = [700,700]

originSkeleton = #()
targetSkeleton = #()
pairedSkeleton = #()
remainSkeleton = #()

UC_RC_tgt = undefined
UC_RC_ori = undefined
UC_RC_left = undefined

struct convertData
(
	new,
	old,
	offset,
	delta,
	scale,
	orth,
	length,
	parent
)


rollout universal_convertor_ro "Skeleton Convertor" width:260 height:400
(
	-- structs
	struct nameData
	(
		bone,
		alternative,
		exclude
	)
	
	struct nameExtendData
	(
		extend,
		alternative
	)
	
	struct oriTransformData
	(
		bone,
		transform
	)
	
	-- variables
	local XmlDoc
	
	local nameSets = #()
	local nameExtends = #()
	local oriTransforms = #()
	local newTransforms = #()
	local convertInformation = #()
	local clearExclude = #()
	
	local hasFound = ""
	local hasScaled = ""
	
	-- functions
	local findChildrenOrigin
	local findChildrenTarget
	local checkName
	local checkNames
	local checkTargetScale
	local openDialog
	local autoPair
	local readTransforms
	local readConvertData
	local applyTransforms
	local orthDeltas
	local orthDelta
	local clearUsed
	local updateProgressBar
	local rcSaveTemp
	local rcLoadTemp
	local rcUndo
	
	-- base position
	local x_pos = 8
	local y_pos = 215
	local gap_x = 8
	local gap_y = 18
	local offset_x = 8
	local offset_y = 18
	local height = 60
	local y_pos2 = 34
	
	
	-- on rollout open
	on universal_convertor_ro open do
	(
		include "UCRCs.ms"
		
		-- load name sets
		fsource = (getDir #scripts) + "\\name_sets.xml"
		if fsource != undefined then
		(
			XmlDoc = dotNetObject "System.Xml.XmlDocument"
			XmlDoc.Load fsource
			docEle = XmlDoc.documentElement
			if docEle != undefined and docEle.name == "Skeleton" then
			(
				for i = 0 to docEle.childNodes.count - 1 do
				(
					collection = nameData()
					for ii = 0 to docEle.childNodes.itemOf[i].childNodes.count - 1 do
					(
						if docEle.childNodes.itemOf[i].childNodes.itemOf[ii].name == "Bone" then
						(
							collection.bone = docEle.childNodes.itemOf[i].childNodes.itemOf[ii].InnerText
						)
						else if docEle.childNodes.itemOf[i].childNodes.itemOf[ii].name == "Alternatives" then
						(
							alt = #()
							for iii = 0 to docEle.childNodes.itemOf[i].childNodes.itemOf[ii].childNodes.count - 1 do
							(
								append alt docEle.childNodes.itemOf[i].childNodes.itemOf[ii].childNodes.itemOf[iii].InnerText
							)
							collection.alternative = alt
						)
						else if docEle.childNodes.itemOf[i].childNodes.itemOf[ii].name == "Excludes" then
						(
							exc = #()
							for iii = 0 to docEle.childNodes.itemOf[i].childNodes.itemOf[ii].childNodes.count - 1 do
							(
								append exc docEle.childNodes.itemOf[i].childNodes.itemOf[ii].childNodes.itemOf[iii].InnerText
							)
							collection.exclude = exc
						)
					)
					append nameSets collection
				)
			)
		)
		
		-- extend
		fsource = (getDir #scripts) + "\\name_sets_extend.xml"
		if fsource != undefined then
		(
			XmlDoc = dotNetObject "System.Xml.XmlDocument"
			XmlDoc.Load fsource
			docEle = XmlDoc.documentElement
			if docEle != undefined and docEle.name == "Extend" then
			(
				for i = 0 to docEle.childNodes.count - 1 do
				(
					collection = nameExtendData()
					for ii = 0 to docEle.childNodes.itemOf[i].childNodes.count - 1 do
					(
						if docEle.childNodes.itemOf[i].childNodes.itemOf[ii].name == "Ex" then
						(
							collection.extend = docEle.childNodes.itemOf[i].childNodes.itemOf[ii].InnerText
						)
						else if docEle.childNodes.itemOf[i].childNodes.itemOf[ii].name == "Alternatives" then
						(
							alt = #()
							for iii = 0 to docEle.childNodes.itemOf[i].childNodes.itemOf[ii].childNodes.count - 1 do
							(
								append alt docEle.childNodes.itemOf[i].childNodes.itemOf[ii].childNodes.itemOf[iii].InnerText
							)
							collection.alternative = alt
						)
					)
					append nameExtends collection
				)
			)
		)
	)
	
	
	progressBar pb "" pos:[6,7] width:234 height:20 \
	color:(color 0 255 0)
	
	
	include "UCGenerate.ms"
	
	include "UCApply.ms"
	

	fn updateProgressBar index end =
	(
		index = index as float
		end = end as float
		pg = index/end
		pg *= 100
		if index == end then
		(
			pg = 0
		)
		pg = floor pg
		pb.value = pg
	)
	
	fn rcUndo =
	(
		if mathching_dialog_ro.undoLimit > 0 then
		(
			targetSkeleton = deepCopy mathching_dialog_ro.undoArray[mathching_dialog_ro.undoSeq].tgtCopy
			pairedSkeleton = deepCopy mathching_dialog_ro.undoArray[mathching_dialog_ro.undoSeq].oriCopy
			remainSkeleton = deepCopy mathching_dialog_ro.undoArray[mathching_dialog_ro.undoSeq].leftCopy
			mathching_dialog_ro.list_tgt.items = targetSkeleton
			mathching_dialog_ro.list_ori.items = pairedSkeleton
			mathching_dialog_ro.list_left.items = remainSkeleton
			
			if mathching_dialog_ro.undoSeq > 1 then
			(
				mathching_dialog_ro.undoSeq -= 1
			)
			else
			(
				mathching_dialog_ro.undoSeq = mathching_dialog_ro.maxUndo
			)
			mathching_dialog_ro.undoLimit -= 1
		)
	)
	
	fn rcSaveTemp =
	(
		f_path = (getDir #scripts) + "\\temp_list.txt"
		f = createFile f_path
		list = ""
		list += "[Target]"
		for i = 1 to targetSkeleton.count do
		(
			list += "\n"
			list += targetSkeleton[i]
		)
		list += "\n"
		list += "[Paired]"
		for i = 1 to pairedSkeleton.count do
		(
			list += "\n"
			list += pairedSkeleton[i]
		)
		list += "\n"
		list += "[Remain]"
		for i = 1 to remainSkeleton.count do
		(
			list += "\n"
			list += remainSkeleton[i]
		)
		if f == undefined then
		(
			messageBox "Unable to save list." \
			title:"" beep:true
		)
		else
		(
			format list to:f
			close f
			free f
			
			messageBox "Saved successfully." \
			title:"" beep:false
		)
	)
	
	fn rcLoadTemp =
	(
		f_path = (getDir #scripts) + "\\temp_list.txt"
		if f_path != undefined then
		(
			file = openFile f_path
			list = #()
			while eof file == false do
			(
				append list (readLine file)
			)
			tgt = findItem list "[Target]"
			ori = findItem list "[Paired]"
			left = findItem list "[Remain]"
			targetSkeleton = #()
			pairedSkeleton = #()
			remainSkeleton = #()
			for i = (tgt + 1) to (ori-1) do
			(
				append targetSkeleton list[i]
			)
			for i = (ori + 1) to (left-1) do
			(
				append pairedSkeleton list[i]
			)
			for i = (left + 1) to list.count do
			(
				append remainSkeleton list[i]
			)
			mathching_dialog_ro.list_tgt.items = targetSkeleton
			mathching_dialog_ro.list_ori.items = pairedSkeleton
			mathching_dialog_ro.list_left.items = remainSkeleton
			openDialog()
			messageBox "Loaded successfully." \
			title:"" beep:false
		)
		else
		(
			messageBox "Can't load file." \
			title:"" beep:true
		)
	)
)


rollout mathching_dialog_ro "Matching" width:mathching_dialog_ro_shape.x height:700
(
	include "UCMatching.ms"
)

if universal_convertor_rf != undefined do closeRolloutFloater universal_convertor_rf
universal_convertor_rf = newRolloutFloater "" 260 400 20 80
addRollout universal_convertor_ro universal_convertor_rf

-- )
