# -*- coding: utf-8 -*-
"""
Totality

This file copmutes the total number of white/black pixels, and the corresponding percentages. This file also computes perimeter based on cotour.
The cotours which are used to compute perimeter are drawn and save out.
"""
import os
import numpy as np
import pandas as pd
import cv2

# The two methods operate on binary masks.
file_path_binary = r"X:\Lily\pHD_research\shoeprint images\segmentation\mask_binary"
# This is needed even though there is only one folder to prevent from the future error in the loop
file_paths =[file_path_binary];
# 
file_path_store = r"X:\Lily\pHD_research\shoeprint images\segmentation\mask_bounding_box"
file_path_store_2 = r"X:\Lily\pHD_research\shoeprint images\segmentation\mask_bounding_box\sub_bounding"
file_path_store_3 = r"X:\Lily\pHD_research\shoeprint images\segmentation\mask_binary_all_contour"
file_path_store_4 = r"X:\Lily\pHD_research\shoeprint images\segmentation\mask_binary_external_contour"
column_names = ["filename", "number_of_black_pix", "number_of_white_pix", "per_black", "per_white","number_of_black_pix_bound", "number_of_white_pix_bound", "per_black_bound", "per_white_bound", "ratio_bound","num_contours","perimeter"];
df = pd.DataFrame(columns=column_names)


for folder_name in file_paths: #if there is more than one folder which needs to be looped, but all images are stored in the same folder 
    current_folder = folder_name
    file_list = os.listdir(current_folder)
    file_name = [file for file in file_list if file.endswith('.png')] #only select the png file (mask) ## if file is not in png, do not select
    for image_path in file_name:
        print(image_path + " is processing and computing.")
        image = cv2.imread(os.path.join(current_folder,image_path))
        h, w, c = image.shape[:3]
        ## convert an image into grayscale if image is in RGB originally
        if c == 3:
            image = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)   
        # make two copies of the mask so they can be used 
        copy = cv2.cvtColor(image, cv2.COLOR_GRAY2BGR)
        copy2 = image.copy()
        h, w = image.shape
        # count the total number of black pixels
        n_black = np.sum(image==0) 
        print("Number of black pixels (ref to background): " + str(n_black))
        # the total number of pixels
        n_total = h*w
        # the total number of white pixels is computed by the total number of pixels - the total number of black pixels
        n_white = n_total-n_black
        print("Number of white pixels (ref to foreground): " + str(n_white))
        percentage_black = (n_black/n_total) * 100
        percentage_white = (n_white/n_total) * 100
        print("Percentage of black pixels (ref to background): " + str(percentage_black))
        print("Percentage of white pixels (ref to foreground): " + str(percentage_white))
        
        ### find a bounding box based on the four points (the most top-left, top-right, bottom-left, bottom-right) which are non-zero (non-black-pixel)
        # check which coordinate has the non-zero pixel value ()
        positions = np.nonzero(image)
        top = positions[0].min() ## python is column-wise, so the first array (start from 0) or list stores all y-coordinates 
        bottom = positions[0].max()
        left = positions[1].min()  ## the second array stores all x-coordinates
        right = positions[1].max()
        ## this is to draw a boundary box on the image
        ### the argument for the rectangle is (image, start point, end point, )
        output = cv2.rectangle(cv2.cvtColor(image, cv2.COLOR_GRAY2BGR), (left, top), (right, bottom), (0,0,255), 5)
        #define the filename for the outputs using the mask filename
        name_split = image_path.split("_cropped") #split the filename using "_cropped", b/c I only want to have shoeID, number of replicate, medium, and substrate
        name = name_split[0]
        
        # compute the height and width for the bounding box
        height = abs(bottom - top)
        width = abs(right - left)
        bounding_box_area = height*width
        
        # crop the image (mask) based on the bounding box, define the cropped image as "bounding box"
        bounding_box = image[top:bottom, left:right]
        # compute the # of black/white pixels, and the corresponding percentages
        n_black_bounding = np.sum(bounding_box==0)
        n_white_bounding = bounding_box_area - n_black_bounding
        print("Number of black pixels (ref to background) in bounding box: " + str(n_black_bounding))
        print("Number of white pixels (ref to foreground) in bounding box: " + str(n_white_bounding))
        percentage_black_bounding = (n_black_bounding/bounding_box_area) * 100
        percentage_white_bounding = (n_white_bounding/bounding_box_area) * 100
        print("Percentage of black pixels (ref to background) in bounding box: " + str(percentage_black_bounding))
        print("Percentage of white pixels (ref to foreground) in bounding box: " + str(percentage_white_bounding))
        
        # compute the ratio (may be used for interation term)
        ratio = bounding_box_area/n_total
        
        # create a all-black (intensity = 0) image with the same dimension of the image (not in bounding box)
        out2 = np.zeros_like(image)
        
        # create an empty array?
        perimeter_all = []
       
        # contour - find all external and internal contours regardless of the hierarchical level (cv2.RETR_LIST), and no approximatation (APPROX_NONE)
        contours,hierarchy = cv2.findContours(image,cv2.RETR_LIST,cv2.CHAIN_APPROX_NONE)
        
        # check how many groups of contours??
        n_contours = len(contours)
        print("Number of contours: " + str(n_contours))
        # loop through each group of contours or each contour of a group of contours
        for contour in contours:
         # get rectangle bounding contour
         [x,y,w,h] = cv2.boundingRect(contour) # define and find a bounding box for each contour

         # draw rectangle around contour on the original image - with red color (0,0,255) in RGB color format and thickness of 5 px
         cv2.rectangle(copy,(x,y),(x+w,y+h),(0,0,255),5) 
         
         # draw each contour on the all-black image created earlier (passed to the first argument). The second argument is the list of the contours,
         # The third argument -1 means drawing all contours, and the last two arguments are the color (white=255) and thickness (3 px) of the contours
         cv2.drawContours(out2, contour, -1, 255, 3)
         
         # compute the perimeter of each contour, and append each perimeter to the list
         perimeter_all.append(cv2.arcLength(contour,True))
         #print(x,y,w,h)

        # sum all the perimeters from all contours as a global perimeter
        n_perimeter = sum(perimeter_all)
        print("Arc_length (perimeter): " + str(n_perimeter))
        
        ## This is to draw only the most outter contour
        contours_e, hierarchy_e = cv2.findContours(image.copy(), cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_NONE)
        # similarly, create a all-black image based on the dimension of the original image
        out = np.zeros_like(image)
        # On this output, draw all of the contours that we have detected
        # in white, and set the thickness to be 3 pixels
        cv2.drawContours(out, contours_e, -1, 255, 3)
        
        ## If checking images is needed - use custom window b/c the size of the original image is too huge (3000 x 7800)
        # Custom window
        #cv2.namedWindow('custom window - original image', cv2.WINDOW_KEEPRATIO)
        #cv2.imshow('custom window - original image', image)
        #cv2.resizeWindow('custom window', 300, 780)
        #cv2.waitKey(0) # waiting until any key is pressed to close the window
        #cv2.destroyAllWindows()
        
        ## write out resulting imagrs
        
        cv2.imwrite(os.path.join(file_path_store,name) + "_bounding_image.png", output) # original image + bounding box
        cv2.imwrite(os.path.join(file_path_store_2,name) + "_bounding_sub_image.png", copy) # original image + bounding box per contour
        cv2.imwrite(os.path.join(file_path_store_3,name) + "_contour_image.png", out2) # "fake image" based on the original image + draw all contours
        cv2.imwrite(os.path.join(file_path_store_4,name) + "_external_contour_image.png", out) # "fake image" based on the original image + draw only external contours
        
        ## append all feature values per image
        df = df.append({'filename':name, 'number_of_black_pix':n_black, 'number_of_white_pix':n_white, 'per_black':percentage_black, 'per_white':percentage_white, 'number_of_black_pix_bound':n_black_bounding , 'number_of_white_pix_bound':n_white_bounding, 'per_black_bound':percentage_black_bounding, 'per_white_bound':percentage_white_bounding, 'ratio_bound':ratio, 'num_contours':n_contours,'perimeter':n_perimeter},ignore_index=True)


## write out the feature values into one csv file
# define where the file should be stored
csv_path_store = r"X:\Lily\pHD_research\feature_extraction\all_features\totality"
df.to_csv(csv_path_store+'\\totality.csv')  
