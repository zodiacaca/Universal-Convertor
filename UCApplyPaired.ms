
/*************************
	Apply ( Paired )
*************************/

bone = getnodebyname convertInformation[i].old
if bone != undefined and classof bone == BoneGeometry then
(
	bone.name = convertInformation[i].new
	parent = getnodebyname convertInformation[i].parent
	if parent != undefined and classof bone == BoneGeometry then
	(
		bone.parent = parent
	)
	else
	(
		bone.parent = undefined 
	)
	
	for t = 1 to (totalframes + 1) do
	(
		at time (t-1)
		(
			animate on
			(
				offset_x = 0
				offset_y = 0
				offset_z = 0
				
				for ii = 1 to oriTransforms.count do
				(
					if bone == oriTransforms[ii].bone do
					(
-- 						preRotate oriTransforms[ii].transform[t] convertInformation[i].delta
						delta = quatToEuler convertInformation[i].delta
						if convertInformation[i].orth then
						(
							delta = orthDeltas delta
						)
						preRotateZ oriTransforms[ii].transform[t] delta.z
						preRotateY oriTransforms[ii].transform[t] delta.y
						preRotateX oriTransforms[ii].transform[t] delta.x
						
						if bone.parent == undefined then
						(
							oriTransforms[ii].transform[t].row4 = convertInformation[i].offset
						)
						else
						(
							offset_x = convertInformation[i].offset.x
							offset_y = convertInformation[i].offset.y
							offset_z = convertInformation[i].offset.z
							
							trf = bone.parent.transform
							pos = trf.row4
							pos += trf.row1 * offset_x + trf.row2 * offset_y + trf.row3 * offset_z
							
							oriTransforms[ii].transform[t].row4 = pos
						)
						
						bone.transform = oriTransforms[ii].transform[t]
						bone.length = convertInformation[i].length
						appendIfUnique clearExclude bone 
					)
				)
			)
		)
	)
)
else
(
	offset = convertInformation[i].offset
	delta = convertInformation[i].delta
	length = convertInformation[i].length
	parent = getnodebyname convertInformation[i].parent
	if parent != undefined and classof parent == BoneGeometry then
	(
		trf = parent.transform
		pos = parent.position + trf.row1 * offset.x + trf.row2 * offset.y + trf.row3 * offset.z
		preRotate trf delta
		endPos = pos + trf.row1 * length
		bone = BoneSys.createBone pos endPos trf.row3
		bone.parent = parent
	)
	else
	(
		mat = matrix3 1
		preRotate mat delta
		endPos = offset + mat.row1 * length
		bone = BoneSys.createBone offset endPos mat.row3
	)
	bone.name = convertInformation[i].new
	append clearExclude bone
)

