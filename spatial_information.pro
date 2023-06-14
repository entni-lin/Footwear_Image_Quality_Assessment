pro spatial_information
; set up working directory
cd, 'X:\Lily\pHD_research\feature_extraction\all_features\spatial_information'

  ; loading folder (CS-bounding in grayscale and HQ-bounding in grayscale)
  
   file_path1 = 'X:\Lily\pHD_research\shoeprint images\segmentation\segmented_images\CS_bounding_gray'
   file_path2 = 'X:\Lily\pHD_research\shoeprint images\segmentation\segmented_images\HQ_bounding_gray'
  
   folders = [file_path1,file_path2]
  
  ; loop through each folder in the folders variable 
  foreach element, folders do begin 
  
  ; files = file_search(element, '*.png', count=count) ;for png images and from one folder (file_path)
  ; files = file_search(element, '*.jpg', count=count); for jpg images and from one folder (file_path)
  files = file_search(element, '*.tif', count=count) ; for tiff images and multiple folders (for each)
   for iii=0L, n_elements(files)-1 do begin
     imagea = files[iii]
     imageb = read_image(imagea)
     clock2 = TIC('Computing: ' + STRTRIM(imagea,2)) & $ ;this is for sanity check - see how long each image takes to process
  ; if input image is in grayscale, the dimension is 2 (only height and width of an image) - jump if statement
     s1 = size(imageb, /N_DIMENSIONS)
     IF (s1 NE 2) THEN BEGIN
       imageb = reform(imageb[0,*,*])
     ENDIF
    

  ; sobel filters 
  kernel_x = [[-1,0,1],[-2,0,2],[-1,0,1]]
  kernel_y = [[-1,-2,-1],[0,0,0],[1,2,1]]
  
  ; apply sobel filters on images directly, however, it set all edge points to zero ---- I don't think this is what I want
  ; imagec = SOBEL(imageb)
  ; need to set edge zero to compute the values of edges - pad zero
  ; check center argument
  filtered_x = convol(float(imageb),kernel_x, /EDGE_ZERO)
  filtered_y = convol(float(imageb), kernel_y, /EDGE_ZERO)
  
  ; check if the white boarder lines could be the issue??
  ; by this, the borders (2 px on each side - the top, bottom, left, right) on the x and y directions are removed
  sl = size(imageb)
  filtered_x = filtered_x[1:sl[1]-2,1:sl[2]-2] 
  filtered_y = filtered_y[1:sl[1]-2,1:sl[2]-2]
  
  ;print, filtered_x 
  ;print, filtered_y
  
  ; compute the magnitude of images
   filters_combined = filtered_x^2 + filtered_y^2
   magnitude = sqrt(filters_combined) ;SI
  
  ; DO NOT USE THESE TWO LINES IF the built-in (approximate) Sobel function is not used
  ;filters_combined = imagec^2 ; DO NOT USE 
  ; magnitude = imagec ; check with the built-in (approximate) Sobel
  ; DO NOT USE THE ABOVE TWO LINES IF the built-in (approximate) Sobel function is not used
  
  ; SANITY CHECK - IF users want to see the result (if TV - display like an image; if print, dispaly in array)
  ;TV, magnitude
  ;print, magnitude
  
  ; compute SI mean
  sl = size(filters_combined) ; new dim - the boarders are removed
  total_pixel = sl[1]*sl[2]
  SI_mean = total(magnitude)/total_pixel
  print, "SI_mean: ",SI_mean
  
  ; compute SI RMS
  SI_rms = sqrt(total(filters_combined)/total_pixel)
  print, "SI_RMS: ",SI_rms
  
  ; compute SI standard deviation
  SI_stdev = sqrt(total(filters_combined-SI_mean^2)/total_pixel)
  print, "SI_stdev: ",SI_stdev
  
  ; file name and features - CS and HQ have different filenames
  IF (element EQ file_path1) THEN BEGIN
    name = FILE_BASENAME(imagea,'_segmented_bounding.tif')
    ;name = FILE_BASENAME(imagea, '.png') ; for image format png
    ;name = FILE_BASENAME(imagea, '.jpg') ; for image format jpg
  ENDIF ELSE IF (element EQ file_path2) THEN BEGIN
    name = FILE_BASENAME(imagea,'_EIGEN_Reg_segmented_bounding.tif')
    ;name = FILE_BASENAME(imagea, '.png') ; for image format png
    ;name = FILE_BASENAME(imagea, '.jpg') ; for image format jpg
  ENDIF

  ; write out results
  filename = 'spatial_inf.txt'
  openw, inlun2, filename, /get_lun ,/APPEND, width= 10000000
  printf, inlun2, name, ',' , SI_mean, ',', SI_rms,',',SI_stdev
  close,inlun2
  free_lun, inlun2
  

  TOC, clock2 & $
  endfor
  endforeach
  TOC
end