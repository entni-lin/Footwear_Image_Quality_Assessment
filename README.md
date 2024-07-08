# Footwear Image Quality Assessment
This repository contains the code for image feature extraction (1-5) and the image quality assessment model (6) as proposed and used in E.-T. Lin, Footwear Image Quality Classification: Using Subjective Assessments and Objective Image Metrics to Predict Impression Quality, PhD Dissertation, West Virginia University (2023)

There are four main image features proposed to apply on footwear impression images (including high-quality Handiprints, relatively low-quality dust and blood impressions):
1. Texture analysis features via gray-level co-occurrence matrix (GLCM) in IDL: glcm_shoe.pro
2. Spatial information via magnitudes of pixels after applying Sobel filters in IDL: spatial_information.pro
3. Fourier analysis in IDL and R: RUN "frequency_component_magnitude.pro" first and then "frequency_component_image_index_compute.R"
4. Wavelet analysis using the method and codes by Vu and Chandler (2012) in Matlab: fish_shoe.m, fish.m, fish_bb.m, and dwt_cdf97.m. Note that after the last three files (fish.m, fish_bb.m, and dwt_cdf97.m) are downloaded, the directory path to them needs to be added to Matlab search path to run the first file. <br>
P. V. Vu and D. M. Chandler, "A Fast Wavelet-Based Algorithm for Global and Local Image Sharpness Estimation," in IEEE Signal Processing Letters, vol. 19, no. 7, pp. 423-426, July 2012, doi: 10.1109/LSP.2012.2199980.
5. Totality/complexity (percentage of white pixels - referred to as impressions, perimeters of contours via OpenCV, and create images with bounding box + contours): totality.py

Lastly, the following R code creates quality assessment models using 10 image features extracted from the above codes:

6. quality_model. R includes the code for the two best-quality assessment models.
