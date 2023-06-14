pro glcm_shoe

  ; set working directory
  cd, 'X:\Lily\pHD_research\feature_extraction\all_features\texture'
  ; set file path
   ; loading folder (CS-bounding in grayscale and HQ-bounding in grayscale)
  
   file_path1 = 'X:\Lily\pHD_research\shoeprint images\segmentation\segmented_images\CS_bounding_gray'
   file_path2 = 'X:\Lily\pHD_research\shoeprint images\segmentation\segmented_images\HQ_bounding_gray'
  
   folders = [file_path1,file_path2]
  
  ; loop through each folder in the folders variable 
    
  ; select a folder
  
for jjj=0L, n_elements(folders)-1 do begin
  file_path = folders[jjj]
  files = file_search(file_path, '*.tif')
  
  ; pick the image
  for iii=0L, n_elements(files)-1 do begin
    imagea = files[iii]
     image_b = read_image(imagea)
     image_size = size(image_b)
     
   ; if input image is in grayscale, the dimension is 2 (only height and width of an image) - jump if statement
      if image_size[0] eq 3 then begin
          x_size = image_size(2) & y_size = image_size(3)
          image_b = reform(image_b[0,*,*])
      endif
      
      ; file name and features - CS and HQ have different filenames
      IF (jjj EQ 0) THEN BEGIN
        name = FILE_BASENAME(imagea,'_segmented_bounding.tif')
        ;name = FILE_BASENAME(imagea, '.png') ; for image format png
        ;name = FILE_BASENAME(imagea, '.jpg') ; for image format jpg
      ENDIF ELSE IF (jjj EQ 1) THEN BEGIN
        name = FILE_BASENAME(imagea,'_EIGEN_Reg_segmented_bounding.tif')
        ;name = FILE_BASENAME(imagea, '.png') ; for image format png
        ;name = FILE_BASENAME(imagea, '.jpg') ; for image format jpg
      ENDIF
   
   print, "Start computing texuture features: ", name
   
   ; prepare to create a grayscale co-occurrence matrix
   ; find the maximum and minumum grayscale values
    max_value = max(image_b)
    min_value = min(image_b)

    ; compute the dimension for the co-occurence matrix
    n = ((max_value-min_value)+1.)^2

    ;0 and 180 degrees orientations
    ;-1 shift the in the secind dimension(row); no shift in the first dimension
    unit_of_shift =-1.

    ;0 degree orientation
    ;-1 shift the in the first dimension(column); no shift in the second dimension
    img_shift_0 = shift(image_b,unit_of_shift,0)
    ; trim the redundant row or column - the final column is removed from the shift and orginal matrix
    img_shift_0_1 =  img_shift_0[0: n_elements(img_shift_0[*,0])-2,*]
    ; trim the final column from the original matrix
    imageo_0_1 = image_b[0: n_elements(img_shift_0[*,0])-2,*]

    ;compute GLCM (0)
    ;HIST_2D function returns the two dimensional density function (histogram) of two variables
    glcm_0 = transpose(hist_2D(imageo_0_1,img_shift_0_1,MAX1=max_value,MAX2=max_value,MIN1=min_value,MIN2=min_value))

    ;compute GLCM (180)
    ;HIST_2D function returns the two dimensional density function (histogram) of two variables
    glcm_180 = transpose(glcm_0)


   ;combine two directions of co-matrix 
    glcm_horizontal = glcm_0+glcm_180
    ;normalize (probability) co-matrix
    normalized_glcm_horizontal = glcm_horizontal/total(glcm_horizontal)
 
    ; feature 1 - Angular second moment (ASM) feature or energy - p^2
    energy_ind = normalized_glcm_horizontal^2
    energy1 = total(energy_ind)
    ;print, 'energy1', energy1

    ; feature 2 - contrast - (i-j)^2*p
    ; create a i and j matrix - i and j are gray values
    ; rebin can help replicate the row
    i = rebin([min_value:max_value],(max_value-min_value)+1.,(max_value-min_value)+1.)
    j = transpose(i)
    differ = (i-j)^2.
    differ_2 = reform(differ,n)
    normalized_glcm_horizontal_2 = reform(normalized_glcm_horizontal,n)
    multiply_1 = normalized_glcm_horizontal_2*differ_2
    contrast1 = total(multiply_1)
    ;print, 'contrast1', contrast1

    ; feature 3 - entropy - -ln(p)*p
    ; create a ln(p) matrix
    ln_glcm = -ALOG(normalized_glcm_horizontal)
    ; find where the values are finite
    ;PRINT, WHERE(FINITE(ln_glcm, /INFINITY))
    ln_glcm_2 = reform(ln_glcm,n)
    ; find where the values are finite/infinite, 1 means finite, 2 means infinite
    G = FINITE(ln_glcm_2)
    FIN = WHERE(G eq 1.0)
    INF = WHERE(G eq 0.0)
    ;set the INF to zero
    ln_glcm_2[INF] = 0.0
    multiply_2 = normalized_glcm_horizontal_2*ln_glcm_2
    entropy1 = total(multiply_2)
    ;print, 'entropy', entropy1

    ; feature 4 - homogeneity - p*(1/1+differ)
    inverse_differ_add_one = differ + 1
    inverse_differ_add_one_2 = reform(inverse_differ_add_one,n)
    multiply_4 = normalized_glcm_horizontal_2/inverse_differ_add_one_2
    homogeneity1 = total(multiply_4)
    ;print, 'homogeneity', homogeneity1
  

    ;90 and 270 degrees orientations

    img_shift_90 = shift(image_b,0,unit_of_shift)
    ; trim the redundant row or column - the final row is removed from the shift and orginal matrix
    img_shift_90_1=img_shift_90[*, 0: n_elements(img_shift_90[0,*])-2]
    ; trim the final row from the original matrix
    imageo_90 = image_b[*, 0: n_elements(img_shift_90[0,*])-2]
    ;compute GLCM (90)
    ;HIST_2D function returns the two dimensional density function (histogram) of two variables
    glcm_90 = hist_2D(imageo_90,img_shift_90_1,MAX1=max_value,MAX2=max_value,MIN1=min_value,MIN2=min_value)
    ;compute GLCM (270) - transpose of glcm_90
    glcm_270 = transpose(glcm_90)
    ;combine two directions of co-matrix
    glcm_vertical = glcm_90+glcm_270
    ;normalize (probability) co-matrix
    normalized_glcm_vertical = glcm_vertical/total(glcm_vertical)

    ; feature 1 - Angular second moment (ASM) feature or energy - p^2
    energy_ind = normalized_glcm_vertical^2
    energy2 = total(energy_ind)
    ;print, 'energy', energy2

    ; feature 2 - contrast - (i-j)^2*p
    ; create a i and j matrix - i and j are gray values
    ; rebin can help replicate the row
    i = rebin([min_value:max_value],(max_value-min_value)+1.,(max_value-min_value)+1.)
    j = transpose(i)
    differ = (i-j)^2.
    differ_2 = reform(differ,n)
    normalized_glcm_vertical_2 = reform(normalized_glcm_vertical,n)
    multiply_1 = normalized_glcm_vertical_2*differ_2
    contrast2 = total(multiply_1)
    ;print, 'contrast', contrast2

    ; feature 3 - entropy - -ln(p)*p
    ; create a ln(p) matrix
    ln_glcm = -ALOG(normalized_glcm_vertical)
    ; find where the values are finite
    ln_glcm_2 = reform(ln_glcm,n)
    ; find where the values are finite/infinite, 1 means finite, 2 means infinite
    G = FINITE(ln_glcm_2)
    FIN = WHERE(G eq 1.0)
    INF = WHERE(G eq 0.0)
    ;set the INF to zero
    ln_glcm_2[INF] = 0.0
    multiply_2 = normalized_glcm_vertical_2*ln_glcm_2
    entropy2 = total(multiply_2)
    ;print, 'entropy', entropy2
    
    ; feature 4 - homogeneity - p*(1/1+differ)
    inverse_differ_add_one = differ + 1
    inverse_differ_add_one_2 = reform(inverse_differ_add_one,n)
    multiply_4 = normalized_glcm_vertical_2/inverse_differ_add_one_2
    homogeneity2 = total(multiply_4)
    ;print, 'homogeneity', homogeneity2
  
  
    ;45 and 225 degrees orientations
    img_shift_45 = shift(image_b,unit_of_shift,-unit_of_shift)
    ; trim the redundant row or column - the final column and first row is removed from the shift and orginal matrix
    img_shift_45_1 =  img_shift_45[0: n_elements(img_shift_45[*,0])-2,1: n_elements(img_shift_45[0,*])-1]
    ;trim the redundant row or column - the final column and final row is removed from the shift and orginal matrix
    imageo_0_1 = image_b[0: n_elements(img_shift_45[*,0])-2,1: n_elements(img_shift_45[0,*])-1]
    ;compute GLCM (45)
    ;HIST_2D function returns the two dimensional density function (histogram) of two variables
    glcm_45 = hist_2D(imageo_0_1,img_shift_45_1,MAX1=max_value,MAX2=max_value,MIN1=min_value,MIN2=min_value)
    ;compute GLCM (225)
    ;HIST_2D function returns the two dimensional density function (histogram) of two variables
    glcm_225 = transpose(glcm_45)

    ;combine two directions of co-matrix
    glcm_secondary_diagonal = glcm_45+glcm_225
    ;normalize (probability) co-matrix
    normalized_glcm_secondary_diagonal = glcm_secondary_diagonal/total(glcm_secondary_diagonal)

    ; feature 1 - Angular second moment (ASM) feature or energy - p^2
    energy_ind = normalized_glcm_secondary_diagonal^2
    energy3 = total(energy_ind)
    ;print, 'energy', energy3

    ; feature 2 - contrast - (i-j)^2*p
    ; create a i and j matrix - i and j are gray values
    ; rebin can help replicate the row
    i = rebin([min_value:max_value],(max_value-min_value)+1.,(max_value-min_value)+1.)
    j = transpose(i)
    differ = (i-j)^2.
    differ_2 = reform(differ,n)
    normalized_glcm_secondary_diagonal_2 = reform(normalized_glcm_secondary_diagonal,n)
    multiply_1 = normalized_glcm_secondary_diagonal_2*differ_2
    contrast3 = total(multiply_1)
    ;print, 'contrast', contrast3

    ; feature 3 - entropy - -ln(p)*p
    ; create a ln(p) matrix
    ln_glcm = -ALOG(normalized_glcm_secondary_diagonal)
    ; find where the values are finite
    ln_glcm_2 = reform(ln_glcm,n)
    ; find where the values are finite/infinite, 1 means finite, 2 means infinite
    G = FINITE(ln_glcm_2)
    FIN = WHERE(G eq 1.0)
    INF = WHERE(G eq 0.0)
    ;set the INF to zero
    ln_glcm_2[INF] = 0.0
    multiply_2 = normalized_glcm_secondary_diagonal_2*ln_glcm_2
    entropy3 = total(multiply_2)
    ;print, 'entropy', entropy3

    ; feature 4 - homogeneity - p*(1/1+differ)
    inverse_differ_add_one = differ + 1
    inverse_differ_add_one_2 = reform(inverse_differ_add_one,n)
    multiply_4 = normalized_glcm_secondary_diagonal_2/inverse_differ_add_one_2
    homogeneity3 = total(multiply_4)
    ;print, 'homogeneity', homogeneity3

    ;135 and 315 degrees orientations
    img_shift_135 = shift(image_b,-unit_of_shift,-unit_of_shift)
    ; trim the redundant row or column - the first column and first row is removed from the shift and orginal matrix
    img_shift_135_1 =  img_shift_135[1: n_elements(img_shift_135[*,0])-1,1: n_elements(img_shift_135[0,*])-1]
    ;trim the redundant row or column - the first column and final row is removed from the shift and orginal matrix
    imageo_0_1 = image_b[1: n_elements(img_shift_135[*,0])-1,1: n_elements(img_shift_135[0,*])-1]
    ;compute GLCM (135)
    ;HIST_2D function returns the two dimensional density function (histogram) of two variables
    glcm_135 = hist_2D(imageo_0_1,img_shift_135_1,MAX1=max_value,MAX2=max_value,MIN1=min_value,MIN2=min_value)
    ;compute GLCM (315)
    ;HIST_2D function returns the two dimensional density function (histogram) of two variables
    ;315 degree orientation is the transpose of the 135 degree orientation
    glcm_315 = transpose(glcm_135)
    ;combine two directions of co-matrix
    glcm_primary_diagonal = glcm_135+glcm_315
    ;normalize (probability) co-matrix
    normalized_glcm_primary_diagonal = glcm_primary_diagonal/total(glcm_primary_diagonal)

    ; feature 1 - Angular second moment (ASM) feature or energy - p^2
    energy_ind = normalized_glcm_primary_diagonal^2
    energy4 = total(energy_ind)
    ;print, 'energy', energy4

    ; feature 2 - contrast - (i-j)^2*p
    ; create a i and j matrix - i and j are gray values
    ; rebin can help replicate the row
    i = rebin([min_value:max_value],(max_value-min_value)+1.,(max_value-min_value)+1.)
    j = transpose(i)
    differ = (i-j)^2.
    differ_2 = reform(differ,n)
    normalized_glcm_primary_diagonal_2 = reform(normalized_glcm_primary_diagonal,n)
    multiply_1 = normalized_glcm_primary_diagonal_2*differ_2
    contrast4 = total(multiply_1)
    ;print, 'contrast', contrast4

    ; feature 3 - entropy - -ln(p)*p
    ; create a ln(p) matrix
    ln_glcm = -ALOG(normalized_glcm_primary_diagonal)
    ;print, ln_glcm
    ; find where the values are finite
    ln_glcm_2 = reform(ln_glcm,n)
    ; find where the values are finite/infinite, 1 means finite, 2 means infinite
    G = FINITE(ln_glcm_2)
    FIN = WHERE(G eq 1.0)
    INF = WHERE(G eq 0.0)
    ;set the INF to zero
    ln_glcm_2[INF] = 0.0
    multiply_2 = normalized_glcm_primary_diagonal_2*ln_glcm_2
    entropy4 = total(multiply_2)
    ;print, 'entropy', entropy4

    ; feature 4 - homogeneity - p*(1/1+differ)
    inverse_differ_add_one = differ + 1
    inverse_differ_add_one_2 = reform(inverse_differ_add_one,n)
    multiply_6 = normalized_glcm_primary_diagonal_2/inverse_differ_add_one_2
    homogeneity4 = total(multiply_6)
    ;print, 'homogeneity', homogeneity4


    ; compute a mean of each feature based on values derived from four directions 
    energy_all = [energy1,energy2,energy3,energy4]
    energy_mean = mean(energy_all, /DOUBLE)
    contrast_all = [contrast1,contrast2,contrast3,contrast4]
    contrast_mean = mean(contrast_all, /DOUBLE)
    entropy_all = [entropy1,entropy2,entropy3,entropy4]
    entropy_mean = mean(entropy_all, /DOUBLE)
    homogeneity_all = [homogeneity1,homogeneity2,homogeneity3,homogeneity4]
    homogeneity_mean = mean(homogeneity_all, /DOUBLE)
    
    ; list out all features
        
    ; order of output: 'filename', 'mean_energy','mean_contrast','mean_entropy','mean_homogeneity', '0/180 energy', '0/180 contrast', '0/180 entropy','0/180 homogeneity','90/270 energy', '90/270 contrast', '90/270 entropy', '90/270 homogeneity', '45/225 energy', '45/225 contrast', '45/225 entropy', '45/225 homogeneity', '135/315 energy', '135/315 contrast', '135/315 entropy', '135/315 homogeneity'

   ; write out the results for the remaining images    
    filename = "texture_features.txt"
    openw, inlun2, filename, /get_lun ,/APPEND, width= 10000
    printf, inlun2, name, ",", energy_mean,",", contrast_mean,",", entropy_mean,",", homogeneity_mean,",", energy1,",", contrast1,",", entropy1,",", homogeneity1,",", energy2,",", contrast2,",", entropy2,",", homogeneity2,",", energy3,",", contrast3,",", entropy3,",", homogeneity3,",", energy4,",", contrast4,",", entropy4,",", homogeneity4
    close,inlun2
    free_lun, inlun2
  
  endfor
  
endfor

end 