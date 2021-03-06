(define (apply-strBlinking-effect img logo-layer bcolor npix spat numframe style fcolor fgrad fpat
		shadow? bgshadow fgshadow xshadow yshadow opacity)
  (let* (
  		(old-gradient (car (gimp-context-get-gradient)))
  		(old-pat (car (gimp-context-get-pattern)))
  		(old-fg (car (gimp-context-get-foreground)))
  		(width (car (gimp-drawable-width logo-layer)))
	 	(height (car (gimp-drawable-height logo-layer)))
	 	(tmpLayer)
	 	(newLayer)
		(shadowLayer)
		(inglowLayer)
		(maskLayer)
	 	(patWD)
	 	(cnt)
	 	(y1)
	 	(x2)
	 	(nwd)
	 	(stepW)
	 	)

		(gimp-image-undo-group-start img)
    	(gimp-context-push)

		(script-fu-util-image-resize-from-layer img logo-layer)
		
		(if (= shadow? TRUE)
		(begin
			(if (>= xshadow 0)
			(begin
				(set! width (+ width xshadow))
				(set! x2 0)
			)
			(begin
				(set! width (- width xshadow))
				(set! x2 (- 0 xshadow))
			))
			(if (>= yshadow 0)
			(begin
				(set! height (+ height yshadow))
				(set! y1 0)
			)
			(begin
				(set! height (- height yshadow))
				(set! y1 (- 0 yshadow))
			))
			(gimp-image-resize img width height x2 y1)
		))

		(set! y1 (/ height 2))
		(set! cnt 0)
		
		(gimp-context-set-gradient fgrad)
		(gimp-context-set-pattern spat)
		(set! patWD (car (gimp-pattern-get-info spat)))
		(set! stepW (/ patWD numframe))
		(set! nwd width)
		(set! x2 0)
		(gimp-selection-none img)

		(while (< cnt numframe)
    		(set! newLayer (car (gimp-layer-new img nwd height RGBA-IMAGE "Background" 100 0)))
			(gimp-image-add-layer img newLayer -1)
			
			(cond
              ((= style 0)
              	(gimp-context-set-foreground fcolor)
              	(gimp-edit-fill newLayer FOREGROUND-FILL))
              ((= style 1)
              	(gimp-edit-blend newLayer CUSTOM-MODE NORMAL-MODE GRADIENT-LINEAR 100 0 REPEAT-NONE
                               FALSE FALSE 0 0 0 x2 y1 (- nwd (/ nwd 5)) y1))
              ((= style 2)
              	(gimp-layer-translate newLayer (- 0 x2) 0)
              	;(gimp-layer-set-offsets newLayer (- 0 x2) 0)
              	(gimp-context-set-pattern fpat)
              	(gimp-selection-all img)
              	(gimp-edit-bucket-fill newLayer PATTERN-BUCKET-FILL NORMAL-MODE 100 0 0 0 0)
              	;(gimp-selection-none img)
              	;(gimp-layer-set-offsets newLayer 0 0)
              	(gimp-layer-translate newLayer 0 0)
              	(gimp-selection-all img)
              	)
              	
              ) ; end of cond
            (gimp-context-set-pattern spat)
			(gimp-edit-bucket-fill newLayer PATTERN-BUCKET-FILL NORMAL-MODE 100 255 0 0 0)
			(gimp-layer-set-offsets newLayer (- 0 x2) 0)
			(gimp-layer-resize-to-image-size newLayer)
			
			(gimp-selection-layer-alpha logo-layer)
			(gimp-selection-invert img)
			(gimp-edit-clear newLayer)
			(gimp-selection-invert img)
			(gimp-selection-grow img npix)
		
			(set! tmpLayer (car (gimp-layer-copy newLayer FALSE)))
			(gimp-image-add-layer img tmpLayer -1)
			
			(gimp-context-set-foreground '(255 255 255))
			(gimp-edit-fill tmpLayer FOREGROUND-FILL)
			(set! inglowLayer (car (gimp-layer-copy tmpLayer FALSE)))
			(gimp-image-add-layer img inglowLayer -1)
			(set! maskLayer (car (gimp-layer-create-mask inglowLayer ADD-SELECTION-MASK)))
			(gimp-layer-add-mask inglowLayer maskLayer)
			(gimp-selection-invert img)
			(gimp-selection-feather img 8)
			(gimp-context-set-foreground bcolor)
			(gimp-edit-fill inglowLayer FOREGROUND-FILL)
			(set! tmpLayer (car (gimp-image-merge-down img inglowLayer CLIP-TO-IMAGE)))
			
			;(gimp-context-set-foreground bcolor)
			;(gimp-edit-fill tmpLayer FOREGROUND-FILL)
			(gimp-image-lower-layer img tmpLayer)
			(set! newLayer (car (gimp-image-merge-down img newLayer CLIP-TO-IMAGE)))
			(gimp-selection-none img)
			
			(if (= shadow? TRUE)
			(begin
				(set! shadowLayer (car (gimp-layer-copy newLayer FALSE)))
				(gimp-image-add-layer img shadowLayer -1)
				(gimp-selection-layer-alpha shadowLayer)
				(gimp-context-set-foreground fgshadow)
				(gimp-edit-fill shadowLayer FOREGROUND-FILL)
				(gimp-selection-none img)
				(plug-in-gauss 1 img shadowLayer 5 5 1)
				(gimp-layer-translate shadowLayer xshadow yshadow)
				(gimp-layer-resize-to-image-size shadowLayer)
				
				(set! tmpLayer (car (gimp-layer-copy shadowLayer FALSE)))
				(gimp-image-add-layer img tmpLayer -1)
				(gimp-selection-layer-alpha tmpLayer)
				(gimp-selection-grow img 3)
				(gimp-context-set-foreground bgshadow)
				(gimp-edit-fill tmpLayer FOREGROUND-FILL)
				(gimp-selection-none img)
				(gimp-image-lower-layer img tmpLayer)

				(gimp-layer-set-opacity shadowLayer opacity)
				(set! shadowLayer (car (gimp-image-merge-down img shadowLayer EXPAND-AS-NECESSARY)))
				
				(gimp-image-lower-layer img shadowLayer)
				(gimp-image-merge-down img newLayer EXPAND-AS-NECESSARY)
			))
			
			(set! cnt (+ cnt 1))
			(set! x2 (+ x2 stepW))
			(set! nwd (+ nwd stepW))
		)
    	(gimp-image-remove-layer img logo-layer)
    	
    	(gimp-selection-none img)
    	(gimp-context-set-pattern old-pat)
		(gimp-context-set-gradient old-gradient)
    	(gimp-context-set-foreground old-fg)

    	(gimp-context-pop)
		(gimp-image-undo-group-end img)
		(gimp-displays-flush)
  )
)

(script-fu-register "apply-strBlinking-effect"
		    "<Image>/Script-Fu/Animators/            ..."
		    "                                 "
		    "JamesH"
		    "JamesH"
		    "11/04/2007"
		    "RGBA"
		    SF-IMAGE        "Image"    0
		    SF-DRAWABLE     "Drawable" 0
		    SF-COLOR      _"            "         '(255 0 255)
		    SF-ADJUSTMENT _"            "          '(5 1 16 1 8 0 0)
		    SF-PATTERN    _"            "   		"Sparkle"
		    SF-ADJUSTMENT _"         "            '(3 1 32 1 8 0 0)
		    SF-OPTION     _"                     "    '("Color" "Gradient" "Pattern")
		    SF-COLOR   	  _"      "           '(115 0 255)
		    SF-GRADIENT   _"      "           "tt1"
		    SF-PATTERN    _"      "   		"3D Green"
			SF-TOGGLE     _"      "           TRUE
			SF-COLOR      _"            "   	'(255 255 255)
		    SF-COLOR      _"            "       '(0 0 0)
            SF-ADJUSTMENT _"            X"    	'(5 -99 99 1 1 0 1)
            SF-ADJUSTMENT _"            Y"    	'(5 -99 99 1 1 0 1)
            SF-ADJUSTMENT _"               "     '(75 1 100 1 1 0 1)
)

(define (script-fu-strBlinking text size font bcolor npix spat numframe style fcolor fgrad fpat
		shadow? bgshadow fgshadow xshadow yshadow opacity)
  (let* (
		(img (car (gimp-image-new 256 256 RGB)))
	 	(text-layer (car (gimp-text-fontname img -1 0 0 text 10 TRUE size PIXELS font)))
		)

		(gimp-image-undo-disable img)
		(gimp-drawable-set-name text-layer "      ")
		
		;(set! opacity (- 100 opacity))
		(apply-strBlinking-effect img text-layer bcolor npix spat numframe style fcolor fgrad fpat
			shadow? bgshadow fgshadow xshadow yshadow opacity)
		
		(gimp-image-undo-enable img)
		(gimp-display-new img)
  )
)

(script-fu-register "script-fu-strBlinking"
		    _"_            ..."
		    "                                 "
		    "JamesH"
		    "JamesH"
		    "11/04/2007"
		    ""
		    SF-STRING     _"Text"               "GIMP"
		    SF-ADJUSTMENT _"Font size (pixels)" '(72 24 1000 1 10 0 1)
		    SF-FONT       _"Font"               "Broadway BT"
		    SF-COLOR      _"            "         '(255 0 255)
		    SF-ADJUSTMENT _"            "          '(5 1 16 1 8 0 0)
		    SF-PATTERN    _"            "   		"Sparkle"
		    SF-ADJUSTMENT _"         "            '(3 1 32 1 8 0 0)
		    SF-OPTION     _"                     "    '("Color" "Gradient" "Pattern")
		    SF-COLOR   	  _"      "           '(115 0 255)
		    SF-GRADIENT   _"      "           "tt1"
		    SF-PATTERN    _"      "   		"3D Green"
			SF-TOGGLE     _"      "           TRUE
			SF-COLOR      _"            "   	'(255 255 255)
		    SF-COLOR      _"            "       '(0 0 0)
            SF-ADJUSTMENT _"            X"    	'(5 -99 99 1 1 0 1)
            SF-ADJUSTMENT _"            Y"    	'(5 -99 99 1 1 0 1)
            SF-ADJUSTMENT _"               "     '(75 1 100 1 1 0 1)
)
			
(script-fu-menu-register "script-fu-strBlinking"
			 _"<Toolbox>/Xtns/Script-Fu/Logos")
