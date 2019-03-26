
/********************
	RCs
********************/

rcmenu UC_RC_tgt
(
	menuItem tgt_rmv "Remove"
	on tgt_rmv picked do
	(
		mathching_dialog_ro.storeLastArrays()		-- undo
	
		mathching_dialog_ro.list_tgt.items = deleteItem targetSkeleton mathching_dialog_ro.tgtSel
		if pairedSkeleton[mathching_dialog_ro.tgtSel] != "-skip-" then
		(
			mathching_dialog_ro.list_left.items = append remainSkeleton pairedSkeleton[mathching_dialog_ro.tgtSel]
		)
		mathching_dialog_ro.list_ori.items = deleteItem pairedSkeleton mathching_dialog_ro.tgtSel
	)
)

rcmenu UC_RC_ori
(
	menuItem ori_tag "Tag"
	on ori_tag picked do
	(
		sel = mathching_dialog_ro.oriSel
		if pairedSkeleton[sel] != "-skip-" then
		(
			if findString pairedSkeleton[sel] "[F]" == 1 then
			(
				pairedSkeleton[sel] = subString pairedSkeleton[sel] 4 pairedSkeleton[sel].count
			)
			else
			(
				pairedSkeleton[sel] = "[F]" + pairedSkeleton[sel]
			)
			mathching_dialog_ro.list_ori.items = pairedSkeleton
		)
	)
	
	separator sprt1
	
	menuItem ori_save "Save Lists"
	on ori_save picked do
	(
		universal_convertor_ro.rcSaveTemp()
	)
	
	menuItem ori_load "Load Lists"
	on ori_load picked do
	(
		universal_convertor_ro.rcLoadTemp()
	)
	
	separator sprt2
	
	menuItem ori_undo "Undo"
	on ori_undo picked do
	(
		universal_convertor_ro.rcUndo()
	)
)

rcmenu UC_RC_left
(
	menuItem left_remove "Remove"
	on left_remove picked do
	(
		mathching_dialog_ro.storeLastArrays()
	
		mathching_dialog_ro.list_left.items = deleteItem remainSkeleton mathching_dialog_ro.leftSel
	)
	
	separator sprt1
	
	menuItem left_save "Save Lists"
	on left_save picked do
	(
		universal_convertor_ro.rcSaveTemp()
	)
	
	menuItem left_load "Load Lists"
	on left_load picked do
	(
		universal_convertor_ro.rcLoadTemp()
	)
	
	separator sprt2
	
	menuItem left_undo "Undo"
	on left_undo picked do
	(
		universal_convertor_ro.rcUndo()
	)
)

