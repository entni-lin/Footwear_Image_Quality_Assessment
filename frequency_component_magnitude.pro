pro frequency_component_magnitude
; set up working directory
  cd, 'X:\Lily\pHD_research\feature_extraction\all_features\frequency_component'

; loading folder (CS-bounding in grayscale and HQ-bounding in grayscale)
  
  file_path1 = 'X:\Lily\pHD_research\shoeprint images\segmentation\segmented_images\CS_bounding_gray'
  file_path2 = 'X:\Lily\pHD_research\shoeprint images\segmentation\segmented_images\HQ_bounding_gray'

  folders = [file_path1,file_path2]

  foreach element, folders do begin
    files = file_search(element, '*.tif', count=count)

    for iii=0L, n_elements(files)-1 do begin

      imagea = files[iii]
      imageb = read_image(imagea)
      ; define filename - CS and HQ have different filenames
      IF (element EQ file_path1) THEN BEGIN
        name = FILE_BASENAME(imagea,'_segmented_bounding.tif')
        ;name = FILE_BASENAME(imagea, '.png') ; for image format png
        ;name = FILE_BASENAME(imagea, '.jpg') ; for image format jpg
      ENDIF ELSE IF (element EQ file_path2) THEN BEGIN
        name = FILE_BASENAME(imagea,'_EIGEN_Reg_segmented_bounding.tif')
        ;name = FILE_BASENAME(imagea, '.png') ; for image format png
        ;name = FILE_BASENAME(imagea, '.jpg') ; for image format jpg
      ENDIF
      print, "Start processing: ", name
      clock2 = TIC('Computing: ' + STRTRIM(imagea,2)) & $ ;this is for sanity check - see how long each image takes to process
      ; if input image is in grayscale, the dimension is 2 (only height and width of an image) - jump if statement
      s1 = size(imageb, /N_DIMENSIONS)
      IF (s1 NE 2) THEN BEGIN
        imageb = reform(imageb[0,*,*])
      ENDIF
      
      
      ; Fast Fourier transform using FFT function 
      ; Compute the two-dimensional FFT.
      f1 = FFT(imageb, /double, /center)
      ; Compute the magnitude of the magnitude of FFT
      frequency_f1 = abs(f1)
      highest_f1 = max(frequency_f1)
      lowest_f1 = min(frequency_f1)
      
      ;print, 'Frequency components of impressions', frequency_f1
      ;print, 'Highest frequency components of test impressions', highest_f1
      ;print, 'Lowest frequency components of test impressions', lowest_f1
      
      ; a old way to extract out the filename
      ;var_a = STRPOS(imagea,'/', /REVERSE_SEARCH) ; MAC
      ;var_a = STRPOS(imagea,'\', /REVERSE_SEARCH) ; lab computer (windows)
      ;var_aa = STRPOS(imagea, '.tif', /REVERSE_SEARCH)
      ;count_a = var_aa-var_a-1
      ;name = strmid(imagea, var_a+1, count_a)
      

       
      ; each image has its own csv file for the magnitude of frequency components
      store_at = 'X:\Lily\pHD_research\feature_extraction\all_features\frequency_component\all_magnitudes\'
      filename = store_at+name+'_magnitudes.csv'
      ; the trick to have a comma between each value in an array
      PS_size = size(frequency_f1, /DIMENSIONS)
      x_size = PS_size[0]
      openw, inlun2, filename, /get_lun , width= 10000000
      theFormat = '(' + StrTrim(x_size,2) + '(F, :, ","))'
      printf, inlun2, frequency_f1,Format=theFormat
      close,inlun2
      free_lun, inlun2
      
      ; write out max and min magnitude in a separate txt file
      filename2 = 'frequency_components_max_min_magnitudes.txt'
      openw, inlun2, filename2, /get_lun ,/APPEND, width= 10000000
      printf, inlun2, name, ',' , highest_f1, ',', lowest_f1
      close,inlun2
      free_lun, inlun2

      TOC, clock2 & $

      endfor
  endforeach
  TOC
end